/**
 * Cấu hình VNPay Payment Gateway
 * 
 * MÔI TRƯỜNG SANDBOX TEST:
 * - URL: https://sandbox.vnpayment.vn/paymentv2/vpcpay.html
 * - Đăng ký tài khoản: https://sandbox.vnpayment.vn/devreg/
 * - Sau khi đăng ký, VNPay sẽ gửi email với TMN_CODE và HASH_SECRET
 * 
 * LƯU Ý:
 * - Các giá trị dưới đây là EXAMPLE - bạn cần đăng ký tài khoản thật
 * - Đặt VNP_TMN_CODE và VNP_HASH_SECRET trong file .env
 * 
 * THẺ TEST:
 * - Bạn sẽ nhận được thông tin thẻ test từ VNPay
 * - Thông thường: số thẻ test và OTP để xác thực
 */

module.exports = {
  // Thông tin merchant (TỪ VNP CUNG CẤP SAU KHI ĐĂNG KÝ)
  vnp_TmnCode: process.env.VNP_TMN_CODE || 'M005UJ08', // ✅ Your TMN Code
  vnp_HashSecret: process.env.VNP_HASH_SECRET || '3B6KILIZOVODCHEVY6CFF', // ✅ Your Hash Secret
  
  // URL của VNPay
  vnp_Url: process.env.VNP_URL || 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html',
  
  // URL return sau khi thanh toán (backend)
  vnp_ReturnUrl: process.env.VNP_RETURN_URL || 'http://localhost:5000/api/payment/vnpay-return',
  
  // Cấu hình khác
  vnp_Api: 'https://sandbox.vnpayment.vn/merchant_webapi/api/transaction',
  vnp_Version: '2.1.0',
  vnp_Command: 'pay',
  vnp_CurrCode: 'VND',
  vnp_Locale: 'vn', // 'vn' hoặc 'en'
  
  // Timeout (phút)
  vnp_ExpireTime: 15,
};

