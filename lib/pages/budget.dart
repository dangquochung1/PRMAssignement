import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prmproject/pages/allocate_budget.dart';
import 'package:prmproject/pages/compensate_budget.dart';
import 'package:prmproject/pages/edit_budget.dart';
import 'package:prmproject/services/database.dart';
import 'package:prmproject/services/shared_pref.dart';

// Trang Ngân sách tháng — zero-based budgeting
// Hiện: đã phân bổ, đã tiêu, còn lại cho mỗi danh mục
class Budget extends StatefulWidget {
  const Budget({super.key});

  @override
  State<Budget> createState() => _BudgetState();
}

class _BudgetState extends State<Budget> {
  // Danh sách nhóm danh mục (load từ SharedPreferences)
  List<Map<String, dynamic>> groups = [];

  // Tổng tài sản (load từ wallets)
  double tongTaiSan = 0;

  // Map lưu tổng đã tiêu theo danh mục: {"Thuê nhà": 15000000, ...}
  Map<String, double> spentByCategory = {};

  String? userId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Load dữ liệu nhóm + ví + giao dịch
  _loadData() async {
    userId = await SharedPreferenceHelper().getUserId();

    // Load groups
    String? jsonStr = await SharedPreferenceHelper().getBudgetGroups();
    if (jsonStr != null && jsonStr.isNotEmpty) {
      List<dynamic> decoded = jsonDecode(jsonStr);
      groups = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    // Load wallets → tính tổng tài sản
    String? walletJson = await SharedPreferenceHelper().getWallets();
    tongTaiSan = 0;
    if (walletJson != null && walletJson.isNotEmpty) {
      List<dynamic> wallets = jsonDecode(walletJson);
      for (var w in wallets) {
        tongTaiSan += (w["amount"] ?? 0).toDouble();
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
            double amount = double.tryParse(data["Amount"] ?? "0") ?? 0;
            if (category.isNotEmpty) {
              spentByCategory[category] = (spentByCategory[category] ?? 0) + amount;
            }
          }
        }
      } catch (e) {
        // Firestore chưa sẵn sàng
      }
    }

