import 'package:prmproject/pages/main_shell.dart';
import 'package:prmproject/pages/login.dart';
import 'package:prmproject/services/database.dart';
import 'package:prmproject/services/shared_pref.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:random_string/random_string.dart';
import 'package:prmproject/utils/validator.dart'; // Import file validate mới tạo

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  String email = "", password = "", name = "";
  TextEditingController namecontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  TextEditingController mailcontroller = TextEditingController();
  TextEditingController confirmpasswordcontroller = TextEditingController();

  bool isLoading = false; // Biến trạng thái để xoay vòng vòng

  registration() async {
    // 1. Kiểm tra Validate trước khi chạy
    String? emailError = AppValidator.validateEmail(mailcontroller.text);
    String? passwordError = AppValidator.validatePassword(passwordcontroller.text);

    if (namecontroller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập tên!")));
      return;
    }
    if (emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(emailError)));
      return;
    }
    if (passwordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(passwordError)));
      return;
    }

    if (passwordcontroller.text != confirmpasswordcontroller.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mật khẩu xác nhận không khớp!")));
      return;
    }

    // 2. Bắt đầu xử lý, khóa nút bấm
    setState(() {
      isLoading = true;
      email = mailcontroller.text;
      password = passwordcontroller.text;
      name = namecontroller.text;
    });

    try {
      // Gọi Firebase Auth (nếu email trùng nó sẽ tự bắn lỗi e.code == 'email-already-in-use')
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      String id = randomAlphaNumeric(10);
      Map<String, dynamic> userInfoMap = {
        "Name": name,
        "Email": email,
        "Id": id,
      };

      await DatabaseMethdos().addUserInfo(userInfoMap, id);
      await SharedPreferenceHelper().saveUserId(id);
      await SharedPreferenceHelper().saveUserName(name);
      await SharedPreferenceHelper().saveUserEmail(email);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Đăng ký thành công", style: TextStyle(fontSize: 20.0))));

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const MainShell()));

    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.orangeAccent,
            content: Text("Mật khẩu quá yếu", style: TextStyle(fontSize: 18.0))));
      } else if (e.code == "email-already-in-use") {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.orangeAccent,
            content: Text("Tài khoản (Email) này đã tồn tại", style: TextStyle(fontSize: 18.0))));
      }
    } finally {
      // Mở khóa nút bấm khi xong (dù lỗi hay không)
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Gốc ngoài cùng là hình nền
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: ResizeImage(
            AssetImage("images/signup.png"),
            width: 1080, // giới hạn resolution
          ),
          fit: BoxFit.cover,
        ),
      ),
      // 2. Scaffold đè lên trên và trong suốt
      child: Scaffold(
        backgroundColor: Colors.transparent, // Nhờ dòng này mới thấy được ảnh nền
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(left: 20.0, top: 50.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Create\nAccount!",
                    style: TextStyle(color: Colors.white, fontSize: 30.0, fontWeight: FontWeight.bold)),
                const SizedBox(height: 100.0),
                const Text("Name", style: TextStyle(color: Colors.white, fontSize: 20.0)),
                const SizedBox(height: 10.0),
                Container(
                  margin: const EdgeInsets.only(right: 30.0),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: TextField(
                    controller: namecontroller,
                    decoration: const InputDecoration(border: InputBorder.none, prefixIcon: Icon(Icons.person)),
                  ),
                ),
                const SizedBox(height: 20.0),
                const Text("Email", style: TextStyle(color: Colors.white, fontSize: 20.0)),
                const SizedBox(height: 10.0),
                Container(
                  margin: const EdgeInsets.only(right: 30.0),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: TextField(
                    controller: mailcontroller,
                    decoration: const InputDecoration(border: InputBorder.none, prefixIcon: Icon(Icons.email)),
                  ),
                ),
                const SizedBox(height: 20.0),
                const Text("Password", style: TextStyle(color: Colors.white, fontSize: 20.0)),
                const SizedBox(height: 10.0),
                Container(
                  margin: const EdgeInsets.only(right: 30.0),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: TextField(
                    obscureText: true,
                    controller: passwordcontroller,
                    decoration: const InputDecoration(border: InputBorder.none, prefixIcon: Icon(Icons.lock)),
                  ),
                ),
                const SizedBox(height: 20.0),
                const Text("Confirm Password", style: TextStyle(color: Colors.white, fontSize: 20.0)),
                const SizedBox(height: 10.0),
                Container(
                  margin: const EdgeInsets.only(right: 30.0),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: TextField(
                    obscureText: true,
                    controller: confirmpasswordcontroller,
                    decoration: const InputDecoration(border: InputBorder.none, prefixIcon: Icon(Icons.lock)),
                  ),
                ),
                const SizedBox(height: 40.0),

                Padding(
                  padding: const EdgeInsets.only(right: 30.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: isLoading ? null : () => registration(),
                      child: Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(color: const Color(0xff904c6e), borderRadius: BorderRadius.circular(50)),
                        child: isLoading
                            ? const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                            : const Icon(Icons.arrow_forward, color: Colors.white, size: 40.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 50.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account?",
                      style: TextStyle(color: Colors.white, fontSize: 18.0),
                    ),
                    const SizedBox(width: 5.0),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const Login()));
                      },
                      child: const Text(
                        "Login",
                        style: TextStyle(color: Color(0xff904c6e), fontSize: 20.0, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 50.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}