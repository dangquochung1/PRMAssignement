import 'package:flutter/material.dart';
import 'package:prmproject/pages/budget.dart';
import 'package:prmproject/pages/wallet.dart';
import 'package:prmproject/pages/analytics.dart';
import 'package:prmproject/pages/profile.dart';
import 'package:prmproject/pages/add_transaction.dart';

// Shell chính — chứa BottomNavigationBar 5 tab
// Tab mặc định khi login xong: Ngân sách (index 0)
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Index mặc định = 0 (Ngân sách)
  int _currentIndex = 0;

  // Danh sách các trang (index 2 = placeholder vì nút + sẽ push sang Expense)
  List<Widget> _pages = [
    const Budget(),
    const Wallet(),
    const SizedBox(),
    const Analytics(),
    const Profile(),
  ];

  void _onTabTapped(int index) async {
    // Nếu bấm nút + (index 2), push sang trang Expense rồi quay lại
    if (index == 2) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddTransaction()),
      );
      // Sau khi đóng AddTransaction, force reload budget
      setState(() {
        _pages[0] = const Budget();  // rebuild lại Budget widget
      });
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF2E7D32),
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: "Ngân sách",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: "Ví tiền",
            ),
            // Nút + ở giữa — icon lớn hơn, nổi bật
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
              label: "",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_outline),
              activeIcon: Icon(Icons.pie_chart),
              label: "Phân tích",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: "Cài đặt",
            ),
          ],
        ),
      ),
    );
  }
}
