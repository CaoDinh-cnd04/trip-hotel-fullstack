# Hướng dẫn Tích hợp VNPay Native SDK (Tùy chọn)

## Lưu ý:
App hiện tại đã hoạt động với **WebView** cho thanh toán VNPay. Native SDK chỉ là tùy chọn để có trải nghiệm tốt hơn trên thiết bị thật.

## Nếu muốn tích hợp Native SDK:

### 1. Copy AAR file:
```powershell
# Copy file từ sample project
Copy-Item "Sample_Android_Native_Mobile SDK_1.0.25\example\app\libs\merchant-1.0.25.aar" `
          -Destination "hotel_mobile\android\app\libs\merchant-1.0.25.aar"
```

### 2. Uncomment code trong MainActivity.kt:
- Dòng 15-17: Uncomment imports VNPay
- Dòng 53-117: Uncomment method `openVnPaySdk()`
- Dòng 30-36: Sửa lại method handler để gọi `openVnPaySdk()`

### 3. Build lại:
```powershell
cd hotel_mobile
flutter clean
flutter pub get
flutter run
```

## Hiện tại:
✅ App đã hoạt động với WebView  
✅ Tự động phát hiện emulator và dùng WebView  
✅ Code Native SDK đã sẵn sàng, chỉ cần uncomment khi có AAR file  

