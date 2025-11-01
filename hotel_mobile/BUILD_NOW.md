# Hướng dẫn Build Ngay

## Đã tối ưu:
✅ Giảm Gradle heap: 3GB → 1.5GB  
✅ Giảm MaxMetaspaceSize: 512m → 256m  
✅ Workers: 1 (build tuần tự)  
✅ NDK: chỉ build x86_64 cho emulator  
✅ Dừng các Gradle daemon cũ  

## Build ngay:

```powershell
cd hotel_mobile

# Dừng các process cũ (nếu có)
Get-Process | Where-Object {$_.ProcessName -like "*java*"} | Stop-Process -Force -ErrorAction SilentlyContinue

# Build
flutter run
```

## Nếu vẫn thiếu RAM:

### Option 1: Build release (nhẹ hơn debug)
```powershell
flutter run --release
```

### Option 2: Build APK rồi cài
```powershell
flutter build apk --debug
# Sau đó cài file: build/app/outputs/flutter-apk/app-debug.apk
```

### Option 3: Giảm heap xuống 1GB (nếu RAM < 4GB)
Sửa `android/gradle.properties`:
```
org.gradle.jvmargs=-Xmx1024M -XX:MaxMetaspaceSize=256m ...
```

### Option 4: Đóng ứng dụng khác
- Đóng Chrome/Edge (chiếm nhiều RAM)
- Đóng Android Studio (nếu không dùng)
- Đóng VS Code (nếu có thể)

## Kiểm tra RAM:
Mở Task Manager (Ctrl+Shift+Esc) → Xem tab Performance → Memory

Nếu RAM < 2GB free → Cần giải phóng hoặc tăng Virtual Memory

