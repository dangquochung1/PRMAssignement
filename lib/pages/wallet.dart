import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prmproject/pages/transaction_detail.dart';
import 'package:prmproject/services/database.dart';
import 'package:prmproject/services/shared_pref.dart';

// Trang Ví tiền — persist ví, ví mặc định, lịch sử giao dịch từ Firestore
class Wallet extends StatefulWidget {
  const Wallet({super.key});

  @override
  State<Wallet> createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  // Danh sách ví thanh toán (persist qua SharedPreferences)
  List<Map<String, dynamic>> wallets = [];

  // Giao dịch (load từ Firestore)
  List<Map<String, dynamic>> transactions = [];

  String? userId;

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
    // Nếu chưa có ví nào, tạo ví mặc định
    if (wallets.isEmpty) {
      wallets = [{"name": "Tiền mặt", "amount": 0.0, "isDefault": true}];
      await SharedPreferenceHelper().saveWallets(jsonEncode(wallets));
    }

    // Load giao dịch từ Firestore
    if (userId != null) {
      try {
        var snapshot = await DatabaseMethdos().getTransactions(userId!);
        transactions = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data["id"] = doc.id; // Lưu id để sau này có thể xóa
          return data;
        }).toList();
      } catch (e) {
        // Firestore chưa có index hoặc lỗi mạng
        transactions = [];
      }
    }

    setState(() {});
  }

  // Lưu wallets
  _saveWallets() async {
    await SharedPreferenceHelper().saveWallets(jsonEncode(wallets));
  }

  // Format số tiền VND
  String formatVND(double amount) {
    final formatter = NumberFormat("#,###", "vi_VN");
    if (amount == 0) return "0đ";
    return "${formatter.format(amount)}đ";
  }

  // Tính tổng tài sản
  double get tongTaiSan {
    double total = 0;
    for (var vi in wallets) {
      total += (vi["amount"] ?? 0).toDouble();
    }
    return total;
  }

  // ---- BOTTOM SHEET: TẠO VÍ MỚI ----
  void _showAddWalletSheet() {
    TextEditingController nameController = TextEditingController();
    TextEditingController amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thanh kéo
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text("Tạo ví mới", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Tên ví
                const Text("Tên ví", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECECF8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Nhập tên ví",
                      hintStyle: TextStyle(color: Colors.black38),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Số dư ban đầu
                const Text("Số dư ban đầu", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECECF8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "0",
                      hintStyle: TextStyle(color: Colors.black38),
                      suffixText: "đ",
                      suffixStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Nút LƯU
                GestureDetector(
                  onTap: () {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(backgroundColor: Colors.redAccent, content: Text("Vui lòng nhập tên ví")),
                      );
                      return;
                    }
                    double amount = double.tryParse(amountController.text) ?? 0;
                    Map<String, dynamic> newWallet = {
                      "name": nameController.text.trim(),
                      "amount": amount,
                      "isDefault": false,
                    };
                    setState(() {
                      wallets.add(newWallet);
                    });
                    _saveWallets();
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text("LƯU", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- HEADER XANH LÁ ----
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // Tổng tài sản
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Tổng tài sản", style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(width: 4),
                        Icon(Icons.visibility_outlined, color: Colors.white.withValues(alpha: 0.7), size: 18),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatVND(tongTaiSan),
                      style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Thanh toán / Theo dõi summary
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const Text("Thanh toán", style: TextStyle(color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text(formatVND(tongTaiSan), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 30, color: Colors.white30),
                        Expanded(
                          child: Column(
                            children: [
                              const Text("Theo dõi", style: TextStyle(color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 2),
                              // Theo dõi luôn = 0
                              const Text("0đ", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ---- 3 NÚT HÀNH ĐỘNG ----
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionButton(Icons.add_circle_outline, "Tạo ví mới", () => _showAddWalletSheet()),
                    _buildActionButton(Icons.swap_horiz, "Chuyển tiền\ngiữa các ví", () {
                      // Chưa xử lý — chỉ UI
                    }),
                    _buildActionButton(Icons.tune, "Điều chỉnh\nsố dư", () {
                      // Chưa xử lý — chỉ UI
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ---- VÍ THANH TOÁN ----
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Text("Ví thanh toán", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              // Hiện danh sách ví ngang
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: wallets.length,
                  itemBuilder: (context, index) {
                    var vi = wallets[index];
                    bool isDefault = vi["isDefault"] == true;
                    return Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.account_balance_wallet, color: Color(0xFF4CAF50), size: 20),
                              const SizedBox(width: 4),
                              if (isDefault)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD4A843),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text("Mặc định", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                                ),
                            ],
                          ),
                          const Spacer(),
                          Text(vi["name"], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                          Text(
                            formatVND((vi["amount"] ?? 0).toDouble()),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // ---- LỊCH SỬ GIAO DỊCH ----
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Lịch sử giao dịch", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: () {},
                      child: const Text("Xem tất cả ›", style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Giao dịch thật hoặc placeholder
              if (transactions.isEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long, color: Colors.grey, size: 40),
                        SizedBox(height: 8),
                        Text("Chưa có giao dịch nào", style: TextStyle(color: Colors.grey, fontSize: 15)),
                      ],
                    ),
                  ),
                )
              else
                ...transactions.map((tx) => _buildTransactionCard(tx)),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Card giao dịch
  Widget _buildTransactionCard(Map<String, dynamic> tx) {
    bool isTienRa = tx["Type"] == "tien_ra";
    double amount = double.tryParse(tx["Amount"] ?? "0") ?? 0;
    String displayAmount = isTienRa ? "-${formatVND(amount)}" : "+${formatVND(amount)}";
    String category = (tx["Category"] != null && tx["Category"].toString().isNotEmpty) 
        ? tx["Category"] 
        : (tx["Label"] ?? "");
    String description = tx["Description"] ?? "Không có mô tả";
    String date = tx["Date"] ?? "";
    String walletName = tx["WalletName"] ?? "";

    return GestureDetector(
      onTap: () async {
        if (tx["id"] == null) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetail(
              transaction: tx,
              walletsJsonStr: jsonEncode(wallets),
            ),
          ),
        );
        // Sau khi quay lại, reload dữ liệu (có thể giao dịch đã bị xóa)
        _loadData();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isTienRa ? Colors.red.shade50 : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isTienRa ? Icons.arrow_upward : Icons.arrow_downward,
                color: isTienRa ? Colors.red.shade700 : const Color(0xFF2E7D32),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Thông tin
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.isNotEmpty ? category : "Giao dịch",
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    description.isNotEmpty ? description : "Không có mô tả",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Số tiền + ngày + ví
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  displayAmount,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isTienRa ? Colors.red.shade700 : const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 2),
                Text(date, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                if (walletName.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(walletName, style: const TextStyle(fontSize: 10, color: Color(0xFF2E7D32))),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Nút hành động tròn
  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF4CAF50), size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
