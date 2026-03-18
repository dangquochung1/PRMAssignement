import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prmproject/pages/logout.dart';
import 'package:prmproject/pages/delete_account.dart';
import 'package:prmproject/services/shared_pref.dart';
import 'package:prmproject/services/sync_service.dart';
class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String? name;
  String? email;
  int avatarIndex = 0;
  String defaultWalletName = "";
  List<Map<String, dynamic>> wallets = [];

  static const List<String> _avatarEmojis = [
    "🐥", "🦊", "🐻", "🐼", "🐨", "🦁", "🐸", "🐧",
  ];

  static const List<Color> _avatarColors = [
    Color(0xFFD4A843),
    Color(0xFFE67E22),
    Color(0xFF8E44AD),
    Color(0xFF2E7D32),
    Color(0xFF1565C0),
    Color(0xFFC0392B),
    Color(0xFF00838F),
    Color(0xFF37474F),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  _loadData() async {
    name = await SharedPreferenceHelper().getUserName();
    email = await SharedPreferenceHelper().getUserEmail();

    int? savedAvatar = await SharedPreferenceHelper().getAvatarIndex();
    if (savedAvatar != null) avatarIndex = savedAvatar;

    String? wJson = await SharedPreferenceHelper().getWallets();
    if (wJson != null && wJson.isNotEmpty) {
      List<dynamic> decoded = jsonDecode(wJson);
      wallets = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    for (var w in wallets) {
      if (w["isDefault"] == true) {
        defaultWalletName = w["name"];
        break;
      }
    }
    if (defaultWalletName.isEmpty && wallets.isNotEmpty) {
      defaultWalletName = wallets.first["name"];
    }

    setState(() {});
  }

  // ---- DIALOG ĐỔI TÊN ----
  void _showEditNameDialog() {
    final ctrl = TextEditingController(text: name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Đổi tên hiển thị",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Nhập tên của bạn",
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("HỦY", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              String newName = ctrl.text.trim();
              if (newName.isNotEmpty) {
                await SharedPreferenceHelper().saveUserName(newName);
                String? uid = await SharedPreferenceHelper().getUserId();
                if (uid != null) SyncService.pushToFirestore(uid); // ← thêm
                setState(() => name = newName);
              }
              if (mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4A843),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child:
            const Text("LƯU", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ---- BOTTOM SHEET CHỌN AVATAR ----
  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx2, setSheet) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                const Text("Chọn avatar",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: List.generate(_avatarEmojis.length, (i) {
                    bool isSel = avatarIndex == i;
                    return GestureDetector(
                      onTap: () async {
                        await SharedPreferenceHelper().saveAvatarIndex(i);
                        String? uid = await SharedPreferenceHelper().getUserId();
                        if (uid != null) SyncService.pushToFirestore(uid); // ← thêm
                        setState(() => avatarIndex = i);
                        setSheet(() {});
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _avatarColors[i],
                          shape: BoxShape.circle,
                          border: isSel
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: isSel
                              ? [
                            BoxShadow(
                              color: _avatarColors[i]
                                  .withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                              : null,
                        ),
                        child: Center(
                          child: Text(_avatarEmojis[i],
                              style: const TextStyle(fontSize: 28)),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        });
      },
    );
  }

  // ---- BOTTOM SHEET ĐỔI VÍ MẶC ĐỊNH ----
  void _showDefaultWalletPicker() {
    List<Map<String, dynamic>> paymentWallets =
    wallets.where((w) => w["type"] != "Tracking").toList();

    if (paymentWallets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Chưa có ví thanh toán nào")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              const Text("Ví mặc định",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                "Ví mặc định sẽ được chọn sẵn khi thêm giao dịch",
                style:
                TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 16),
              ...paymentWallets.map((w) {
                bool isSel = w["name"] == defaultWalletName;
                double bal = (w["amount"] ?? 0).toDouble();
                final NumberFormat formatter =
                NumberFormat("#,###", "vi_VN");
                String balStr = "${formatter.format(bal)}đ";

                return GestureDetector(
                  onTap: () async {
                    for (var ww in wallets) {
                      ww["isDefault"] = (ww["name"] == w["name"]);
                    }
                    await SharedPreferenceHelper().saveWallets(jsonEncode(wallets));
                    String? uid = await SharedPreferenceHelper().getUserId();
                    if (uid != null) SyncService.pushToFirestore(uid); // ← thêm
                    setState(() => defaultWalletName = w["name"]);
                    if (mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            backgroundColor: Colors.green,
                            content: Text(
                                "Đã đặt '${w["name"]}' làm ví mặc định")),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSel
                          ? const Color(0xFFE8F5E9)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: isSel
                          ? Border.all(
                          color: const Color(0xFF4CAF50), width: 1.5)
                          : Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSel
                                ? const Color(0xFFE8F5E9)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.account_balance_wallet,
                              color: isSel
                                  ? const Color(0xFF4CAF50)
                                  : Colors.grey.shade500,
                              size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(w["name"],
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isSel
                                        ? Colors.black87
                                        : Colors.black54,
                                  )),
                              Text(balStr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSel
                                        ? const Color(0xFF2E7D32)
                                        : Colors.grey.shade500,
                                  )),
                            ],
                          ),
                        ),
                        if (isSel)
                          const Icon(Icons.check_circle,
                              color: Color(0xFF4CAF50), size: 22),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ---- HEADER ----
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 24),
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    const Text("Cài đặt",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    // Avatar — bấm để đổi
                    GestureDetector(
                      onTap: _showAvatarPicker,
                      child: Stack(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: _avatarColors[
                              avatarIndex.clamp(0, 7)],
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 3),
                            ),
                            child: Center(
                              child: Text(
                                _avatarEmojis[avatarIndex.clamp(0, 7)],
                                style:
                                const TextStyle(fontSize: 40),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFD4A843),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tên — bấm để đổi
                    GestureDetector(
                      onTap: _showEditNameDialog,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name ?? "Tên của bạn",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.edit,
                              color: Colors.white70, size: 16),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email ?? "",
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Ví mặc định
                    _buildSettingItem(
                      icon: Icons.account_balance_wallet,
                      iconColor: const Color(0xFF4CAF50),
                      title: "Ví mặc định",
                      subtitle: defaultWalletName.isNotEmpty
                          ? defaultWalletName
                          : "Chưa chọn",
                      onTap: _showDefaultWalletPicker,
                    ),
                    const SizedBox(height: 12),

                    // Tên hiển thị
                    _buildSettingItem(
                      icon: Icons.person_outline,
                      iconColor: Colors.blue.shade400,
                      title: "Tên hiển thị",
                      subtitle: name ?? "Chưa đặt tên",
                      onTap: _showEditNameDialog,
                    ),
                    const SizedBox(height: 12),

                    // Avatar
                    _buildSettingItem(
                      icon: Icons.face_outlined,
                      iconColor: const Color(0xFFD4A843),
                      title: "Avatar",
                      subtitle: "Thay đổi hình đại diện",
                      onTap: _showAvatarPicker,
                      trailing: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _avatarColors[
                          avatarIndex.clamp(0, 7)],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _avatarEmojis[avatarIndex.clamp(0, 7)],
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    _buildSettingItem(
                      icon: Icons.cloud_download_outlined,
                      iconColor: const Color(0xFF1565C0),
                      title: "Đồng bộ từ đám mây",
                      subtitle:
                          "Lấy ngân sách, ví, nhãn… từ Firebase (ghi đè bản trên máy)",
                      onTap: () async {
                        String? uid =
                            await SharedPreferenceHelper().getUserId();
                        if (uid == null) return;
                        if (!mounted) return;
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFFD4A843))),
                        );
                        try {
                          await SyncService.pullFromFirestore(uid);
                        } finally {
                          if (mounted) Navigator.pop(context);
                        }
                        await _loadData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFF2E7D32),
                              content: Text(
                                  "Đã tải dữ liệu từ đám mây. Mở lại tab Ngân sách / Ví để xem."),
                            ),
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 24),

                    // Logout
                    _buildDangerItem(
                      icon: Icons.logout,
                      label: "Đăng xuất",
                      onTap: () => performLogout(context),
                    ),
                    const SizedBox(height: 12),

                    // Delete account
                    _buildDangerItem(
                      icon: Icons.delete_outline,
                      label: "Xóa tài khoản",
                      onTap: () => showDeleteAccountDialog(context),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            trailing ??
                Icon(Icons.chevron_right,
                    color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.red.shade600, size: 22),
            const SizedBox(width: 14),
            Text(label,
                style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.red.shade300),
          ],
        ),
      ),
    );
  }
}