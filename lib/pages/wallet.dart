import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prmproject/pages/transaction_detail.dart';
import 'package:prmproject/pages/transfer_wallet.dart';
import 'package:prmproject/services/database.dart';
import 'package:prmproject/services/shared_pref.dart';
import 'package:prmproject/pages/full_history.dart';
// Trang Ví tiền
class Wallet extends StatefulWidget {
  const Wallet({super.key});

  @override
  State<Wallet> createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  List<Map<String, dynamic>> wallets = [];
  List<Map<String, dynamic>> transactions = [];
  String? userId;

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
      wallets = [
        {"name": "Tiền mặt", "amount": 0.0, "isDefault": true}
      ];
      await SharedPreferenceHelper().saveWallets(jsonEncode(wallets));
    }

    if (userId != null) {
      try {
        var snapshot = await DatabaseMethdos().getTransactions(userId!);
        transactions = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data["id"] = doc.id;
          return data;
        }).toList();
      } catch (e) {
        transactions = [];
      }
    }

    setState(() {});
  }

  _saveWallets() async {
    await SharedPreferenceHelper().saveWallets(jsonEncode(wallets));
  }

  String formatVND(double amount) {
    final formatter = NumberFormat("#,###", "vi_VN");
    if (amount == 0) return "0đ";
    return "${formatter.format(amount)}đ";
  }

  double get tongTaiSan => tongThanhToan + tongTheoDoi;

  double get tongThanhToan {
    double total = 0;
    for (var vi in wallets) {
      if (vi["type"] != "Tracking") total += (vi["amount"] ?? 0).toDouble();
    }
    return total;
  }

  double get tongTheoDoi {
    double total = 0;
    for (var vi in wallets) {
      if (vi["type"] == "Tracking") total += (vi["amount"] ?? 0).toDouble();
    }
    return total;
  }

  // ---- BOTTOM SHEET: CHỌN LOẠI VÍ ----
  void _showAddWalletSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF5F5F0),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                  ],
                ),
                const SizedBox(height: 16),
                const Text("Tạo ví mới",
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _showCreateWalletForm(isTracking: false);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.account_balance_wallet,
                              color: Color(0xFF4CAF50), size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Ví thanh toán",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              Text("Ví dùng để quản lý chi tiêu hàng ngày",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _showCreateWalletForm(isTracking: true);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.visibility_outlined,
                              color: Colors.blue.shade400, size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Ví theo dõi",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                  "Theo dõi tài sản mà không ảnh hưởng ngân sách",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
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

  // ---- FORM TẠO VÍ MỚI ----
  void _showCreateWalletForm({required bool isTracking}) {
    TextEditingController nameController = TextEditingController();
    TextEditingController amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF5F5F0),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                    const SizedBox(width: 12),
                    Text(
                      isTracking ? "Tạo ví theo dõi" : "Tạo ví thanh toán",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                const Text("Tên ví",
                    style: TextStyle(
                        fontSize: 15, color: Colors.black87)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                        border: InputBorder.none, hintText: "Vd: Tiền mặt"),
                  ),
                ),
                const SizedBox(height: 20),

                const Text("Số dư hiện tại",
                    style: TextStyle(
                        fontSize: 15, color: Colors.black87)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Text("đ",
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                              decoration: TextDecoration.underline)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "0",
                            hintStyle: TextStyle(color: Colors.black38),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Bạn nhập số tiền càng chính xác thì chúng tôi có thể giúp bạn cập nhật ngân sách càng chính xác hơn",
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 30),

                GestureDetector(
                  onTap: () {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            backgroundColor: Colors.redAccent,
                            content: Text("Vui lòng nhập tên ví")),
                      );
                      return;
                    }
                    double amount =
                        double.tryParse(amountController.text) ?? 0;
                    Map<String, dynamic> newWallet = {
                      "name": nameController.text.trim(),
                      "amount": amount,
                      "isDefault": false,
                      "type": isTracking ? "Tracking" : "Payment",
                    };
                    setState(() {
                      wallets.add(newWallet);
                    });
                    _saveWallets();
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isTracking
                          ? Colors.blue.shade400
                          : const Color(0xFFD4A843),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text("TẠO VÍ",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
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

  // ---- BOTTOM SHEET: ĐIỀU CHỈNH SỐ DƯ ----
  void _showAdjustBalanceSheet() {
    // Map tên ví → controller
    Map<String, TextEditingController> controllers = {};
    for (var w in wallets) {
      double currentAmt = (w["amount"] ?? 0).toDouble();
      controllers[w["name"]] =
          TextEditingController(text: currentAmt.toStringAsFixed(0));
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx2, setSheet) {
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F0),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
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
                          child: Text("Cập nhật số dư hiện tại trong ví",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 32),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (wallets
                            .where((w) => w["type"] != "Tracking")
                            .isNotEmpty) ...[
                          const Text("Ví thanh toán",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          ...wallets
                              .where((w) => w["type"] != "Tracking")
                              .map((w) => _adjustCard(
                                  w, controllers, setSheet)),
                          const SizedBox(height: 20),
                        ],
                        if (wallets
                            .where((w) => w["type"] == "Tracking")
                            .isNotEmpty) ...[
                          const Text("Ví theo dõi",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          ...wallets
                              .where((w) => w["type"] == "Tracking")
                              .map((w) => _adjustCard(
                                  w, controllers, setSheet)),
                        ],
                      ],
                    ),
                  ),
                ),

                // Nút Điều chỉnh số
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: () async {
                      if (userId == null) return;
                      String dateStr = DateFormat('dd-MM-yyyy')
                          .format(DateTime.now());

                      for (var w in wallets) {
                        String wName = w["name"];
                        double oldAmt =
                            (w["amount"] ?? 0).toDouble();
                        double newAmt = double.tryParse(
                                controllers[wName]?.text ?? "") ??
                            oldAmt;
                        double diff = newAmt - oldAmt;

                        if (diff.abs() > 0) {
                          // Lưu giao dịch khớp số dư
                          await DatabaseMethdos().addTransaction({
                            "Amount": diff.abs().toStringAsFixed(0),
                            "Type": diff > 0
                                ? "tien_vao"
                                : "tien_ra",
                            "WalletName": wName,
                            "Category": "",
                            "Label": "khop_so_du",
                            "Description": "Balance adjust...",
                            "Date": dateStr,
                            "SubType": "khop_so_du",
                          }, userId!);

                          w["amount"] = newAmt;
                        }
                      }

                      await SharedPreferenceHelper()
                          .saveWallets(jsonEncode(wallets));

                      if (mounted) {
                        Navigator.pop(ctx);
                        _loadData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              backgroundColor: Colors.green,
                              content: Text("Đã cập nhật số dư!")),
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4A843),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text("ĐIỀU CHỈNH SỐ",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _adjustCard(
      Map<String, dynamic> w,
      Map<String, TextEditingController> controllers,
      StateSetter setSheet) {
    double oldAmt = (w["amount"] ?? 0).toDouble();
    double newAmt =
        double.tryParse(controllers[w["name"]]?.text ?? "") ?? oldAmt;
    double diff = newAmt - oldAmt;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: w["type"] == "Tracking"
                      ? Colors.blue.shade50
                      : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  w["type"] == "Tracking"
                      ? Icons.visibility_outlined
                      : Icons.account_balance_wallet,
                  color: w["type"] == "Tracking"
                      ? Colors.blue.shade400
                      : const Color(0xFF4CAF50),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(w["name"],
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                    Text(
                      "Lần cuối cập nhật  ${formatVND(oldAmt)}",
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text("Số dư mới",
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              const Spacer(),
              if (diff != 0)
                Text(
                  diff > 0 ? "+${formatVND(diff)}" : "-${formatVND(diff.abs())}",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: diff > 0
                        ? const Color(0xFF2E7D32)
                        : Colors.red.shade600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controllers[w["name"]],
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "0",
                    ),
                    onChanged: (_) => setSheet(() {}),
                  ),
                ),
                const Text("đ",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- ACTION BUTTON ----
  Widget _buildActionButton(
      IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Icon(icon, color: const Color(0xFF2E7D32), size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> paymentWallets =
        wallets.where((w) => w["type"] != "Tracking").toList();
    List<Map<String, dynamic>> trackingWallets =
        wallets.where((w) => w["type"] == "Tracking").toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- HEADER ----
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 20),
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Tổng tài sản",
                        style: TextStyle(
                            color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      formatVND(tongTaiSan),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Ví thanh toán",
                                  style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12)),
                              Text(formatVND(tongThanhToan),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Ví theo dõi",
                                  style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12)),
                              Text(formatVND(tongTheoDoi),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
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
                    _buildActionButton(
                        Icons.add_circle_outline, "Tạo ví mới",
                        () => _showAddWalletSheet()),
                    _buildActionButton(
                      Icons.swap_horiz,
                      "Chuyển tiền\ngiữa các ví",
                      () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const TransferWallet()),
                        );
                        if (result == true) _loadData();
                      },
                    ),
                    _buildActionButton(
                        Icons.tune, "Điều chỉnh\nsố dư",
                        () => _showAdjustBalanceSheet()),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ---- VÍ THANH TOÁN ----
              if (paymentWallets.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("Ví thanh toán",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: paymentWallets.length,
                    itemBuilder: (context, index) {
                      var vi = paymentWallets[index];
                      bool isDefault = vi["isDefault"] == true;
                      return Container(
                        width: 140,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDefault
                              ? const Color(0xFF2E7D32)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vi["name"],
                              style: TextStyle(
                                color: isDefault
                                    ? Colors.white
                                    : Colors.black87,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Text(
                              formatVND(
                                  (vi["amount"] ?? 0).toDouble()),
                              style: TextStyle(
                                color: isDefault
                                    ? Colors.white
                                    : Colors.black87,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ---- VÍ THEO DÕI ----
              if (trackingWallets.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("Ví theo dõi",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: trackingWallets.length,
                    itemBuilder: (context, index) {
                      var vi = trackingWallets[index];
                      return Container(
                        width: 140,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.blue.shade200, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vi["name"],
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Text(
                              formatVND(
                                  (vi["amount"] ?? 0).toDouble()),
                              style: TextStyle(
                                color: Colors.blue.shade800,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ---- LỊCH SỬ GIAO DỊCH ----
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Lịch sử giao dịch",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const FullHistory()),
                      ).then((_) => _loadData()),
                      child: const Text("Xem tất cả ›",
                          style: TextStyle(
                              color: Color(0xFF4CAF50),
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

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
                        Icon(Icons.receipt_long,
                            color: Colors.grey, size: 40),
                        SizedBox(height: 8),
                        Text("Chưa có giao dịch nào",
                            style: TextStyle(
                                color: Colors.grey, fontSize: 15)),
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

  // ---- CARD GIAO DỊCH ----
  Widget _buildTransactionCard(Map<String, dynamic> tx) {
    String txType = tx["Type"] ?? "";
    String subType = tx["SubType"] ?? "";
    String labelField = tx["Label"] ?? "";

    // Xác định tên hiển thị
    String displayName;
    IconData displayIcon;
    Color displayColor;
    bool isPositive;

    if (txType == "chuyen_tien") {
      displayName = "Chuyển tiền";
      String transferTo = tx["TransferTo"] ?? "";
      displayIcon = Icons.swap_horiz;
      displayColor = Colors.blue.shade600;
      isPositive = false;
    } else if (txType == "chuyen_tien_nhan") {
      displayName = "Chuyển tiền";
      displayIcon = Icons.swap_horiz;
      displayColor = const Color(0xFF2E7D32);
      isPositive = true;
    } else if (subType == "khop_so_du" || labelField == "khop_so_du") {
      displayName = "Khớp số dư";
      displayIcon = Icons.tune;
      displayColor = txType == "tien_vao"
          ? const Color(0xFF2E7D32)
          : Colors.red.shade600;
      isPositive = txType == "tien_vao";
    } else if (txType == "tien_ra") {
      displayName = (tx["Category"] != null &&
              tx["Category"].toString().isNotEmpty)
          ? tx["Category"]
          : (tx["Label"] ?? "Chi tiêu");
      displayIcon = Icons.arrow_upward;
      displayColor = Colors.red.shade700;
      isPositive = false;
    } else {
      // tien_vao
      displayName = (tx["Label"] != null &&
              tx["Label"].toString().isNotEmpty &&
              tx["Label"] != "khop_so_du")
          ? tx["Label"]
          : (tx["Category"] ?? "Thu nhập");
      displayIcon = Icons.arrow_downward;
      displayColor = const Color(0xFF2E7D32);
      isPositive = true;
    }

    double amount =
        double.tryParse(tx["Amount"]?.toString() ?? "0") ?? 0;
    String displayAmount = isPositive
        ? "+${formatVND(amount)}"
        : "-${formatVND(amount)}";

    String description = tx["Description"] ?? "";
    if (txType == "chuyen_tien" && description.isEmpty) {
      description = "Tiền mặt -> ${tx["TransferTo"] ?? ""}";
    } else if (txType == "chuyen_tien_nhan" && description.isEmpty) {
      description = "${tx["TransferFrom"] ?? ""} -> ${tx["WalletName"] ?? ""}";
    }

    String date = tx["Date"] ?? "";
    String walletName = tx["WalletName"] ?? "";

    // Tag wallet
    Color tagColor;
    if (txType == "chuyen_tien" || txType == "chuyen_tien_nhan") {
      tagColor = Colors.blue.shade400;
    } else if (subType == "khop_so_du" || labelField == "khop_so_du") {
      tagColor = Colors.grey.shade500;
    } else {
      tagColor = const Color(0xFF4CAF50);
    }

    return GestureDetector(
      onTap: () async {
        if (tx["id"] == null) return;
        // Chỉ cho xem chi tiết giao dịch thường
        if (txType != "chuyen_tien" &&
            txType != "chuyen_tien_nhan") {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionDetail(
                transaction: tx,
                walletsJsonStr: jsonEncode(wallets),
              ),
            ),
          );
          _loadData();
        }
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
                color: isPositive
                    ? const Color(0xFFE8F5E9)
                    : (txType == "chuyen_tien"
                        ? Colors.blue.shade50
                        : Colors.red.shade50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(displayIcon, color: displayColor, size: 22),
            ),
            const SizedBox(width: 12),
            // Thông tin
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    description.isNotEmpty
                        ? description
                        : "Không có mô tả",
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 12),
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
                    color: displayColor,
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 11),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: tagColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    walletName,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}