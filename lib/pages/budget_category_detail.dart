import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prmproject/services/database.dart';
import 'package:prmproject/services/shared_pref.dart';
import 'package:prmproject/services/sync_service.dart';
import 'package:prmproject/pages/transaction_detail.dart';

/// Chi tiết danh mục ngân sách: tên, loại, số liệu, lịch sử (không sửa phân bổ, không xóa danh mục).
class BudgetCategoryDetail extends StatefulWidget {
  final int groupIndex;
  final int categoryIndex;
  final DateTime budgetMonth;

  const BudgetCategoryDetail({
    super.key,
    required this.groupIndex,
    required this.categoryIndex,
    required this.budgetMonth,
  });

  @override
  State<BudgetCategoryDetail> createState() => _BudgetCategoryDetailState();
}

class _BudgetCategoryDetailState extends State<BudgetCategoryDetail> {
  List<Map<String, dynamic>> groups = [];
  List<Map<String, dynamic>> transactions = [];
  String? userId;
  String walletsJson = "[]";
  bool loading = true;

  String get _filterMonth =>
      DateFormat("MM-yyyy").format(widget.budgetMonth);

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    userId = await SharedPreferenceHelper().getUserId();
    String? jsonStr = await SharedPreferenceHelper().getBudgetGroups();
    if (jsonStr != null && jsonStr.isNotEmpty) {
      List<dynamic> decoded = jsonDecode(jsonStr);
      groups = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    String? w = await SharedPreferenceHelper().getWallets();
    if (w != null) walletsJson = w;

    if (userId != null) {
      try {
        transactions =
            await DatabaseMethdos().getTransactionsCached(userId!, forceRefresh: true);
      } catch (_) {
        transactions = [];
      }
    }
    if (mounted) setState(() => loading = false);
  }

  Map<String, dynamic>? get _cat {
    if (widget.groupIndex < 0 || widget.groupIndex >= groups.length) {
      return null;
    }
    List cats = groups[widget.groupIndex]["categories"] as List? ?? [];
    if (widget.categoryIndex < 0 || widget.categoryIndex >= cats.length) {
      return null;
    }
    return Map<String, dynamic>.from(cats[widget.categoryIndex] as Map);
  }

  String get _categoryName => _cat?["name"]?.toString() ?? "";

  String get _catType => _cat?["type"]?.toString() ?? "chi_tieu";

  double get _allocated => (_cat?["allocated"] ?? 0).toDouble();

  double _spentForMonth(String name) {
    double s = 0;
    for (var data in transactions) {
      if (data["Type"] != "tien_ra") continue;
      String txDate = data["Date"]?.toString() ?? "";
      if (!txDate.endsWith(_filterMonth)) continue;
      if ((data["Category"] ?? "") == name) {
        s += double.tryParse(data["Amount"]?.toString() ?? "0") ?? 0;
      }
    }
    return s;
  }

  List<Map<String, dynamic>> _txsForCategory(String name,
      {bool monthOnly = false}) {
    List<Map<String, dynamic>> list = [];
    for (var tx in transactions) {
      if ((tx["Category"] ?? "").toString() != name) continue;
      if (monthOnly) {
        String txDate = tx["Date"]?.toString() ?? "";
        if (!txDate.endsWith(_filterMonth)) continue;
      }
      list.add(tx);
    }
    list.sort((a, b) {
      try {
        return DateFormat("dd-MM-yyyy")
            .parse(b["Date"]?.toString() ?? "")
            .compareTo(
                DateFormat("dd-MM-yyyy").parse(a["Date"]?.toString() ?? ""));
      } catch (_) {
        return 0;
      }
    });
    return list;
  }

  String formatVND(double amount) {
    final formatter = NumberFormat("#,###", "vi_VN");
    if (amount == 0) return "0đ";
    return "${formatter.format(amount)}đ";
  }

