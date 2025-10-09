# HƯỚNG DẪN THIẾT LẬP FIREBASE CHO TRIP HOTEL

## 🎯 THÔNG TIN DỰ ÁN
- **Tên dự án**: Trip Hotel
- **Package Name (Android)**: com.example.hotel_mobile
- **Bundle ID (iOS)**: com.example.hotelMobile
- **Web App**: Trip Hotel Web

## 🔥 BƯỚC 1: TẠO FIREBASE PROJECT

### 1.1 Tạo Project trên Firebase Console
1. Truy cập: https://console.firebase.google.com/
2. Nhấn "Create a project" hoặc "Add project"
3. **Project name**: `trip-hotel`
4. **Project ID**: `trip-hotel-xxxxx` (Firebase sẽ tự tạo)
5. Bật Google Analytics (khuyến nghị)
6. Chọn Analytics account hoặc tạo mới

### 1.2 Kích hoạt Authentication
1. Trong Firebase Console, vào **Authentication**
2. Nhấn **Get started**
3. Vào tab **Sign-in method**
4. Kích hoạt **Google**:
   - Bật toggle "Enable"
   - **Project support email**: your-email@gmail.com
   - Nhấn **Save**

### 1.3 Thêm App vào Firebase Project

#### Android App:
1. Nhấn icon Android trong Project Overview
2. **Android package name**: `com.example.hotel_mobile`
3. **App nickname**: `Trip Hotel Android`
4. **Debug signing certificate SHA-1**: (tùy chọn - để sau)
5. Download `google-services.json`

#### iOS App:
1. Nhấn icon iOS trong Project Overview  
2. **iOS bundle ID**: `com.example.hotelMobile`
3. **App nickname**: `Trip Hotel iOS`
4. Download `GoogleService-Info.plist`

#### Web App:
1. Nhấn icon Web trong Project Overview
2. **App nickname**: `Trip Hotel Web`
3. **Hosting**: Không cần setup ngay
4. Copy Web configuration

## 🔧 BƯỚC 2: CẤU HÌNH SHA-1 CHO ANDROID

### Tạo SHA-1 fingerprint:
```bash
# Debug keystore
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Hoặc trên Windows:
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

Copy SHA-1 fingerprint và thêm vào Firebase Console:
1. Vào Project Settings > Your apps > Android app
2. Nhấn "Add fingerprint"
3. Paste SHA-1 fingerprint

## 📋 DANH SÁCH FILE CẦN TẢI
- ✅ `google-services.json` (Android)
- ✅ `GoogleService-Info.plist` (iOS)  
- ✅ Web config object (Web)

## 🔗 LINKS QUAN TRỌNG
- Firebase Console: https://console.firebase.google.com/
- FlutterFire docs: https://firebase.flutter.dev/
- Firebase Auth docs: https://firebase.flutter.dev/docs/auth/usage/