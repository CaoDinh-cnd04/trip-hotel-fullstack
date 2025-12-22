/**
 * Cấu hình MoMo Payment Gateway
 * 
 * MÔI TRƯỜNG TEST:
 * - API: https://test-payment.momo.vn/v2/gateway/api/create
 * 
 * ⚠️ QUAN TRỌNG VỀ CREDENTIALS:
 * 
 * Option 1: Test Credentials Công Khai (Mặc định)
 * - Partner Code: MOMO
 * - Access Key: F8BBA842ECF85
 * - Secret Key: K951B6PE1waDMi640xX08PD3vg6EkVlz
 * - ✅ Ưu điểm: Dùng ngay được, không cần đăng ký
 * - ❌ Nhược điểm: Nhiều người cùng dùng, có thể bị giới hạn, không có Partner Scheme ID
 * 
 * Option 2: Credentials Riêng (Khuyến nghị)
 * - Đăng ký tại: https://business.momo.vn
 * - Sau khi đăng ký, lấy credentials riêng và cập nhật vào file .env
 * - ✅ Ưu điểm: Credentials riêng, có Partner Scheme ID, phù hợp cho production
 * 
 * LƯU Ý:
 * - Credentials này từ file .env
 * - Đảm bảo .env được load đúng
 * - Nếu dùng credentials riêng, cập nhật trong file .env
 */

// Đọc config từ .env
const partnerCode = process.env.MOMO_PARTNER_CODE || 'MOMO';
const accessKey = process.env.MOMO_ACCESS_KEY || 'F8BBA842ECF85';
const secretKey = process.env.MOMO_SECRET_KEY || 'K951B6PE1waDMi640xX08PD3vg6EkVlz';
const apiEndpoint = process.env.MOMO_API_ENDPOINT || 'https://test-payment.momo.vn/v2/gateway/api/create';
// ⚠️ QUAN TRỌNG: MoMo KHÔNG chấp nhận localhost - PHẢI dùng public URL
const returnUrl = process.env.MOMO_RETURN_URL || 'http://42.114.148.78:5000/api/payment/momo-return';
const ipnUrl = process.env.MOMO_IPN_URL || 'http://42.114.148.78:5000/api/payment/momo-ipn';

// Validate config
if (!partnerCode || partnerCode.length === 0) {
  console.error('❌ MoMo Config Error: MOMO_PARTNER_CODE is missing or empty!');
}
if (!accessKey || accessKey.length === 0) {
  console.error('❌ MoMo Config Error: MOMO_ACCESS_KEY is missing or empty!');
}
if (!secretKey || secretKey.length === 0) {
  console.error('❌ MoMo Config Error: MOMO_SECRET_KEY is missing or empty!');
}
if (returnUrl.includes('localhost') || returnUrl.includes('127.0.0.1')) {
  console.error('❌ MoMo Config Error: Return URL is localhost!');
  console.error('   MoMo KHÔNG chấp nhận localhost.');
  console.error('   Vui lòng set MOMO_RETURN_URL trong file .env với IP public.');
  console.error('   Ví dụ: MOMO_RETURN_URL=http://42.114.148.78:5000/api/payment/momo-return');
}
if (ipnUrl.includes('localhost') || ipnUrl.includes('127.0.0.1')) {
  console.error('❌ MoMo Config Error: IPN URL is localhost!');
  console.error('   MoMo KHÔNG chấp nhận localhost cho IPN.');
  console.error('   Vui lòng set MOMO_IPN_URL trong file .env với IP public.');
  console.error('   Ví dụ: MOMO_IPN_URL=http://42.114.148.78:5000/api/payment/momo-ipn');
}

// Log config để debug (chỉ log một phần để bảo mật)
console.log('💗 MoMo Config Loaded:');
console.log('   Partner Code:', partnerCode);
console.log('   Access Key:', accessKey);
console.log('   Secret Key Length:', secretKey.length);
console.log('   Secret Key (first 10):', secretKey.substring(0, 10) + '...');
console.log('   Secret Key (last 10):', '...' + secretKey.substring(secretKey.length - 10));
console.log('   API Endpoint:', apiEndpoint);
console.log('   Return URL:', returnUrl);
console.log('   IPN URL:', ipnUrl);

module.exports = {
  // Thông tin merchant (từ MoMo cung cấp)
  // ✅ Đọc từ file .env - Đảm bảo file .env có đúng giá trị
  // MOMO_PARTNER_CODE=MOMO
  // MOMO_ACCESS_KEY=F8BBA842ECF85
  // MOMO_SECRET_KEY=K951B6PE1waDMi640xX08PD3vg6EkVlz
  partnerCode,
  accessKey,
  secretKey, // ✅ Test credentials
  
  // MoMo API endpoint
  // MOMO_API_ENDPOINT=https://test-payment.momo.vn/v2/gateway/api/create
  apiEndpoint,
  
  // URL return sau khi thanh toán (backend)
  // ⚠️ QUAN TRỌNG: MoMo KHÔNG chấp nhận localhost!
  // MOMO_RETURN_URL=http://42.114.148.78:5000/api/payment/momo-return
  returnUrl,
  
  // IPN (Instant Payment Notification) - callback từ MoMo
  // MOMO_IPN_URL=http://42.114.148.78:5000/api/payment/momo-ipn
  ipnUrl,
  
  // Request type
  requestType: 'captureWallet', // hoặc 'payWithATM', 'payWithCC'
  
  // Language
  lang: 'vi', // 'vi' hoặc 'en'
  
  // Auto capture (tự động capture payment sau khi authorize)
  autoCapture: true,
};

