# Fix Nhanh: Thiếu Dung Lượng Emulator

## Vấn đề:
Android Emulator không có đủ dung lượng để cài APK.

## Giải pháp nhanh (chọn 1):

### Option 1: Tăng dung lượng Emulator (Khuyên dùng)
1. Mở **Android Studio**
2. **Tools** → **Device Manager**
3. Click emulator → **Edit** (biểu tượng bút chì)
4. **Show Advanced Settings**
5. Tăng **Internal Storage** lên **4GB** hoặc **8GB**
6. **Finish** → **Cold Boot Now**

### Option 2: Xóa cache trên Emulator
Mở emulator → **Settings** → **Storage** → **Free up space**

### Option 3: Build APK nhẹ hơn
```powershell
cd hotel_mobile
flutter build apk --debug --target-platform android-x64
```

### Option 4: Dùng thiết bị thật
Kết nối điện thoại Android → Enable USB Debugging → `flutter run`

### Option 5: Recreate Emulator
1. Xóa emulator cũ
2. Tạo mới với:
   - Internal Storage: **4GB+**
   - RAM: **2GB+**

## Sau khi fix, build lại:
```powershell
cd hotel_mobile
flutter run
```

