# HƯỚNG DẪN CẤU HÌNH FIREBASE AUTHENTICATION CHO MOBILE APP

## � FIREBASE + FACEBOOK + GOOGLE AUTHENTICATION

### �📱 THÔNG TIN ỨNG DỤNG CỦA BẠN

#### Firebase Project:
- **Project ID**: trip-hotel
- **Project Number**: 871253844733
- **Project Name**: Trip Hotel

#### Android:
- **Package Name**: com.example.hotel_mobile
- **Class Name**: com.example.hotel_mobile.MainActivity

#### iOS:
- **Bundle ID**: com.example.hotelMobile

#### Facebook App:
- **App ID**: 1361581552264816
- **App Name**: Trip Hotel

---

## 🔧 CÁC BƯỚC CẤU HÌNH FIREBASE AUTHENTICATION

## 🔧 CÁC BƯỚC CẤU HÌNH FIREBASE AUTHENTICATION

### BƯỚC 1: CẤU HÌNH FIREBASE CONSOLE

1. **Truy cập Firebase Console:**
   - URL: https://console.firebase.google.com/project/trip-hotel
   - Chọn project "trip-hotel"

2. **Bật Authentication:**
   - Vào Authentication > Sign-in method
   - Bật các provider: Google, Facebook, Email/Password

3. **Cấu hình Google Sign-In:**
   - Nhấn "Google" > Enable
   - Project support email: email của bạn
   - Tự động được cấu hình với Firebase

4. **Cấu hình Facebook Sign-In:**
   - Nhấn "Facebook" > Enable
   - App ID: `1361581552264816`
   - App Secret: (lấy từ Facebook Developer Console)
   - OAuth redirect URI: Copy URL này để dán vào Facebook App

### BƯỚC 2: CẤU HÌNH FACEBOOK DEVELOPER CONSOLE

1. **Truy cập Facebook Developer:**
   - URL: https://developers.facebook.com/apps/1361581552264816/

2. **Thêm OAuth Redirect URI:**
   - Vào Facebook Login > Settings
   - Paste OAuth redirect URI từ Firebase Console
   - Format: `https://trip-hotel.firebaseapp.com/__/auth/handler`

3. **Cấu hình Platform Android:**
   - Vào Settings > Basic > Add Platform > Android
   - Package Name: `com.example.hotel_mobile`
   - Class Name: `com.example.hotel_mobile.MainActivity`
   - Key Hashes: (xem bước 3)

4. **Cấu hình Platform iOS:**
   - Add Platform > iOS
   - Bundle ID: `com.example.hotelMobile`

### BƯỚC 3: TẠO KEY HASH CHO ANDROID

**Cách 1: Sử dụng Script đã tạo sẵn**
```bash
cd d:\DACN\baocao\hotel_mobile
./generate_sha1.bat
```

**Cách 2: Manual (cần OpenSSL)**
```bash
# Debug Key Hash
keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android -keypass android | openssl sha1 -binary | openssl base64
```

**Windows:**
```cmd
keytool -exportcert -alias androiddebugkey -keystore "%USERPROFILE%\.android\debug.keystore" -storepass android -keypass android | openssl sha1 -binary | openssl base64
```

Copy kết quả vào Facebook Developer Console > Android Platform > Key Hashes.

### BƯỚC 4: CẤU HÌNH APP FILES

#### Android (Đã hoàn thành ✅):
- `android/app/google-services.json` - Firebase config
- `android/build.gradle.kts` - Google Services plugin
- `android/app/build.gradle.kts` - Apply plugin

#### iOS (Cần hoàn thiện):
- Download `GoogleService-Info.plist` từ Firebase Console
- Thay thế file template hiện tại
- Cấu hình URL schemes trong `Info.plist`

#### Flutter (Đã hoàn thành ✅):
- `lib/firebase_options.dart` - Firebase configuration
- `lib/core/services/google_auth_service.dart` - Google Auth
- `lib/core/services/facebook_auth_service.dart` - Facebook Auth
- `lib/presentation/widgets/google_signin_button.dart` - Google UI
- `lib/presentation/widgets/facebook_login_button.dart` - Facebook UI

---

## 🎯 CÁCH SỬ DỤNG AUTHENTICATION

### 1. Google Sign-In Flow:
```
User clicks Google button 
→ Firebase Auth 
→ Google OAuth 
→ Firebase User 
→ App Login Success
```

### 2. Facebook Sign-In Flow:
```
User clicks Facebook button 
→ Facebook OAuth 
→ Firebase Auth 
→ Firebase User 
→ App Login Success
```