    setState(() {});
  }

  // Tính tổng đã phân bổ từ tất cả danh mục
  double get tienDaPhanBo {
    double total = 0;
    for (var group in groups) {
      List cats = group["categories"] ?? [];
      for (var cat in cats) {
        total += (cat["allocated"] ?? 0).toDouble();
      }
    }
    return total;
  }

  // Tiền chưa phân bổ = tổng tài sản - đã phân bổ
  double get tienChuaPhanBo => tongTaiSan - tienDaPhanBo;

  // Tính tổng allocated 1 nhóm
  double _groupTotal(Map<String, dynamic> group) {
    double total = 0;
    List cats = group["categories"] ?? [];
    for (var cat in cats) {
      total += (cat["allocated"] ?? 0).toDouble();
    }
    return total;
  }

  // Lấy danh sách danh mục vượt ngân sách kèm số tiền vượt
  List<Map<String, dynamic>> get overBudgetCategories {
    List<Map<String, dynamic>> result = [];
    for (var group in groups) {
      List cats = group["categories"] ?? [];
      for (var cat in cats) {
        double allocated = (cat["allocated"] ?? 0).toDouble();
        double spent = spentByCategory[cat["name"]] ?? 0;
        if (spent > allocated) {
          result.add({
            "name": cat["name"],
            "overAmount": spent - allocated,
          });
        }
      }
    }
    return result;
  }

  int get overBudgetCount => overBudgetCategories.length;

  // Format số tiền VND
  String formatVND(double amount) {
    final formatter = NumberFormat("#,###", "vi_VN");
    if (amount == 0) return "0đ";
    return "${formatter.format(amount)}đ";
  }

  // Lấy tên tháng hiện tại bằng tiếng Việt
  String getCurrentMonth() {
    final now = DateTime.now();
    return "Tháng ${now.month} ${now.year}";
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
              // ---- HEADER ----
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // Title + icon edit
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),
                        const Text(
                          "Ngân sách tháng",
                          style: TextStyle(color: Colors.white, fontSize: 22.0, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        // Icon bút (edit)
                        GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const EditBudget()),
                            );
                            _loadData();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.edit, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    // Tháng hiện tại
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            getCurrentMonth(),
                            style: const TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),

              // ---- THẺ TIỀN PHÂN BỔ ----
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text("Tiền đã phân bổ", style: TextStyle(color: Color(0xFF2E7D32), fontSize: 14.0, fontWeight: FontWeight.w500)),
                              const SizedBox(width: 4),
                              Icon(Icons.edit, color: const Color(0xFF2E7D32).withValues(alpha: 0.6), size: 14),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(formatVND(tienDaPhanBo), style: const TextStyle(color: Color(0xFF1B5E20), fontSize: 24.0, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text("Tiền chưa phân bổ", style: TextStyle(color: Color(0xFF2E7D32), fontSize: 14.0, fontWeight: FontWeight.w500)),
                              const SizedBox(width: 4),
                              Icon(Icons.edit, color: const Color(0xFF2E7D32).withValues(alpha: 0.6), size: 14),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(formatVND(tienChuaPhanBo), style: const TextStyle(color: Color(0xFF1B5E20), fontSize: 24.0, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const Text("💰", style: TextStyle(fontSize: 50)),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),

              // ---- NÚT GIAO VIỆC CHO TIỀN ----
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AllocateBudget(tongTaiSan: tongTaiSan)),
                    );
                    _loadData();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("GIAO VIỆC CHO TIỀN", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20.0),

              // ---- CẢNH BÁO VƯỢT NGÂN SÁCH (bấm vào → bù đắp) ----
              if (overBudgetCount > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GestureDetector(
                    onTap: () async {
                      // Lấy danh mục vượt đầu tiên để bù
                      var overCats = overBudgetCategories;
                      if (overCats.isNotEmpty) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CompensateBudget(
                              overCategoryName: overCats.first["name"],
                              overAmount: overCats.first["overAmount"],
                              tongTaiSan: tongTaiSan,
                            ),
                          ),
                        );
                        _loadData();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Có $overBudgetCount danh mục chi tiêu vượt mức số tiền đã phân bổ.",
                                  style: TextStyle(fontSize: 13, color: Colors.orange.shade900, fontWeight: FontWeight.w500),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text("$overBudgetCount", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Bạn đã chi tiêu vượt kế hoạch. Bấm để bù đắp.",
                            style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ---- DANH SÁCH NHÓM DANH MỤC ----
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    if (groups.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: const Column(
                          children: [
                            Icon(Icons.folder_open, color: Colors.grey, size: 48),
                            SizedBox(height: 12),
                            Text("Chưa có nhóm danh mục nào", style: TextStyle(color: Colors.grey, fontSize: 16)),
                            SizedBox(height: 4),
                            Text("Bấm icon ✏️ ở góc phải để bắt đầu", style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ),

                    // Hiện danh sách từng nhóm
                    ...groups.map((group) {
                      List categories = group["categories"] ?? [];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tên nhóm + tổng
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(group["name"], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text(formatVND(_groupTotal(group)), style: const TextStyle(color: Colors.grey, fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Danh mục trong nhóm
                          ...categories.map((cat) {
                            IconData catIcon = IconData(cat["icon"] ?? 0xe318, fontFamily: 'MaterialIcons');
                            double allocated = (cat["allocated"] ?? 0).toDouble();
                            double spent = spentByCategory[cat["name"]] ?? 0;
                            double remaining = allocated - spent;
                            String catType = cat["type"] ?? "chi_tieu";
                            bool isOverBudget = spent > allocated;
                            double savingsGoal = (cat["savingsGoal"] ?? 0).toDouble();

                            if (catType == "tiet_kiem") {
                              return _buildSavingsCard(
                                icon: catIcon,
                                name: cat["name"],
                                allocated: allocated,
                                savingsGoal: savingsGoal,
                              );
                            } else {
                              return _buildSpendingCard(
                                icon: catIcon,
                                name: cat["name"],
                                allocated: allocated,
                                spent: spent,
                                remaining: remaining,
                                isOverBudget: isOverBudget,
                              );
                            }
                          }),
                          const SizedBox(height: 16),
                        ],
                      );
                    }),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- CARD CHI TIÊU ----
  // Hiện: đã phân bổ, đã tiêu, còn lại + progress bar xanh lá
  Widget _buildSpendingCard({
    required IconData icon,
    required String name,
    required double allocated,
    required double spent,
    required double remaining,
    required bool isOverBudget,
  }) {
    const Color categoryColor = Color(0xFF4CAF50);
    double progress = allocated > 0 ? (spent / allocated).clamp(0.0, 1.0) : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isOverBudget ? Border.all(color: Colors.orange.shade400, width: 1.5) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Tên + icon + đã phân bổ
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: categoryColor, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(child: Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
                        const Icon(Icons.more_horiz, color: Colors.grey, size: 20),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text("Đã phân bổ: ${formatVND(allocated)}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverBudget ? Colors.orange.shade400 : categoryColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Đã tiêu + Còn lại
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Đã tiêu", style: TextStyle(color: Colors.grey, fontSize: 11)),
                    Text(
                      formatVND(spent),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isOverBudget ? Colors.red.shade700 : Colors.black87),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("Còn lại", style: TextStyle(color: Colors.grey, fontSize: 11)),
                    Text(
                      remaining < 0 ? "-${formatVND(remaining.abs())}" : formatVND(remaining),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: remaining < 0 ? Colors.red.shade700 : const Color(0xFF2E7D32)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Cảnh báo vượt ngân sách
          if (isOverBudget) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Bạn đã chi tiêu vượt kế hoạch", style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.w500)),
                  GestureDetector(
                    onTap: () async {
                      double overAmt = (spent - allocated).abs();
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CompensateBudget(
                            overCategoryName: name,
                            overAmount: overAmt,
                            tongTaiSan: tongTaiSan,
                          ),
                        ),
                      );
                      _loadData();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(6)),
                      child: const Text("Chỉnh sửa", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---- CARD TIẾT KIỆM ----
  // Hiện: "Đã phân bổ: X / Y" (progress/goal), progress bar xanh dương
  // Nếu allocated == 0: hiện "Cần phân bổ thêm"
  Widget _buildSavingsCard({
    required IconData icon,
    required String name,
    required double allocated,
    required double savingsGoal,
  }) {
    const Color categoryColor = Color(0xFF1976D2);
    // Dùng savingsGoal nếu có, nếu không thì dùng allocated làm mục tiêu
    double target = savingsGoal > 0 ? savingsGoal : allocated;
    double progress = target > 0 ? (allocated / target).clamp(0.0, 1.0) : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tên + icon + đã phân bổ dạng X/Y
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: categoryColor, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(child: Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
                        const Icon(Icons.more_horiz, color: Colors.grey, size: 20),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // "Đã phân bổ: 0đ / 100.000đ"
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Roboto'),
                        children: [
                          const TextSpan(text: "Đã phân bổ: "),
                          TextSpan(
                            text: formatVND(allocated),
                            style: TextStyle(
                              color: allocated > 0 ? const Color(0xFF1976D2) : Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (target > 0) ...[
                            const TextSpan(text: " / "),
                            TextSpan(text: formatVND(target)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar xanh dương
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(categoryColor),
            ),
          ),
          const SizedBox(height: 8),
          // Dòng dưới: trạng thái + số tiền mục tiêu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Nếu chưa phân bổ → "Cần phân bổ thêm"
              // Nếu đã phân bổ → hiện % hoàn thành
              allocated == 0
                  ? Text("Cần phân bổ thêm", style: TextStyle(color: Colors.orange.shade700, fontSize: 12, fontWeight: FontWeight.w500))
                  : Text(
                      "${(progress * 100).toStringAsFixed(0)}% hoàn thành",
                      style: const TextStyle(color: Color(0xFF1976D2), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
              if (target > 0)
                Text(formatVND(target), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
