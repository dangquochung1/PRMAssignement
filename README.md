# 💰 Expense Tracker — Quản lý tài chính cá nhân

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Firestore-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-lightgrey?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

**Ứng dụng quản lý tài chính cá nhân theo phương pháp Zero-Based Budgeting, xây dựng bằng Flutter & Firebase.**

</div>

---

## 📋 Mục lục

- [Giới thiệu](#-giới-thiệu)
- [Tính năng](#-tính-năng)
- [Kiến trúc & Công nghệ](#-kiến-trúc--công-nghệ)
- [Cấu trúc thư mục](#-cấu-trúc-thư-mục)
- [Cài đặt & Chạy](#-cài-đặt--chạy)
- [Cấu hình Firebase](#-cấu-hình-firebase)
- [Hướng dẫn sử dụng](#-hướng-dẫn-sử-dụng)
- [Screenshots](#-screenshots)
- [Roadmap](#-roadmap)
- [Đóng góp](#-đóng-góp)

---

## 🌟 Giới thiệu

**Expense Tracker** là ứng dụng quản lý tài chính cá nhân được xây dựng theo mô hình **Zero-Based Budgeting** — mọi đồng tiền đều được giao một "việc làm" cụ thể trước khi chi tiêu. Người dùng có thể:

- Theo dõi chi tiêu và thu nhập theo thời gian thực
- Phân bổ ngân sách cho từng danh mục chi tiêu
- Quản lý nhiều ví tiền (ví thanh toán & ví theo dõi)
- Phân tích xu hướng tài chính qua biểu đồ trực quan
- Chuyển tiền giữa các ví một cách nhanh chóng

> **Nguyên lý:** *"Giao việc cho mọi đồng tiền trước khi tháng bắt đầu."*

---

## ✨ Tính năng

### 🏦 Quản lý ví
| Tính năng | Mô tả |
|---|---|
| Ví thanh toán | Theo dõi tiền mặt, tài khoản ngân hàng, v.v. |
| Ví theo dõi | Theo dõi tài sản đầu tư, crypto mà không ảnh hưởng ngân sách |
| Chuyển tiền | Chuyển tiền giữa các ví với lịch sử giao dịch đầy đủ |
| Điều chỉnh số dư | Khớp số dư thực tế với số dư trong app |
| Ví mặc định | Đặt ví mặc định để tự động chọn khi thêm giao dịch |

### 💳 Giao dịch
| Tính năng | Mô tả |
|---|---|
| Tiền ra / Tiền vào | Ghi nhận chi tiêu và thu nhập nhanh chóng qua numpad |
| Danh mục & Nhãn | Phân loại giao dịch theo nhóm danh mục tùy chỉnh |
| Ví theo dõi | Tự động vô hiệu hóa yêu cầu danh mục cho ví theo dõi |
| Lịch sử đầy đủ | Tìm kiếm, lọc theo tháng và ví, nhóm theo ngày |
| Xóa giao dịch | Hoàn trả số dư ví khi xóa |

### 📊 Ngân sách (Zero-Based Budgeting)
| Tính năng | Mô tả |
|---|---|
| Nhóm danh mục | Tổ chức danh mục chi tiêu theo nhóm (Nhà ở, Ăn uống, v.v.) |
| Phân bổ ngân sách | Giao số tiền cụ thể cho từng danh mục |
| Tiết kiệm | Theo dõi mục tiêu tiết kiệm với progress bar |
| Bù đắp vượt mức | Tự động cảnh báo và hỗ trợ bù đắp khi vượt ngân sách |
| Lọc theo tháng | Xem ngân sách theo tháng/năm, chỉ hiển thị tháng có data |
| Tên ngân sách tùy chỉnh | Đổi tên ngân sách theo ý muốn |

### 📈 Phân tích
| Tính năng | Mô tả |
|---|---|
| Biểu đồ chi tiêu | Phân tích chi tiêu theo danh mục (Bar chart) |
| Biểu đồ thu nhập | Phân tích thu nhập theo ví |
| So sánh | Chi tiêu vs Thu nhập theo thời gian |
| Lọc thời gian | Xem 3, 6 hoặc 12 tháng gần nhất |
| Tự động loại trừ | Giao dịch chuyển tiền không ảnh hưởng analytics |

### 👤 Cài đặt & Hồ sơ
| Tính năng | Mô tả |
|---|---|
| Avatar | 8 lựa chọn emoji avatar với màu nền tùy chỉnh |
| Tên hiển thị | Thay đổi tên không cần cập nhật Firebase |
| Ví mặc định | Chọn ví mặc định hiển thị khi thêm giao dịch |
| Đăng xuất | Xóa session local, giữ nguyên data |
| Xóa tài khoản | Xóa toàn bộ dữ liệu trên Firestore |

---

## 🏗 Kiến trúc & Công nghệ

```
┌─────────────────────────────────────────────┐
│                  Flutter UI                  │
│  (StatefulWidget + setState — no BLoC)       │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│              Services Layer                  │
│  ┌────────────────┐  ┌─────────────────────┐│
│  │  DatabaseMethods│  │SharedPreferenceHelper││
│  │  (Firestore)   │  │  (Local cache)      ││
│  └────────────────┘  └─────────────────────┘│
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│           Firebase Backend                   │
│  ┌─────────────┐  ┌─────────────────────┐   │
│  │Firebase Auth│  │Cloud Firestore      │   │
│  │(Email/Pass) │  │users/{id}/Transactions│  │
│  └─────────────┘  └─────────────────────┘   │
└─────────────────────────────────────────────┘
```

### Stack chính

| Thành phần | Công nghệ | Phiên bản |
|---|---|---|
| Framework | Flutter | 3.x |
| Language | Dart | 3.x |
| Authentication | Firebase Auth | latest |
| Database | Cloud Firestore | latest |
| Local Storage | SharedPreferences | latest |
| Charts | fl_chart / custom | latest |
| Date Format | intl | latest |
| Platform | Android, iOS, Web | — |

### Mô hình dữ liệu Firestore

```
users/
  {userId}/
    Transactions/
      {txId}/
        Amount:      "150000"
        Type:        "tien_ra" | "tien_vao" | "chuyen_tien" | "chuyen_tien_nhan"
        WalletName:  "Tiền mặt"
        Category:    "Ăn uống"
        Label:       "khop_so_du"
        SubType:     "khop_so_du"
        Description: "Trà sữa"
        Date:        "15-03-2026"
        TransferTo:  "Crypto"      (chỉ cho chuyen_tien)
        TransferFrom:"Tiền mặt"    (chỉ cho chuyen_tien_nhan)
```

### Dữ liệu Local (SharedPreferences)

| Key | Kiểu | Mô tả |
|---|---|---|
| `{userId}_WALLETSKEY` | String (JSON) | Danh sách ví + số dư |
| `{userId}_BUDGETGROUPSKEY` | String (JSON) | Nhóm danh mục + allocated |
| `{userId}_BUDGETNAMEKEY` | String | Tên ngân sách |
| `{userId}_AVATARINDEXKEY` | int | Index avatar đã chọn |
| `{userId}_USERLABELSKEY` | List\<String\> | Danh sách nhãn thu nhập |

---

## 📁 Cấu trúc thư mục

```
lib/
├── main.dart                    # Entry point
├── pages/
│   ├── onboarding.dart          # Màn hình chào mừng
│   ├── signup.dart              # Đăng ký tài khoản
│   ├── login.dart               # Đăng nhập
│   ├── main_shell.dart          # Bottom navigation shell (5 tabs)
│   │
│   ├── budget.dart              # Tab Ngân sách — Zero-Based Budgeting
│   ├── allocate_budget.dart     # Phân bổ ngân sách
│   ├── edit_budget.dart         # Chỉnh sửa nhóm danh mục
│   ├── compensate_budget.dart   # Bù đắp chi tiêu vượt mức
│   │
│   ├── wallet.dart              # Tab Ví tiền
│   ├── add_transaction.dart     # Thêm giao dịch (tiền ra/vào)
│   ├── transfer_wallet.dart     # Chuyển tiền giữa ví
│   ├── full_history.dart        # Lịch sử giao dịch đầy đủ
│   ├── transaction_detail.dart  # Chi tiết giao dịch
│   │
│   ├── analytics.dart           # Tab Phân tích — Biểu đồ
│   │
│   ├── profile.dart             # Tab Cài đặt — Hồ sơ
│   ├── logout.dart              # Xử lý đăng xuất
│   └── delete_account.dart      # Xóa tài khoản
│
├── services/
│   ├── database.dart            # Firebase Firestore methods
│   └── shared_pref.dart         # SharedPreferences helper
│
└── utils/
    └── validator.dart           # Email & password validation
```

---

## 🚀 Cài đặt & Chạy

### Yêu cầu hệ thống

- Flutter SDK `>= 3.0.0`
- Dart SDK `>= 3.0.0`
- Android Studio / VS Code
- Tài khoản Firebase

### 1. Clone repository

```bash
git clone https://github.com/your-username/expense-tracker.git
cd expense-tracker
```

### 2. Cài đặt dependencies

```bash
flutter pub get
```

### 3. Cấu hình Firebase (xem bước tiếp theo)

### 4. Chạy ứng dụng

```bash
# Debug mode
flutter run

# Release mode (khuyến nghị để test performance)
flutter run --release

# Web
flutter run -d chrome

# Build web production
flutter build web --web-renderer canvaskit --release
```

---

## 🔥 Cấu hình Firebase

### Bước 1: Tạo project Firebase

1. Truy cập [Firebase Console](https://console.firebase.google.com/)
2. Tạo project mới
3. Bật **Authentication** → Sign-in method → **Email/Password**
4. Tạo **Firestore Database** → Start in production mode

### Bước 2: Thêm app vào Firebase

```bash
# Cài FlutterFire CLI
dart pub global activate flutterfire_cli

# Cấu hình tự động
flutterfire configure
```

Lệnh trên sẽ tự tạo file `lib/firebase_options.dart`.

### Bước 3: Cập nhật `main.dart`

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```

### Bước 4: Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid != null;

      match /Transactions/{txId} {
        allow read, write: if request.auth != null;
      }
    }
  }
}
```

### Bước 5: Firestore Index

Tạo composite index cho collection `Transactions`:

| Collection | Fields | Order |
|---|---|---|
| Transactions | `Date` | Descending |

> Hoặc để Firestore tự tạo index lần đầu chạy app — nó sẽ hiện link trong console log.

---

## 📖 Hướng dẫn sử dụng

### Lần đầu sử dụng

```
1. Đăng ký tài khoản → 2. Tạo ví đầu tiên → 3. Thêm số dư
   → 4. Tạo nhóm danh mục → 5. Phân bổ ngân sách → 6. Bắt đầu ghi chép!
```

### Luồng Zero-Based Budgeting

```
Tổng tài sản (ví thanh toán)
        │
        ├── Phân bổ → Ăn uống:    3,000,000đ
        ├── Phân bổ → Thuê nhà:   5,000,000đ
        ├── Phân bổ → Tiết kiệm:  2,000,000đ
        └── Tiền chưa phân bổ:    0đ  ← Mục tiêu!
```

### Loại giao dịch

| Type | Mô tả | Ảnh hưởng số dư |
|---|---|---|
| `tien_ra` | Chi tiêu thông thường | Trừ ví |
| `tien_vao` | Thu nhập | Cộng ví |
| `chuyen_tien` | Chuyển đi | Trừ ví nguồn |
| `chuyen_tien_nhan` | Nhận chuyển | Cộng ví đích |
| `khop_so_du` | Điều chỉnh số dư | Tăng/giảm tùy chênh lệch |

---

## 📸 Screenshots

```
┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   Ngân sách  │  │   Ví tiền    │  │  Thêm GD     │  │  Phân tích   │
│              │  │              │  │              │  │              │
│  134,000,000 │  │  Tiền mặt   │  │   -150,000đ  │  │  Bar Chart   │
│  chưa phân bổ│  │  149,905,000 │  │              │  │  Chi tiêu    │
│              │  │              │  │  [Numpad]    │  │  vs Thu nhập │
│  Tháng 3 2026│  │  Chuyển tiền │  │              │  │              │
└──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘
```

---

## 🗺 Roadmap

### v1.0 — Current ✅
- [x] Xác thực Firebase (Email/Password)
- [x] Quản lý ví (thanh toán & theo dõi)
- [x] Thêm giao dịch tiền ra/vào với numpad
- [x] Phân bổ ngân sách Zero-Based
- [x] Biểu đồ phân tích chi tiêu
- [x] Chuyển tiền giữa ví
- [x] Điều chỉnh số dư (Khớp số dư)
- [x] Lịch sử giao dịch đầy đủ với bộ lọc
- [x] Lọc ngân sách theo tháng/năm có data
- [x] Cài đặt: Avatar, tên, ví mặc định

### v1.1 — Planned 🔨
- [ ] Thông báo push nhắc nhở ghi chép
- [ ] Export dữ liệu ra file CSV/Excel
- [ ] Dark mode
- [ ] Ngân sách tái tạo tự động hàng tháng
- [ ] Mục tiêu tài chính (Financial Goals)
- [ ] Widget màn hình chính (Home Screen Widget)

### v2.0 — Future 🚀
- [ ] Đồng bộ đa thiết bị real-time
- [ ] Chia sẻ ngân sách nhóm (gia đình)
- [ ] Kết nối ngân hàng tự động (Open Banking)
- [ ] AI phân tích thói quen chi tiêu

---

## 🔧 Tối ưu hiệu suất

### Web Performance

```bash
# Build production với CanvasKit renderer
flutter build web --web-renderer canvaskit --release
```

### Firestore Caching

```dart
// Bật offline persistence cho web (thêm vào main.dart)
try {
  await FirebaseFirestore.instance.enablePersistence(
    const PersistenceSettings(synchronizeTabs: true),
  );
} catch (_) {}
```

### Giới hạn query

```dart
// Chỉ lấy 50 giao dịch mới nhất thay vì toàn bộ
.orderBy("Date", descending: true)
.limit(50)
.get()
```

---

## 🤝 Đóng góp

Mọi đóng góp đều được chào đón! Vui lòng:

1. Fork repository
2. Tạo branch mới: `git checkout -b feature/ten-tinh-nang`
3. Commit thay đổi: `git commit -m 'feat: thêm tính năng X'`
4. Push lên branch: `git push origin feature/ten-tinh-nang`
5. Tạo Pull Request

### Commit Convention

```
feat:     Tính năng mới
fix:      Sửa lỗi
refactor: Cải thiện code không thêm tính năng
perf:     Tối ưu hiệu suất
docs:     Cập nhật tài liệu
chore:    Cập nhật dependencies, config
```

---

## 🐛 Known Issues

| Issue | Trạng thái | Ghi chú |
|---|---|---|
| Firestore index cần tạo thủ công lần đầu | ⚠️ Known | Xem console log để lấy link tạo index |
| Web build lần đầu load chậm | ⚠️ Known | Dùng `--web-renderer canvaskit` để cải thiện |
| SharedPreferences trên Web dùng localStorage | ℹ️ By design | Data lưu trong browser |

---

## 📄 License

```
MIT License

Copyright (c) 2026 Expense Tracker

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software...
```

Xem chi tiết tại [LICENSE](LICENSE).

---

## 🙏 Acknowledgements

- [Flutter](https://flutter.dev/) — UI framework
- [Firebase](https://firebase.google.com/) — Backend as a Service
- [intl](https://pub.dev/packages/intl) — Định dạng số tiền VND
- [shared_preferences](https://pub.dev/packages/shared_preferences) — Local storage

---

<div align="center">

Made with ❤️ and ☕

**[⬆ Về đầu trang](#-expense-tracker--quản-lý-tài-chính-cá-nhân)**

</div>