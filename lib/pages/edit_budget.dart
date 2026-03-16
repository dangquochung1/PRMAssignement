import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prmproject/services/shared_pref.dart';
import 'package:prmproject/services/sync_service.dart';
// Trang chỉnh sửa ngân sách — quản lý nhóm danh mục + danh mục
class EditBudget extends StatefulWidget {
  const EditBudget({super.key});

  @override
  State<EditBudget> createState() => _EditBudgetState();
}

class _EditBudgetState extends State<EditBudget> {
  // Dữ liệu nhóm danh mục — lưu dạng List<Map>
  List<Map<String, dynamic>> groups = [];

  // Danh sách icon có sẵn để chọn
  final List<IconData> availableIcons = [
    Icons.home, Icons.phone_android, Icons.wifi,
    Icons.restaurant, Icons.shopping_bag, Icons.local_grocery_store,
    Icons.directions_car, Icons.flight, Icons.school,
    Icons.medical_services, Icons.fitness_center, Icons.pets,
    Icons.movie, Icons.music_note, Icons.sports_esports,
    Icons.laptop, Icons.watch, Icons.checkroom,
    Icons.savings, Icons.account_balance, Icons.credit_card,
    Icons.electric_bolt, Icons.water_drop, Icons.local_gas_station,
  ];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  // Load nhóm danh mục từ SharedPreferences
  _loadGroups() async {
    String? jsonStr = await SharedPreferenceHelper().getBudgetGroups();
    if (jsonStr != null && jsonStr.isNotEmpty) {
      List<dynamic> decoded = jsonDecode(jsonStr);
      groups = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    setState(() {});
  }

  // Lưu nhóm danh mục vào SharedPreferences
  _saveGroups() async {
    String jsonStr = jsonEncode(groups);
    await SharedPreferenceHelper().saveBudgetGroups(jsonStr);
    String? userId = await SharedPreferenceHelper().getUserId();
    if (userId != null) SyncService.pushToFirestore(userId); // ← thêm
  }

  // Format số tiền VND
  String formatVND(double amount) {
    final formatter = NumberFormat("#,###", "vi_VN");
    if (amount == 0) return "0đ";
    return "${formatter.format(amount)}đ";
  }

  // ---- DIALOG XÁC NHẬN XÓA NHÓM DANH MỤC ----
  void _showDeleteGroupDialog(int groupIndex) {
    String groupName = groups[groupIndex]["name"];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Bạn muốn xóa nhóm danh mục "$groupName" thật hả?',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Toàn bộ các danh mục trong nhóm này cũng sẽ bị xóa. Các giao dịch đã được tạo trong nhóm vẫn có thể tìm thấy ở trong ví.",
            style: TextStyle(fontSize: 15, color: Colors.black87),
          ),
          actions: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text("Thôi, không xóa nữa", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                setState(() {
                  groups.removeAt(groupIndex);
                });
                _saveGroups();
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text("Ừ, xóa đi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---- DIALOG XÁC NHẬN XÓA DANH MỤC ----
  void _showDeleteCategoryDialog(int groupIndex, int catIndex) {
    String catName = (groups[groupIndex]["categories"] as List)[catIndex]["name"];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Bạn muốn xóa danh mục "$catName" thật hả?',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Số tiền còn lại trong danh mục sẽ trở thành "Tiền chưa có việc". Các giao dịch trong danh mục này vẫn có thể xem được trong ví.',
            style: TextStyle(fontSize: 15, color: Colors.black87),
          ),
          actions: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text("Thôi, không xóa nữa", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                setState(() {
                  (groups[groupIndex]["categories"] as List).removeAt(catIndex);
                });
                _saveGroups();
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text("Ừ, xóa đi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---- BOTTOM SHEET: TẠO NHÓM DANH MỤC ----
  void _showAddGroupSheet() {
    TextEditingController groupNameController = TextEditingController();

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
              const Text(
                "Thêm nhóm hạng mục mới",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Input tên nhóm
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFECECF8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: groupNameController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Nhập tên nhóm",
                    hintStyle: TextStyle(color: Colors.black54),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Nút LƯU
              GestureDetector(
                onTap: () {
                  if (groupNameController.text.trim().isNotEmpty) {
                    setState(() {
                      groups.add({
                        "name": groupNameController.text.trim(),
                        "categories": [],
                      });
                    });
                    _saveGroups();
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4A843),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text("LƯU", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---- BOTTOM SHEET: THÊM DANH MỤC ----
  void _showAddCategorySheet(int groupIndex) {
    TextEditingController nameController = TextEditingController();
    TextEditingController savingsGoalController = TextEditingController();
    String selectedType = "chi_tieu"; // Mặc định là Chi tiêu
    int selectedIconIndex = 0;
    String savingsMode = "theo_thang"; // Mặc định
    DateTime targetDate = DateTime.now();

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
                    const Text(
                      "Thêm danh mục mới",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // ---- CHỌN ICON ----
                    Row(
                      children: [
                        // Icon đã chọn
                        GestureDetector(
                          onTap: () {
                            // Hiện dialog chọn icon
                            _showIconPicker(context, selectedIconIndex, (index) {
                              setSheetState(() {
                                selectedIconIndex = index;
                              });
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(availableIcons[selectedIconIndex], color: const Color(0xFF2E7D32), size: 30),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            _showIconPicker(context, selectedIconIndex, (index) {
                              setSheetState(() {
                                selectedIconIndex = index;
                              });
                            });
                          },
                          child: const Text("Thay đổi", style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ---- LOẠI DANH MỤC ----
                    const Text("Loại danh mục", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Chi tiêu
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() => selectedType = "chi_tieu"),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selectedType == "chi_tieu" ? const Color(0xFFD4A843) : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selectedType == "chi_tieu" ? const Color(0xFFD4A843) : Colors.grey.shade400,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  "Chi tiêu",
                                  style: TextStyle(
                                    color: selectedType == "chi_tieu" ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Tiết kiệm
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() => selectedType = "tiet_kiem"),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selectedType == "tiet_kiem" ? const Color(0xFFD4A843) : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selectedType == "tiet_kiem" ? const Color(0xFFD4A843) : Colors.grey.shade400,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  "Tiết kiệm",
                                  style: TextStyle(
                                    color: selectedType == "tiet_kiem" ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ---- TÊN DANH MỤC ----
                    const Text("Tên danh mục", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
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
                          hintText: "Nhập tên danh mục",
                          hintStyle: TextStyle(color: Colors.black38),
                        ),
                      ),
                    ),

                    // ---- PHẦN TIẾT KIỆM (chỉ hiện khi chọn Tiết kiệm) ----
                    if (selectedType == "tiet_kiem") ...[
                      const SizedBox(height: 20),
                      const Text("Mục tiêu tiết kiệm", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECECF8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: savingsGoalController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Nhập số tiền",
                            hintStyle: TextStyle(color: Colors.black38),
                            suffixText: "đ",
                            suffixStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2 option: Theo tháng / Theo tổng số tiền
                      Row(
                        children: [
                          // Theo tháng
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setSheetState(() => savingsMode = "theo_thang"),
                              child: Row(
                                children: [
                                  Icon(
                                    savingsMode == "theo_thang" ? Icons.radio_button_checked : Icons.radio_button_off,
                                    color: savingsMode == "theo_thang" ? const Color(0xFFD4A843) : Colors.grey,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text("Theo tháng", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ),
                          // Theo tổng số tiền
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setSheetState(() => savingsMode = "theo_tong"),
                              child: Row(
                                children: [
                                  Icon(
                                    savingsMode == "theo_tong" ? Icons.radio_button_checked : Icons.radio_button_off,
                                    color: savingsMode == "theo_tong" ? const Color(0xFFD4A843) : Colors.grey,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 6),
                                  const Flexible(
                                    child: Text("Theo tổng số tiền", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Date picker (chỉ hiện khi chọn "Theo tổng số tiền")
                      if (savingsMode == "theo_tong") ...[
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: targetDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setSheetState(() {
                                targetDate = picked;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECECF8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Color(0xFFD4A843), size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  "Ngày mục tiêu: ${DateFormat('dd/MM/yyyy').format(targetDate)}",
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],

                    const SizedBox(height: 24),

                    // ---- NÚT LƯU ----
                    GestureDetector(
                      onTap: () {
                        if (nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(backgroundColor: Colors.redAccent, content: Text("Vui lòng nhập tên danh mục")),
                          );
                          return;
                        }

                        Map<String, dynamic> newCategory = {
                          "name": nameController.text.trim(),
                          "icon": availableIcons[selectedIconIndex].codePoint,
                          "type": selectedType,
                        };

                        // Thêm thông tin tiết kiệm nếu cần
                        if (selectedType == "tiet_kiem") {
                          double? goal = double.tryParse(savingsGoalController.text);
                          newCategory["savingsGoal"] = goal ?? 0;
                          newCategory["savingsMode"] = savingsMode;
                          if (savingsMode == "theo_tong") {
                            newCategory["targetDate"] = DateFormat('yyyy-MM-dd').format(targetDate);
                          }
                        }

                        setState(() {
                          (groups[groupIndex]["categories"] as List).add(newCategory);
                        });
                        _saveGroups();
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4A843),
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
      },
    );
  }

  // ---- DIALOG CHỌN ICON ----
  void _showIconPicker(BuildContext context, int currentIndex, Function(int) onSelected) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Chọn icon", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: availableIcons.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    onSelected(index);
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: index == currentIndex ? const Color(0xFFE8F5E9) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: index == currentIndex ? Border.all(color: const Color(0xFF2E7D32), width: 2) : null,
                    ),
                    child: Icon(
                      availableIcons[index],
                      color: index == currentIndex ? const Color(0xFF2E7D32) : Colors.black54,
                      size: 26,
                    ),
                  ),
                );
              },
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
        child: Column(
          children: [
            // ---- HEADER ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Nút đóng
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
                      child: Text(
                        "Chỉnh sửa ngân sách",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  // Nút LƯU trên header
                  GestureDetector(
                    onTap: () {
                      _saveGroups();
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "LƯU",
                      style: TextStyle(color: Color(0xFFD4A843), fontSize: 16, fontWeight: FontWeight.bold),
                    ),
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
                      // ---- NÚT TẠO NHÓM DANH MỤC ----
                      GestureDetector(
                        onTap: _showAddGroupSheet,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4A843),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.create_new_folder, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                "TẠO NHÓM DANH MỤC",
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ---- DANH SÁCH NHÓM + CATEGORIES ----
                      ...groups.asMap().entries.map((entry) {
                        int groupIndex = entry.key;
                        Map<String, dynamic> group = entry.value;
                        List categories = group["categories"] ?? [];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Dấu trừ đỏ + Tên nhóm + tổng tiền
                            Row(
                              children: [
                                // Dấu trừ đỏ — xóa nhóm
                                GestureDetector(
                                  onTap: () => _showDeleteGroupDialog(groupIndex),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: const BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.remove, color: Colors.white, size: 16),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    group["name"],
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const Text("0đ", style: TextStyle(fontSize: 16, color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Danh sách danh mục trong nhóm
                            ...categories.asMap().entries.map((catEntry) {
                              int catIndex = catEntry.key;
                              Map<String, dynamic> cat = Map<String, dynamic>.from(catEntry.value);
                              IconData catIcon = IconData(cat["icon"] ?? 0xe318, fontFamily: 'MaterialIcons');
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Dấu trừ đỏ — xóa danh mục
                                    GestureDetector(
                                      onTap: () => _showDeleteCategoryDialog(groupIndex, catIndex),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: const BoxDecoration(
                                          color: Colors.redAccent,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.remove, color: Colors.white, size: 14),
                                      ),
                                    ),
                                    // Card danh mục
                                    Expanded(
                                      child: Container(
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
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE8F5E9),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Icon(catIcon, color: const Color(0xFF2E7D32), size: 24),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(cat["name"], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                                    ],
                                                  ),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      const Text("Đã phân bổ:", style: TextStyle(color: Colors.grey, fontSize: 13)),
                                                      const Text(
                                                        "0đ",
                                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),

                            // Nút + THÊM DANH MỤC (cuối mỗi nhóm)
                            GestureDetector(
                              onTap: () => _showAddCategorySheet(groupIndex),
                              child: Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 24),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFF4CAF50), width: 1.5),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_circle_outline, color: Color(0xFF4CAF50), size: 20),
                                    SizedBox(width: 6),
                                    Text(
                                      "THÊM DANH MỤC",
                                      style: TextStyle(color: Color(0xFF4CAF50), fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
