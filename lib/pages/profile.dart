import 'package:flutter/material.dart';
import 'package:prmproject/services/shared_pref.dart';
import 'package:prmproject/pages/logout.dart';
import 'package:prmproject/pages/delete_account.dart';

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
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.only(top: 50.0),
          child: Column(
            children: [
              // Header — không cần nút back vì giờ Profile nằm trong tab
              const Center(
                child: Text("Profile", style: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, color: Colors.black)),
              ),
              const SizedBox(height: 20.0),
              ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: Image.asset("images/boy1.jpg", height: 150, width: 150, fit: BoxFit.cover),
              ),
              const SizedBox(height: 50.0),

              // NAME
              _buildProfileItem(Icons.person, "Name", name ?? "Name"),
              const SizedBox(height: 30.0),

              // EMAIL
              _buildProfileItem(Icons.email, "Email", email ?? "Email"),
              const SizedBox(height: 30.0),

              // Nội dung hiển thị ở đây giờ chỉ còn Logout, Delete Account
              // Nút LogOut
              GestureDetector(
                onTap: () {
                  // Bấm vào là logout ngay lập tức
                  performLogout(context);
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
                  // Hiện dialog xác nhận xóa tài khoản
                  showDeleteAccountDialog(context);
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

  // Hàm hỗ trợ build UI cho gọn
  Widget _buildProfileItem(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.only(left: 20.0),
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(227, 238, 104, 86),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 40.0),
          const SizedBox(width: 20.0),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
              Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}