import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prmproject/services/database.dart';
import 'package:prmproject/services/shared_pref.dart';

class Analytics extends StatefulWidget {
  const Analytics({super.key});

  @override
  State<Analytics> createState() => _AnalyticsState();
}

class _AnalyticsState extends State<Analytics> {
  bool isExpenseTab = true;
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> allTransactions = [];
  
  List<String> expenseCategories = [];
  List<String> selectedExpenseCategories = [];
  
  List<String> incomeWallets = [];
  List<String> selectedIncomeWallets = [];
  
  String incomeGroupType = "Ví"; // Hoặc "Nhãn"
  bool isLoading = true;

  // State cho Phân tích nâng cao
  int summaryMonths = 3;
  
  int categoryMonths = 3;
  String? selectedAnalysisCategory;

  int walletMonths = 3;
  String? selectedAnalysisWallet;

  final List<Color> chartColors = [
    const Color(0xFFFBCA10), // Yellow
    const Color(0xFF5B420C), // Dark Brown
    const Color(0xFF2FB870), // Light Green
    const Color(0xFF00ACC1), // Cyan
    const Color(0xFFB148B9), // Purple
    const Color(0xFF2B2B2B), // Blackish
    const Color(0xFFD32F2F), // Red
    const Color(0xFFFF7043), // Orange
    const Color(0xFF3F51B5), // Indigo
    const Color(0xFF8BC34A), // Lime Green
  ];

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    String? userId = await SharedPreferenceHelper().getUserId();
    if (userId == null) return;
    try {
      // 1. Đọc danh sách ví để lấy các thẻ Ví theo dõi
      List<String> trackingWalletNames = [];
      String? walletJson = await SharedPreferenceHelper().getWallets();
      if (walletJson != null && walletJson.isNotEmpty) {
        List<dynamic> decoded = jsonDecode(walletJson);
        for (var w in decoded) {
          if (w is Map && w["type"] == "Tracking") {
            trackingWalletNames.add(w["name"] ?? "");
          }
        }
      }

      QuerySnapshot snapshot = await DatabaseMethdos().getTransactions(userId);
      List<Map<String, dynamic>> temp = [];
      Set<String> eCategories = {};
      Set<String> iWallets = {};

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        
        // Bỏ qua nếu giao dịch thuộc Ví theo dõi
        String wName = data["WalletName"] ?? "";
        if (trackingWalletNames.contains(wName)) continue;
        // Bỏ qua giao dịch chuyển tiền — không hiện trong analytics
        String txType = data["Type"] ?? "";
        if (txType == "chuyen_tien" || txType == "chuyen_tien_nhan") continue;
        data["id"] = doc.id;
        temp.add(data);

        String type = data["Type"] ?? "";
        if (type == "tien_ra") {
          String cat = (data["Category"] != null && data["Category"].toString().isNotEmpty) 
            ? data["Category"] 
            : (data["Label"] ?? "Không rõ");
          eCategories.add(cat);
        } else if (type == "tien_vao") {
          String wallet = data["WalletName"] ?? "Không rõ";
          iWallets.add(wallet);
        }
      }

      if (mounted) {
        setState(() {
          allTransactions = temp;
          expenseCategories = eCategories.toList();
          incomeWallets = iWallets.toList();
          
          if (selectedExpenseCategories.isEmpty) selectedExpenseCategories = List.from(expenseCategories);
          if (selectedIncomeWallets.isEmpty) selectedIncomeWallets = List.from(incomeWallets);

          if (expenseCategories.isNotEmpty && selectedAnalysisCategory == null) {
            selectedAnalysisCategory = expenseCategories.first;
          }
          if (incomeWallets.isNotEmpty && selectedAnalysisWallet == null) {
            selectedAnalysisWallet = incomeWallets.first;
          }
          
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _buildCurrencyText(double amount, double numSize) {
    final formatter = NumberFormat("#,###", "vi_VN");
    String val = amount == 0 ? "0" : formatter.format(amount);
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontFamily: 'Roboto', color: Colors.black87),
        children: [
          TextSpan(
            text: val, 
            style: TextStyle(fontSize: numSize, fontWeight: FontWeight.bold)
          ),
          TextSpan(
            text: "đ", 
            style: TextStyle(fontSize: numSize, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)
          ),
        ],
      ),
    );
  }

