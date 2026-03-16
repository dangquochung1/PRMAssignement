import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prmproject/services/shared_pref.dart';

class DatabaseMethdos {
  Future addUserInfo(Map<String, dynamic> userInfoMap, String Id) async{
    await FirebaseFirestore.instance.collection("users").doc(Id).set(userInfoMap);
  }
  Future addUserExpense(Map<String, dynamic> userExpense, String Id) async{
    await FirebaseFirestore.instance.collection("users").doc(Id).collection("Expense").add(userExpense);
  }
  Future addUserIncome(Map<String, dynamic> userIncome, String Id) async{
    await FirebaseFirestore.instance.collection("users").doc(Id).collection("Income").add(userIncome);
  }

  // Xóa toàn bộ dữ liệu user trên Firestore (sub-collections + document)
  Future deleteUserData(String Id) async {
    // Xóa sub-collection Expense
    var expenseSnapshot = await FirebaseFirestore.instance
        .collection("users").doc(Id).collection("Expense").get();
    for (var doc in expenseSnapshot.docs) {
      await doc.reference.delete();
    }

    // Xóa sub-collection Income
    var incomeSnapshot = await FirebaseFirestore.instance
        .collection("users").doc(Id).collection("Income").get();
    for (var doc in incomeSnapshot.docs) {
      await doc.reference.delete();
    }

    // Xóa document user
    await FirebaseFirestore.instance.collection("users").doc(Id).delete();
  }

  // Thêm giao dịch mới (tiền ra hoặc tiền vào)
  Future addTransaction(Map<String, dynamic> transactionData, String Id) async {
    await FirebaseFirestore.instance
        .collection("users").doc(Id).collection("Transactions").add(transactionData);
  }

  // Lấy danh sách giao dịch
  Future<QuerySnapshot> getTransactions(String Id) async {
    return await FirebaseFirestore.instance
        .collection("users").doc(Id).collection("Transactions")
        .orderBy("Date", descending: true)
        .get();
  }

  // Xóa 1 giao dịch
  Future deleteTransaction(String Id, String transactionId) async {
    await FirebaseFirestore.instance
        .collection("users").doc(Id).collection("Transactions")
        .doc(transactionId)
        .delete();
  }
  Future<List<Map<String, dynamic>>> getTransactionsCached(
      String userId, {
        bool forceRefresh = false,
      }) async {
    // 1. Thử đọc cache trước (nếu không forceRefresh)
    if (!forceRefresh) {
      String? cached = await SharedPreferenceHelper().getTransactionsCache();
      if (cached != null && cached.isNotEmpty) {
        List<dynamic> decoded = jsonDecode(cached);
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }

    // 2. Không có cache → gọi Firestore
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("Transactions")
        .orderBy("Date", descending: true)
        .get();

    List<Map<String, dynamic>> result = snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data["id"] = doc.id;
      return data;
    }).toList();

    // 3. Lưu cache lại
    await SharedPreferenceHelper().saveTransactionsCache(jsonEncode(result));

    return result;
  }
}
