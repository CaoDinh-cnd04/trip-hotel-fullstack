/**
 * Cấu hình MoMo Payment Gateway
 * 
 * MÔI TRƯỜNG TEST:
 * - API: https://test-payment.momo.vn/v2/gateway/api/create
 * - Đây là credentials TEST (sandbox)
 * - Production sẽ có credentials khác
 * 
 * LƯU Ý:
 * - Credentials này từ file .env
 * - Đảm bảo .env được load đúng
 */

module.exports = {
  // Thông tin merchant (từ MoMo cung cấp)
  partnerCode: process.env.MOMO_PARTNER_CODE || 'MOMO',
  accessKey: process.env.MOMO_ACCESS_KEY || 'F8BBA842ECF85',
  secretKey: process.env.MOMO_SECRET_KEY || 'K951B6PE1waDMi640xX08PD3vg6EkVlz', // ✅ Test credentials
  
  // MoMo API endpoint
  apiEndpoint: process.env.MOMO_API_ENDPOINT || 'https://test-payment.momo.vn/v2/gateway/api/create',
  
  // URL return sau khi thanh toán (backend)
  returnUrl: process.env.MOMO_RETURN_URL || 'http://localhost:5000/api/payment/momo-return',
  
  // IPN (Instant Payment Notification) - callback từ MoMo
  ipnUrl: process.env.MOMO_IPN_URL || 'http://localhost:5000/api/payment/momo-ipn',
  
  // Request type
  requestType: 'captureWallet', // hoặc 'payWithATM', 'payWithCC'
  
  // Language
  lang: 'vi', // 'vi' hoặc 'en'
  
  // Auto capture (tự động capture payment sau khi authorize)
  autoCapture: true,
};

