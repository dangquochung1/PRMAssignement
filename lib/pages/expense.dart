import 'package:prmproject/services/shared_pref.dart';
import 'package:prmproject/services/support_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prmproject/services/database.dart';

class Expense extends StatefulWidget {
  const Expense({super.key});

  @override
  State<Expense> createState() => _ExpenseState();
}

class _ExpenseState extends State<Expense> {
  String? Id;
  List<String> dynamicCategories = [];
  String? value;

  getthssahredpref() async {
    Id = await SharedPreferenceHelper().getUserId();

    // Load danh sách Category
    List<String>? savedCats = await SharedPreferenceHelper().getUserCategories();
    if (savedCats == null || savedCats.isEmpty) {
      // Nếu chưa có, tạo mặc định
      dynamicCategories = ['Shopping', 'Grocery', 'Others'];
      await SharedPreferenceHelper().saveUserCategories(dynamicCategories);
    } else {
      dynamicCategories = savedCats;
    }

    if (dynamicCategories.isNotEmpty) {
      value = dynamicCategories[0]; // Set giá trị mặc định cho dropdown
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    getthssahredpref();
  }

  DateTime selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  String get formattedDate {
    return DateFormat('dd-MM-yyyy').format(selectedDate);
  }

  TextEditingController amountcontroller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView( // FIX LỖI OVERFLOW KHI BẬT BÀN PHÍM
        child: Container(
          margin: const EdgeInsets.only(top: 50.0, bottom: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Material(
                        elevation: 3.0,
                        borderRadius: BorderRadius.circular(60),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xffee6856),
                            borderRadius: BorderRadius.circular(60),
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 30.0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 70.0),
                    Text("Add Expense", style: AppWidget.healineTextStyle(24.0))
                  ],
                ),
              ),
              const SizedBox(height: 30.0),
              Center(
                child: Image.asset("images/expense.png", height: 200, width: 200, fit: BoxFit.cover),
              ),
              const SizedBox(height: 24.0),

              // AMOUNT
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Text("Enter Amount", style: AppWidget.healineTextStyle(20.0)),
              ),
              const SizedBox(height: 10.0),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20.0),
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFececf8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: amountcontroller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Amount",
                    hintStyle: TextStyle(color: Colors.black54, fontSize: 18.0, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 24.0),

              // CATEGORY DROPDOWN
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Text("Select Category", style: AppWidget.healineTextStyle(20.0)),
              ),
              const SizedBox(height: 10.0),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20.0),
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: const Color(0xFFececf8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    items: dynamicCategories.map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(item, style: const TextStyle(fontSize: 18.0, color: Colors.black)),
                    )).toList(),
                    onChanged: ((val) => setState(() {
                      value = val;
                    })),
                    dropdownColor: Colors.white,
                    hint: const Text("Select Category"),
                    iconSize: 36,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                    value: value,
                  ),
                ),
              ),
              const SizedBox(height: 30.0),

              // DATE PICKER
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Material(
                        elevation: 1.0,
                        borderRadius: BorderRadius.circular(60),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xffee6856),
                            borderRadius: BorderRadius.circular(60),
                          ),
                          child: const Icon(Icons.calendar_today, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Text(formattedDate, style: AppWidget.healineTextStyle(22.0)),
                  ],
                ),
              ),
              const SizedBox(height: 40.0),

              // HÀNG 2 NÚT: Lưu & tiếp tục / Lưu & đóng
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    // LƯU & TIẾP TỤC: thêm giao dịch, giữ nguyên màn hình
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          if (amountcontroller.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                backgroundColor: Colors.red,
                                content: Text("Vui lòng nhập Amount")));
                            return;
                          }

                          Map<String, dynamic> addExpense = {
                            "Amount": amountcontroller.text,
                            "Category": value,
                            "Date": formattedDate,
                          };

                          if (Id == null) return;

                          await DatabaseMethdos().addUserExpense(addExpense, Id!);
                          setState(() {
                            amountcontroller.clear();
                          });
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            backgroundColor: Colors.green,
                            content: Text("Đã lưu, tiếp tục nhập khoản chi tiếp theo"),
                          ));
                        },
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade400,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              "Lưu & tiếp tục",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // LƯU & ĐÓNG: thêm giao dịch rồi thoát màn hình
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          if (amountcontroller.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                backgroundColor: Colors.red,
                                content: Text("Vui lòng nhập Amount")));
                            return;
                          }

                          Map<String, dynamic> addExpense = {
                            "Amount": amountcontroller.text,
                            "Category": value,
                            "Date": formattedDate,
                          };

                          if (Id == null) return;

                          await DatabaseMethdos().addUserExpense(addExpense, Id!);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            backgroundColor: Colors.green,
                            content: Text("Đã lưu khoản chi"),
                          ));
                          Navigator.pop(context);
                        },
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xff4CAF50),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              "Lưu & đóng",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}