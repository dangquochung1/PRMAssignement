import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prmproject/services/shared_pref.dart';

// Trang phân bổ ngân sách — chỉnh sửa số tiền phân bổ cho từng danh mục
class AllocateBudget extends StatefulWidget {
  final double tongTaiSan; // Tổng tài sản từ ví

  const AllocateBudget({super.key, required this.tongTaiSan});

  @override
  State<AllocateBudget> createState() => _AllocateBudgetState();
}

class _AllocateBudgetState extends State<AllocateBudget> {
  List<Map<String, dynamic>> groups = [];
  // Map lưu controllers cho từng danh mục: key = "groupIdx_catIdx"
  Map<String, TextEditingController> controllers = {};

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  // Load nhóm danh mục
  _loadGroups() async {
    String? jsonStr = await SharedPreferenceHelper().getBudgetGroups();
    if (jsonStr != null && jsonStr.isNotEmpty) {
      List<dynamic> decoded = jsonDecode(jsonStr);
      groups = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    // Tạo controllers cho mỗi danh mục
    for (int g = 0; g < groups.length; g++) {
      List cats = groups[g]["categories"] ?? [];
      for (int c = 0; c < cats.length; c++) {
        double allocated = (cats[c]["allocated"] ?? 0).toDouble();
        controllers["${g}_$c"] = TextEditingController(
          text: allocated > 0 ? _formatNumber(allocated) : "",
        );
      }
    }
    setState(() {});
  }

  // Format số không có "đ"
  String _formatNumber(double amount) {
    if (amount == 0) return "";
    final formatter = NumberFormat("#,###", "vi_VN");
    return formatter.format(amount);
  }

  // Format VND
  String formatVND(double amount) {
    final formatter = NumberFormat("#,###", "vi_VN");
    if (amount == 0) return "0đ";
    return "${formatter.format(amount)}đ";
  }

  // Tính tổng đã phân bổ
  double get tongDaPhanBo {
    double total = 0;
    for (var group in groups) {
      List cats = group["categories"] ?? [];
      for (var cat in cats) {
        total += (cat["allocated"] ?? 0).toDouble();
      }
    }
    return total;
  }

  // Tiền chưa có việc = tổng tài sản - đã phân bổ
  double get tienChuaCoViec => widget.tongTaiSan - tongDaPhanBo;

  // Tính tổng allocated cho 1 nhóm
  double _groupTotal(Map<String, dynamic> group) {
    double total = 0;
    List cats = group["categories"] ?? [];
    for (var cat in cats) {
      total += (cat["allocated"] ?? 0).toDouble();
    }
    return total;
  }

  // Lưu lại dữ liệu
  _saveGroups() async {
    String jsonStr = jsonEncode(groups);
    await SharedPreferenceHelper().saveBudgetGroups(jsonStr);
  }

  @override
  void dispose() {
    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 20, color: Colors.black54),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text("Phân bổ ngân sách", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _saveGroups();
                      Navigator.pop(context);
                    },
                    child: const Text("LƯU", style: TextStyle(color: Color(0xFFD4A843), fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            // ---- NỘI DUNG ----
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ---- 2 THẺ: Tiền chưa có việc + Tiền đã phân bổ ----
                      Row(
                        children: [
                          // Tiền chưa có việc
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text("Tiền chưa có việc", style: TextStyle(color: Colors.white70, fontSize: 12)),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.info_outline, color: Colors.white70, size: 14),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatVND(tienChuaCoViec),
                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Tiền đã phân bổ
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4A843),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text("Tiền đã phân bổ", style: TextStyle(color: Colors.white70, fontSize: 12)),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.info_outline, color: Colors.white70, size: 14),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatVND(tongDaPhanBo),
                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ---- DANH SÁCH NHÓM + DANH MỤC ----
                      ...groups.asMap().entries.map((entry) {
                        int gIdx = entry.key;
                        Map<String, dynamic> group = entry.value;
                        List categories = group["categories"] ?? [];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tên nhóm + tổng
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(group["name"], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text(formatVND(_groupTotal(group)), style: const TextStyle(fontSize: 15, color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Danh sách danh mục với input phân bổ
                            ...categories.asMap().entries.map((catEntry) {
                              int cIdx = catEntry.key;
                              Map<String, dynamic> cat = Map<String, dynamic>.from(catEntry.value);
                              IconData catIcon = IconData(cat["icon"] ?? 0xe318, fontFamily: 'MaterialIcons');
                              String key = "${gIdx}_$cIdx";

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
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
                                child: Row(
                                  children: [
                                    // Icon
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(catIcon, color: const Color(0xFF2E7D32), size: 22),
                                    ),
                                    const SizedBox(width: 10),
                                    // Tên + "Đã phân bổ"
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(cat["name"], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                          const Text("Đã phân bổ:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    // Input số tiền
                                    SizedBox(
                                      width: 120,
                                      child: TextField(
                                        controller: controllers[key],
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                        decoration: InputDecoration(
                                          hintText: "0",
                                          hintStyle: TextStyle(color: Colors.grey.shade400),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
                                          ),
                                          suffixText: "đ",
                                        ),
                                        onChanged: (value) {
                                          // Parse và cập nhật allocated
                                          String cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                                          double amount = double.tryParse(cleanValue) ?? 0;
                                          setState(() {
                                            (groups[gIdx]["categories"] as List)[cIdx]["allocated"] = amount;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 16),
                          ],
                        );
                      }),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
