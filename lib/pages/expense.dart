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

  getthssahredpref() async {
    Id = await SharedPreferenceHelper().getUserId();
    setState(() {

    });

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
      initialDate: DateTime.now(), // Always show today initially
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

  String? value;
  final List<String> quizitems = [
    'Shopping',
    'Grocery',
    'Others',
  ];
  TextEditingController amountcontroller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.only(top: 50.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Back Button & Title
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
                          borderRadius: BorderRadius.circular(60), // Đã fix dòng bị cụt
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 30.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 70.0),
                  Text(
                    "Add Expense",
                    style: AppWidget.healineTextStyle(24.0),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30.0),

            // 2. Image
            Center(
              child: Image.asset(
                "images/expense.png",
                height: 200,
                width: 200,
                fit: BoxFit.cover, // Đã fix chữ 'f' bị cụt
              ),
            ),
            const SizedBox(height: 24.0),

            // 3. Amount Input
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Text(
                "Enter Amount",
                style: AppWidget.healineTextStyle(20.0),
              ),
            ),
            const SizedBox(height: 10.0),
            Container(
              margin: const EdgeInsets.only(left: 20.0, right: 20.0),
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: const Color(0xFFececf8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: amountcontroller,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Amount",
                  hintStyle: TextStyle(
                    color: Colors.black,
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24.0),

            // 4. Category Dropdown
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Text(
                "Select Category",
                style: AppWidget.healineTextStyle(20.0),
              ),
            ),
            const SizedBox(height: 10.0),
            Container(
              margin: const EdgeInsets.only(left: 20.0, right: 20.0),
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: const Color(0xFFececf8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  items: quizitems
                      .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(
                      item,
                      style: const TextStyle(
                          fontSize: 18.0, color: Colors.black),
                    ),
                  ))
                      .toList(),
                  onChanged: ((value) => setState(() {
                    this.value = value;
                  })),
                  dropdownColor: Colors.white,
                  hint: const Text("Select Category"),
                  iconSize: 36,
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.black,
                  ),
                  value: value,
                ),
              ),
            ),
            const SizedBox(height: 30.0),

            // 5. Date Picker
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      _selectDate(context);
                    },
                    child: Material(
                      elevation: 1.0,
                      borderRadius: BorderRadius.circular(60),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xffee6856), // Đã fix lỗi màu
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: const Icon(
                          Icons.calendar_today,
                          color: Colors.white, // Đã fix lỗi chữ Color bị cụt
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    '$formattedDate',
                    style: AppWidget.healineTextStyle(22.0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60.0),

            // 6. Submit Button

            GestureDetector(
              onTap:() async {
                Map<String, dynamic> addExpense = {
                  "Amount": amountcontroller.text,
                  "Category": value,
                  "Date":  '$formattedDate',
                };

                // hàm mới
                if (Id == null) {
                  // Có thể hiện SnackBar báo lỗi "Đang tải dữ liệu người dùng, vui lòng thử lại"
                  return;
                }
                await DatabaseMethdos().addUserExpense(addExpense, Id!);
                setState(() {
                  amountcontroller.text="";
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor: Colors.green,
                    content: Text(
                      "Expense added successfully",
                      style: TextStyle(fontSize: 20.0),
                    )));
              },
              child: Center(
                child: Container(
                  height: 50,
                  width: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xffee6856),
                    borderRadius: BorderRadius.circular(10), // Đã fix chữ 'ci' bị cụt
                  ),
                  child: const Center(
                    child: Text(
                      "Submit",
                      style: TextStyle(
                        color: Colors.white, // Đã fix lỗi TextStyle
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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