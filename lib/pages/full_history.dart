import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prmproject/pages/transaction_detail.dart';
import 'package:prmproject/services/database.dart';
import 'package:prmproject/services/shared_pref.dart';

class FullHistory extends StatefulWidget {
  const FullHistory({super.key});

  @override
  State<FullHistory> createState() => _FullHistoryState();
}

class _FullHistoryState extends State<FullHistory> {
  List<Map<String, dynamic>> allTransactions = [];
  List<Map<String, dynamic>> wallets = [];
  String? userId;
  bool isLoading = true;

  DateTime? selectedMonth;
  String? selectedWalletFilter;
  String searchText = "";
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadData()); // ← thêm Future.microtask
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  _loadData() async {
    userId = await SharedPreferenceHelper().getUserId();
    String? walletJson = await SharedPreferenceHelper().getWallets();
    if (walletJson != null && walletJson.isNotEmpty) {
      List<dynamic> decoded = jsonDecode(walletJson);
      wallets = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (userId != null) {
      try {
        // ✅ Dùng cache thay vì gọi thẳng Firestore
        allTransactions = await DatabaseMethdos().getTransactionsCached(userId!);
      } catch (_) {
        allTransactions = [];
      }
    }
    if (mounted) setState(() => isLoading = false);
  }

  String formatVND(double v) {
    final f = NumberFormat("#,###", "vi_VN");
    return v == 0 ? "0đ" : "${f.format(v)}đ";
  }

  List<Map<String, dynamic>> get filteredTransactions {
    return allTransactions.where((tx) {
      if (selectedMonth != null) {
        String df = DateFormat("MM-yyyy").format(selectedMonth!);
        if (!(tx["Date"] ?? "").toString().endsWith(df)) return false;
      }
      if (selectedWalletFilter != null && (tx["WalletName"] ?? "") != selectedWalletFilter) return false;
      if (searchText.isNotEmpty) {
        String q = searchText.toLowerCase();
        bool match = (tx["Description"] ?? "").toString().toLowerCase().contains(q) ||
            (tx["Category"] ?? "").toString().toLowerCase().contains(q) ||
            (tx["Label"] ?? "").toString().toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  List<DateTime> get availableMonths {
    Set<String> seen = {};
    List<DateTime> months = [];
    for (var tx in allTransactions) {
      String d = tx["Date"] ?? "";
      if (d.length >= 7) {
        String key = d.substring(d.length - 7);
        if (seen.add(key)) {
          var parts = key.split("-");
          if (parts.length == 2) months.add(DateTime(int.tryParse(parts[1]) ?? 2024, int.tryParse(parts[0]) ?? 1));
        }
      }
    }
    months.sort((a, b) => b.compareTo(a));
    return months;
  }

  void _showMonthPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          const Text("Chọn tháng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.all_inclusive, color: Color(0xFF4CAF50)),
            title: const Text("Tất cả tháng"),
            trailing: selectedMonth == null ? const Icon(Icons.check, color: Color(0xFF4CAF50)) : null,
            onTap: () { setState(() => selectedMonth = null); Navigator.pop(ctx); },
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView(shrinkWrap: true, children: availableMonths.map((m) {
              bool isSel = selectedMonth != null && selectedMonth!.month == m.month && selectedMonth!.year == m.year;
              return ListTile(
                title: Text("Tháng ${m.month}/${m.year}", style: const TextStyle(fontSize: 15)),
                trailing: isSel ? const Icon(Icons.check, color: Color(0xFF4CAF50)) : null,
                onTap: () { setState(() => selectedMonth = m); Navigator.pop(ctx); },
              );
            }).toList()),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _showWalletPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          const Text("Lọc theo ví", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ListTile(
            leading: const Icon(Icons.all_inclusive, color: Color(0xFF4CAF50)),
            title: const Text("Tất cả ví"),
            trailing: selectedWalletFilter == null ? const Icon(Icons.check, color: Color(0xFF4CAF50)) : null,
            onTap: () { setState(() => selectedWalletFilter = null); Navigator.pop(ctx); },
          ),
          const Divider(height: 1),
          ...wallets.map((w) => ListTile(
            leading: Icon(w["type"] == "Tracking" ? Icons.visibility_outlined : Icons.account_balance_wallet, color: const Color(0xFF4CAF50)),
            title: Text(w["name"]),
            trailing: selectedWalletFilter == w["name"] ? const Icon(Icons.check, color: Color(0xFF4CAF50)) : null,
            onTap: () { setState(() => selectedWalletFilter = w["name"]); Navigator.pop(ctx); },
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> tx) {
    String txType = tx["Type"] ?? "";
    String subType = tx["SubType"] ?? "";
    String labelField = tx["Label"] ?? "";
    String displayName;
    IconData displayIcon;
    Color displayColor;
    bool isPositive;

    if (txType == "chuyen_tien") {
      displayName = "Chuyển tiền"; displayIcon = Icons.swap_horiz; displayColor = Colors.blue.shade600; isPositive = false;
    } else if (txType == "chuyen_tien_nhan") {
      displayName = "Chuyển tiền"; displayIcon = Icons.swap_horiz; displayColor = const Color(0xFF2E7D32); isPositive = true;
    } else if (subType == "khop_so_du" || labelField == "khop_so_du") {
      displayName = "Khớp số dư"; displayIcon = Icons.tune;
      isPositive = txType == "tien_vao"; displayColor = isPositive ? const Color(0xFF2E7D32) : Colors.red.shade600;
    } else if (txType == "tien_ra") {
      displayName = (tx["Category"] ?? "").toString().isNotEmpty ? tx["Category"] : (tx["Label"] ?? "Chi tiêu");
      displayIcon = Icons.arrow_upward; displayColor = Colors.red.shade700; isPositive = false;
    } else {
      displayName = (tx["Label"] ?? "").toString().isNotEmpty && tx["Label"] != "khop_so_du"
          ? tx["Label"] : (tx["Category"] ?? "Thu nhập");
      displayIcon = Icons.arrow_downward; displayColor = const Color(0xFF2E7D32); isPositive = true;
    }

    double amount = double.tryParse(tx["Amount"]?.toString() ?? "0") ?? 0;
    String displayAmount = isPositive ? "+${formatVND(amount)}" : "-${formatVND(amount)}";
    String description = tx["Description"] ?? "";
    String walletName = tx["WalletName"] ?? "";

    return GestureDetector(
      onTap: () async {
        if (tx["id"] == null || txType == "chuyen_tien" || txType == "chuyen_tien_nhan") return;
        await Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionDetail(transaction: tx, walletsJsonStr: jsonEncode(wallets))));
        _loadData();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isPositive ? const Color(0xFFE8F5E9) : txType == "chuyen_tien" ? Colors.blue.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(displayIcon, color: displayColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(description.isNotEmpty ? description : "Không có mô tả",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(displayAmount, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: displayColor)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF4CAF50), borderRadius: BorderRadius.circular(6)),
                  child: Text(walletName, style: const TextStyle(color: Colors.white, fontSize: 10)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredTransactions;
    // Group by date
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var tx in filtered) {
      String d = tx["Date"] ?? "Không rõ";
      grouped.putIfAbsent(d, () => []).add(tx);
    }
    List<String> dates = grouped.keys.toList()..sort((a, b) {
      try { return DateFormat("dd-MM-yyyy").parse(b).compareTo(DateFormat("dd-MM-yyyy").parse(a)); } catch (_) { return 0; }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle), child: const Icon(Icons.arrow_back, size: 20)),
                      ),
                      const Expanded(child: Center(child: Text("Lịch sử giao dịch", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)))),
                      const SizedBox(width: 32),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        hintText: "Tìm kiếm giao dịch theo mô tả",
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        border: InputBorder.none,
                        icon: Icon(Icons.search, color: Colors.grey, size: 20),
                      ),
                      onChanged: (v) => setState(() => searchText = v),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Tháng
                        GestureDetector(
                          onTap: _showMonthPicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: selectedMonth != null ? const Color(0xFFD4A843) : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(children: [
                              Icon(Icons.calendar_today, size: 14, color: selectedMonth != null ? Colors.white : Colors.black54),
                              const SizedBox(width: 4),
                              Text(
                                selectedMonth != null ? "T${selectedMonth!.month} ${selectedMonth!.year}" : "Tháng ${DateTime.now().month} ${DateTime.now().year}",
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selectedMonth != null ? Colors.white : Colors.black87),
                              ),
                              Icon(Icons.keyboard_arrow_down, size: 16, color: selectedMonth != null ? Colors.white : Colors.black54),
                            ]),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Ví tiền
                        GestureDetector(
                          onTap: _showWalletPicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: selectedWalletFilter != null ? const Color(0xFF4CAF50) : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(children: [
                              Icon(Icons.account_balance_wallet, size: 14, color: selectedWalletFilter != null ? Colors.white : Colors.black54),
                              const SizedBox(width: 4),
                              Text(
                                selectedWalletFilter ?? "Ví tiền",
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selectedWalletFilter != null ? Colors.white : Colors.black87),
                              ),
                              Icon(Icons.keyboard_arrow_down, size: 16, color: selectedWalletFilter != null ? Colors.white : Colors.black54),
                            ]),
                          ),
                        ),
                        // Clear filter
                        if (selectedMonth != null || selectedWalletFilter != null || searchText.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () { setState(() { selectedMonth = null; selectedWalletFilter = null; searchText = ""; _searchCtrl.clear(); }); },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(20)),
                              child: Row(children: [const Icon(Icons.clear, size: 14, color: Colors.red), const SizedBox(width: 4), const Text("Xóa lọc", style: TextStyle(fontSize: 13, color: Colors.red, fontWeight: FontWeight.w600))]),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
                  : filtered.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.receipt_long, size: 60, color: Colors.grey),
                const SizedBox(height: 12),
                Text(searchText.isNotEmpty ? "Không tìm thấy kết quả" : "Chưa có giao dịch nào", style: const TextStyle(color: Colors.grey, fontSize: 15)),
              ]))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: dates.length,
                itemBuilder: (_, i) {
                  String date = dates[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(date, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
                      ),
                      ...grouped[date]!.map((tx) => _buildCard(tx)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}