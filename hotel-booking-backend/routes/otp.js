const express = require('express');
const router = express.Router();
const otpController = require('../controllers/otpController');

// Gửi mã OTP
router.post('/send-otp', otpController.sendOTP);

// Xác thực mã OTP
router.post('/verify-otp', otpController.verifyOTP);

// Gửi lại mã OTP
router.post('/resend-otp', otpController.resendOTP);

// Clean expired OTPs (admin only - có thể gọi định kỳ)
router.post('/clean-expired', otpController.cleanExpiredOTPs);

module.exports = router;
