class AppValidator {
  // Validate Email
  static String? validateEmail(String value) {
    if (value.isEmpty) {
      return "Email không được để trống";
    }

    // Sử dụng chuỗi thô r'''...''' để bọc Regex chứa cả nháy đơn, nháy kép và backslash
    final RegExp emailRegex = RegExp(
      r'''(?:[a-z0-9!#$%&'*+\x2f=?^_`\x7b-\x7d~\x2d]+(?:\.[a-z0-9!#$%&'*+\x2f=?^_`\x7b-\x7d~\x2d]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9\x2d]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9\x2d]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9])|[a-z0-9\x2d]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])''',
      caseSensitive: false, // Bật ignore case vì Regex của bạn dùng chữ thường [a-z]
    );

    if (!emailRegex.hasMatch(value)) {
      return "Email không hợp lệ";
    }

    return null;
  }

  // Validate Password
  static String? validatePassword(String value) {
    if (value.isEmpty) {
      return "Mật khẩu không được để trống";
    }
    if (value.length < 6) {
      return "Mật khẩu phải có ít nhất 6 ký tự";
    }
    return null;
  }
}