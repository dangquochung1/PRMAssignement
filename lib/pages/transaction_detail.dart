import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prmproject/services/database.dart';
import 'package:prmproject/services/shared_pref.dart';

// Màn hình chi tiết giao dịch
class TransactionDetail extends StatefulWidget {
  final Map<String, dynamic> transaction;
  final String walletsJsonStr;

  const TransactionDetail({
    super.key,
    required this.transaction,
    required this.walletsJsonStr,
  });

  @override
  State<TransactionDetail> createState() => _TransactionDetailState();
}

class _TransactionDetailState extends State<TransactionDetail> {
  // Format số tiền
  String formatVND(double amount) {
    final formatter = NumberFormat("#,###", "vi_VN");
    if (amount == 0) return "0đ";
    return "${formatter.format(amount)}đ";
  }

  Future<void> _deleteTransaction() async {
    String? userId = await SharedPreferenceHelper().getUserId();
    if (userId == null) return;

    String txId = widget.transaction["id"];
    String type = widget.transaction["Type"] ?? "";
    String subType = widget.transaction["SubType"] ?? "";
    String labelField = widget.transaction["Label"] ?? "";
    String walletName = widget.transaction["WalletName"] ?? "";
    double amount = double.tryParse(widget.transaction["Amount"] ?? "0") ?? 0;

    // Không cho phép xóa giao dịch thuộc loại khớp số dư
    if (subType == "khop_so_du" || labelField == "khop_so_du") {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.orange,
            content: Text("Giao dịch điều chỉnh số dư không thể xóa."),
          ),
        );
      }
      return;
    }

    // 1. Xóa trên Firestore
    await DatabaseMethdos().deleteTransaction(userId, txId);
    await SharedPreferenceHelper().clearTransactionsCache(); // ← thêm dòng này
    // 2. Chỉnh lại số dư ví (Hoàn trả)
    // Nếu tiền ra -> Xóa đi nghĩa là được cộng lại tiền
    // Nếu tiền vào -> Xóa đi nghĩa là bị trừ tiền
    List<Map<String, dynamic>> wallets = [];
    if (widget.walletsJsonStr.isNotEmpty) {
      List<dynamic> decoded = jsonDecode(widget.walletsJsonStr);
      wallets = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    double adjustment = (type == "tien_ra") ? amount : -amount;

    for (var w in wallets) {
      if (w["name"] == walletName) {
        w["amount"] = (w["amount"] ?? 0.0) + adjustment;
        break;
      }
    }

    // 3. Lưu lại ví
    await SharedPreferenceHelper().saveWallets(jsonEncode(wallets));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.green, content: Text("Đã xóa giao dịch!")),
      );
      Navigator.pop(context); // Quay về màn hình Wallet
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isTienRa = widget.transaction["Type"] == "tien_ra";
    String subType = widget.transaction["SubType"] ?? "";
    String labelField = widget.transaction["Label"] ?? "";
    bool isKhopSoDu = subType == "khop_so_du" || labelField == "khop_so_du";
    double amount = double.tryParse(widget.transaction["Amount"] ?? "0") ?? 0;
    String displayAmount = isTienRa ? "-${formatVND(amount)}" : "+${formatVND(amount)}";
    String category = (widget.transaction["Category"] != null && widget.transaction["Category"].toString().isNotEmpty) 
        ? widget.transaction["Category"] 
        : (widget.transaction["Label"] ?? "Không rõ");
    String walletName = widget.transaction["WalletName"] ?? "Không rõ";
    String date = widget.transaction["Date"] ?? "";
    String description = widget.transaction["Description"] ?? "Không có mô tả";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 20, color: Colors.black54),
                    ),
                  ),
                  const Text("Chi tiết giao dịch", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () {
                      // Bấm vào edit - Tạm thời chưa có UI Edit
                    },
                    child: const Icon(Icons.edit, color: Colors.black54),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Icon trên cùng
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isTienRa ? Colors.red.shade50 : const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isTienRa ? Icons.arrow_upward : Icons.arrow_downward,
                color: isTienRa ? Colors.red.shade700 : const Color(0xFF2E7D32),
                size: 28,
              ),
            ),
            const SizedBox(height: 12),

            // Số tiền to
            Text(
              displayAmount,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: isTienRa ? Colors.red.shade700 : const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 8),

            // Ngày
            Text(date, style: const TextStyle(fontSize: 15, color: Colors.black54)),
            const SizedBox(height: 30),

            // Card chi tiết
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Danh mục / Nhãn
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(isTienRa ? Icons.category : Icons.label, color: Colors.orange.shade600, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isTienRa ? "Danh mục" : "Nhãn", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(category, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Ví
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.account_balance_wallet, color: Color(0xFF4CAF50), size: 20),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Ví", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(walletName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Divider
                  Divider(color: Colors.grey.shade300),
                  const SizedBox(height: 12),

                  // Ghi chú
                  const Text("Ghi chú", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    description.isEmpty ? "Không có mô tả" : description,
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Nút xóa (ẩn với giao dịch khớp số dư)
            if (!isKhopSoDu)
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Xóa giao dịch?"),
                      content: const Text("Giao dịch này sẽ bị xóa vĩnh viễn và số dư ví sẽ được hoàn trả lại. Bạn có chắc chắn không?"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("HỦY", style: TextStyle(color: Colors.grey))),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _deleteTransaction();
                          },
                          child: const Text("XÓA", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text("XÓA GIAO DỊCH", style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}
