import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prmproject/pages/signup.dart';
import 'package:prmproject/services/shared_pref.dart';

// Hàm xử lý đăng xuất — bấm vào là logout ngay lập tức
Future<void> performLogout(BuildContext context) async {
  try {
    // Đăng xuất Firebase Auth
    await FirebaseAuth.instance.signOut();

    // Xóa dữ liệu local (SharedPreferences)
    await SharedPreferenceHelper().clearUserSession();

    // Chuyển về trang Đăng ký, xóa hết stack navigation
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SignUp()),
        (route) => false,
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("Đăng xuất thất bại: $e", style: const TextStyle(fontSize: 16.0)),
        ),
      );
    }
  }
}