  List<MapEntry<String, double>> _getAggregatedData() {
    Map<String, double> aggregatedData = {};
    String dateFilter = DateFormat("MM-yyyy").format(selectedDate);

    for (var tx in allTransactions) {
      String txDate = tx["Date"] ?? ""; 
      if (!txDate.endsWith(dateFilter)) continue; 

      String type = tx["Type"] ?? "";
      double amount = double.tryParse(tx["Amount"]?.toString() ?? "0") ?? 0;

      if (isExpenseTab && type == "tien_ra") {
        String cat = (tx["Category"] != null && tx["Category"].toString().isNotEmpty) 
            ? tx["Category"] 
            : (tx["Label"] ?? "Không rõ");
        
        if (selectedExpenseCategories.contains(cat)) {
          aggregatedData[cat] = (aggregatedData[cat] ?? 0) + amount;
        }
      } else if (!isExpenseTab && type == "tien_vao") {
        String wallet = tx["WalletName"] ?? "Không rõ";
        
        if (selectedIncomeWallets.contains(wallet)) {
           String groupKey;
           if (incomeGroupType == "Ví") {
             groupKey = wallet;
           } else {
             groupKey = (tx["Category"] != null && tx["Category"].toString().isNotEmpty) 
                ? tx["Category"] 
                : (tx["Label"] ?? "Không có nhãn"); 
           }
           aggregatedData[groupKey] = (aggregatedData[groupKey] ?? 0) + amount;
        }
      }
    }

    var sorted = aggregatedData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); 
    return sorted;
  }

  // --- Sinh dữ liệu cho Chi tiêu so với thu nhập ---
  List<Map<String, dynamic>> _getSummaryData(int months) {
    List<Map<String, dynamic>> result = [];
    DateTime now = DateTime.now();

    for (int i = months - 1; i >= 0; i--) {
      DateTime monthTarget = DateTime(now.year, now.month - i);
      String monthStr = DateFormat("MM-yyyy").format(monthTarget);
      
      double totalInc = 0;
      double totalExp = 0;

      for (var tx in allTransactions) {
        String txDate = tx["Date"] ?? ""; 
        if (txDate.endsWith(monthStr)) {
           String type = tx["Type"] ?? "";
           double amount = double.tryParse(tx["Amount"]?.toString() ?? "0") ?? 0;
           if (type == "tien_vao") totalInc += amount;
           if (type == "tien_ra") totalExp += amount;
        }
      }

      result.add({
        "label": "T${monthTarget.month}",
        "income": totalInc,
        "expense": totalExp
      });
    }
    return result;
  }

  // --- Sinh dữ liệu cho Phân tích danh mục ---
  List<Map<String, dynamic>> _getCategoryData(int months, String categoryName) {
    List<Map<String, dynamic>> result = [];
    DateTime now = DateTime.now();

    for (int i = months - 1; i >= 0; i--) {
       DateTime monthTarget = DateTime(now.year, now.month - i);
       String monthStr = DateFormat("MM-yyyy").format(monthTarget);

       double totalCatExp = 0;
       for (var tx in allTransactions) {
         String txDate = tx["Date"] ?? ""; 
         if (txDate.endsWith(monthStr)) {
            String type = tx["Type"] ?? "";
            if (type == "tien_ra") {
               String cat = (tx["Category"] != null && tx["Category"].toString().isNotEmpty) 
                   ? tx["Category"] 
                   : (tx["Label"] ?? "Không rõ");
               if (cat == categoryName) {
                  double amount = double.tryParse(tx["Amount"]?.toString() ?? "0") ?? 0;
                  totalCatExp += amount;
               }
            }
         }
       }
       result.add({
         "label": "T${monthTarget.month}",
         "value": totalCatExp
       });
    }
    return result;
  }

  // --- Sinh dữ liệu cho Phân tích Ví (Wallet) ---
  List<Map<String, dynamic>> _getWalletData(int months, String walletName) {
    List<Map<String, dynamic>> result = [];
    DateTime now = DateTime.now();

    for (int i = months - 1; i >= 0; i--) {
       DateTime monthTarget = DateTime(now.year, now.month - i);
       String monthStr = DateFormat("MM-yyyy").format(monthTarget);

       double net = 0;
       for (var tx in allTransactions) {
         String wName = tx["WalletName"] ?? "Không rõ";
         if (wName == walletName) {
           String txDate = tx["Date"] ?? ""; 
           if (txDate.endsWith(monthStr)) {
              String type = tx["Type"] ?? "";
              double amount = double.tryParse(tx["Amount"]?.toString() ?? "0") ?? 0;
              if (type == "tien_vao") net += amount;
              if (type == "tien_ra") net -= amount; // Chi tiêu là số âm
           }
         }
       }
       result.add({
         "label": "T${monthTarget.month}",
         "value": net < 0 ? 0 : net // Tránh âm vì biểu đồ gốc show từ 0 trở lên
       });
    }
    return result;
  }

  // --- Modal chọn thời gian ---
  void _showTimePicker(int currentVal, Function(int) onSelected) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: Colors.white,
      builder: (ctx) {
         return Container(
           padding: const EdgeInsets.symmetric(vertical: 20),
           child: Column(
             mainAxisSize: MainAxisSize.min,
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text("Chọn khoảng thời gian", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
               ),
               ...[3, 6, 12].map((val) => ListTile(
                 title: Text("$val tháng gần đây", style: const TextStyle(fontSize: 16)),
                 trailing: currentVal == val ? const Icon(Icons.check, color: Colors.black87) : null,
                 tileColor: currentVal == val ? const Color(0xFFFFF9E6) : Colors.transparent, 
                 onTap: () {
                    onSelected(val);
                    Navigator.pop(ctx);
                 },
               )),
             ]
           )
         );
      }
    );
  }

  // --- Modal chọn Option chung ---
  void _showOptionPicker(String title, List<String> options, String? currentVal, Function(String) onSelected) {
      showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: Colors.white,
      builder: (ctx) {
         return Container(
           padding: const EdgeInsets.symmetric(vertical: 20),
           constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
           child: Column(
             mainAxisSize: MainAxisSize.min,
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
               ),
               Flexible(
                 child: SingleChildScrollView(
                   child: Column(
                     children: options.map((opt) => ListTile(
                       title: Text(opt, style: const TextStyle(fontSize: 16)),
                       trailing: currentVal == opt ? const Icon(Icons.check, color: Colors.black87) : null,
                       tileColor: currentVal == opt ? const Color(0xFFFFF9E6) : Colors.transparent, 
                       onTap: () {
                          onSelected(opt);
                          Navigator.pop(ctx);
                       },
                     )).toList()
                   )
                 )
               )
             ]
           )
         );
      }
    );
  }

  void _showFilterBottomSheet() {
    List<String> items = isExpenseTab ? expenseCategories : incomeWallets;
    List<String> tempSelected = List.from(isExpenseTab ? selectedExpenseCategories : selectedIncomeWallets);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: Colors.white,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Lọc ${isExpenseTab ? "Danh mục" : "Ví"}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: items.map((item) {
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item, style: const TextStyle(fontSize: 16)),
                            value: tempSelected.contains(item),
                            activeColor: const Color(0xFFFBCA10),
                            onChanged: (val) {
                              setSheetState(() {
                                if (val == true) {
                                  tempSelected.add(item);
                                } else {
                                  tempSelected.remove(item);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        if (isExpenseTab) {
                          selectedExpenseCategories = List.from(tempSelected);
                        } else {
                          selectedIncomeWallets = List.from(tempSelected);
                        }
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFBCA10),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text("Áp dụng", style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            );
          }
        );
      }
    );
  }

  void _showGroupByPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: Colors.white,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text("Nhóm theo", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                title: const Text("Ví", style: TextStyle(fontSize: 16)),
                trailing: incomeGroupType == "Ví" ? const Icon(Icons.check, color: Colors.black87) : null,
                tileColor: incomeGroupType == "Ví" ? const Color(0xFFFFF9E6) : Colors.transparent, 
                onTap: () {
                   setState(() => incomeGroupType = "Ví");
                   Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text("Nhãn", style: TextStyle(fontSize: 16)),
                trailing: incomeGroupType == "Nhãn" ? const Icon(Icons.check, color: Colors.black87) : null,
                tileColor: incomeGroupType == "Nhãn" ? const Color(0xFFFFF9E6) : Colors.transparent,
                onTap: () {
                   setState(() => incomeGroupType = "Nhãn");
                   Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      }
    );
  }

  List<PieChartSectionData> _getChartSections(List<MapEntry<String, double>> sortedData) {
    if (sortedData.isEmpty) return [];
    List<PieChartSectionData> sections = [];
    for (int i=0; i<sortedData.length; i++) {
       sections.add(PieChartSectionData(
         color: chartColors[i % chartColors.length],
         value: sortedData[i].value,
         title: "", 
         radius: 35, 
       ));
    }
    return sections;
  }

  // ============== CÁC WIDGET NÂNG CAO ================

  Widget _buildSummaryBarChart() {
     var data = _getSummaryData(summaryMonths);
     double maxVal = 0;
     for (var d in data) {
        if (d["income"] > maxVal) maxVal = d["income"];
        if (d["expense"] > maxVal) maxVal = d["expense"];
     }
     if (maxVal == 0) maxVal = 100000;
     
     double avgInc = data.fold(0.0, (sum, i) => sum + i["income"]) / summaryMonths;
     double avgExp = data.fold(0.0, (sum, i) => sum + i["expense"]) / summaryMonths;

     return Container(
       margin: const EdgeInsets.only(top: 30),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            const Padding(
              padding: EdgeInsets.only(left: 16.0, bottom: 16),
              child: Text("Chi tiêu so với thu nhập", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                   BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                ]
              ),
              child: Column(
                children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                        Expanded(
                          child: Wrap(
                             spacing: 12,
                             runSpacing: 4,
                             crossAxisAlignment: WrapCrossAlignment.center,
                             children: [
                                Row(
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                      Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFFFBCA10), shape: BoxShape.circle)),
                                      const SizedBox(width: 4),
                                      const Text("Chi tiêu", style: TextStyle(fontSize: 14)),
                                   ]
                                ),
                                Row(
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                      Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFF2FB870), shape: BoxShape.circle)),
                                      const SizedBox(width: 4),
                                      const Text("Thu nhập", style: TextStyle(fontSize: 14)),
                                   ]
                                ),
                             ]
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                           onTap: () => _showTimePicker(summaryMonths, (v) => setState(() => summaryMonths = v)),
                           child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                 border: Border.all(color: Colors.grey.shade300),
                                 borderRadius: BorderRadius.circular(8)
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text("$summaryMonths tháng gần đây", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_ios, size: 12)
                                ]
                              )
                           )
                        )
                     ],
                   ),
                   const SizedBox(height: 40),
                   SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                         height: 200,
                         width: data.length > 3 
                              ? (MediaQuery.of(context).size.width - 72) / 3 * data.length 
                              : MediaQuery.of(context).size.width - 72,
                         child: BarChart(
                            BarChartData(
                               alignment: BarChartAlignment.spaceAround,
                               maxY: maxVal * 1.2,
                               barTouchData: BarTouchData(enabled: false),
                               titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                     sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 32,
                                        getTitlesWidget: (value, meta) {
                                        if (value.toInt() >= 0 && value.toInt() < data.length) {
                                           return Padding(
                                             padding: const EdgeInsets.only(top: 8.0),
                                             child: Text(data[value.toInt()]["label"], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                           );
                                        }
                                        return const Text("");
                                     }
                                  )
                               ),
                               leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                     showTitles: true,
                                     reservedSize: 60,
                                     getTitlesWidget: (value, meta) {
                                        final formatter = NumberFormat("#,###", "vi_VN");
                                        if (value == 0) return const Text("0", style: TextStyle(fontSize: 11));
                                        if (value >= maxVal * 1.1) return const Text("");
                                        return Text(formatter.format(value), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold));
                                     }
                                  )
                               ),
                               topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                               rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: FlGridData(
                               show: true,
                               drawVerticalLine: false,
                               horizontalInterval: maxVal > 0 ? maxVal / 4 : 1,
                               getDrawingHorizontalLine: (val) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(data.length, (i) {
                               return BarChartGroupData(
                                  x: i,
                                  barRods: [
                                     BarChartRodData(toY: data[i]["expense"], color: const Color(0xFFFBCA10), width: 14, borderRadius: const BorderRadius.vertical(top: Radius.circular(2))),
                                     BarChartRodData(toY: data[i]["income"], color: const Color(0xFF2FB870), width: 14, borderRadius: const BorderRadius.vertical(top: Radius.circular(2))),
                                  ]
                               );
                            })
                         )
                      )
                   ),
                   ),
                   const SizedBox(height: 20),
                   const Divider(),
                   const SizedBox(height: 10),
                   Align(
                     alignment: Alignment.centerLeft,
                     child: Text("Trung bình $summaryMonths tháng gần đây", style: const TextStyle(fontSize: 14, color: Colors.black87)),
                   ),
                   const SizedBox(height: 12),
                   Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Row(children: [
                            Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFF2FB870), shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            const Text("Thu nhập", style: TextStyle(fontSize: 15)),
                         ]),
                         _buildCurrencyText(avgInc, 15)
                      ]
                   ),
                   const SizedBox(height: 8),
                   Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Row(children: [
                            Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFFFBCA10), shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            const Text("Chi tiêu", style: TextStyle(fontSize: 15)),
                         ]),
                         _buildCurrencyText(avgExp, 15)
                      ]
                   ),
                ]
              )
            )
         ]
       )
     );
  }

  Widget _buildCategoryAnalysisChart() {
     if (selectedAnalysisCategory == null) return const SizedBox();
     var data = _getCategoryData(categoryMonths, selectedAnalysisCategory!);
     double maxVal = 0;
     for (var d in data) {
        if (d["value"] > maxVal) maxVal = d["value"];
     }
     if (maxVal == 0) maxVal = 100000;

     double avgExp = data.fold(0.0, (sum, i) => sum + i["value"]) / categoryMonths;

     return Container(
       margin: const EdgeInsets.only(top: 30),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            const Padding(
              padding: EdgeInsets.only(left: 16.0, bottom: 16),
              child: Text("Phân tích danh mục", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                   BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                ]
              ),
              child: Column(
                children: [
                   Row(
                      children: [
                         Container(
                           padding: const EdgeInsets.all(8),
                           decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                           child: const Icon(Icons.category, color: Colors.green)
                         ),
                         const SizedBox(width: 12),
                         Expanded(
                           child: Text(selectedAnalysisCategory!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                         ),
                         GestureDetector(
                           onTap: () => _showOptionPicker("Chọn danh mục", expenseCategories, selectedAnalysisCategory, (val) => setState(() => selectedAnalysisCategory = val)),
                           child: const Icon(Icons.edit, color: Colors.black87)
                         )
                      ]
                   ),
                   const SizedBox(height: 20),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                        Expanded(
                          child: Wrap(
                             spacing: 8,
                             runSpacing: 4,
                             crossAxisAlignment: WrapCrossAlignment.center,
                             children: [
                                Row(
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                      Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFFBCA10), shape: BoxShape.circle)),
                                      const SizedBox(width: 8),
                                      const Text("Chi tiêu", style: TextStyle(fontSize: 14)),
                                   ]
                                ),
                             ]
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                           onTap: () => _showTimePicker(categoryMonths, (v) => setState(() => categoryMonths = v)),
                           child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                 border: Border.all(color: Colors.grey.shade300),
                                 borderRadius: BorderRadius.circular(8)
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text("$categoryMonths tháng gần đây", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_ios, size: 12)
                                ]
                              )
                           )
                        )
                     ],
                   ),
                   const SizedBox(height: 40),
                   SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                         height: 200,
                         width: data.length > 3 
                              ? (MediaQuery.of(context).size.width - 72) / 3 * data.length 
                              : MediaQuery.of(context).size.width - 72,
                         child: LineChart(
                            LineChartData(
                               minY: 0,
                               maxY: maxVal * 1.2,
                               titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                     sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 32,
                                        getTitlesWidget: (value, meta) {
                                        if (value.toInt() >= 0 && value.toInt() < data.length) {
                                           return Padding(
                                             padding: const EdgeInsets.only(top: 8.0),
                                             child: Text(data[value.toInt()]["label"], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                           );
                                        }
                                        return const Text("");
                                     }
                                  )
                               ),
                               leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                     showTitles: true,
                                     reservedSize: 60,
                                     getTitlesWidget: (value, meta) {
                                        final formatter = NumberFormat("#,###", "vi_VN");
                                        if (value == 0) return const Text("0", style: TextStyle(fontSize: 11));
                                        if (value >= maxVal * 1.1) return const Text("");
                                        return Text(formatter.format(value), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold));
                                     }
                                  )
                               ),
                               topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                               rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: FlGridData(
                               show: true,
                               drawVerticalLine: false,
                               horizontalInterval: maxVal > 0 ? maxVal / 4 : 1,
                               getDrawingHorizontalLine: (val) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                               LineChartBarData(
                                  spots: List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i]["value"])),
                                  isCurved: false,
                                  color: const Color(0xFFFBCA10),
                                  barWidth: 2,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: const Color(0xFFFBCA10), strokeWidth: 1, strokeColor: Colors.white)),
                                  belowBarData: BarAreaData(show: false),
                               )
                            ]
                         )
                      )
                   ),
                   ),
                  const SizedBox(height: 20),
                   const Divider(),
                   const SizedBox(height: 10),
                   Align(
                     alignment: Alignment.centerLeft,
                     child: Text("Trung bình $categoryMonths tháng gần đây", style: const TextStyle(fontSize: 14, color: Colors.black87)),
                   ),
                   const SizedBox(height: 12),
                   Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Row(children: [
                            Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFFFBCA10), shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(selectedAnalysisCategory!, style: const TextStyle(fontSize: 15)),
                         ]),
                         _buildCurrencyText(avgExp, 15)
                      ]
                   ),
                ]
              )
            )
         ]
       )
     );
  }

  Widget _buildWalletAnalysisChart() {
     if (selectedAnalysisWallet == null) return const SizedBox();
     var data = _getWalletData(walletMonths, selectedAnalysisWallet!);
     double maxVal = 0;
     for (var d in data) {
        if (d["value"] > maxVal) maxVal = d["value"];
     }
     if (maxVal == 0) maxVal = 100000;

     return Container(
       margin: const EdgeInsets.only(top: 30),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            const Padding(
              padding: EdgeInsets.only(left: 16.0, bottom: 16),
              child: Text("Số dư các ví", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                   BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                ]
              ),
              child: Column(
                children: [
                   Row(
                      children: [
                         Container(
                           padding: const EdgeInsets.all(8),
                           decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                           child: const Icon(Icons.account_balance_wallet, color: Colors.green)
                         ),
                         const SizedBox(width: 12),
                         Expanded(
                           child: Text(selectedAnalysisWallet!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                         ),
                         GestureDetector(
                           onTap: () => _showOptionPicker("Chọn ví", incomeWallets, selectedAnalysisWallet, (val) => setState(() => selectedAnalysisWallet = val)),
                           child: const Icon(Icons.edit, color: Colors.black87)
                         )
                      ]
                   ),
                   const SizedBox(height: 20),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                        Expanded(
                          child: Wrap(
                             spacing: 8,
                             runSpacing: 4,
                             crossAxisAlignment: WrapCrossAlignment.center,
                             children: [
                                Row(
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                      Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFFBCA10), shape: BoxShape.circle)),
                                      const SizedBox(width: 8),
                                      const Text("Tổng cộng", style: TextStyle(fontSize: 14)),
                                   ]
                                ),
                             ]
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                           onTap: () => _showTimePicker(walletMonths, (v) => setState(() => walletMonths = v)),
                           child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                 border: Border.all(color: Colors.grey.shade300),
                                 borderRadius: BorderRadius.circular(8)
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text("$walletMonths tháng gần đây", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_ios, size: 12)
                                ]
                              )
                           )
                        )
                     ],
                   ),
                   const SizedBox(height: 40),
                   SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                         height: 200,
                         width: data.length > 3 
                              ? (MediaQuery.of(context).size.width - 72) / 3 * data.length 
                              : MediaQuery.of(context).size.width - 72,
                         child: LineChart(
                            LineChartData(
                               minY: 0,
                               maxY: maxVal * 1.2,
                               titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                     sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 32,
                                        getTitlesWidget: (value, meta) {
                                        if (value.toInt() >= 0 && value.toInt() < data.length) {
                                           return Padding(
                                             padding: const EdgeInsets.only(top: 8.0),
                                             child: Text(data[value.toInt()]["label"], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                           );
                                        }
                                        return const Text("");
                                     }
                                  )
                               ),
                               leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                     showTitles: true,
                                     reservedSize: 60,
                                     getTitlesWidget: (value, meta) {
                                        final formatter = NumberFormat("#,###", "vi_VN");
                                        if (value == 0) return const Text("0", style: TextStyle(fontSize: 11));
                                        if (value >= maxVal * 1.1) return const Text("");
                                        return Text(formatter.format(value), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold));
                                     }
                                  )
                               ),
                               topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                               rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: FlGridData(
                               show: true,
                               drawVerticalLine: false,
                               horizontalInterval: maxVal > 0 ? maxVal / 4 : 1,
                               getDrawingHorizontalLine: (val) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                               LineChartBarData(
                                  spots: List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i]["value"])),
                                  isCurved: false,
                                  color: const Color(0xFFFBCA10),
                                  barWidth: 2,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: const Color(0xFFFBCA10), strokeWidth: 1, strokeColor: Colors.white)),
                                  belowBarData: BarAreaData(show: false),
                               )
                            ]
                         )
                      )
                   ),
                   ),
                       ]
              )
            )
         ]
       )
     );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(backgroundColor: Color(0xFFFAF9F6), body: Center(child: CircularProgressIndicator(color: Color(0xFFFBCA10))));
    }

    var sortedData = _getAggregatedData();
    double totalAmount = sortedData.fold(0.0, (sum, item) => sum + item.value);
    int badgeCount = isExpenseTab ? selectedExpenseCategories.length : selectedIncomeWallets.length;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6), // Warm cream background
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFFFAF9F6),
            floating: false,
            pinned: true,
            expandedHeight: 120.0,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text("Tổng quan", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 18)),
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              background: SafeArea(
                child: Container(
                  padding: const EdgeInsets.only(left: 20, top: 10),
                  alignment: Alignment.topLeft,
                  child: const Text("Phân tích", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                     BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                  ]
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                     // 1. Tab Toggle + Filter
                     Row(
                       children: [
                         Expanded(
                           child: Container(
                             padding: const EdgeInsets.all(4),
                             decoration: BoxDecoration(
                                color: const Color(0xFFFAF9F6),
                                borderRadius: BorderRadius.circular(30),
                             ),
                             child: Row(
                               children: [
                                 Expanded(
                                   child: GestureDetector(
                                     onTap: () => setState(() => isExpenseTab = true),
                                     child: Container(
                                       padding: const EdgeInsets.symmetric(vertical: 10),
                                       decoration: BoxDecoration(
                                         color: isExpenseTab ? const Color(0xFFFBCA10) : Colors.transparent,
                                         borderRadius: BorderRadius.circular(30)
                                       ),
                                       alignment: Alignment.center,
                                       child: Text("Chi tiêu", style: TextStyle(fontWeight: isExpenseTab ? FontWeight.bold : FontWeight.w500, color: isExpenseTab ? Colors.black87 : Colors.black54)),
                                     )
                                   )
                                 ),
                                 Expanded(
                                   child: GestureDetector(
                                     onTap: () => setState(() => isExpenseTab = false),
                                     child: Container(
                                       padding: const EdgeInsets.symmetric(vertical: 10),
                                       decoration: BoxDecoration(
                                         color: !isExpenseTab ? const Color(0xFFFBCA10) : Colors.transparent,
                                         borderRadius: BorderRadius.circular(30)
                                       ),
                                       alignment: Alignment.center,
                                       child: Text("Thu nhập", style: TextStyle(fontWeight: !isExpenseTab ? FontWeight.bold : FontWeight.w500, color: !isExpenseTab ? Colors.black87 : Colors.black54)),
                                     )
                                   )
                                 ),
                               ]
                             )
                           )
                         ),
                         const SizedBox(width: 16),
                         GestureDetector(
                           onTap: _showFilterBottomSheet,
                           child: Stack(
                             clipBehavior: Clip.none,
                             children: [
                               const Icon(Icons.filter_list, size: 28, color: Colors.black87),
                               if (badgeCount > 0)
                                 Positioned(
                                   right: -4, top: -4,
                                   child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(color: Color(0xFFFBCA10), shape: BoxShape.circle),
                                      alignment: Alignment.center,
                                      child: Text("$badgeCount", style: const TextStyle(fontSize: 10, color: Colors.black87, fontWeight: FontWeight.bold)),
                                   )
                                 )
                             ]
                           )
                         )
                       ]
                     ),
                     const SizedBox(height: 24),

                     // 2. Month Selector
                     Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         GestureDetector(
                           onTap: () => setState(() => selectedDate = DateTime(selectedDate.year, selectedDate.month - 1)),
                           child: const Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.arrow_left, color: Colors.grey)),
                         ),
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                           decoration: BoxDecoration(
                             color: Colors.white,
                             border: Border.all(color: Colors.grey.shade300),
                             borderRadius: BorderRadius.circular(12),
                           ),
                           child: Row(
                             children: [
                                Text("Tháng ${selectedDate.month} ${selectedDate.year}", style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.black54)
                             ]
                           )
                         ),
                         GestureDetector(
                           onTap: () => setState(() => selectedDate = DateTime(selectedDate.year, selectedDate.month + 1)),
                           child: const Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.arrow_right, color: Colors.grey)),
                         ),
                       ]
                     ),
                     const SizedBox(height: 20),

                     // 3. Group By (Income Only)
                     if (!isExpenseTab)
                       Padding(
                         padding: const EdgeInsets.only(bottom: 20.0),
                         child: Row(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                              const Text("Sắp xếp theo  ", style: TextStyle(color: Colors.black87, fontSize: 14)),
                              GestureDetector(
                                onTap: _showGroupByPicker,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                     border: Border.all(color: Colors.grey.shade300),
                                     borderRadius: BorderRadius.circular(8)
                                  ),
                                  child: Row(
                                    children: [
                                      Text(incomeGroupType, style: const TextStyle(fontWeight: FontWeight.w500)),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.keyboard_arrow_down, size: 16)
                                    ]
                                  )
                                )
                              )
                           ]
                         ),
                       ),

                     // 4. Chart & List or Empty State
                     if (totalAmount == 0)
                       Container(
                         height: 240,
                         alignment: Alignment.center,
                         child: Text(
                           isExpenseTab ? "Bạn không có bất kì chi phí nào trong tháng này." : "Bạn không có thu nhập nào trong tháng này.",
                           style: const TextStyle(color: Colors.grey, fontSize: 15),
                           textAlign: TextAlign.center,
                         )
                       )
                     else ...[
                       // Chart
                       SizedBox(
                         height: 240,
                         child: Stack(
                           alignment: Alignment.center,
                           children: [
                              PieChart(
                                 PieChartData(
                                    sectionsSpace: 0,
                                    centerSpaceRadius: 85,
                                    sections: _getChartSections(sortedData),
                                 )
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(isExpenseTab ? "Tổng chi tiêu" : "Tổng thu", style: const TextStyle(color: Colors.black87, fontSize: 15)),
                                  const SizedBox(height: 4),
                                  _buildCurrencyText(totalAmount, 22),
                                ]
                              )
                           ]
                         )
                       ),
                       const SizedBox(height: 20),

                       // List
                       ListView.builder(
                         shrinkWrap: true,
                         physics: const NeverScrollableScrollPhysics(),
                         itemCount: sortedData.length,
                         itemBuilder: (ctx, index) {
                             String name = sortedData[index].key;
                             double amount = sortedData[index].value;
                             double pct = (amount / totalAmount) * 100;
                             Color color = chartColors[index % chartColors.length];

                             return Padding(
                               padding: const EdgeInsets.symmetric(vertical: 12),
                               child: Row(
                                 crossAxisAlignment: CrossAxisAlignment.center,
                                 children: [
                                    Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                         Container(
                                           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                           decoration: BoxDecoration(color: const Color(0xFF135A42), borderRadius: BorderRadius.circular(4)), 
                                           child: Text("${pct.toStringAsFixed(1)}%", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))
                                         ),
                                         const SizedBox(height: 6),
                                         _buildCurrencyText(amount, 16),
                                      ]
                                    )
                                 ]
                               )
                             );
                         }
                       ),
                     ]
                  ]
                )
              )
            ),
          ),
          
          // ---- PHẦN NÂNG CAO (ADVANCED ANALYTICS) ----
          SliverToBoxAdapter(child: _buildSummaryBarChart()),
          SliverToBoxAdapter(child: _buildCategoryAnalysisChart()),
          SliverToBoxAdapter(child: _buildWalletAnalysisChart()),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ]
      )
    );
  }
}