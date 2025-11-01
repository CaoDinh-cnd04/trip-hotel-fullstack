# Hướng dẫn giải phóng dung lượng ổ đĩa cho Flutter Build

## Lỗi: "There is not enough space on the disk"

Nếu bạn gặp lỗi này, hãy làm theo các bước sau:

### 1. Xóa cache và build files

```bash
# Trong thư mục hotel_mobile
flutter clean

# Xóa Gradle cache
cd android
rmdir /s /q .gradle
cd app
rmdir /s /q build
cd ..

# Xóa Flutter build
cd ..
rmdir /s /q build
```

### 2. Xóa thêm cache nếu vẫn thiếu dung lượng

```bash
# Xóa Flutter pub cache (cẩn thận - sẽ phải tải lại packages)
flutter pub cache clean

# Xóa Gradle cache toàn hệ thống (Windows)
# Vào: C:\Users\<YourUsername>\.gradle\caches
# Xóa thư mục này (sẽ làm chậm build lần đầu)

# Xóa Android SDK cache (cẩn thận)
# Vào: C:\Users\<YourUsername>\AppData\Local\Android\Sdk\.android
```

### 3. Tăng dung lượng ổ đĩa

- Xóa các file không cần thiết
- Di chuyển project sang ổ đĩa khác có nhiều dung lượng hơn
- Dọn dẹp ổ đĩa Windows (Disk Cleanup)

### 4. Build lại

```bash
cd hotel_mobile
flutter pub get
flutter run
```

## Lưu ý

- Flutter build có thể chiếm 5-10GB dung lượng
- Gradle cache có thể chiếm thêm 1-2GB
- Đảm bảo có ít nhất 15GB dung lượng trống


