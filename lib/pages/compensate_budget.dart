import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prmproject/services/database.dart';
import 'package:prmproject/services/shared_pref.dart';

// Trang bù đắp chi tiêu vượt mức
// Hiển thị danh sách các nguồn được chọn để bù tiền (vuốt để xóa)
class CompensateBudget extends StatefulWidget {
  final String overCategoryName;
  final double overAmount; // Số tiền cần bù (tổng cộng)
  final double tongTaiSan;

  const CompensateBudget({
    super.key,
    required this.overCategoryName,
    required this.overAmount,
    required this.tongTaiSan,
  });

  @override
  State<CompensateBudget> createState() => _CompensateBudgetState();
}

class _CompensateBudgetState extends State<CompensateBudget> {
  List<Map<String, dynamic>> groups = [];
  Map<String, double> spentByCategory = {};

  // Lưu trữ các nguồn đã chọn để bù
  // Format: { "name": String, "amount": double, "icon": int, "type": String, "available": double }
  List<Map<String, dynamic>> selectedSources = [];

  // Controllers cho các TextField nhập số tiền bù của mỗi nguồn
  Map<String, TextEditingController> amountControllers = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  _loadData() async {
    String? jsonStr = await SharedPreferenceHelper().getBudgetGroups();
    if (jsonStr != null && jsonStr.isNotEmpty) {
      List<dynamic> decoded = jsonDecode(jsonStr);
      groups = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    String? userId = await SharedPreferenceHelper().getUserId();
    spentByCategory = {};
    if (userId != null) {
      try {
        var snapshot = await DatabaseMethdos().getTransactions(userId);
        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          if (data["Type"] == "tien_ra") {
            String cat = data["Category"] ?? "";
            double amt = double.tryParse(data["Amount"] ?? "0") ?? 0;
            if (cat.isNotEmpty) {
              spentByCategory[cat] = (spentByCategory[cat] ?? 0) + amt;
            }
          }
        }
      } catch (e) {
        // Bỏ qua lỗi
      }
    }
    setState(() {});
  }

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

  double get tienChuaCoViec => widget.tongTaiSan - tongDaPhanBo;

  String formatVND(double amount) {
    final formatter = NumberFormat("#,###", "vi_VN");
    if (amount == 0) return "0đ";
    return "${formatter.format(amount)}đ";
  }

  // Lấy TẤT CẢ danh sách nguồn có thể bù (kể cả những nguồn đã chọn để dễ disable)
  List<Map<String, dynamic>> get allAvailableSources {
    List<Map<String, dynamic>> sources = [];

    // Tiền chưa có việc
    if (tienChuaCoViec > 0) {
      sources.add({
        "name": "Tiền chưa có việc",
        "available": tienChuaCoViec,
        "icon": Icons.account_balance.codePoint,
        "type": "unallocated",
      });
    }

    // Tiền từ các danh mục khác
    for (var group in groups) {
      List cats = group["categories"] ?? [];
      String groupType = group["type"] ?? "chi_tieu";

      for (var cat in cats) {
        String catName = cat["name"];
        if (catName == widget.overCategoryName) continue; // Không bù từ chính nó

        double allocated = (cat["allocated"] ?? 0).toDouble();
        double spent = spentByCategory[catName] ?? 0;

        double available;
        String catType = cat["type"] ?? groupType;
        if (catType == "tiet_kiem") {
          available = allocated;
        } else {
          available = allocated - spent;
        }

        if (available > 0) {
          sources.add({
            "name": catName,
            "available": available,
            "icon": cat["icon"] ?? 0xe318,
            "type": catType,
          });
        }
      }
    }
    return sources;
  }

  // Tổng số tiền đang được chọn để bù
  double get totalCompensatedAmount {
    double total = 0;
    amountControllers.forEach((key, controller) {
      total += double.tryParse(controller.text.replaceAll(',', '')) ?? 0;
    });
    return total;
  }