  bool _nameTaken(String name) {
    for (int gi = 0; gi < groups.length; gi++) {
      List cats = groups[gi]["categories"] as List? ?? [];
      for (int ci = 0; ci < cats.length; ci++) {
        if (gi == widget.groupIndex && ci == widget.categoryIndex) continue;
        if ((cats[ci]["name"]?.toString() ?? "").trim() == name) return true;
      }
    }
    return false;
  }

  Future<void> _editName() async {
    final cat = _cat;
    if (cat == null || userId == null) return;
    final oldName = _categoryName;
    final ctrl = TextEditingController(text: oldName);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Đổi tên danh mục",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Tên danh mục",
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("HỦY", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final n = ctrl.text.trim();
              if (n.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Tên không được để trống")),
                );
                return;
              }
              if (n == oldName) {
                Navigator.pop(ctx);
                return;
              }
              if (_nameTaken(n)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Đã có danh mục trùng tên")),
                );
                return;
              }
              try {
                await DatabaseMethdos()
                    .renameTransactionCategory(userId!, oldName, n);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Lỗi đổi tên: $e")),
                  );
                }
                return;
              }
              (groups[widget.groupIndex]["categories"] as List)[widget
                  .categoryIndex]["name"] = n;
              await SharedPreferenceHelper()
                  .saveBudgetGroups(jsonEncode(groups));
              await SyncService.pushToFirestore(userId!);
              if (mounted) {
                Navigator.pop(ctx);
                setState(() {});
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4A843),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("LƯU", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTxRow(Map<String, dynamic> tx) {
    final txType = tx["Type"] ?? "";
    final amount = double.tryParse(tx["Amount"]?.toString() ?? "0") ?? 0;
    final isOut = txType == "tien_ra";
    final color = isOut ? Colors.red.shade700 : const Color(0xFF2E7D32);
    final prefix = isOut ? "-" : "+";
    final desc = (tx["Description"]?.toString() ?? "").trim();
    final wallet = tx["WalletName"]?.toString() ?? "";

    return GestureDetector(
      onTap: () async {
        if (tx["id"] == null) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionDetail(
              transaction: tx,
              walletsJsonStr: walletsJson,
            ),
          ),
        );
        _load();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isOut ? Icons.arrow_upward : Icons.arrow_downward,
                color: const Color(0xFFD4A843),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_categoryName,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(
                    desc.isNotEmpty ? desc : "Không có mô tả",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (wallet.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      wallet.length > 10
                          ? "${wallet.substring(0, 10)}…"
                          : wallet,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                Text(
                  "$prefix${formatVND(amount)}",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tx["Date"]?.toString() ?? "",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F0),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFD4A843))),
      );
    }

    final cat = _cat;
    if (cat == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F0),
        body: SafeArea(
          child: Column(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
              const Expanded(
                child: Center(child: Text("Không tìm thấy danh mục")),
              ),
            ],
          ),
        ),
      );
    }

    final name = _categoryName;
    final isSaving = _catType == "tiet_kiem";
    final spent = _spentForMonth(name);
    final allocated = _allocated;
    final remaining = allocated - spent;
    final icon = IconData(cat["icon"] ?? 0xe318, fontFamily: 'MaterialIcons');
    final monthTxs = _txsForCategory(name, monthOnly: true);
    final allTxs = _txsForCategory(name, monthOnly: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context, true),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSaving
                          ? const Color(0xFFFFF8E1)
                          : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: isSaving
                          ? const Color(0xFFD4A843)
                          : const Color(0xFF4CAF50),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isSaving ? "Tiết kiệm" : "Chi tiêu",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFD4A843),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _editName,
                    icon: const Icon(Icons.edit_outlined,
                        color: Color(0xFFD4A843)),
                    tooltip: "Sửa tên",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _infoRow("Số tiền đã phân bổ", formatVND(allocated)),
                    const Divider(height: 24),
                    _infoRow("Số tiền đã tiêu", formatVND(spent),
                        valueColor: Colors.red.shade700),
                    const Divider(height: 24),
                    _infoRow(
                      "Còn lại",
                      formatVND(remaining.abs()),
                      valueColor: remaining >= 0
                          ? const Color(0xFF2E7D32)
                          : Colors.red.shade700,
                      prefix: remaining < 0 ? "-" : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Lịch sử",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  if (allTxs.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CategoryTransactionHistoryPage(
                              categoryName: name,
                              walletsJson: walletsJson,
                            ),
                          ),
                        ).then((_) => _load());
                      },
                      child: const Text(
                        "Xem tất cả",
                        style: TextStyle(
                          color: Color(0xFFD4A843),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: monthTxs.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          allTxs.isEmpty
                              ? "Chưa có giao dịch cho danh mục này"
                              : "Chưa có giao dịch trong tháng này.\nBấm \"Xem tất cả\" để xem các tháng khác.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: monthTxs.length > 5 ? 5 : monthTxs.length,
                      itemBuilder: (_, i) => _buildTxRow(monthTxs[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value,
      {Color? valueColor, String? prefix}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
        Text(
          "${prefix ?? ""}$value",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}

/// Toàn bộ giao dịch của một danh mục (mọi tháng).
class CategoryTransactionHistoryPage extends StatefulWidget {
  final String categoryName;
  final String walletsJson;

  const CategoryTransactionHistoryPage({
    super.key,
    required this.categoryName,
    required this.walletsJson,
  });

  @override
  State<CategoryTransactionHistoryPage> createState() =>
      _CategoryTransactionHistoryPageState();
}

class _CategoryTransactionHistoryPageState
    extends State<CategoryTransactionHistoryPage> {
  List<Map<String, dynamic>> list = [];
  bool loading = true;
  String? userId;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    userId = await SharedPreferenceHelper().getUserId();
    if (userId != null) {
      list = await DatabaseMethdos().getTransactionsCached(userId!);
      list = list
          .where((tx) =>
              (tx["Category"] ?? "").toString() == widget.categoryName)
          .toList();
      list.sort((a, b) {
        try {
          return DateFormat("dd-MM-yyyy")
              .parse(b["Date"]?.toString() ?? "")
              .compareTo(
                  DateFormat("dd-MM-yyyy").parse(a["Date"]?.toString() ?? ""));
        } catch (_) {
          return 0;
        }
      });
    }
    if (mounted) setState(() => loading = false);
  }

  String formatVND(double amount) {
    final formatter = NumberFormat("#,###", "vi_VN");
    if (amount == 0) return "0đ";
    return "${formatter.format(amount)}đ";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.categoryName,
          style: const TextStyle(
              color: Colors.black87,
              fontSize: 17,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4A843)))
          : list.isEmpty
              ? Center(
                  child: Text("Chưa có giao dịch",
                      style: TextStyle(color: Colors.grey.shade600)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final tx = list[i];
                    final txType = tx["Type"] ?? "";
                    final amount =
                        double.tryParse(tx["Amount"]?.toString() ?? "0") ?? 0;
                    final isOut = txType == "tien_ra";
                    final color =
                        isOut ? Colors.red.shade700 : const Color(0xFF2E7D32);
                    final desc =
                        (tx["Description"]?.toString() ?? "").trim();
                    final wallet = tx["WalletName"]?.toString() ?? "";
                    return GestureDetector(
                      onTap: () async {
                        if (tx["id"] == null) return;
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TransactionDetail(
                              transaction: tx,
                              walletsJsonStr: widget.walletsJson,
                            ),
                          ),
                        );
                        _load();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isOut
                                    ? Colors.red.shade50
                                    : const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isOut
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: color,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tx["Date"]?.toString() ?? "",
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600)),
                                  Text(
                                    desc.isNotEmpty
                                        ? desc
                                        : "Không có mô tả",
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "${isOut ? "-" : "+"}${formatVND(amount)}",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                                if (wallet.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      wallet,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
