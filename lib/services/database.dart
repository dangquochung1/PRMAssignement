import 'package:cloud_firestore/cloud_firestore.dart';

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
}