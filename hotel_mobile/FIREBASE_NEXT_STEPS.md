# 🔥 HƯỚNG DẪN HOÀN TẤT FIREBASE GOOGLE SIGN-IN

## ✅ ĐÃ HOÀN THÀNH
- [x] Cài đặt Firebase CLI
- [x] Thêm Firebase dependencies  
- [x] Tạo Firebase Auth Service
- [x] Tạo Google Sign-In Button components
- [x] Cập nhật main.dart để khởi tạo Firebase

## 🔧 CÁC BƯỚC TIẾP THEO

### BƯỚC 1: TẠO FIREBASE PROJECT
1. Truy cập: https://console.firebase.google.com/
2. Tạo project mới tên **"trip-hotel"**
3. Kích hoạt **Authentication** > **Google Sign-In**

### BƯỚC 2: THÊM APP VÀO FIREBASE

#### Android:
1. Thêm Android app với package: `com.example.hotel_mobile`
2. Download `google-services.json`
3. Đặt vào: `android/app/google-services.json`

#### iOS:
1. Thêm iOS app với bundle: `com.example.hotelMobile`
2. Download `GoogleService-Info.plist`  
3. Đặt vào: `ios/Runner/GoogleService-Info.plist`

#### Web:
1. Thêm Web app
2. Copy Web config và cập nhật `lib/firebase_options.dart`

### BƯỚC 3: CẬP NHẬT CẤU HÌNH

#### Android (`android/app/build.gradle.kts`):
```kotlin
// Thêm vào cuối file
apply plugin: 'com.google.gms.google-services'
```

#### Android (`android/build.gradle.kts`):
```kotlin
dependencies {
    classpath 'com.google.gms:google-services:4.3.15'
}
```

### BƯỚC 4: CẬP NHẬT FIREBASE OPTIONS
Thay thế nội dung trong `lib/firebase_options.dart` bằng config thực tế từ Firebase Console.

### BƯỚC 5: THÊM GOOGLE ICON
1. Tạo thư mục: `assets/icons/`
2. Thêm file: `google_icon.png`
3. Cập nhật `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/icons/
```

### BƯỚC 6: SỬ DỤNG TRONG LOGIN SCREEN
```dart
import 'package:flutter/material.dart';
import '../widgets/google_signin_button.dart';

// Trong build method:
GoogleSignInButton(
  onSignInSuccess: () {
    // Navigate to home
    Navigator.pushReplacementNamed(context, '/home');
  },
  onSignInError: (error) {
    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
  },
)
```

## 🚀 TEST FIREBASE GOOGLE SIGN-IN

### Development:
1. Thêm SHA-1 fingerprint vào Firebase Console
2. Chạy: `flutter run`
3. Test Google Sign-In

### Production:
1. Thêm release SHA-1 fingerprint
2. Update `firebase_options.dart` với production config
3. Build và deploy

## 🔗 LINKS QUAN TRỌNG
- Firebase Console: https://console.firebase.google.com/
- FlutterFire Docs: https://firebase.flutter.dev/
- Authentication Guide: https://firebase.flutter.dev/docs/auth/usage/

## 📞 BACKEND INTEGRATION
Sau khi hoàn thành, Firebase sẽ cung cấp ID Token có thể gửi lên backend để verify và tạo session.