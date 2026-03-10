import 'package:flutter/material.dart';
import 'package:prmproject/services/support_widget.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:prmproject/pages/profile.dart';
import 'package:prmproject/services/shared_pref.dart';
class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String? name;

  getSharedPref() async {
    name = await SharedPreferenceHelper().getUserName();
    setState(() {}); // Gọi setState để giao diện update lại khi có data
  }

  @override
  void initState() {
    super.initState();
    getSharedPref();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            // Giảm top margin xuống vì SafeArea đã tự đẩy xuống rồi
            margin: const EdgeInsets.only(top: 10.0, left: 20.0, right: 20.0, bottom: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- PHẦN HEADER ----
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Welcome Back",
                          style: TextStyle(
                              color: Color.fromARGB(149, 0, 0, 0),
                              fontSize: 16.0,
                              fontWeight: FontWeight.w500),
                        ),
                        Text(
                            name ?? "Guest",
                          style: AppWidget.healineTextStyle(20.0),
                        )
                      ],
                    ),
                    GestureDetector(
                      onTap: (){
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const Profile()));
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(60),
                        child: Image.asset("images/boy1.jpg",
                            height: 70, width: 67, fit: BoxFit.cover),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 30.0),

                // ---- TIÊU ĐỀ ----
                Text("Manage your\nexpenses",
                    style: AppWidget.healineTextStyle(30)),
                const SizedBox(height: 20.0),

                // ---- THẺ CHI TIẾT EXPENSES ----
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: const Color.fromARGB(48, 0, 0, 0), width: 2.0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Expenses", style: AppWidget.healineTextStyle(20.0)),
                          const Text("\$300",
                              style: TextStyle(
                                  color: Color(0xffee6856),
                                  fontSize: 25.0,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 5.0),
                      const Text(
                        "1 Sep 2025 - 30 Sep 2025",
                        style: TextStyle(
                            color: Color.fromARGB(149, 0, 0, 0),
                            fontSize: 15.0,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 30.0),

                      // ---- BIỂU ĐỒ VÀ CHÚ THÍCH ----
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Biểu đồ Donut Chart sử dụng fl_chart
                          SizedBox(
                            height: 120,
                            width: 120,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 35,
                                sections: [
                                  PieChartSectionData(
                                    color: const Color(0xffee6856), // Đỏ (Shopping)
                                    value: 50,
                                    title: '50%',
                                    radius: 25,
                                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  PieChartSectionData(
                                    color: Colors.green.shade400, // Xanh lá nhạt (Grocery)
                                    value: 30,
                                    title: '30%',
                                    radius: 25,
                                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  PieChartSectionData(
                                    color: Colors.teal, // Xanh đậm (Others)
                                    value: 20,
                                    title: '20%',
                                    radius: 25,
                                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Cột Chú thích (Legend)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLegendItem(const Color(0xffee6856), "Shopping", 500),
                              const SizedBox(height: 15),
                              _buildLegendItem(Colors.green.shade400, "Grocery", 300),
                              const SizedBox(height: 15),
                              _buildLegendItem(Colors.teal, "Others", 200),
                            ],
                          )
                        ],
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 30.0),

                // ---- NÚT CHỌN THỜI GIAN ----
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTimeButton("This Month", false),
                    _buildTimeButton("This Year", true),
                  ],
                ),

                const SizedBox(height: 30.0),

                // ---- THẺ INCOME VÀ EXPENSES BÊN DƯỚI ----
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                          "Income", "+\$5000", Colors.green),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildSummaryCard(
                          "Expenses", "+\$5000", const Color(0xffee6856)),
                    ),
                  ],
                ),

                const SizedBox(height: 30.0),

                // ---- THẺ THÔNG BÁO LIKE ----
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                  decoration: BoxDecoration(
                    color: const Color(0xffffa08c), // Màu cam sữa nhẹ giống hình
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          "images/like.png",
                          height: 30,
                          width: 30,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 20.0),
                      // ĐÃ BỌC EXPANDED Ở ĐÂY ĐỂ FIX LỖI TRAN VIỀN
                      const Expanded(
                        child: Text(
                          "Your expense plan looks good",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- CÁC HÀM HỖ TRỢ (WIDGET BUILDERS) ----

  Widget _buildLegendItem(Color color, String text, double value) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              "\$${value.toInt()}",
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
            )
          ],
        )
      ],
    );
  }

  Widget _buildTimeButton(String title, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xffee6856) : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isSelected ? Colors.transparent : Colors.grey.shade400,
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            amount,
            style: TextStyle(
                color: color, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            height: 5,
            width: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(5),
            ),
          )
        ],
      ),
    );
  }
}