# 📧 Hướng Dẫn Cấu Hình Email Service

## 🎯 Tổng Quan

Email service cho phép gửi:
- ✉️ Mã OTP đăng nhập
- 📬 Xác nhận đặt phòng
- 🔔 Thông báo hệ thống
- 📨 Email bulk cho nhiều người dùng

---

## ⚙️ Cách Bật Email Service

### 1. Sử dụng Gmail (Khuyên dùng)

#### Bước 1: Tạo App Password
1. Truy cập: https://myaccount.google.com/security
2. Bật **"2-Step Verification"** (Xác thực 2 bước)
3. Sau khi bật, vào: https://myaccount.google.com/apppasswords
4. Chọn **"Mail"** và **"Other"** (đặt tên: Hotel Backend)
5. Click **"Generate"** → Copy mã 16 ký tự

#### Bước 2: Cấu Hình Backend

**Cách 1: Sử dụng Environment Variables (Khuyên dùng)**

Tạo file `.env` trong thư mục `hotel-booking-backend/`:

```env
# Email Configuration
EMAIL_ENABLED=true
EMAIL_TEST_MODE=false

# Gmail SMTP
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password-16-digits

# Sender Info
EMAIL_FROM_NAME=Hotel Management System
EMAIL_FROM_EMAIL=your-email@gmail.com
```

**Cách 2: Sửa trực tiếp file config/email.js**

Mở `hotel-booking-backend/config/email.js` và sửa:

```javascript
smtp: {
  host: 'smtp.gmail.com',
  port: 587,
  secure: false,
  auth: {
    user: 'your-email@gmail.com',        // Email của bạn
    pass: 'xxxx xxxx xxxx xxxx'          // App Password 16 ký tự
  }
},

enabled: true,  // Bật email service
testMode: false // Tắt test mode để gửi email thật
```

---

### 2. Sử dụng SMTP Khác

Nếu dùng Outlook, Yahoo, hoặc SMTP tùy chỉnh:

```env
EMAIL_HOST=smtp.office365.com    # Outlook
# EMAIL_HOST=smtp.mail.yahoo.com # Yahoo

EMAIL_PORT=587
EMAIL_USER=your-email@outlook.com
EMAIL_PASS=your-password
```

---

## 🧪 Test Mode

Để test mà không gửi email thật:

```env
EMAIL_ENABLED=true
EMAIL_TEST_MODE=true
```

Khi bật test mode:
- ✅ Email được log ra console
- ❌ Không gửi email thật
- 💡 Dùng để kiểm tra logic mà không spam inbox

---

## 🚀 Khởi Động Lại Backend

Sau khi cấu hình:

```bash
cd hotel-booking-backend
npm start
```

Kiểm tra log:
- ✅ `Email service ready` → Email đã hoạt động
- ❌ `Email service error` → Kiểm tra lại config

---

## 📝 Sử Dụng Email Service

### Gửi OTP
```javascript
const emailService = require('./services/emailService');
await emailService.sendOTPEmail('user@example.com', '123456', 5);
```

### Gửi Xác Nhận Booking
```javascript
await emailService.sendBookingConfirmation('user@example.com', {
  bookingCode: 'BOOK-001',
  hotelName: 'Hanoi Hotel',
  checkInDate: '01/11/2025',
  checkOutDate: '03/11/2025',
  nights: 2,
  totalPrice: '1,000,000'
});
```

### Gửi Thông Báo
```javascript
await emailService.sendNotificationEmail('user@example.com', {
  tieu_de: 'Khuyến mãi đặc biệt',
  noi_dung: 'Giảm 50% cho booking tuần này!',
  link: 'https://hotel.com/promotions'
});
```

---

## ⚠️ Lưu Ý

1. **App Password**: KHÔNG phải password email thường! Phải tạo App Password riêng
2. **2-Step Verification**: Bắt buộc phải bật để tạo App Password
3. **Rate Limiting**: Gmail giới hạn ~500 email/ngày cho tài khoản miễn phí
4. **Security**: KHÔNG commit file .env lên Git!

---

## 🐛 Troubleshooting

### Lỗi: "Invalid login"
→ Kiểm tra App Password có đúng không, không có dấu cách

### Lỗi: "Application-specific password required"
→ Chưa bật 2-Step Verification hoặc chưa tạo App Password

### Email không gửi
→ Kiểm tra `EMAIL_ENABLED=true` và `EMAIL_TEST_MODE=false`

### Emails đi vào Spam
→ Cần cấu hình SPF/DKIM/DMARC (nâng cao, dùng SMTP provider chuyên nghiệp)

---

## 🎁 Email Templates

Email service đã có sẵn 3 templates đẹp:
- 🔐 **OTP Email**: Mã OTP với box nổi bật
- ✅ **Booking Confirmation**: Thông tin booking chi tiết
- 🔔 **Notification**: Thông báo chung với button CTA

Tất cả đều responsive và có gradient background đẹp mắt!

---

## ✅ Quick Start (Gmail)

```bash
# 1. Tạo App Password từ Google Account
# 2. Tạo file .env:
echo "EMAIL_ENABLED=true
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password" > .env

# 3. Khởi động
npm start
```

🎉 Done! Email service đã sẵn sàng!

