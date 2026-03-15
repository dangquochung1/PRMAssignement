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
  // Loại giao dịch: true = tiền ra, false = tiền vào
  bool isTienRa = true;

  // Dữ liệu
  String amount = "0";
  String description = "";
  String? selectedWallet;
  String? selectedCategory; // Bắt buộc cho tiền ra
  String? selectedLabel; // Optional cho tiền vào
  DateTime selectedDate = DateTime.now();
  String? userId;

  // Danh sách ví và danh mục
  List<Map<String, dynamic>> wallets = [];
  List<Map<String, dynamic>> groups = [];
  List<String> labels = []; // Nhãn cho tiền vào

  // Map lưu tổng đã tiêu theo danh mục
  Map<String, double> spentByCategory = {};
  // Map lưu allocated theo danh mục
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

    // Load wallets
    String? walletJson = await SharedPreferenceHelper().getWallets();
    if (walletJson != null && walletJson.isNotEmpty) {
      List<dynamic> decoded = jsonDecode(walletJson);
      wallets = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (wallets.isEmpty) {
      wallets = [{"name": "Tiền mặt", "amount": 0.0, "isDefault": true}];
    }

    // Set ví mặc định
    for (var w in wallets) {
      if (w["isDefault"] == true) {
        selectedWallet = w["name"];
        break;
      }
    }
    selectedWallet ??= wallets.first["name"];

    // Load budget groups (cho danh mục)
    String? groupJson = await SharedPreferenceHelper().getBudgetGroups();
    if (groupJson != null && groupJson.isNotEmpty) {
      List<dynamic> decoded = jsonDecode(groupJson);
      groups = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    // Tính allocated theo danh mục từ groups
    allocatedByCategory = {};
    for (var group in groups) {
      List cats = group["categories"] ?? [];
      for (var cat in cats) {
        allocatedByCategory[cat["name"]] = (cat["allocated"] ?? 0).toDouble();
      }
    }

    // Load giao dịch → tính đã tiêu theo danh mục
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
              spentByCategory[category] = (spentByCategory[category] ?? 0) + amt;
            }
          }
        }
      } catch (e) {
        // Firestore chưa sẵn sàng
      }

      // Load Labels
      labels = await SharedPreferenceHelper().getUserLabels() ?? [];
    }

    setState(() {});
  }

  // Format số tiền
  String get formattedAmount {
    double val = double.tryParse(amount) ?? 0;
    if (val == 0) return "0";
    final formatter = NumberFormat("#,###", "vi_VN");
    return formatter.format(val);
  }

  // Bấm số trên numpad
  void _onNumPress(String num) {
    setState(() {
      if (amount == "0") {
        amount = num;
      } else {
        amount += num;
      }
    });
  }

  // Xóa 1 số
  void _onBackspace() {
    setState(() {
      if (amount.length > 1) {
        amount = amount.substring(0, amount.length - 1);
      } else {
        amount = "0";
      }
    });
  }

  // Lưu giao dịch
  Future<bool> _saveTransaction() async {
    if (userId == null) return false;

    double amountVal = double.tryParse(amount) ?? 0;
    if (amountVal == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.redAccent, content: Text("Vui lòng nhập số tiền")),
      );
      return false;
    }

    // Tiền ra bắt buộc có danh mục
    if (isTienRa && selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.redAccent, content: Text("Vui lòng chọn danh mục")),
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

    // Cập nhật số dư ví
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

  // Lấy danh sách tất cả danh mục từ groups
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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Chọn ví", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...wallets.map((w) {
                bool isSelected = w["name"] == selectedWallet;
                return GestureDetector(
                  onTap: () {
                    setState(() => selectedWallet = w["name"]);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFE8F5E9) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected ? Border.all(color: const Color(0xFF4CAF50)) : null,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet, color: Color(0xFF4CAF50)),
                        const SizedBox(width: 12),
                        Text(w["name"], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        if (w["isDefault"] == true) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4A843),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text("Mặc định", style: TextStyle(color: Colors.white, fontSize: 11)),
                          ),
                        ],
                        const Spacer(),
                        if (isSelected) const Icon(Icons.check, color: Color(0xFF4CAF50)),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
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
                  const Text("Chọn danh mục", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        ...groups.map((group) {
                          List cats = group["categories"] ?? [];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(group["name"], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                              const SizedBox(height: 8),
                              ...cats.map((cat) {
                                IconData catIcon = IconData(cat["icon"] ?? 0xe318, fontFamily: 'MaterialIcons');
                                bool isSelected = cat["name"] == selectedCategory;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() => selectedCategory = cat["name"]);
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                                    margin: const EdgeInsets.only(bottom: 6),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(catIcon, color: const Color(0xFF2E7D32), size: 22),
                                        const SizedBox(width: 12),
                                        Text(cat["name"], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                                        const Spacer(),
                                        if (isSelected) const Icon(Icons.check, color: Color(0xFF4CAF50)),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: 12),
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

  // ---- BOTTOM SHEET: NHÃN (tiền vào) ----
  void _showLabelPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Chọn nhãn", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  // Input tìm / tạo mới
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECECF8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: labelSearchController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Tìm hoặc tạo nhãn mới...",
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                      ),
                      onChanged: (val) => setSheetState(() {}),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Hiện nhãn hiện có
                  if (labels.isNotEmpty) ...[
                    Container(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                      child: SingleChildScrollView(
                        child: Column(
                          children: labels.map((label) {
                            bool isSelected = label == selectedLabel;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() => selectedLabel = label);
                                        Navigator.pop(context);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                            color: isSelected ? const Color(0xFF2E7D32) : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Nút Sửa
                                  GestureDetector(
                                    onTap: () {
                                      TextEditingController editController = TextEditingController(text: label);
                                      showDialog(
                                        context: context,
                                        builder: (dialogCtx) => AlertDialog(
                                          title: const Text("Sửa nhãn"),
                                          content: TextField(
                                            controller: editController,
                                            decoration: const InputDecoration(hintText: "Tên nhãn mới"),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(dialogCtx),
                                              child: const Text("HỦY", style: TextStyle(color: Colors.grey)),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                String newName = editController.text.trim();
                                                if (newName.isNotEmpty && !labels.contains(newName)) {
                                                  setState(() {
                                                    int index = labels.indexOf(label);
                                                    if (index != -1) {
                                                      labels[index] = newName;
                                                      if (selectedLabel == label) selectedLabel = newName;
                                                    }
                                                  });
                                                  SharedPreferenceHelper().saveUserLabels(labels);
                                                  setSheetState(() {});
                                                }
                                                Navigator.pop(dialogCtx);
                                              },
                                              child: const Text("LƯU", style: TextStyle(color: Color(0xFF4CAF50))),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: Icon(Icons.edit, color: Colors.grey, size: 20),
                                    ),
                                  ),
                                  // Nút Xóa
                                  GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (dialogCtx) => AlertDialog(
                                          title: const Text("Xóa nhãn?"),
                                          content: const Text("Bạn có chắc chắn muốn xóa nhãn này?"),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(dialogCtx),
                                              child: const Text("HỦY", style: TextStyle(color: Colors.grey)),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  labels.remove(label);
                                                  if (selectedLabel == label) selectedLabel = null;
                                                });
                                                SharedPreferenceHelper().saveUserLabels(labels);
                                                setSheetState(() {});
                                                Navigator.pop(dialogCtx);
                                              },
                                              child: const Text("XÓA", style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Nút tạo nhãn mới
                  if (labelSearchController.text.trim().isNotEmpty &&
                      !labels.contains(labelSearchController.text.trim()))
                    GestureDetector(
                      onTap: () {
                        String newLabel = labelSearchController.text.trim();
                        setState(() {
                          labels.add(newLabel);
                          selectedLabel = newLabel;
                        });
                        SharedPreferenceHelper().saveUserLabels(labels);
                        labelSearchController.clear();
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF4CAF50)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add, color: Color(0xFF4CAF50), size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Tạo nhãn "${labelSearchController.text.trim()}"',
                              style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SafeArea(
        child: Column(
          children: [
            // ---- HEADER: Close + Toggle ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 20, color: Colors.black54),
                    ),
                  ),
                  const Spacer(),
                  // Toggle Tiền ra / Tiền vào
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() {
                            isTienRa = true;
                            selectedCategory = null;
                            selectedLabel = null;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: isTienRa ? const Color(0xFFD4A843) : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                if (isTienRa) const Text("✕ ", style: TextStyle(color: Colors.white, fontSize: 12)),
                                Text(
                                  "Tiền ra",
                                  style: TextStyle(
                                    color: isTienRa ? Colors.white : Colors.black54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() {
                            isTienRa = false;
                            selectedCategory = null;
                            selectedLabel = null;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: !isTienRa ? const Color(0xFF4CAF50) : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                if (!isTienRa) const Text("✕ ", style: TextStyle(color: Colors.white, fontSize: 12)),
                                Text(
                                  "Tiền vào",
                                  style: TextStyle(
                                    color: !isTienRa ? Colors.white : Colors.black54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 32), // Balance cho nút close
                ],
              ),
            ),

            // ---- PHẦN HIỂN THỊ SỐ TIỀN ----
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Emoji
                    const Text("🐥", style: TextStyle(fontSize: 50)),
                    const SizedBox(height: 10),
                    // Số tiền
                    Text(
                      "${isTienRa ? '-' : '+'}đ$formattedAmount",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: isTienRa ? Colors.red.shade700 : const Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Mô tả
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Text("Thêm mô tả"),
                            content: TextField(
                              controller: descController,
                              decoration: const InputDecoration(hintText: "Nhập mô tả..."),
                            ),
                            actions: [
                              GestureDetector(
                                onTap: () {
                                  setState(() => description = descController.text);
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4CAF50),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text("OK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Text(
                        descController.text.isEmpty ? "Thêm mô tả..." : descController.text,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ---- THANH ĐÃ TIÊU / CÒN LẠI (chỉ tiền ra + đã chọn danh mục) ----
            if (isTienRa && selectedCategory != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.red.shade50,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Đã tiêu", style: TextStyle(color: Colors.grey, fontSize: 11)),
                          Text(
                            _formatVND(spentByCategory[selectedCategory] ?? 0),
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text("Còn lại", style: TextStyle(color: Colors.grey, fontSize: 11)),
                          Builder(builder: (context) {
                            double allocated = allocatedByCategory[selectedCategory] ?? 0;
                            double spent = spentByCategory[selectedCategory] ?? 0;
                            double remaining = allocated - spent;
                            return Text(
                              remaining < 0 ? "-${_formatVND(remaining.abs())}" : _formatVND(remaining),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: remaining < 0 ? Colors.red.shade700 : const Color(0xFF2E7D32),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  // Chọn ví
                  GestureDetector(
                    onTap: _showWalletPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet, color: Color(0xFF4CAF50), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            selectedWallet ?? "Ví",
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Chọn danh mục (tiền ra) hoặc nhãn (tiền vào)
                  GestureDetector(
                    onTap: isTienRa ? _showCategoryPicker : _showLabelPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isTienRa ? Icons.category : Icons.label_outline,
                            color: Colors.grey.shade600,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isTienRa
                                ? (selectedCategory ?? "Danh mục")
                                : (selectedLabel ?? "Nhãn"),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Chọn ngày
                  GestureDetector(
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.grey.shade600, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd/MM').format(selectedDate),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ---- CUSTOM NUMPAD ----
            Container(
              color: const Color(0xFFFFF8E1),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                children: [
                  // Hàng 1
                  Row(
                    children: [
                      _numButton("1"), _numButton("2"), _numButton("3"),
                      _actionButton(Icons.backspace_outlined, Colors.grey.shade700, _onBackspace),
                    ],
                  ),
                  // Hàng 2
                  Row(
                    children: [
                      _numButton("4"), _numButton("5"), _numButton("6"),
                      // Lưu & tiếp tục
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            bool saved = await _saveTransaction();
                            if (saved && mounted) {
                              setState(() {
                                amount = "0";
                                descController.clear();
                                selectedCategory = null;
                                selectedLabel = null;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(backgroundColor: Color(0xFF4CAF50), content: Text("Đã lưu! Tiếp tục nhập...")),
                              );
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.all(3),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00897B),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.add, color: Colors.white, size: 18),
                                Text("Lưu &\ntiếp tục", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Hàng 3
                  Row(
                    children: [
                      _numButton("7"), _numButton("8"), _numButton("9"),
                      // Lưu & đóng
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            bool saved = await _saveTransaction();
                            if (saved && mounted) {
                              Navigator.pop(context);
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.all(3),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.check, color: Colors.white, size: 18),
                                Text("Lưu &\nđóng", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Hàng 4
                  Row(
                    children: [
                      _actionButton(Icons.subdirectory_arrow_right, const Color(0xFFD4A843), () {}),
                      _numButton("000"),
                      _numButton("0"),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Nút số trên numpad
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
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1)),
            ],
          ),
          child: Center(
            child: Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }

  // Nút hành động trên numpad
  Widget _actionButton(IconData icon, Color color, VoidCallback onTap) {
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

  // Format VND
  String _formatVND(double amount) {
    final formatter = NumberFormat("#,###", "vi_VN");
    if (amount == 0) return "0đ";
    return "${formatter.format(amount)}đ";
  }
}
