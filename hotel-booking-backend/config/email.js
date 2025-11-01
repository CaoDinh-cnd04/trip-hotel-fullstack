// Email configuration
module.exports = {
  // Gmail SMTP Configuration
  // Để sử dụng Gmail:
  // 1. Bật 2-Step Verification: https://myaccount.google.com/security
  // 2. Tạo App Password: https://myaccount.google.com/apppasswords
  // 3. Thay thế EMAIL_USER và EMAIL_PASS bên dưới
  
  smtp: {
    host: process.env.EMAIL_HOST || 'smtp.gmail.com',
    port: parseInt(process.env.EMAIL_PORT) || 587,
    secure: false, // true for 465, false for other ports
    auth: {
      user: process.env.EMAIL_USER || 'caonhatdinh04@gmail.com',
      pass: process.env.EMAIL_PASS || 'yisrhxtqwjcnbmna'     // Thay bằng App Password
    }
  },
  
  // Email gửi đi mặc định
  from: {
    name: process.env.EMAIL_FROM_NAME || 'Hotel Management System',
    email: process.env.EMAIL_FROM_EMAIL || process.env.EMAIL_USER || 'Trip@hotel.com'
  },
  
  // Bật/tắt email service
  enabled: process.env.EMAIL_ENABLED === 'true' || true, // Bật mặc định
  
  // Chế độ test (chỉ log, không gửi thật)
  testMode: process.env.EMAIL_TEST_MODE === 'true' || false
};

