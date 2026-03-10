import 'package:prmproject/services/database.dart';
import 'package:prmproject/services/support_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prmproject/services/shared_pref.dart';
class Income extends StatefulWidget {
  const Income({super.key});

  @override
  State<Income> createState() => _IncomeState();
}

class _IncomeState extends State<Income> {
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

  TextEditingController amountcontroller = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: EdgeInsets.only(top: 50.0),
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
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xffee6856),
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 30.0,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 70.0),
                  Text(
                    "Add Income",
                    style: AppWidget.healineTextStyle(24.0), // Lưu ý: hàm này có thể là 'headlineTextStyle' nếu bạn có gõ sai chính tả trong class AppWidget
                  ),
                ],
              ),
            ),
            SizedBox(height: 30.0),
            Center(
              child: Image.asset(
                "images/income.png",
                height: 200,
                width: 200,
                fit: BoxFit.cover, // Dự đoán phần bị che khuất
              ),
            ),
            SizedBox(height: 24.0),
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Text(
                "Enter Amount",
                style: AppWidget.healineTextStyle(20.0),
              ),
            ),
            SizedBox(height: 10.0),
            Container(
              margin: EdgeInsets.only(left: 20.0, right: 20.0),
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: Color(0xFFececf8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: amountcontroller,
                decoration: InputDecoration(
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
            SizedBox(height: 30.0),
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
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xffee6856),
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          color: Colors.white, // Dự đoán dựa trên ô vuông màu trắng báo mã màu
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  Text(
                    '$formattedDate',
                    style: AppWidget.healineTextStyle(22.0),
                  ),
                ],
              ),
            ),
            SizedBox(height: 60.0),
            GestureDetector(
              onTap: ()async{
                Map<String, dynamic> addIncome = {
                  "Amount": amountcontroller.text,
                  "Date":  '$formattedDate',
                };
                // hàm mới
                if (Id == null) {
                  // Có thể hiện SnackBar báo lỗi "Đang tải dữ liệu người dùng, vui lòng thử lại"
                  return;
                }
                await DatabaseMethdos().addUserIncome(addIncome, Id!);
                setState(() {
                  amountcontroller.text="";
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor: Colors.green,
                    content: Text(
                      "Income added successfully",
                      style: TextStyle(fontSize: 20.0),
                    )));
              },
              child: Center(
                child: Container(
                  height: 50,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Color(0xffee6856),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      "Submit",
                      style: TextStyle(
                        color: Colors.white, // Dự đoán phần bị che khuất
                        fontSize: 20.0,
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