# 🏨 Trip Hotel - Full Stack Application

Hệ thống đặt phòng khách sạn full-stack bao gồm ứng dụng mobile Flutter và backend Node.js.

## 📁 Cấu trúc dự án

```
baocao/
├── hotel_mobile/          # Flutter Mobile App
│   ├── lib/
│   │   ├── core/          # Core services, theme
│   │   ├── data/          # Models, repositories
│   │   └── presentation/  # UI screens, widgets
│   ├── android/           # Android configuration
│   ├── ios/              # iOS configuration
│   └── web/              # Web configuration
│
├── hotel-booking-backend/ # Node.js Backend API
│   ├── controllers/       # API controllers
│   ├── models/           # Database models
│   ├── routes/           # API routes
│   ├── middleware/       # Auth, CORS, upload
│   ├── config/           # Database config
│   └── uploads/          # File uploads
│
├── images/               # Shared images/assets
└── README.md            # This file
```

## 🚀 Tech Stack

### 📱 Frontend (Mobile)
- **Framework**: Flutter 3.35.3
- **Language**: Dart 3.5.3
- **State Management**: BLoC Pattern
- **Authentication**: Firebase Auth + Facebook Login
- **UI**: Material Design + Custom components
- **Platforms**: Android, iOS, Web

### 🔧 Backend (API Server)
- **Runtime**: Node.js 16+
- **Framework**: Express.js
- **Database**: SQL Server
- **Authentication**: JWT + Social OAuth
- **File Upload**: Multer
- **API Documentation**: REST API

### 🔗 Integrations
- **Firebase**: Authentication, Analytics
- **Facebook**: Social Login
- **Google**: Sign-In, Maps (future)
- **Payment**: Integration ready

## ✨ Tính năng chính

### 🔐 Authentication & Authorization
- ✅ Email/Password đăng nhập
- ✅ Facebook Login
- ✅ Google Sign-In (Firebase)
- ✅ JWT token management
- ✅ Session persistence
- ✅ User profile management

### 🏨 Hotel Management
- 🔍 Tìm kiếm khách sạn theo location
- 📍 Hiển thị trên bản đồ
- 🖼️ Gallery hình ảnh
- ⭐ Rating và reviews
- 💰 Price comparison
- 📋 Detailed information

### 📱 Booking System
- 📅 Date picker (checkin/checkout)
- 👥 Guest number selection
- 🛏️ Room type selection
- 💳 Payment integration ready
- 📧 Email confirmation
- 📋 Booking management

### 👤 User Features
- 👤 User profile
- 📖 Booking history
- ⭐ Write reviews
- 💝 Favorites list
- 🔔 Notifications

## 🛠️ Cài đặt và chạy

### Prerequisites
```bash
# Flutter SDK
flutter --version  # >= 3.35.3

# Node.js
node --version     # >= 16.x
npm --version      # >= 8.x

# Git
git --version
```

### 🔧 Backend Setup
```bash
# 1. Vào thư mục backend
cd hotel-booking-backend

# 2. Cài đặt dependencies
npm install

# 3. Cấu hình database (config/db.js)
# Cập nhật connection string SQL Server

# 4. Chạy server
npm start
# Server sẽ chạy tại: http://localhost:3000
```

### 📱 Mobile App Setup
```bash
# 1. Vào thư mục mobile
cd hotel_mobile

# 2. Cài đặt dependencies
flutter pub get

# 3. Cấu hình Firebase (xem hướng dẫn bên dưới)

# 4. Chạy app
flutter run
```

## 🔥 Firebase Configuration

