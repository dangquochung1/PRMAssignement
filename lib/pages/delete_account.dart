import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prmproject/pages/signup.dart';
import 'package:prmproject/services/database.dart';
import 'package:prmproject/services/shared_pref.dart';

// Hiện dialog xác nhận xóa tài khoản
void showDeleteAccountDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Delete Account",
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEE6856)),
        ),
        content: const Text(
          "Are you sure?",
          style: TextStyle(fontSize: 18.0),
        ),
        actions: [
          // Nút No — đóng dialog, không làm gì
          GestureDetector(
            onTap: () {
              Navigator.pop(dialogContext);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Text(
                "No",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          // Nút Yes — xóa vĩnh viễn tài khoản
          GestureDetector(
            onTap: () async {
              // Đóng dialog trước
              Navigator.pop(dialogContext);
              // Thực hiện xóa tài khoản
              await _deleteAccount(context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: const Color(0xFFEE6856),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Text(
                "Yes",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      );
    },
  );
}

// Hàm xử lý xóa tài khoản vĩnh viễn
Future<void> _deleteAccount(BuildContext context) async {
  try {
    // Lấy userId từ SharedPreferences
    String? userId = await SharedPreferenceHelper().getUserId();

    if (userId != null) {
      // Xóa dữ liệu Firestore (Expense, Income, user document)
      await DatabaseMethdos().deleteUserData(userId);
    }

    // Xóa tài khoản Firebase Auth
    await FirebaseAuth.instance.currentUser?.delete();

    // Xóa dữ liệu local (không xóa của user khác nếu có trên máy)
    await SharedPreferenceHelper().clearUserSession();

    // Chuyển về trang Đăng ký + hiện thông báo
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SignUp()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Tài khoản đã được xóa", style: TextStyle(fontSize: 18.0)),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("Xóa tài khoản thất bại: $e", style: const TextStyle(fontSize: 16.0)),
        ),
      );
    }
  }
}