  // Mở BottomSheet chọn nguồn
  void _showAddSourceSheet() {
    List<Map<String, dynamic>> available = allAvailableSources;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Color(0xFFF5F5F0),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Thanh kéo
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Text("Thêm nguồn tiền", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: available.length,
                  itemBuilder: (context, index) {
                    var source = available[index];
                    bool alreadySelected = selectedSources.any((s) => s["name"] == source["name"]);

                    return GestureDetector(
                      onTap: alreadySelected ? null : () {
                        // Chọn nguồn
                        setState(() {
                          selectedSources.add(source);
                          // Mặc định điền phần tiền còn thiếu (nếu đủ)
                          double needMore = widget.overAmount - totalCompensatedAmount;
                          double valToFill = 0;
                          if (needMore > 0) {
                            valToFill = needMore <= source["available"] ? needMore : source["available"];
                          }
                          
                          // Khởi tạo controller cho nguồn mới
                          amountControllers[source["name"]] = TextEditingController(text: valToFill.toStringAsFixed(0));
                          amountControllers[source["name"]]!.addListener(() {
                              setState(() {}); // Lắng nghe để update Tổng tiền bù
                          });
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: alreadySelected ? Colors.grey.shade200 : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: alreadySelected ? [] : [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: alreadySelected ? Colors.grey.shade300 : const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(IconData(source["icon"], fontFamily: 'MaterialIcons'), 
                                color: alreadySelected ? Colors.grey : const Color(0xFF2E7D32), size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(source["name"], style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: alreadySelected ? Colors.grey : Colors.black)),
                                  Text(
                                    source["type"] == "unallocated" ? "Tiền nhàn rỗi" : "Còn lại",
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              formatVND(source["available"]),
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: alreadySelected ? Colors.grey : const Color(0xFF2E7D32)),
                            ),
                            const SizedBox(width: 8),
                            if (alreadySelected)
                               const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 20)
                            else
                               const Icon(Icons.add_circle_outline, color: Color(0xFF4CAF50), size: 20),
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
  }

  // --- LOGIC LƯU TẤT CẢ NGUỒN VÀ BÙ TIỀN ---
  Future<void> _saveAllCompensations() async {
    // 1. Kiểm tra validation (Có gõ số tiền quá mức available của từng nguồn không?)
    for (var source in selectedSources) {
      double inputAmt = double.tryParse(amountControllers[source["name"]]!.text) ?? 0;
      if (inputAmt > source["available"]) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text("Nguồn '${source["name"]}' không đủ tiền!")),
        );
        return;
      }
    }

    double totalInput = totalCompensatedAmount;
    if (totalInput == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.orangeAccent, content: Text("Bạn chưa nhập số dư nào để bù.")),
      );
      return;
    }

    // 2. Apply việc bù tiền
    for (var source in selectedSources) {
      double inputAmt = double.tryParse(amountControllers[source["name"]]!.text) ?? 0;
      if (inputAmt <= 0) continue;

      if (source["type"] == "unallocated") {
        // Lấy từ tiền chưa báo việc -> chỉ cần tăng đích (Target)
        _addAllocationTarget(widget.overCategoryName, inputAmt);
      } else {
        // Lấy từ danh mục khác -> Giảm nguồn source, tăng đích Target
        _transferAllocation(source["name"], widget.overCategoryName, inputAmt);
      }
    }

    // 3. Save to SharedPreferences
    String jsonStr = jsonEncode(groups);
    await SharedPreferenceHelper().saveBudgetGroups(jsonStr);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.green, content: Text("Đã bù tiền thành công!")),
      );
      Navigator.pop(context);
    }
  }

  void _transferAllocation(String sourceName, String targetName, double amount) {
    for (int g = 0; g < groups.length; g++) {
      List cats = groups[g]["categories"] ?? [];
      for (int c = 0; c < cats.length; c++) {
        if (cats[c]["name"] == sourceName) {
          double oldAlloc = (cats[c]["allocated"] ?? 0).toDouble();
          (groups[g]["categories"] as List)[c]["allocated"] = oldAlloc - amount;
        }
        if (cats[c]["name"] == targetName) {
          double oldAlloc = (cats[c]["allocated"] ?? 0).toDouble();
          (groups[g]["categories"] as List)[c]["allocated"] = oldAlloc + amount;
        }
      }
    }
  }

  void _addAllocationTarget(String targetName, double amount) {
    for (int g = 0; g < groups.length; g++) {
      List cats = groups[g]["categories"] ?? [];
      for (int c = 0; c < cats.length; c++) {
        if (cats[c]["name"] == targetName) {
          double oldAlloc = (cats[c]["allocated"] ?? 0).toDouble();
          (groups[g]["categories"] as List)[c]["allocated"] = oldAlloc + amount;
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    double needToCover = widget.overAmount;
    double remainingToCover = needToCover - totalCompensatedAmount;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0), // Nền giống màu ảnh
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
                      decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 20, color: Colors.black54),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text("Bù đắp chi tiêu vượt mức", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  // Nút LƯU
                  GestureDetector(
                    onTap: _saveAllCompensations,
                    child: const Text("LƯU", style: TextStyle(color: Color(0xFFD4A843), fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            // ---- CARD TỔNG KẾT VƯỢT MỨC ----
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFC8E6C9), // Nền xanh nhạt
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Text(widget.overCategoryName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    remainingToCover > 0 ? formatVND(remainingToCover) : "0đ",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: remainingToCover <= 0 ? const Color(0xFF2E7D32) : Colors.red.shade700),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20), // Xanh lá đậm
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      remainingToCover <= 0 ? "Đã điều chỉnh đủ khoản vượt mức" : "Cần điều chỉnh thêm ${formatVND(remainingToCover)}", 
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ---- DANH SÁCH CÁC NGUỒN ĐÃ CHỌN (Swipe to delete) ----
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: selectedSources.length + 1, // +1 cho nút Thêm nguồn tiền
                itemBuilder: (context, index) {
                  if (index == selectedSources.length) {
                    // NÚT THÊM NGUỒN TIỀN
                    return GestureDetector(
                      onTap: _showAddSourceSheet,
                      child: Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 30),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD4A843), style: BorderStyle.solid), // Khung vàng
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle, color: Color(0xFFD4A843), size: 20),
                            SizedBox(width: 8),
                            Text("THÊM NGUỒN TIỀN", style: TextStyle(color: Color(0xFFD4A843), fontSize: 15, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  }

                  // CÁC THẺ CARD NHẬP SỐ TIỀN THỰC TẾ
                  var source = selectedSources[index];
                  TextEditingController controller = amountControllers[source["name"]]!;

                  return Dismissible(
                    key: Key(source["name"]),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      setState(() {
                        selectedSources.removeAt(index);
                        amountControllers.remove(source["name"]);
                      });
                    },
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white, size: 30),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                           BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Bù số tiền:", style: TextStyle(fontSize: 13, color: Colors.grey)),
                          const SizedBox(height: 8),
                          // TEXT FIELD NHẬP TIỀN
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                const Text("đ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: controller,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    decoration: const InputDecoration(border: InputBorder.none),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text("Lấy từ:", style: TextStyle(fontSize: 13, color: Colors.grey)),
                          const SizedBox(height: 8),
                          // THÔNG TIN SOURCE
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E0), // Nền cam nhạt
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(IconData(source["icon"], fontFamily: 'MaterialIcons'), color: Colors.orange.shade700, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(source["name"], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    RichText(
                                      text: TextSpan(
                                        style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Roboto'),
                                        children: [
                                          const TextSpan(text: "Còn lại: "),
                                          TextSpan(text: formatVND(source["available"]), style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.edit, color: Colors.grey, size: 20),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
