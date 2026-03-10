import 'package:flutter/material.dart';
import 'package:prmproject/pages/expense.dart';
import 'package:prmproject/pages/income.dart';
import 'package:prmproject/services/shared_pref.dart';
class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String? name;
  String? email;

  getSharedPref() async {
    name = await SharedPreferenceHelper().getUserName();
    email = await SharedPreferenceHelper().getUserEmail();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    getSharedPref();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView( // Thêm ScrollView để tránh lỗi tràn màn hình (overflow) trên máy nhỏ
        child: Container(
          padding: const EdgeInsets.only(top: 50.0), // Padding đẩy nội dung xuống dưới Status Bar
          child: Column(
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
                            color: const Color(0xFFEE6856), // Khôi phục mã màu nút back
                            borderRadius: BorderRadius.circular(60),
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 30.0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 110.0),
                    const Text(
                      "Profile",
                      // Thay AppWidget.healineTextStyle bằng TextStyle cơ bản để code có thể chạy ngay
                      style: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),
              ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: Image.asset(
                  "images/boy1.jpg",
                  height: 150,
                  width: 150,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 50.0),

              // Vùng hiển thị Tên
              Container(
                padding: const EdgeInsets.only(left: 20.0),
                height: 70,
                margin: const EdgeInsets.only(left: 20.0, right: 20.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(227, 238, 104, 86),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.white, size: 40.0),
                    const SizedBox(width: 20.0),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Name", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                        Text(name ?? "Name", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30.0),

              // Vùng hiển thị Email
              Container(
                padding: const EdgeInsets.only(left: 20.0),
                height: 70,
                margin: const EdgeInsets.only(left: 20.0, right: 20.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(227, 238, 104, 86),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email, color: Colors.white, size: 40.0),
                    const SizedBox(width: 20.0),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Email", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                        Text(email ?? "Email", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30.0),

              // Nút Add Expense
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const Expense()));
                },
                child: Container(
                  padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                  height: 70,
                  margin: const EdgeInsets.only(left: 20.0, right: 20.0),
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(227, 238, 104, 86),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.credit_card, color: Colors.white, size: 40.0),
                      SizedBox(width: 20.0),
                      Text("Add Expense", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                      Spacer(),
                      Icon(Icons.arrow_forward_ios, color: Colors.white),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30.0),

              // Nút Add Income (Đã sửa ở dòng 114)
              GestureDetector(
                onTap: () {
                  // Đã sửa thành Income() theo yêu cầu của bạn
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const Income()));
                },
                child: Container(
                  padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                  height: 70,
                  margin: const EdgeInsets.only(left: 20.0, right: 20.0),
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(227, 238, 104, 86),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.attach_money, color: Colors.white, size: 40.0),
                      SizedBox(width: 20.0),
                      Text("Add Income", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                      Spacer(),
                      Icon(Icons.arrow_forward_ios, color: Colors.white),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30.0),

              // Nút LogOut
              GestureDetector(
                onTap: () {
                  // Code xử lý đăng xuất ở đây
                },
                child: Container(
                  padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                  height: 70,
                  margin: const EdgeInsets.only(left: 20.0, right: 20.0),
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(227, 238, 104, 86),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.logout, color: Colors.white, size: 40.0),
                      SizedBox(width: 20.0),
                      Text("LogOut", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                      Spacer(),
                      Icon(Icons.arrow_forward_ios, color: Colors.white),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30.0),

              // Nút Delete Account
              GestureDetector(
                onTap: () {
                  // Code xử lý xóa tài khoản ở đây
                },
                child: Container(
                  padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                  height: 70,
                  margin: const EdgeInsets.only(left: 20.0, right: 20.0),
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(227, 238, 104, 86),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.delete, color: Colors.white, size: 40.0),
                      SizedBox(width: 20.0),
                      Text("Delete Account", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                      Spacer(),
                      Icon(Icons.arrow_forward_ios, color: Colors.white),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40.0), // Padding dưới cùng để kết thúc giao diện
            ],
          ),
        ),
      ),
    );
  }
}