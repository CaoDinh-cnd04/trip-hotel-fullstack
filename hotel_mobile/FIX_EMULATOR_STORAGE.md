# Fix Lỗi "INSTALL_FAILED_INSUFFICIENT_STORAGE" trên Emulator

## Vấn đề:
Android Emulator không có đủ dung lượng để cài đặt APK.

## Giải pháp:

### 1. Xóa app cũ (đã thử):
```powershell
adb shell pm uninstall com.example.hotel_mobile
```

### 2. Xóa cache/data trên emulator:
```powershell
# Xóa cache của app (nếu đã cài)
adb shell pm clear com.example.hotel_mobile

# Xóa cache của các app khác để giải phóng dung lượng
adb shell pm trim-caches 500M
```

### 3. Tăng dung lượng Emulator:
1. Mở **Android Studio** → **Tools** → **Device Manager**
2. Chọn emulator → Click **Edit** (biểu tượng bút chì)
3. **Show Advanced Settings**
4. Tăng **Internal Storage** lên **4GB** hoặc **8GB**
5. Click **Finish** → **Next** → **Finish**
6. **Wipe Data** và restart emulator

### 4. Xóa app không cần thiết trên emulator:
```powershell
# Xem tất cả app
adb shell pm list packages

# Xóa các app mẫu (nếu có)
adb shell pm uninstall -k --user 0 com.android.browser
adb shell pm uninstall -k --user 0 com.android.email
# (cẩn thận - chỉ xóa app mẫu, không xóa system apps)
```

### 5. Giảm kích thước APK:
Đã tối ưu trong `build.gradle.kts`, nhưng có thể:
- Build release thay vì debug (nhẹ hơn)
- Chỉ build cho architecture cần thiết

### 6. Dùng thiết bị thật:
Nếu emulator vẫn thiếu dung lượng, dùng thiết bị Android thật.

### 7. Recreate Emulator:
1. Xóa emulator cũ
2. Tạo emulator mới với:
   - Internal Storage: **4GB+**
   - SD Card: **512MB**
   - RAM: **2GB+**

## Build lại sau khi fix:
```powershell
cd hotel_mobile
flutter clean
flutter run
```

## Kiểm tra dung lượng:
```powershell
# Xem dung lượng còn lại
adb shell df -h /data

# Nên có ít nhất 500MB trống
```

