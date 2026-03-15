import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prmproject/services/database.dart';
import 'package:prmproject/services/shared_pref.dart';

// Trang chuyển tiền giữa các ví
class TransferWallet extends StatefulWidget {
  const TransferWallet({super.key});

  @override
  State<TransferWallet> createState() => _TransferWalletState();
}

class _TransferWalletState extends State<TransferWallet> {
  List<Map<String, dynamic>> wallets = [];
  String? sourceWallet;
  String? destWallet;
  String amount = "0";
  DateTime selectedDate = DateTime.now();
  String? userId;

  TextEditingController descController = TextEditingController();

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
    if (wallets.isNotEmpty) {
      sourceWallet = wallets.first["name"];
      destWallet = wallets.length > 1 ? wallets[1]["name"] : null;
    }
    setState(() {});
  }

  String get formattedAmount {
    double val = double.tryParse(amount) ?? 0;
    if (val == 0) return "0";
    final formatter = NumberFormat("#,###", "vi_VN");
    return formatter.format(val);
  }

  String formatVND(double v) {
    final formatter = NumberFormat("#,###", "vi_VN");
    if (v == 0) return "0đ";
    return "${formatter.format(v)}đ";
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

  // Đổi nguồn ↔ đích
  void _swapWallets() {
    setState(() {
      final tmp = sourceWallet;
      sourceWallet = destWallet;
      destWallet = tmp;
    });
  }

  // Bottom sheet chọn ví (phân loại Ví thanh toán / Ví theo dõi)
  void _showWalletPicker({required bool isSource}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        List<Map<String, dynamic>> paymentWallets =
            wallets.where((w) => w["type"] != "Tracking").toList();
        List<Map<String, dynamic>> trackingWallets =
            wallets.where((w) => w["type"] == "Tracking").toList();

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thanh kéo
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text("Chọn ví",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                if (paymentWallets.isNotEmpty) ...[
                  const Text("Ví thanh toán",
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...paymentWallets.map((w) {
                    String wName = w["name"];
                    // Không cho chọn ví đang được chọn ở phía kia
                    bool isOtherSide = isSource
                        ? wName == destWallet
                        : wName == sourceWallet;
                    return _walletPickerItem(
                        w, isSource, isOtherSide, context);
                  }),
                  const SizedBox(height: 12),
                ],

                if (trackingWallets.isNotEmpty) ...[
                  const Text("Ví theo dõi",
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...trackingWallets.map((w) {
                    String wName = w["name"];
                    bool isOtherSide = isSource
                        ? wName == destWallet
                        : wName == sourceWallet;
                    return _walletPickerItem(
                        w, isSource, isOtherSide, context);
                  }),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _walletPickerItem(Map<String, dynamic> w, bool isSource,
      bool isOtherSide, BuildContext ctx) {
    String wName = w["name"];
    double bal = (w["amount"] ?? 0).toDouble();
    bool isSelected =
        isSource ? wName == sourceWallet : wName == destWallet;

    return GestureDetector(
      onTap: isOtherSide
          ? null
          : () {
              setState(() {
                if (isSource) {
                  sourceWallet = wName;
                } else {
                  destWallet = wName;
                }
              });
              Navigator.pop(ctx);
            },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isOtherSide
              ? Colors.grey.shade100
              : isSelected
                  ? const Color(0xFFE8F5E9)
                  : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: const Color(0xFF4CAF50), width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                wName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isOtherSide ? Colors.grey : Colors.black,
                ),
              ),
            ),
            Text(
              formatVND(bal),
              style: TextStyle(
                fontSize: 14,
                color: isOtherSide ? Colors.grey : const Color(0xFF2E7D32),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _doTransfer() async {
    if (userId == null) return;

    double amountVal = double.tryParse(amount) ?? 0;
    if (amountVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text("Vui lòng nhập số tiền")),
      );
      return;
    }

    if (sourceWallet == null || destWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text("Vui lòng chọn cả 2 ví")),
      );
      return;
    }

    if (sourceWallet == destWallet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: Colors.orangeAccent,
            content: Text("Ví nguồn và ví đích không được giống nhau")),
      );
      return;
    }

    // Kiểm tra số dư ví nguồn
    double sourceBalance = 0;
    for (var w in wallets) {
      if (w["name"] == sourceWallet) {
        sourceBalance = (w["amount"] ?? 0).toDouble();
        break;
      }
    }
    if (amountVal > sourceBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
                "Ví '$sourceWallet' không đủ số dư (hiện có ${formatVND(sourceBalance)})")),
      );
      return;
    }

    String dateStr = DateFormat('dd-MM-yyyy').format(selectedDate);
    String desc = descController.text.trim();

    // Lưu 2 giao dịch vào Firestore
    // 1. Trừ tiền khỏi ví nguồn
    await DatabaseMethdos().addTransaction({
      "Amount": amount,
      "Type": "chuyen_tien",
      "WalletName": sourceWallet ?? "",
      "Category": "",
      "Label": "",
      "Description": desc.isNotEmpty ? desc : "Chuyển tới $destWallet",
      "TransferTo": destWallet ?? "",
      "Date": dateStr,
    }, userId!);

    // 2. Cộng tiền vào ví đích
    await DatabaseMethdos().addTransaction({
      "Amount": amount,
      "Type": "chuyen_tien_nhan",
      "WalletName": destWallet ?? "",
      "Category": "",
      "Label": "",
      "Description": desc.isNotEmpty ? desc : "Nhận từ $sourceWallet",
      "TransferFrom": sourceWallet ?? "",
      "Date": dateStr,
    }, userId!);

    // Cập nhật số dư local
    for (var w in wallets) {
      if (w["name"] == sourceWallet) {
        w["amount"] = (w["amount"] ?? 0.0) - amountVal;
      } else if (w["name"] == destWallet) {
        w["amount"] = (w["amount"] ?? 0.0) + amountVal;
      }
    }
    await SharedPreferenceHelper().saveWallets(jsonEncode(wallets));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: Colors.green,
            content: Text("Chuyển tiền thành công!")),
      );
      Navigator.pop(context, true); // true = có thay đổi, wallet cần reload
    }
  }

  // Chọn ngày
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => selectedDate = picked);
    }
  }

  // Widget nút numpad
  Widget _numBtn(String label) {
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

  @override
  Widget build(BuildContext context) {
    double srcBalance = 0;
    for (var w in wallets) {
      if (w["name"] == sourceWallet) {
        srcBalance = (w["amount"] ?? 0).toDouble();
        break;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SafeArea(
        child: Column(
          children: [
            // ---- HEADER ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          shape: BoxShape.circle),
                      child: const Icon(Icons.close,
                          size: 20, color: Colors.black54),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text("Chuyển tiền giữa các ví",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 32),
                ],
              ),
            ),

            // ---- CHỌN VÍ NGUỒN → ĐÍCH ----
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // Ví nguồn
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showWalletPicker(isSource: true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Từ",
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              sourceWallet ?? "Chọn ví",
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Nút swap
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: GestureDetector(
                      onTap: _swapWallets,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFD4A843),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),

                  // Ví đích
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showWalletPicker(isSource: false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4A843).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Đến",
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              destWallet ?? "Chọn ví",
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ---- SỐ TIỀN ----
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Bạn muốn chuyển đi",
                        style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 8),
                    // Số tiền
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            fontFamily: 'Roboto', color: Colors.black),
                        children: [
                          TextSpan(
                            text: formattedAmount,
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD4A843),
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFFD4A843),
                            ),
                          ),
                          const TextSpan(
                            text: "đ",
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD4A843),
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFFD4A843),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Số dư ví nguồn
                    if (sourceWallet != null)
                      Text(
                        "Số dư: ${formatVND(srcBalance)}",
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12),
                      ),
                    const SizedBox(height: 16),

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
                              bottom:
                                  MediaQuery.of(ctx).viewInsets.bottom + 20,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                      borderRadius: BorderRadius.circular(12),
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
                                    backgroundColor: const Color(0xFF4CAF50),
                                    minimumSize:
                                        const Size(double.infinity, 48),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  child: const Text("Xong",
                                      style: TextStyle(color: Colors.white)),
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
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Ngày
                    GestureDetector(
                      onTap: _selectDate,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today,
                              size: 14,
                              color: const Color(0xFFD4A843)),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd/MM/yyyy').format(selectedDate),
                            style: const TextStyle(
                              color: Color(0xFFD4A843),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ---- NUMPAD ----
            Container(
              color: const Color(0xFFF0EFE8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                children: [
                  // Hàng 1
                  Row(children: [
                    _numBtn("1"),
                    _numBtn("2"),
                    _numBtn("3"),
                    Expanded(
                      child: GestureDetector(
                        onTap: _onBackspace,
                        child: Container(
                          margin: const EdgeInsets.all(3),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                              child: Icon(Icons.backspace_outlined,
                                  color: Colors.black54)),
                        ),
                      ),
                    ),
                  ]),
                  Row(children: [
                    _numBtn("4"),
                    _numBtn("5"),
                    _numBtn("6"),
                    Expanded(
                      child: GestureDetector(
                        onTap: _doTransfer,
                        child: Container(
                          margin: const EdgeInsets.all(3),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4A843),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text("→",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ),
                  ]),
                  Row(children: [
                    _numBtn("7"),
                    _numBtn("8"),
                    _numBtn("9"),
                    Expanded(child: Container()),
                  ]),
                  Row(children: [
                    Expanded(child: Container()),
                    _numBtn("0"),
                    _numBtn("000"),
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