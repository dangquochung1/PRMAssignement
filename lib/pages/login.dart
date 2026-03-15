import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prmproject/pages/main_shell.dart';
import 'package:prmproject/pages/signup.dart';
import 'package:prmproject/services/shared_pref.dart';
import 'package:prmproject/utils/validator.dart'; // Import validate

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String email = "", password = "";
  TextEditingController mailcontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();

  bool isLoading = false;

  userLogin() async {
    // 1. Kiểm tra Validate
    String? emailError = AppValidator.validateEmail(mailcontroller.text);
    if (emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(emailError)));
      return;
    }
    if (passwordcontroller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập mật khẩu")));
      return;
    }

    // 2. Bắt đầu xử lý
    setState(() {
      isLoading = true;
      email = mailcontroller.text;
      password = passwordcontroller.text;
    });

    try {
      // Gọi Firebase để đăng nhập
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);

      // Đăng nhập thành công, tìm thông tin user trên Firestore để lưu SharedPreferences
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('Email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        String id = querySnapshot.docs[0]["Id"];
        String name = querySnapshot.docs[0]["Name"];

        await SharedPreferenceHelper().saveUserId(id);
        await SharedPreferenceHelper().saveUserName(name);
        await SharedPreferenceHelper().saveUserEmail(email);
      }

      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainShell()));

    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.redAccent, content: Text("Không tìm thấy tài khoản với Email này.")));
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.redAccent, content: Text("Sai thông tin đăng nhập.")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.redAccent, content: Text(e.message ?? "Đăng nhập thất bại")));
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Đưa Container ảnh nền ra gốc ngoài cùng
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("images/login.png"),
          fit: BoxFit.cover, // Phủ kín toàn bộ màn hình điện thoại
        ),
      ),
      // 2. Bọc Scaffold vào bên trong và set trong suốt
      child: Scaffold(
        backgroundColor: Colors.transparent, // Chìa khóa là dòng này!
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(left: 30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(right: 50.0, top: 90.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text("Welcome\nBack!",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 40.0, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 180.0),
                const Text("Email",
                    style: TextStyle(color: Color(0xff3f3d65), fontSize: 24.0, fontWeight: FontWeight.w500)),
                const SizedBox(height: 10.0),
                Container(
                  margin: const EdgeInsets.only(right: 30.0),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: TextField(
                    controller: mailcontroller,
                    decoration: const InputDecoration(
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.mail, size: 28.0, color: Color(0xff904c6e)),
                        hintText: "Enter Email",
                        hintStyle: TextStyle(fontSize: 18.0)),
                  ),
                ),
                const SizedBox(height: 30.0),
                const Text("Password",
                    style: TextStyle(color: Color(0xff3f3d65), fontSize: 24.0, fontWeight: FontWeight.w500)),
                const SizedBox(height: 10.0),
                Container(
                  margin: const EdgeInsets.only(right: 30.0),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: TextField(
                    controller: passwordcontroller,
                    obscureText: true,
                    decoration: const InputDecoration(
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.password, size: 28.0, color: Color(0xff904c6e)),
                        hintText: "Enter Password",
                        hintStyle: TextStyle(fontSize: 18.0, color: Color(0xff3f3d65), fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 50.0),

                Padding(
                  padding: const EdgeInsets.only(right: 30.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: isLoading ? null : () => userLogin(),
                      child: Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(color: const Color(0xff904c6e), borderRadius: BorderRadius.circular(60)),
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
                      "Don't have an account?",
                      style: TextStyle(color: Colors.black, fontSize: 16.0, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 5.0),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                            context, MaterialPageRoute(builder: (context) => const SignUp()));
                      },
                      child: const Text(
                        "Signup",
                        style: TextStyle(color: Color(0xff904c6e), fontSize: 20.0, fontWeight: FontWeight.bold),
                      ),
                    ),
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