### 1. Tạo Firebase Project
1. Vào [Firebase Console](https://console.firebase.google.com)
2. Tạo project mới: "trip-hotel"
3. Enable Authentication với Email/Password và Google

### 2. Android Setup
1. Add Android app với package: `com.example.hotel_mobile`
2. Download `google-services.json`
3. Đặt vào: `hotel_mobile/android/app/google-services.json`

### 3. iOS Setup
1. Add iOS app với bundle ID: `com.example.hotelMobile`
2. Download `GoogleService-Info.plist`
3. Đặt vào: `hotel_mobile/ios/Runner/GoogleService-Info.plist`

### 4. Web Setup
Cập nhật `hotel_mobile/lib/firebase_options.dart` với web config

## 📘 Facebook Login Setup

### 1. Facebook Developer Console
1. Vào [Facebook Developers](https://developers.facebook.com)
2. Tạo app mới với ID: `1361581552264816`
3. Add Android platform:
   - Package: `com.example.hotel_mobile`
   - Key Hash: (generate từ debug keystore)

### 2. Generate Key Hash
```bash
cd hotel_mobile
# Windows
./generate_facebook_keyhash.bat

# Hoặc manual
keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore | openssl sha1 -binary | openssl base64
```

## 🚀 Development Workflow

### 🔄 Daily Development
```bash
# 1. Pull latest changes
git pull origin main

# 2. Backend development
cd hotel-booking-backend
npm run dev

# 3. Mobile development (new terminal)
cd hotel_mobile
flutter run

# 4. Test changes
flutter test
npm test
```

### 📦 Building for Production

#### Android APK
```bash
cd hotel_mobile
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

#### iOS IPA (requires macOS)
```bash
cd hotel_mobile
flutter build ios --release
```

#### Backend Production
```bash
cd hotel-booking-backend
npm run build
npm run start:prod
```

## 🔒 Security & Best Practices

### 🛡️ Security Measures
- ✅ API rate limiting
- ✅ Input validation & sanitization
- ✅ JWT token expiration
- ✅ HTTPS only in production
- ✅ SQL injection prevention
- ✅ XSS protection

### 📝 Files NEVER to commit
- `google-services.json`
- `GoogleService-Info.plist`
- `firebase_options.dart`
- `config/db.js`
- `.env` files
- Keystore files

### 🔑 Environment Variables
```bash
# Backend (.env)
DB_SERVER=your_sql_server
DB_NAME=hotel_booking
DB_USER=your_username
DB_PASSWORD=your_password
JWT_SECRET=your_jwt_secret
FACEBOOK_APP_SECRET=your_facebook_secret

# Mobile (stored in Firebase/Facebook config)
```

## 🧪 Testing

### Backend Testing
```bash
cd hotel-booking-backend
npm test                    # Unit tests
npm run test:integration   # Integration tests
npm run test:e2e          # End-to-end tests
```

### Mobile Testing
```bash
cd hotel_mobile
flutter test              # Unit tests
flutter test integration_test/  # Integration tests
flutter drive --target=test_driver/app.dart  # E2E tests
```

## 📊 Project Status

### ✅ Completed Features
- [x] User authentication (Email, Facebook, Google)
- [x] Hotel listing and search
- [x] User profile management
- [x] Basic booking flow
- [x] API documentation
- [x] Cross-platform mobile app

### 🚧 In Progress
- [ ] Payment integration
- [ ] Push notifications
- [ ] Advanced search filters
- [ ] Admin dashboard
- [ ] Booking management

### 🔮 Future Enhancements
- [ ] Google Maps integration
- [ ] Multiple languages support
- [ ] Dark theme
- [ ] Offline mode
- [ ] Hotel management portal
- [ ] Analytics dashboard

## 🤝 Contributing

### Git Workflow
```bash
# 1. Create feature branch
git checkout -b feature/new-feature

# 2. Make changes and commit
git add .
git commit -m "Add new feature"

# 3. Push and create PR
git push origin feature/new-feature
```

### Code Style
- **Dart**: Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- **JavaScript**: ESLint configuration
- **Commits**: Conventional commits format

## 📞 Support & Contact

### 🐛 Bug Reports
Tạo issue mới với:
- OS và version
- Steps to reproduce
- Expected vs actual behavior
- Screenshots nếu có

### 💡 Feature Requests
Mô tả chi tiết:
- Use case
- Proposed solution
- Alternative solutions
- Additional context

### 📧 Contact
- **Developer**: Your Name
- **Email**: your.email@example.com
- **Project**: Trip Hotel Full Stack

---

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for amazing framework
- Firebase for authentication services
- Node.js community
- All contributors

---

⭐ **Star this repository if you find it helpful!**

🔗 **Repository**: [https://github.com/yourusername/trip-hotel-fullstack](https://github.com/yourusername/trip-hotel-fullstack)