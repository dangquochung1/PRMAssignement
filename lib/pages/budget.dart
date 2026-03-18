import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prmproject/pages/allocate_budget.dart';
import 'package:prmproject/pages/compensate_budget.dart';
import 'package:prmproject/pages/edit_budget.dart';
import 'package:prmproject/pages/budget_category_detail.dart';
import 'package:prmproject/services/database.dart';
import 'package:prmproject/services/shared_pref.dart';

class Budget extends StatefulWidget {
  const Budget({super.key});

  @override
  State<Budget> createState() => _BudgetState();
}

class _BudgetState extends State<Budget> {
  List<Map<String, dynamic>> groups = [];
  double tongTaiSan = 0;
  Map<String, double> spentByCategory = {};
  String? userId;

  // Tên ngân sách (có thể edit)
  String budgetName = "Ngân sách tháng";

  // Tháng đang xem
  DateTime selectedBudgetDate = DateTime.now();

  // Tập hợp các tháng có giao dịch, dạng "MM-yyyy"
  Set<String> availableMonths = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadData()); // ← thêm Future.microtask
  }

  _loadData() async {
    userId = await SharedPreferenceHelper().getUserId();

    String? savedName = await SharedPreferenceHelper().getBudgetName();

    if (savedName != null && savedName.isNotEmpty) budgetName = savedName;

    String? jsonStr = await SharedPreferenceHelper().getBudgetGroups();
    if (jsonStr != null && jsonStr.isNotEmpty) {
      List<dynamic> decoded = jsonDecode(jsonStr);
      groups = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    String? walletJson = await SharedPreferenceHelper().getWallets();
    tongTaiSan = 0;
    if (walletJson != null && walletJson.isNotEmpty) {
      List<dynamic> wallets = jsonDecode(walletJson);
      for (var w in wallets) {
        if (w is Map && w["type"] != "Tracking") {
          tongTaiSan += (w["amount"] ?? 0).toDouble();
        }
      }
    }

    spentByCategory = {};
    availableMonths = {};
    String filterMonth = DateFormat("MM-yyyy").format(selectedBudgetDate);

    if (userId != null) {
      try {
        // ✅ Dùng cache thay vì gọi thẳng Firestore
        List<Map<String, dynamic>> txList =
        await DatabaseMethdos().getTransactionsCached(userId!);

        for (var data in txList) {
          String txDate = data["Date"] ?? "";
          if (txDate.length >= 7) {
            String mmyyyy = txDate.substring(txDate.length - 7);
            availableMonths.add(mmyyyy);
          }
          String txType = data["Type"] ?? "";
          if (txType == "tien_ra" && txDate.endsWith(filterMonth)) {
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

  double get tienChuaPhanBo => tongTaiSan - tienDaPhanBo;

  double _groupTotal(Map<String, dynamic> group) {
    double total = 0;
    List cats = group["categories"] ?? [];
    for (var cat in cats) {
      total += (cat["allocated"] ?? 0).toDouble();
    }
    return total;
  }

  List<Map<String, dynamic>> get overBudgetCategories {
    List<Map<String, dynamic>> result = [];
    for (var group in groups) {
      List cats = group["categories"] ?? [];
      for (var cat in cats) {
        double allocated = (cat["allocated"] ?? 0).toDouble();
        double spent = spentByCategory[cat["name"]] ?? 0;
        String catType = cat["type"] ?? "chi_tieu";

        bool isOver = false;
        if (catType == "tiet_kiem") {
          // Tiết kiệm: cảnh báo khi rút tiền (spent) vượt quá đã tích lũy (allocated)
          isOver = spent > allocated;
        } else {
          // Chi tiêu: cảnh báo khi chi vượt phân bổ (kể cả chưa phân bổ = 0 mà đã chi)
          isOver = spent > allocated;
        }

        // Chi tiêu: luôn cảnh báo khi vượt. Tiết kiệm: chỉ khi đã có phân bổ > 0 (tránh nhiễu)
        final bool shouldWarn =
            isOver && (catType == "chi_tieu" || allocated > 0);
        if (shouldWarn) {
          result.add({
            "name": cat["name"],
            "overAmount": spent - allocated,
            "type": catType,  // ← thêm type để phân biệt khi hiển thị
          });
        }
      }
    }
    return result;
  }

  int get overBudgetCount => overBudgetCategories.length;

  String formatVND(double amount) {
    final formatter = NumberFormat("#,###", "vi_VN");
    if (amount == 0) return "0đ";
    return "${formatter.format(amount)}đ";
  }

  String get currentMonthLabel =>
      "Tháng ${selectedBudgetDate.month} ${selectedBudgetDate.year}";

  // ---- DIALOG ĐỔI TÊN NGÂN SÁCH ----
  void _showEditNameDialog() {
    final ctrl = TextEditingController(text: budgetName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Đổi tên ngân sách",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Nhập tên ngân sách",
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
            child: const Text("HỦY",
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                await SharedPreferenceHelper()
                    .saveBudgetName(ctrl.text.trim());
                setState(() => budgetName = ctrl.text.trim());
              }
              if (mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4A843),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("LƯU",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ---- MONTH/YEAR PICKER dựa trên data thực ----
  void _showMonthYearPicker() {
    // Nếu không có data, không mở picker (tháng đầu tiên)
    if (availableMonths.isEmpty) return;

    // Tập năm có data
    Set<int> enabledYears = {};
    for (String mm in availableMonths) {
      List<String> parts = mm.split("-");
      if (parts.length == 2) {
        int? y = int.tryParse(parts[1]);
        if (y != null) enabledYears.add(y);
      }
    }

    int pickerYear = selectedBudgetDate.year;
    // Nếu năm hiện tại không có data, lấy năm đầu tiên
    if (!enabledYears.contains(pickerYear) && enabledYears.isNotEmpty) {
      pickerYear = enabledYears.first;
    }

    bool showYears = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx2, setSheet) {
          // Tháng enabled cho năm đang xem
          Set<int> enabledMonths = {};
          for (String mm in availableMonths) {
            List<String> parts = mm.split("-");
            if (parts.length == 2 && int.tryParse(parts[1]) == pickerYear) {
              int? m = int.tryParse(parts[0]);
              if (m != null) enabledMonths.add(m);
            }
          }

          return Container(
            height: 400,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F0),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Drag handle
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                // Header: click để toggle tháng/năm
                GestureDetector(
                  onTap: () => setSheet(() => showYears = !showYears),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (showYears) ...[
                        const Icon(Icons.chevron_left,
                            color: Color(0xFFD4A843)),
                        Text(
                          "Tháng ${selectedBudgetDate.month}",
                          style: const TextStyle(
                            color: Color(0xFFD4A843),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else ...[
                        Text(
                          "$pickerYear",
                          style: const TextStyle(
                            color: Color(0xFFD4A843),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down,
                            color: Color(0xFFD4A843)),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Grid tháng hoặc năm
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: showYears
                        // ---- LƯỚI NĂM ----
                        ? GridView.count(
                            crossAxisCount: 4,
                            childAspectRatio: 2.0,
                            children: List.generate(16, (i) {
                              int startYear = DateTime.now().year - 5;
                              int y = startYear + i;
                              bool enabled = enabledYears.contains(y);
                              bool isSel = y == pickerYear;
                              return GestureDetector(
                                onTap: enabled
                                    ? () => setSheet(() {
                                          pickerYear = y;
                                          showYears = false;
                                        })
                                    : null,
                                child: Container(
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isSel
                                        ? const Color(0xFFD4A843)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    "$y",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSel
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSel
                                          ? Colors.white
                                          : enabled
                                              ? Colors.black87
                                              : Colors.grey.shade400,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          )
                        // ---- LƯỚI THÁNG ----
                        : GridView.count(
                            crossAxisCount: 3,
                            childAspectRatio: 2.5,
                            children: List.generate(12, (i) {
                              int m = i + 1;
                              bool enabled = enabledMonths.contains(m);
                              bool isSel =
                                  selectedBudgetDate.month == m &&
                                      selectedBudgetDate.year == pickerYear;
                              return GestureDetector(
                                onTap: enabled
                                    ? () {
                                        setState(() => selectedBudgetDate =
                                            DateTime(pickerYear, m));
                                        Navigator.pop(ctx);
                                        _loadData();
                                      }
                                    : null,
                                child: Container(
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isSel
                                        ? const Color(0xFFD4A843)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    "Tháng $m",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSel
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSel
                                          ? Colors.white
                                          : enabled
                                              ? Colors.black87
                                              : Colors.grey.shade400,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        });
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
              // ---- HEADER ----
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 16.0),
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // Title + icon settings + icon edit
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Bánh răng (edit tên)
                        GestureDetector(
                          onTap: _showEditNameDialog,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color:
                                  Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.settings,
                                color: Colors.white, size: 20),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          budgetName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22.0,
                              fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        // Icon bút (edit danh mục)
                        GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const EditBudget()),
                            );
                            _loadData();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color:
                                  Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.edit,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    // Tháng hiện tại — có thể bấm để đổi
                    GestureDetector(
                      onTap: _showMonthYearPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentMonthLabel,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down,
                                color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),

              // ---- THẺ TIỀN PHÂN BỔ ----
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tiền chưa phân bổ
                        Row(
                          children: [
                            const Text("Tiền chưa phân bổ",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => AllocateBudget(
                                          tongTaiSan: tongTaiSan)),
                                );
                                _loadData();
                              },
                              child: const Icon(Icons.edit,
                                  color: Colors.white70, size: 14),
                            ),
                          ],
                        ),
                        Text(
                          formatVND(tienChuaPhanBo),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        // Tiền đã phân bổ
                        Row(
                          children: [
                            const Text("Tiền đã phân bổ",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => AllocateBudget(
                                          tongTaiSan: tongTaiSan)),
                                );
                                _loadData();
                              },
                              child: const Icon(Icons.edit,
                                  color: Colors.white70, size: 14),
                            ),
                          ],
                        ),
                        Text(
                          formatVND(tienDaPhanBo),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        // Nút GIAO VIỆC CHO TIỀN
                        GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      AllocateBudget(tongTaiSan: tongTaiSan)),
                            );
                            _loadData();
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                      Colors.white.withValues(alpha: 0.5),
                                  width: 1),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "GIAO VIỆC CHO TIỀN",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward,
                                    color: Colors.white, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Mascot
                    Positioned(
                      right: 0,
                      bottom: 32,
                      child: Opacity(
                        opacity: 0.9,
                        child: Image.asset(
                          'assets/images/mascot.png',
                          width: 80,
                          errorBuilder: (_, __, ___) => const Text("🐥",
                              style: TextStyle(fontSize: 50)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ---- CẢNH BÁO VƯỢT NGÂN SÁCH ----
              if (overBudgetCount > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GestureDetector(
                    onTap: () async {
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.orange.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: Colors.orange.shade700,
                                  size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Có $overBudgetCount danh mục chi tiêu vượt mức số tiền đã phân bổ.",
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.orange.shade900,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text("$overBudgetCount",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Bạn đã chi tiêu vượt kế hoạch. Bấm để bù đắp.",
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ---- DANH SÁCH NHÓM DANH MỤC ----
              ...groups.asMap().entries.map((ge) {
                final group = ge.value;
                final int gIdx = ge.key;
                double groupTotal = _groupTotal(group);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tiêu đề nhóm
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            group["name"] ?? "Nhóm",
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            formatVND(groupTotal),
                            style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          ...(group["categories"] as List? ?? [])
                              .asMap()
                              .entries
                              .map((ce) {
                            final cat = ce.value;
                            final int cIdx = ce.key;
                            IconData catIcon = IconData(
                                cat["icon"] ?? 0xe318,
                                fontFamily: 'MaterialIcons');
                            double allocated =
                                (cat["allocated"] ?? 0).toDouble();
                            double spent =
                                spentByCategory[cat["name"]] ?? 0;
                            double remaining = allocated - spent;
                            String catType =
                                cat["type"] ?? "chi_tieu";
                            bool isOverBudget = spent > allocated;
                            double savingsGoal =
                                (cat["savingsGoal"] ?? 0).toDouble();

                            Widget card;
                            if (catType == "tiet_kiem") {
                              card = _buildSavingsCard(
                                icon: catIcon,
                                name: cat["name"],
                                allocated: allocated,
                                savingsGoal: savingsGoal,
                              );
                            } else {
                              card = _buildSpendingCard(
                                icon: catIcon,
                                name: cat["name"],
                                allocated: allocated,
                                spent: spent,
                                remaining: remaining,
                                isOverBudget: isOverBudget,
                              );
                            }
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          BudgetCategoryDetail(
                                        groupIndex: gIdx,
                                        categoryIndex: cIdx,
                                        budgetMonth: selectedBudgetDate,
                                      ),
                                    ),
                                  );
                                  _loadData();
                                },
                                child: card,
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                );
              }),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpendingCard({
    required IconData icon,
    required String name,
    required double allocated,
    required double spent,
    required double remaining,
    required bool isOverBudget,
  }) {
    const Color categoryColor = Color(0xFF4CAF50);
    double progress =
        allocated > 0 ? (spent / allocated).clamp(0.0, 1.0) : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isOverBudget
            ? Border.all(color: Colors.red.shade300, width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isOverBudget
                      ? Colors.red.shade50
                      : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    color: isOverBudget
                        ? Colors.red.shade700
                        : categoryColor,
                    size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    Text(
                      "Đã phân bổ: ${formatVND(allocated)}",
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isOverBudget
                        ? "-${formatVND(remaining.abs())}"
                        : formatVND(remaining),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isOverBudget
                          ? Colors.red.shade700
                          : const Color(0xFF2E7D32),
                    ),
                  ),
                  Text(
                    "Đã tiêu: ${formatVND(spent)}",
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              color: isOverBudget ? Colors.red.shade400 : categoryColor,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsCard({
    required IconData icon,
    required String name,
    required double allocated,
    required double savingsGoal,
  }) {
    double progress =
        savingsGoal > 0 ? (allocated / savingsGoal).clamp(0.0, 1.0) : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFFD4A843).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    color: const Color(0xFFD4A843), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    Text("Tiết kiệm",
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatVND(allocated),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD4A843))),
                  if (savingsGoal > 0)
                    Text(
                      "/ ${formatVND(savingsGoal)}",
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 11),
                    ),
                ],
              ),
            ],
          ),
          if (savingsGoal > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                color: const Color(0xFFD4A843),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}