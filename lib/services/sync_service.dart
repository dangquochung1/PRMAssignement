import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prmproject/services/shared_pref.dart';

class SyncService {
  /// ĐẨY tất cả data từ SharedPrefs lên Firestore
  /// Gọi sau mỗi lần save local
  static Future<void> pushToFirestore(String userId) async {
    try {
      final prefs = SharedPreferenceHelper();

      String? wallets      = await prefs.getWallets();
      String? budgetGroups = await prefs.getBudgetGroups();
      String? budgetName   = await prefs.getBudgetName();
      List<String>? cats   = await prefs.getUserCategories();
      List<String>? labels = await prefs.getUserLabels();
      int? avatarIndex     = await prefs.getAvatarIndex();

      Map<String, dynamic> data = {};
      if (wallets != null)      data["wallets"]      = wallets;
      if (budgetGroups != null) data["budgetGroups"] = budgetGroups;
      if (budgetName != null)   data["budgetName"]   = budgetName;
      if (cats != null)         data["categories"]   = cats;
      if (labels != null)       data["labels"]       = labels;
      if (avatarIndex != null)  data["avatarIndex"]  = avatarIndex;

      if (data.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(userId)
            .set(data, SetOptions(merge: true));
      }
    } catch (e) {
      // Không crash app nếu offline
    }
  }

  /// KÉO tất cả data từ Firestore về SharedPrefs
  /// Gọi sau khi login thành công
  static Future<void> pullFromFirestore(String userId) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .get();

      if (!doc.exists) return;
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      final prefs = SharedPreferenceHelper();

      if (data["wallets"] != null) {
        await prefs.saveWallets(data["wallets"]);
      }
      if (data["budgetGroups"] != null) {
        await prefs.saveBudgetGroups(data["budgetGroups"]);
      }
      if (data["budgetName"] != null) {
        await prefs.saveBudgetName(data["budgetName"]);
      }
      if (data["categories"] != null) {
        await prefs.saveUserCategories(List<String>.from(data["categories"]));
      }
      if (data["labels"] != null) {
        await prefs.saveUserLabels(List<String>.from(data["labels"]));
      }
      if (data["avatarIndex"] != null) {
        await prefs.saveAvatarIndex(data["avatarIndex"]);
      }
    } catch (e) {
      // Không crash nếu offline, dùng data local
    }
  }
}