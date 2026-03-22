import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:prmproject/pages/login.dart';
import 'firebase_options.dart';

void main() async {
  // Bắt buộc phải có dòng này trước khi khởi tạo Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // DÙNG OPTIONS Ở ĐÂY
  );
  runApp(const MyApp());
}
// aa
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Precache ảnh nền ngay khi app khởi động
    precacheImage(const AssetImage("images/login.png"), context);

    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff904c6e)),
      ),
      home: const Login(),
    );
  }
}