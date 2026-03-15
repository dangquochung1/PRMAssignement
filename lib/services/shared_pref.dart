import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceHelper {
  static String userIdKey = "USERKEY";
  static String userNameKey = "USERNAMEKEY";
  static String userEmailKey = "USEREMAILKEY";
  static String userCategoriesKey = "USERCATEGORIESKEY"; // Key mới cho Category

  Future<bool> saveUserId(String getUserId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(userIdKey, getUserId);
  }

  Future<bool> saveUserName(String getUserName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(userNameKey, getUserName);
  }

  Future<bool> saveUserEmail(String getUserEmail) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(userEmailKey, getUserEmail);
  }

  // --- HÀM MỚI CHO CATEGORY ---
  Future<bool> saveUserCategories(List<String> categories) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString(userIdKey) ?? "unknown";
    return prefs.setStringList("${userId}_$userCategoriesKey", categories);
  }

  Future<List<String>?> getUserCategories() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString(userIdKey) ?? "unknown";
    return prefs.getStringList("${userId}_$userCategoriesKey");
  }
  // -----------------------------

  // --- HÀM CHO NHÃN (LABEL) ---
  static String userLabelsKey = "USERLABELSKEY";

  Future<bool> saveUserLabels(List<String> labels) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString(userIdKey) ?? "unknown";
    return prefs.setStringList("${userId}_$userLabelsKey", labels);
  }

  Future<List<String>?> getUserLabels() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString(userIdKey) ?? "unknown";
    return prefs.getStringList("${userId}_$userLabelsKey");
  }
  // -----------------------------

  Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userIdKey);
  }

  Future<String?> getUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userNameKey);
  }

  Future<String?> getUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userEmailKey);
  }

  // --- HÀM CHO NHÓM DANH MỤC NGÂN SÁCH ---
  static String budgetGroupsKey = "BUDGETGROUPSKEY";

  Future<bool> saveBudgetGroups(String jsonStr) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString(userIdKey) ?? "unknown";
    return prefs.setString("${userId}_$budgetGroupsKey", jsonStr);
  }

  Future<String?> getBudgetGroups() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString(userIdKey) ?? "unknown";
    return prefs.getString("${userId}_$budgetGroupsKey");
  }
  // -----------------------------------------

  // --- HÀM CHO VÍ TIỀN ---
  static String walletsKey = "WALLETSKEY";

  Future<bool> saveWallets(String jsonStr) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString(userIdKey) ?? "unknown";
    return prefs.setString("${userId}_$walletsKey", jsonStr);
  }

  Future<String?> getWallets() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString(userIdKey) ?? "unknown";
    return prefs.getString("${userId}_$walletsKey");
  }
  // -------------------------

  // Xóa session đăng nhập hiện tại (không xóa hết data local của máy)
  Future<bool> clearUserSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(userIdKey);
    await prefs.remove(userNameKey);
    await prefs.remove(userEmailKey);
    return true;
  }
}