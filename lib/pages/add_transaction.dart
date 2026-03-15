import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prmproject/services/database.dart';
import 'package:prmproject/services/shared_pref.dart';

// Trang thêm giao dịch — Tiền ra / Tiền vào
class AddTransaction extends StatefulWidget {
  const AddTransaction({super.key});

  @override
  State<AddTransaction> createState() => _AddTransactionState();
}

class _AddTransactionState extends State<AddTransaction> {
  bool isTienRa = true;

  String amount = "0";
  String description = "";
  String? selectedWallet;
  String? selectedCategory;
  String? selectedLabel;
  DateTime selectedDate = DateTime.now();
  String? userId;

  List<Map<String, dynamic>> wallets = [];
  List<Map<String, dynamic>> groups = [];
  List<String> labels = [];

  Map<String, double> spentByCategory = {};
  Map<String, double> allocatedByCategory = {};

  TextEditingController descController = TextEditingController();
  TextEditingController labelSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  _loadData() async {
    userId = await SharedPreferenceHelper().getUserId();

    String? walletJson = await SharedPreferenceHelper().getWallets();
    if (walletJson != null && walletJson.isNotEmpty) {
      List<dynamic> decoded = jsonDecode(walletJson);
      wallets = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (wallets.isEmpty) {
      wallets = [{"name": "Tiền mặt", "amount": 0.0, "isDefault": true}];
    }

    for (var w in wallets) {
      if (w["isDefault"] == true) {
        selectedWallet = w["name"];
        break;
      }
    }
    selectedWallet ??= wallets.first["name"];

    String? groupJson = await SharedPreferenceHelper().getBudgetGroups();
    if (groupJson != null && groupJson.isNotEmpty) {
      List<dynamic> decoded = jsonDecode(groupJson);
      groups = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    allocatedByCategory = {};
    for (var group in groups) {
      List cats = group["categories"] ?? [];
      for (var cat in cats) {
        allocatedByCategory[cat["name"]] =
            (cat["allocated"] ?? 0).toDouble();
      }
    }

    spentByCategory = {};
    if (userId != null) {
      try {
        var snapshot = await DatabaseMethdos().getTransactions(userId!);
        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          if (data["Type"] == "tien_ra") {
            String category = data["Category"] ?? "";
            double amt = double.tryParse(data["Amount"] ?? "0") ?? 0;
            if (category.isNotEmpty) {
              spentByCategory[category] =
                  (spentByCategory[category] ?? 0) + amt;
            }
          }
        }
      } catch (e) {
        // Firestore chưa sẵn sàng
      }

      labels = await SharedPreferenceHelper().getUserLabels() ?? [];
    }

    setState(() {});
  }

  // Kiểm tra ví đang chọn có phải ví theo dõi không
  bool get _isTrackingWallet {
    for (var w in wallets) {
      if (w["name"] == selectedWallet && w["type"] == "Tracking") {
        return true;
      }
    }
    return false;
  }

  String get formattedAmount {
    double val = double.tryParse(amount) ?? 0;
    if (val == 0) return "0";
    final formatter = NumberFormat("#,###", "vi_VN");
    return formatter.format(val);
  }

  void _onNumPress(String num) {
    setState(() {
      if (amount == "0") {
        amount = num;
      } else {
        amount += num;
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (amount.length > 1) {
        amount = amount.substring(0, amount.length - 1);
      } else {
        amount = "0";
      }
    });
  }

  Future<bool> _saveTransaction() async {
    if (userId == null) return false;

    double amountVal = double.tryParse(amount) ?? 0;
    if (amountVal == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text("Vui lòng nhập số tiền")),
      );
      return false;
    }

    // Tiền ra bắt buộc có danh mục — TRỪ KHI ví theo dõi
    if (isTienRa && selectedCategory == null && !_isTrackingWallet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text("Vui lòng chọn danh mục")),
      );
      return false;
    }

    Map<String, dynamic> transactionData = {
      "Amount": amount,
      "Type": isTienRa ? "tien_ra" : "tien_vao",
      "WalletName": selectedWallet ?? "",
      "Category": selectedCategory ?? "",
      "Label": selectedLabel ?? "",
      "Description": descController.text,
      "Date": DateFormat('dd-MM-yyyy').format(selectedDate),
    };

    await DatabaseMethdos().addTransaction(transactionData, userId!);

    double amountChange = isTienRa ? -amountVal : amountVal;
    for (var w in wallets) {
      if (w["name"] == selectedWallet) {
        w["amount"] = (w["amount"] ?? 0.0) + amountChange;
        break;
      }
    }
    await SharedPreferenceHelper().saveWallets(jsonEncode(wallets));

    return true;
  }

  List<Map<String, dynamic>> get allCategories {
    List<Map<String, dynamic>> result = [];
    for (var group in groups) {
      List cats = group["categories"] ?? [];
      for (var cat in cats) {
        result.add(Map<String, dynamic>.from(cat));
      }
    }
    return result;
  }

  // ---- BOTTOM SHEET: CHỌN VÍ ----
  void _showWalletPicker() {
    List<Map<String, dynamic>> paymentWallets =
        wallets.where((w) => w["type"] != "Tracking").toList();
    List<Map<String, dynamic>> trackingWallets =
        wallets.where((w) => w["type"] == "Tracking").toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Chọn ví",
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              if (paymentWallets.isNotEmpty) ...[
                const Text("Ví thanh toán",
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...paymentWallets.map((w) => _walletItem(w)),
                const SizedBox(height: 8),
              ],

              if (trackingWallets.isNotEmpty) ...[
                const Text("Ví theo dõi",
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...trackingWallets.map((w) => _walletItem(w)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _walletItem(Map<String, dynamic> w) {
    bool isSelected = w["name"] == selectedWallet;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedWallet = w["name"];
          // Nếu chuyển sang ví theo dõi, clear danh mục
          if (w["type"] == "Tracking") {
            selectedCategory = null;
          }
        });
        Navigator.pop(context);
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE8F5E9)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: const Color(0xFF4CAF50))
              : null,
        ),
        child: Row(
          children: [
            const Icon(Icons.account_balance_wallet,
                color: Color(0xFF4CAF50)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(w["name"],
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            if (w["type"] == "Tracking")
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text("Theo dõi",
                    style: TextStyle(
                        color: Colors.black54, fontSize: 11)),
              ),
            if (w["isDefault"] == true) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4A843),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text("Mặc định",
                    style: TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ],
            const SizedBox(width: 8),
            if (isSelected)
              const Icon(Icons.check, color: Color(0xFF4CAF50)),
          ],
        ),
      ),
    );
  }

  // ---- BOTTOM SHEET: CHỌN DANH MỤC ----
  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Chọn danh mục",
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        ...groups.map((group) {
                          List cats = group["categories"] ?? [];
                          if (cats.isEmpty) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(group["name"] ?? "Nhóm",
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              ...cats.map((cat) {
                                bool isSelected =
                                    selectedCategory == cat["name"];
                                double allocated =
                                    (cat["allocated"] ?? 0).toDouble();
                                double spent =
                                    spentByCategory[cat["name"]] ?? 0;
                                double remaining = allocated - spent;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() =>
                                        selectedCategory = cat["name"]);
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 16),
                                    margin:
                                        const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFE8F5E9)
                                          : Colors.grey.shade100,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: isSelected
                                          ? Border.all(
                                              color:
                                                  const Color(0xFF4CAF50))
                                          : null,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          IconData(cat["icon"] ?? 0xe318,
                                              fontFamily: 'MaterialIcons'),
                                          color: const Color(0xFF4CAF50),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(cat["name"],
                                              style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight:
                                                      FontWeight.w600)),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              _formatVND(remaining < 0
                                                  ? 0
                                                  : remaining),
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  color: remaining < 0
                                                      ? Colors.red.shade600
                                                      : const Color(
                                                          0xFF2E7D32)),
                                            ),
                                            Text("còn lại",
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors
                                                        .grey.shade500)),
                                          ],
                                        ),
                                        if (isSelected) ...[
                                          const SizedBox(width: 8),
                                          const Icon(Icons.check,
                                              color: Color(0xFF4CAF50),
                                              size: 18),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: 8),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---- BOTTOM SHEET: CHỌN NHÃN (tiền vào) ----
  void _showLabelPicker() {
    String searchText = "";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx2, setSheet) {
          List<String> filtered = labels
              .where((l) =>
                  l.toLowerCase().contains(searchText.toLowerCase()))
              .toList();
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            expand: false,
            builder: (_, scrollCtrl) {
              return Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Chọn nhãn",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: labelSearchController,
                      decoration: InputDecoration(
                        hintText: "Tìm nhãn...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) =>
                          setSheet(() => searchText = v),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollCtrl,
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          bool isSel = selectedLabel == filtered[i];
                          return GestureDetector(
                            onTap: () {
                              setState(
                                  () => selectedLabel = filtered[i]);
                              Navigator.pop(ctx);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 16),
                              margin:
                                  const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? const Color(0xFFE8F5E9)
                                    : Colors.grey.shade100,
                                borderRadius:
                                    BorderRadius.circular(12),
                                border: isSel
                                    ? Border.all(
                                        color: const Color(0xFF4CAF50))
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Text(filtered[i],
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600)),
                                  const Spacer(),
                                  if (isSel)
                                    const Icon(Icons.check,
                                        color: Color(0xFF4CAF50),
                                        size: 18),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        });
      },
    );
  }

  // Chọn ngày
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => selectedDate = picked);
  }

  Widget _numButton(String label) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onNumPress(label),
        child: Container(
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1)),
            ],
          ),
          child: Center(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }

  Widget _actionButton(
      IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: Icon(icon, color: color, size: 24)),
        ),
      ),
    );
  }

  String _formatVND(double amount) {
    final formatter = NumberFormat("#,###", "vi_VN");
    if (amount == 0) return "0đ";
    return "${formatter.format(amount)}đ";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SafeArea(
        child: Column(
          children: [
            // ---- HEADER: Đóng + Tab Tiền ra / Tiền vào ----
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(color: Colors.white),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle),
                      child: const Icon(Icons.close,
                          size: 20, color: Colors.black54),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Toggle Tiền ra / Tiền vào
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                isTienRa = true;
                                selectedLabel = null;
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8),
                                decoration: BoxDecoration(
                                  color: isTienRa
                                      ? const Color(0xFFD4A843)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    if (isTienRa)
                                      const Text("✕ ",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12)),
                                    Text(
                                      "Tiền ra",
                                      style: TextStyle(
                                        color: isTienRa
                                            ? Colors.white
                                            : Colors.black54,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                isTienRa = false;
                                selectedCategory = null;
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8),
                                decoration: BoxDecoration(
                                  color: !isTienRa
                                      ? const Color(0xFF4CAF50)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    if (!isTienRa)
                                      const Text("✕ ",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12)),
                                    Text(
                                      "Tiền vào",
                                      style: TextStyle(
                                        color: !isTienRa
                                            ? Colors.white
                                            : Colors.black54,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                ],
              ),
            ),

            // ---- SỐ TIỀN ----
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("🐥",
                        style: TextStyle(fontSize: 50)),
                    const SizedBox(height: 10),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: Colors.black),
                        children: [
                          TextSpan(
                            text:
                                "${isTienRa ? '-' : '+'}$formattedAmount",
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: isTienRa
                                  ? const Color(0xFFD4A843)
                                  : const Color(0xFF4CAF50),
                              decoration: TextDecoration.underline,
                              decorationColor: isTienRa
                                  ? const Color(0xFFD4A843)
                                  : const Color(0xFF4CAF50),
                            ),
                          ),
                          TextSpan(
                            text: "đ",
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: isTienRa
                                  ? const Color(0xFFD4A843)
                                  : const Color(0xFF4CAF50),
                              decoration: TextDecoration.underline,
                              decorationColor: isTienRa
                                  ? const Color(0xFFD4A843)
                                  : const Color(0xFF4CAF50),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Mô tả
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (ctx) => Padding(
                            padding: EdgeInsets.only(
                              left: 20,
                              right: 20,
                              top: 20,
                              bottom: MediaQuery.of(ctx).viewInsets.bottom +
                                  20,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text("Thêm mô tả",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: descController,
                                  autofocus: true,
                                  decoration: InputDecoration(
                                    hintText: "Nhập mô tả...",
                                    filled: true,
                                    fillColor: Colors.grey.shade100,
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  onSubmitted: (_) {
                                    Navigator.pop(ctx);
                                    setState(() {});
                                  },
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    setState(() {});
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF4CAF50),
                                    minimumSize:
                                        const Size(double.infinity, 48),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  child: const Text("Xong",
                                      style: TextStyle(
                                          color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Text(
                        descController.text.isEmpty
                            ? "Thêm mô tả..."
                            : descController.text,
                        style: TextStyle(
                          color: descController.text.isEmpty
                              ? Colors.grey.shade400
                              : Colors.black87,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ---- THANH ĐÃ TIÊU / CÒN LẠI ----
            if (isTienRa && selectedCategory != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                color: Colors.red.shade50,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Đã tiêu",
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 11)),
                          Text(
                            _formatVND(
                                spentByCategory[selectedCategory] ?? 0),
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text("Còn lại",
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 11)),
                          Builder(builder: (context) {
                            double allocated =
                                allocatedByCategory[selectedCategory] ??
                                    0;
                            double spent =
                                spentByCategory[selectedCategory] ?? 0;
                            double remaining = allocated - spent;
                            return Text(
                              remaining < 0
                                  ? "-${_formatVND(remaining.abs())}"
                                  : _formatVND(remaining),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: remaining < 0
                                    ? Colors.red.shade700
                                    : const Color(0xFF2E7D32),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // ---- THANH CHỌN: Ví + Danh mục/Nhãn + Ngày ----
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                    top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  // Chọn ví
                  GestureDetector(
                    onTap: _showWalletPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet,
                              color: Color(0xFF4CAF50), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            selectedWallet ?? "Ví",
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Chọn danh mục hoặc nhãn
                  if (isTienRa) ...[
                    // Nếu ví theo dõi: hiện mờ, không bấm
                    if (_isTrackingWallet)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.category_outlined,
                                color: Colors.grey.shade400, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              "Không cần danh mục",
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: _showCategoryPicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: selectedCategory != null
                                ? const Color(0xFFE8F5E9)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                selectedCategory != null
                                    ? Icons.check_circle
                                    : Icons.category_outlined,
                                color: selectedCategory != null
                                    ? const Color(0xFF4CAF50)
                                    : Colors.black54,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                selectedCategory ?? "Danh mục",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: selectedCategory != null
                                      ? Colors.black87
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ] else ...[
                    // Tiền vào: chọn nhãn
                    GestureDetector(
                      onTap: _showLabelPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: selectedLabel != null
                              ? const Color(0xFFE8F5E9)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.label_outline,
                              color: selectedLabel != null
                                  ? const Color(0xFF4CAF50)
                                  : Colors.black54,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              selectedLabel ?? "Nhãn",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: selectedLabel != null
                                    ? Colors.black87
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Chọn ngày
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd/MM/yy').format(selectedDate),
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ---- NUMPAD ----
            Container(
              color: const Color(0xFFF0EFE8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                children: [
                  Row(children: [
                    _numButton("1"),
                    _numButton("2"),
                    _numButton("3"),
                    _actionButton(
                        Icons.backspace_outlined, Colors.black54, _onBackspace),
                  ]),
                  Row(children: [
                    _numButton("4"),
                    _numButton("5"),
                    _numButton("6"),
                    // Nút lưu
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          bool ok = await _saveTransaction();
                          if (ok && mounted) Navigator.pop(context, true);
                        },
                        child: Container(
                          margin: const EdgeInsets.all(3),
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: isTienRa
                                ? const Color(0xFFD4A843)
                                : const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              isTienRa ? "Chi" : "Thu",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]),
                  Row(children: [
                    _numButton("7"),
                    _numButton("8"),
                    _numButton("9"),
                    Expanded(child: Container()),
                  ]),
                  Row(children: [
                    Expanded(child: Container()),
                    _numButton("0"),
                    _numButton("000"),
                    Expanded(child: Container()),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}