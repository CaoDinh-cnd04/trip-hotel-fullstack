# 🏨 Hotel Mobile Booking App

Ứng dụng mobile đặt phòng khách sạn và homestay được xây dựng bằng Flutter, kết nối với backend Node.js và SQL Server.

## 📋 Mục lục

- [Tổng quan dự án](#-tổng-quan-dự-án)
- [Tính năng chính](#-tính-năng-chính)
- [Thư viện sử dụng](#-thư-viện-sử-dụng)
- [Cài đặt và chạy dự án](#-cài-đặt-và-chạy-dự-án)
- [Cấu trúc dự án](#-cấu-trúc-dự-án)
- [API Endpoints](#-api-endpoints)
- [Screenshots](#-screenshots)

## 🎯 Tổng quan dự án

### Kiến trúc hệ thống:
- **Frontend**: Flutter (Cross-platform mobile app)
- **Backend**: Node.js + Express.js
- **Database**: SQL Server
- **Authentication**: Firebase Auth (Google, Facebook)
- **Payment**: VNPay, VietQR
- **Maps**: Google Maps

### Mục tiêu:
Xây dựng ứng dụng đặt phòng khách sạn hoàn chỉnh với giao diện thân thiện, tích hợp thanh toán và bản đồ.

## ✨ Tính năng chính

### 🔐 1. Xác thực người dùng
- [x] Đăng ký tài khoản bằng email
- [x] Đăng nhập Google
- [x] Đăng nhập Facebook  
- [x] Quên mật khẩu (reset qua email)
- [x] Quản lý hồ sơ cá nhân

### 🏠 2. Tìm kiếm & Khám phá
- [x] Tìm kiếm khách sạn theo địa điểm, ngày, số người
- [x] Bộ lọc nâng cao (giá, rating, tiện nghi)
- [x] Hiển thị trên bản đồ với pins
- [x] Gợi ý địa điểm hot
- [x] Lịch sử tìm kiếm và bookmark

### 🛏️ 3. Hiển thị khách sạn
- [x] Gallery hình ảnh với carousel slider
- [x] Thông tin chi tiết (mô tả, tiện nghi, chính sách)
- [x] Đánh giá và ratings từ khách hàng
- [x] So sánh giá theo ngày
- [x] Chia sẻ khách sạn
- [x] Thêm vào danh sách yêu thích

### 📅 4. Đặt phòng
- [x] Chọn ngày check-in/out với calendar
- [x] Chọn số lượng khách (người lớn, trẻ em)
- [x] Chọn loại phòng và số phòng
- [x] Tính toán giá real-time (thuế, phí)
- [x] Áp dụng mã giảm giá và khuyến mãi
- [x] Xác nhận thông tin khách hàng

### 💳 5. Thanh toán
- [x] VNPay integration
- [x] VietQR payment
- [x] Lưu thông tin thanh toán
- [x] Hóa đơn điện tử
- [x] Hoàn tiền tự động

### 🔔 6. Thông báo
- [x] Push notifications (booking updates, promotions)
- [x] In-app messaging với hotel
- [x] Email confirmations

### 🗺️ 7. Bản đồ & Định vị
- [x] Google Maps tích hợp
- [x] Hiển thị vị trí khách sạn
- [x] Chỉ đường GPS đến khách sạn

### 📊 8. Lịch sử & Quản lý
- [x] Lịch sử đặt phòng (completed, upcoming, cancelled)
- [x] Chi tiết booking với QR code
- [x] Modify/Cancel booking
- [x] Download voucher/invoice

## 📦 Thư viện sử dụng

### Core Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # UI Components
  cupertino_icons: ^1.0.8
  flutter_screenutil: ^5.9.0
  animations: ^2.0.8
  lottie: ^2.7.0
  shimmer: ^3.0.0

  # State Management
  flutter_bloc: ^8.1.3
  provider: ^6.1.1

  # Networking
  dio: ^5.4.0
  dio_cache_interceptor: ^3.5.0
  connectivity_plus: ^5.0.2

  # Authentication
  firebase_auth: ^4.15.0
  google_sign_in: ^6.1.5
  flutter_facebook_auth: ^6.0.4

  # Maps & Location
  google_maps_flutter: ^2.5.0
  geolocator: ^10.1.0
  geocoding: ^2.1.1

  # Payment (Vietnam)
  vnpay_flutter: ^1.0.8

  # Media & Images
  cached_network_image: ^3.3.0
  carousel_slider: ^4.2.1
  flutter_staggered_grid_view: ^0.7.0

  # Date & Calendar
  table_calendar: ^3.0.9
  intl: ^0.18.1

  # Storage
  shared_preferences: ^2.2.2
  hive: ^2.2.3

  # Notifications
  firebase_messaging: ^14.7.6
  flutter_local_notifications: ^16.3.0

  # Utils
  qr_flutter: ^4.1.0
  share_plus: ^7.2.1
  url_launcher: ^6.2.1
  flutter_rating_bar: ^4.0.1

  # Forms
  flutter_form_builder: ^9.1.1
  form_builder_validators: ^9.1.0

  # Search
  searchfield: ^0.8.5
  flutter_typeahead: ^4.8.0
```

## 🚀 Cài đặt và chạy dự án

### Yêu cầu hệ thống:
- Flutter SDK >= 3.9.2
- Dart SDK >= 3.0.0
- Android Studio / VS Code
- Node.js >= 14.x (cho backend)
- SQL Server (cho database)

### 1. Clone repository
```bash
git clone [repository-url]
cd hotel_mobile
```

### 2. Cài đặt Flutter dependencies
```bash
flutter pub get
```

### 3. Cấu hình Firebase
1. Tạo project trên [Firebase Console](https://console.firebase.google.com/)
2. Thêm Android/iOS app vào project
3. Tải về `google-services.json` (Android) và `GoogleService-Info.plist` (iOS)
4. Đặt files vào thư mục tương ứng:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`

### 4. Cấu hình Google Maps API
1. Tạo API key tại [Google Cloud Console](https://console.cloud.google.com/)
2. Enable Google Maps SDK for Android/iOS
3. Thêm API key vào:

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<meta-data 
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY"/>
```

**iOS** (`ios/Runner/AppDelegate.swift`):
```swift
GMSServices.provideAPIKey("YOUR_API_KEY")
```

### 5. Cấu hình Social Login

#### Google Sign-In:
- Tải `google-services.json` từ Firebase Console
- Thêm SHA-1 fingerprint vào Firebase project

#### Facebook Login:
1. Tạo app tại [Facebook Developers](https://developers.facebook.com/)
2. Thêm App ID vào `android/app/src/main/res/values/strings.xml`:
```xml
<string name="facebook_app_id">YOUR_FACEBOOK_APP_ID</string>
```

### 6. Setup Backend (Node.js)
```bash
cd ../hotel-booking-backend
npm install
```

Tạo file `.env`:
```env
# Database
DB_SERVER=localhost
DB_PORT=1433
DB_DATABASE=khach_san
DB_USER=sa
DB_PASSWORD=123
DB_USE_WINDOWS_AUTH=false
DB_ENCRYPT=false
DB_TRUST_SERVER_CERTIFICATE=true

# JWT
JWT_SECRET=your_jwt_secret_here
JWT_EXPIRES_IN=24h

# VNPay
VNPAY_TMN_CODE=your_vnpay_tmn_code
VNPAY_SECRET_KEY=your_vnpay_secret
VNPAY_URL=https://sandbox.vnpayment.vn/paymentv2/vpcpay.html
VNPAY_RETURN_URL=http://localhost:5000/api/v2/vnpay/return

# Server
PORT=5000
NODE_ENV=development
```

### 7. Setup Database (SQL Server)
1. Cài đặt SQL Server
2. Tạo database `khach_san`
3. Chạy script SQL để tạo tables (xem file `/database/schema.sql`)

### 8. Chạy dự án

#### Backend:
```bash
cd hotel-booking-backend
npm run dev
```
Server sẽ chạy tại: `http://localhost:5000`

#### Mobile App:
```bash
cd hotel_mobile
flutter run
```

### 9. Build cho Production

#### Android APK:
```bash
flutter build apk --release
```

#### iOS:
```bash
flutter build ios --release
```

## 📁 Cấu trúc dự án

```
hotel_mobile/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   ├── utils/
│   │   └── theme/
│   ├── data/
│   │   ├── models/
│   │   ├── repositories/
│   │   └── services/
│   ├── presentation/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── bloc/
│   └── main.dart
├── assets/
│   ├── images/
│   ├── icons/
│   └── fonts/
├── android/
├── ios/
└── pubspec.yaml
```

## 🌐 API Endpoints

### Authentication
- `POST /api/v2/auth/register` - Đăng ký
- `POST /api/v2/auth/login` - Đăng nhập
- `POST /api/v2/auth/forgot-password` - Quên mật khẩu

### Hotels
- `GET /api/v2/khachsan` - Lấy danh sách khách sạn
- `GET /api/v2/khachsan/:id` - Chi tiết khách sạn
- `GET /api/v2/khachsan/search` - Tìm kiếm khách sạn

### Bookings
- `POST /api/v2/phieudatphong` - Tạo booking
- `GET /api/v2/phieudatphong/user/:id` - Lịch sử booking
- `PUT /api/v2/phieudatphong/:id` - Cập nhật booking

### Payment
- `POST /api/v2/vnpay/create-payment` - Tạo payment URL
- `GET /api/v2/vnpay/return` - VNPay callback

## 📱 Screenshots

_Sẽ được cập nhật sau khi hoàn thành UI_

## 🤝 Đóng góp

1. Fork project
2. Tạo feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.


---
**Đồ án chuyên ngành - Ứng dụng đặt phòng khách sạn**
