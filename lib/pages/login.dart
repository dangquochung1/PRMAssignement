import 'package:flutter/material.dart';
// Lưu ý: Đảm bảo bạn đã có file này trong project
import 'package:prmproject/pages/signup.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  // Khai báo các biến state và controllers dựa trên ảnh số 4 và số 2
  String email = "", password = "";
  TextEditingController mailcontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();

  // Hàm userLogin được gọi trong ảnh 4, tạo một hàm trống để tránh lỗi
  userLogin() {
    // Thêm logic xử lý đăng nhập của bạn ở đây (Firebase, API, v.v.)
    print("Email: $email, Password: $password");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Stack(
          children: [
            Image.asset(
              "images/login.png",
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.cover,
            ),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(left: 30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 50.0, top: 90.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            "Welcome\nBack!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 40.0,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 180.0,),
                    Text(
                      "Email",
                      style: TextStyle(
                          color: Color(0xff3f3d65),
                          fontSize: 24.0,
                          fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 10.0,),
                    Container(
                      margin: EdgeInsets.only(right: 30.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: mailcontroller, // Bổ sung controller từ ảnh 2
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Icon(
                              Icons.mail,
                              size: 28.0,
                              color: Color(0xff904c6e),
                            ),
                            hintText: "Enter Email",
                            hintStyle: TextStyle(fontSize: 18.0)),
                      ),
                    ),
                    SizedBox(height: 30.0,),
                    Text(
                      "Password",
                      style: TextStyle(
                          color: Color(0xff3f3d65),
                          fontSize: 24.0,
                          fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 10.0,),
                    Container(
                      margin: EdgeInsets.only(right: 30.0),
                      child: TextField(
                        controller: passwordcontroller, // Bổ sung controller từ ảnh 2
                        obscureText: true, // Nên có cho password
                        decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.password,
                              size: 28.0,
                              color: Color(0xff904c6e),
                            ),
                            hintText: "Enter Password",
                            hintStyle: TextStyle(
                                fontSize: 18.0,
                                color: Color(0xff3f3d65),
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    SizedBox(height: 50.0,),
                    Padding(
                      padding: const EdgeInsets.only(left: 40.0, right: 60.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Next",
                            style: TextStyle(
                                color: Color(0xff3f3d65),
                                fontSize: 30.0,
                                fontWeight: FontWeight.bold),
                          ),
                          // Bổ sung GestureDetector và logic từ ảnh 4
                          GestureDetector(
                            onTap: () {
                              if (mailcontroller.text != "" && passwordcontroller.text != "") {
                                setState(() {
                                  email = mailcontroller.text;
                                  password = passwordcontroller.text;
                                });
                                userLogin();
                              }
                            },
                            child: Container(
                              height: 100,
                              width: 100,
                              decoration: BoxDecoration(
                                  color: Color(0xff904c6e),
                                  borderRadius: BorderRadius.circular(60)),
                              child: Icon(Icons.arrow_forward,
                                  color: Colors.white, size: 40.0),
                            ),
                          )
                        ],
                      ),
                    ),
                    SizedBox(height: 50.0,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w500),
                        ),
                        SizedBox(width: 5.0,), // Thêm chút khoảng cách cho đẹp
                        GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => SignUp()));
                            },
                            child: Text(
                              "Signup",
                              style: TextStyle(
                                  color: Color(0xff904c6e),
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.bold),
                            )),
                      ],
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}