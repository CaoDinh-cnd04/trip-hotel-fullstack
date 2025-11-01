# Hướng dẫn Fix Lỗi "Insufficient Memory" khi Build Flutter

## Vấn đề
```
There is insufficient memory for the Java Runtime Environment to continue.
Native memory allocation (malloc) failed to allocate 1048576 bytes.
```

## Đã thực hiện:
1. ✅ Giảm Gradle heap size từ 3GB → 1.5GB
2. ✅ Giảm MaxMetaspaceSize từ 512m → 256m
3. ✅ Giới hạn workers.max = 1 (build tuần tự)
4. ✅ Tối ưu NDK chỉ build cho x86_64 (emulator)
5. ✅ Đã dừng các Gradle daemon cũ

## Các bước tiếp theo:

### 1. Đóng các ứng dụng khác
- Đóng các ứng dụng không cần thiết để giải phóng RAM
- Chrome, VS Code, Android Studio (nếu không dùng) chiếm nhiều RAM

### 2. Tăng Virtual Memory (Page File) trên Windows
1. Mở **System Properties** → **Advanced** → **Performance Settings**
2. Chọn **Advanced** tab → **Virtual Memory** → **Change**
3. Tăng **Initial size** và **Maximum size** lên 4096 MB hoặc hơn
4. Click **Set** → **OK** → Restart

### 3. Build lại với clean:
```powershell
cd hotel_mobile

# Dừng tất cả Gradle daemon
Get-Process | Where-Object {$_.ProcessName -like "*java*" -or $_.ProcessName -like "*gradle*"} | Stop-Process -Force -ErrorAction SilentlyContinue

# Clean và build
flutter clean
flutter pub get
flutter run
```

### 4. Nếu vẫn lỗi, thử build release (nhẹ hơn debug):
```powershell
flutter run --release
```

### 5. Hoặc build APK trực tiếp:
```powershell
flutter build apk --debug
```

## Kiểm tra RAM hiện tại:
```powershell
# Xem RAM đang dùng
Get-CimInstance Win32_OperatingSystem | Select-Object TotalVisibleMemorySize, FreePhysicalMemory

# Hoặc dùng Task Manager (Ctrl+Shift+Esc)
```

## Nếu máy có ít RAM (< 8GB):
- Giảm heap size xuống còn 1024M trong `gradle.properties`
- Tắt hết ứng dụng không cần thiết
- Chỉ build trên emulator, không chạy Android Studio cùng lúc

