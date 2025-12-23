# 🔑 Fix Google Sign-In Error - Get SHA-1

## ❌ Lỗi hiện tại:
```
PlatformException(sign_in_failed,
com.google.android.gms.common.api.ApiException: 10:, null, null)
```

**Nguyên nhân:** SHA-1 fingerprint trong Firebase chưa đúng (đang là `sha1_placeholder`)

---

## ✅ CÁCH FIX (3 BƯỚC):

### **Bước 1: Lấy SHA-1 Fingerprint**

#### **Cách 1: Dùng Flutter (Đơn giản nhất)**
```bash
cd D:\DACN\baocao\hotel_mobile
flutter doctor -v
```
Tìm dòng: **"Android toolchain"** → Copy đường dẫn Java

Sau đó chạy:
```bash
# Thay <JAVA_PATH> bằng đường dẫn từ flutter doctor
<JAVA_PATH>\bin\keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

#### **Cách 2: Dùng Gradle**
```bash
cd D:\DACN\baocao\hotel_mobile\android
gradlew signingReport
```

Tìm dòng **SHA1:** và copy fingerprint (dạng: `A1:B2:C3:...`)

#### **Cách 3: Tìm thủ công**
1. Mở **Android Studio**
2. Menu: **Build → Generate Signed Bundle / APK**
3. Chọn **APK** → Next
4. Click **"Create new..."** hoặc chọn keystore có sẵn
5. SHA-1 sẽ hiển thị ở góc dưới

---

### **Bước 2: Thêm SHA-1 vào Firebase**

1. Vào **Firebase Console**: https://console.firebase.google.com
2. Chọn project **"trip-hotel"**
3. Vào **Settings** (⚙️) → **Project settings**
4. Scroll xuống → Chọn app **"hotel_mobile (com.example.hotel_mobile)"**
5. Trong phần **"SHA certificate fingerprints"**, click **"Add fingerprint"**
6. **Paste SHA-1** vừa lấy được
7. Click **"Save"**

---

### **Bước 3: Download google-services.json mới**

1. Vẫn ở trang Firebase Console
2. Scroll xuống → Click **"Download google-services.json"**
3. **REPLACE file cũ:**
   ```
   D:\DACN\baocao\hotel_mobile\android\app\google-services.json
   ```
4. **Clean và rebuild:**
   ```bash
   cd D:\DACN\baocao\hotel_mobile
   flutter clean
   flutter pub get
   flutter run
   ```

---

## 🎯 VÍ DỤ SHA-1:

SHA-1 sẽ có dạng:
```
SHA1: A1:B2:C3:D4:E5:F6:01:02:03:04:05:06:07:08:09:0A:1B:2C:3D:4E
```

Copy **TOÀN BỘ** chuỗi này (kể cả `SHA1:` hoặc chỉ phần sau dấu `:`)

---

## ⚠️ LƯU Ý:

1. **Debug vs Release:**
   - Debug keystore: `%USERPROFILE%\.android\debug.keystore`
   - Release keystore: (bạn tự tạo khi build release)
   - Mỗi keystore có SHA-1 **KHÁC NHAU**!

2. **Nhiều SHA-1:**
   - Bạn có thể thêm **NHIỀU SHA-1** vào Firebase
   - Thêm cả debug + release để test trên cả 2 môi trường

3. **Package name phải khớp:**
   - Firebase: `com.example.hotel_mobile`
   - AndroidManifest.xml: `com.example.hotel_mobile`
   - Phải giống nhau 100%!

---

## 🔍 VERIFY:

Sau khi thêm SHA-1 và download file mới, kiểm tra:

```json
// google-services.json
"oauth_client": [
  {
    "client_id": "...",
    "client_type": 1,
    "android_info": {
      "package_name": "com.example.hotel_mobile",
      "certificate_hash": "a1b2c3d4e5f6..."  // ✅ KHÔNG còn "sha1_placeholder"
    }
  }
]
```

---

## 🚀 TEST AGAIN:

```bash
flutter clean
flutter pub get
flutter run
```

Thử đăng nhập bằng Google → Should work! ✅

---

## 📞 NẾU VẪN LỖI:

1. Kiểm tra **Package name** có đúng không
2. Kiểm tra **SHA-1** có đúng không (debug keystore)
3. Đảm bảo đã **download google-services.json MỚI**
4. Chạy `flutter clean` và rebuild

---

**Good luck!** 🎉

