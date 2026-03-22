import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prmproject/utils/validator.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  String email = "";
  TextEditingController mailcontroller = TextEditingController();

  final _formkey = GlobalKey<FormState>();

  resetPassword() async {
    String? emailError = AppValidator.validateEmail(mailcontroller.text);
    if (emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(emailError)));
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: mailcontroller.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Email khôi phục mật khẩu đã được gửi!", style: TextStyle(fontSize: 18.0))));
      Navigator.pop(context); // Quay lại trang Login
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == "user-not-found") {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Không tìm thấy tài khoản với email này.", style: TextStyle(fontSize: 18.0))));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.message ?? "Đã xảy ra lỗi, vui lòng thử lại sau", style: const TextStyle(fontSize: 18.0))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        title: const Text("Quên Mật Khẩu"),
        backgroundColor: const Color(0xFFD4A843),
      ),
      body: Container(
        child: Column(
          children: [
            const SizedBox(height: 70.0),
            Container(
              alignment: Alignment.topCenter,
              child: const Text(
                "Khôi Phục Mật Khẩu",
                style: TextStyle(
                    color: Color(0xff904c6e),
                    fontSize: 30.0,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10.0),
            const Text(
              "Nhập email của bạn",
              style: TextStyle(
                  color: Color(0xff904c6e),
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold),
            ),
            Expanded(
                child: Form(
                    key: _formkey,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                      child: ListView(
                        children: [
                          Container(
                            padding: const EdgeInsets.only(left: 10.0),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white70, width: 2.0),
                              borderRadius: BorderRadius.circular(30),
                              color: Colors.white,
                            ),
                            child: TextFormField(
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập Email';
                                }
                                return null;
                              },
                              controller: mailcontroller,
                              style: const TextStyle(color: Colors.black),
                              decoration: const InputDecoration(
                                  hintText: "Email",
                                  hintStyle:
                                  TextStyle(fontSize: 18.0, color: Colors.black26),
                                  prefixIcon: Icon(
                                    Icons.person,
                                    color: Colors.black45,
                                    size: 30.0,
                                  ),
                                  border: InputBorder.none),
                            ),
                          ),
                          const SizedBox(
                            height: 40.0,
                          ),
                          GestureDetector(
                            onTap: () {
                              if (_formkey.currentState!.validate()) {
                                setState(() {
                                  email = mailcontroller.text;
                                });
                                resetPassword();
                              }
                            },
                            child: Container(
                              width: 140,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: const Color(0xff904c6e),
                                  borderRadius: BorderRadius.circular(10)),
                              child: const Center(
                                child: Text(
                                  "Gửi Email Khôi Phục",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 50.0,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Chưa có tài khoản?",
                                style: TextStyle(
                                    fontSize: 18.0, color: Colors.black54),
                              ),
                              const SizedBox(
                                width: 5.0,
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context); // You can navigate to signup if you want
                                },
                                child: const Text(
                                  "Tạo tài khoản",
                                  style: TextStyle(
                                      color: Color(0xff904c6e),
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.w500),
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ))),
          ],
        ),
      ),
    );
  }
}