### 3. Email/Password Flow:
```
User enters credentials 
→ Firebase Auth 
→ Firebase User 
→ App Login Success
```

---

## 📱 TEST TRÊN CÁC PLATFORM

## 📱 TEST TRÊN CÁC PLATFORM

### Android (Recommended):
```bash
# Enable Developer Mode first
start ms-settings:developers

# Build and run
cd d:\DACN\baocao\hotel_mobile
flutter run -d android
```

### iOS (Cần MacOS):
```bash
flutter run -d ios
```

### Web (Debug only):
```bash
flutter run -d chrome --web-port=8080
```

---

## � ƯU ĐIỂM CỦA FIREBASE AUTHENTICATION

### 1. **Tập trung hóa:**
- Quản lý tất cả authentication ở một nơi
- Không cần setup riêng cho từng provider
- Dễ dàng thêm provider mới

### 2. **Bảo mật cao:**
- Firebase handle OAuth flow
- Automatic token refresh
- Secure session management

### 3. **Dễ integration:**
- Flutter plugins chính thức
- Cross-platform support
- Real-time user state changes

### 4. **Analytics & Monitoring:**
- User analytics trong Firebase Console
- Authentication metrics
- Error tracking

---

## �🚨 LƯU Ý QUAN TRỌNG

### Development:
1. **Facebook App Mode**: Để ở "Development" và thêm test users
2. **Key Hash**: Sử dụng debug keystore hash
3. **Domains**: `localhost` cho development

### Production:
1. **Facebook App Mode**: Chuyển sang "Live"
2. **Key Hash**: Sử dụng release keystore hash
3. **Domains**: Domain thật của app
4. **Privacy Policy**: URL thật
5. **Terms of Service**: URL thật

### Firebase Security:
1. **Firestore Rules**: Cấu hình security rules
2. **API Keys**: Restrict API keys theo domain/app
3. **Auth Domain**: Chỉ cho phép domain được verify

---

## 🔍 DEBUG & TROUBLESHOOTING

### Lỗi Google Sign-In:
```
❌ "PlatformException(sign_in_failed)"
✅ Kiểm tra: SHA-1 fingerprint trong Firebase Console
✅ Kiểm tra: google-services.json đúng chưa
✅ Kiểm tra: Package name khớp chưa
```

### Lỗi Facebook Sign-In:
```
❌ "Invalid key hash"
✅ Chạy lại generate_sha1.bat
✅ Copy key hash vào Facebook Developer Console
✅ Kiểm tra App Mode (Development/Live)
```

### Lỗi Firebase:
```
❌ "Firebase not initialized"
✅ Kiểm tra: firebase_options.dart
✅ Kiểm tra: Firebase.initializeApp() trong main.dart
✅ Kiểm tra: Dependencies trong pubspec.yaml
```

### Debug Commands:
```bash
# Check dependencies
flutter pub deps

# Analyze code
flutter analyze

# Clean build
flutter clean && flutter pub get

# Check Firebase connection
flutter run --debug
# Xem logs để kiểm tra Firebase initialization
```

---

## � KIỂM TRA THÀNH CÔNG

### ✅ Checklist hoàn thành:

#### Firebase Console:
- [ ] Authentication providers enabled (Google, Facebook, Email)
- [ ] Android app added với đúng package name
- [ ] iOS app added với đúng bundle ID
- [ ] Web app added (optional)

#### Facebook Developer Console:
- [ ] OAuth redirect URI từ Firebase added
- [ ] Android platform với đúng package name
- [ ] Key hash added
- [ ] iOS platform với đúng bundle ID

#### Flutter App:
- [ ] `google-services.json` trong `android/app/`
- [ ] `GoogleService-Info.plist` trong `ios/Runner/`
- [ ] Firebase initialized trong `main.dart`
- [ ] Auth services working
- [ ] UI buttons working

#### Test Results:
- [ ] Google Sign-In works on Android
- [ ] Facebook Sign-In works on Android
- [ ] Email/Password works
- [ ] User state persistence works
- [ ] Sign-out works properly

---

## 🎯 NEXT STEPS

1. **Backend Integration:**
   - Sync Firebase Users với backend database
   - Implement user profile management
   - Add role-based permissions

2. **Enhanced Features:**
   - Email verification
   - Password reset
   - Phone number authentication
   - Anonymous sign-in for guests

3. **Production Ready:**
   - Setup proper Firestore security rules
   - Configure production OAuth settings
   - Add proper error handling
   - Implement user feedback systems

---

**🎉 Chúc mừng! Bạn đã có hệ thống authentication hoàn chỉnh với Firebase!**