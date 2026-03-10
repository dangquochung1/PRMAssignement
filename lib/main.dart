import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

// Đã đổi lại thành dạng import package để đồng nhất với các file khác của bạn
import 'package:prmproject/pages/home.dart';
import 'package:prmproject/pages/onboarding.dart';
import 'package:prmproject/pages/signup.dart';
import 'package:prmproject/pages/login.dart';

void main() async {
  // Bắt buộc phải có dòng này trước khi khởi tạo Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker', // Đã đổi tên app cho phù hợp với dự án
      debugShowCheckedModeBanner: false, // Ẩn chữ "DEBUG" góc phải màn hình
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff904c6e)), // Chỉnh seed color theo tone màu app của bạn
      ),
      // Bắt đầu luồng từ trang Đăng ký
      home: const SignUp(),
    );
  }
}