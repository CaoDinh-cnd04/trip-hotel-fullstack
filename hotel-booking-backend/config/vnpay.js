/**
 * ============================================
 * VNPay Payment Gateway Configuration
 * ============================================
 * 
 * SANDBOX TEST ENVIRONMENT:
 * - Payment URL: https://sandbox.vnpayment.vn/paymentv2/vpcpay.html
 * - Merchant Admin: https://sandbox.vnpayment.vn/merchantv2/
 * - Login: dcao52862@gmail.com
 * - Documentation: https://sandbox.vnpayment.vn/apis/docs/thanh-toan-pay/pay.html
 * 
 * MERCHANT CREDENTIALS (VNPay đã cấp):
 * - Terminal ID: M0O5UJ08
 * - Hash Secret: 2EUDNGDHMR3DNHY7IZY1AIBOKB35JFE3
 * - Public IP: 42.114.148.78:5000
 * - Return URL: http://42.114.148.78:5000/api/payment/vnpay-return (ĐÃ ĐĂNG KÝ)
 * - IPN URL: http://42.114.148.78:5000/api/payment/vnpay-ipn (ĐÃ ĐĂNG KÝ)
 * 
 * LƯU Ý:
 * - Môi trường SANDBOX TEST - KHÔNG dùng cho thanh toán thật
 * - VNPay KHÔNG chấp nhận localhost - PHẢI dùng public URL
 * - Return URL và IPN URL ĐÃ được đăng ký trong VNPay Merchant Admin
 * - Hash Secret đã được cập nhật: 2EUDNGDHMR3DNHY7IZY1AIBOKB35JFE3
 * 
 * ⚠️ QUAN TRỌNG VỀ IP:
 * - IP 42.114.148.78 chỉ hoạt động khi máy có IP đó
 * - Khi đổi mạng → IP thay đổi → VNPay không callback được
 * - ✅ GIẢI PHÁP: Dùng Cloudflare Tunnel (xem README-VNPAY-URL.md)
 * - Chạy: .\start-cloudflare-and-update-env.ps1 để tự động cập nhật URL
 */

// ============================================
// Load Configuration từ .env (hoặc dùng default đã đăng ký)
// ============================================

const vnp_TmnCode = (process.env.VNP_TMN_CODE || 'M0O5UJ08').trim();
const vnp_HashSecret = (process.env.VNP_HASH_SECRET || '2EUDNGDHMR3DNHY7IZY1AIBOKB35JFE3').trim();
const vnp_Url = process.env.VNP_URL || 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';

// ⚠️ QUAN TRỌNG: Dùng public URL ĐÃ ĐĂNG KÝ với VNPay
const vnp_ReturnUrl = process.env.VNP_RETURN_URL || 'http://42.114.148.78:5000/api/payment/vnpay-return';
const vnp_IpnUrl = process.env.VNP_IPN_URL || 'http://42.114.148.78:5000/api/payment/vnpay-ipn';

// ============================================
// Validation & Security Checks
// ============================================

if (!vnp_TmnCode || vnp_TmnCode.length === 0) {
  console.error('❌ VNPay Error: Terminal Code (VNP_TMN_CODE) is missing!');
  throw new Error('VNPay Terminal Code is required');
}

if (!vnp_HashSecret || vnp_HashSecret.length === 0) {
  console.error('❌ VNPay Error: Hash Secret (VNP_HASH_SECRET) is missing!');
  throw new Error('VNPay Hash Secret is required');
}

if (vnp_HashSecret.length !== 32) {
  console.warn(`⚠️ VNPay Warning: Hash Secret length is ${vnp_HashSecret.length} (expected 32 characters)`);
}

// Kiểm tra localhost (VNPay sẽ reject)
const isLocalhost = vnp_ReturnUrl.includes('localhost') || vnp_ReturnUrl.includes('127.0.0.1');
if (isLocalhost) {
  console.error('');
  console.error('╔════════════════════════════════════════════════════════════╗');
  console.error('║  ⚠️  VNPay Configuration ERROR: localhost detected!       ║');
  console.error('╠════════════════════════════════════════════════════════════╣');
  console.error('║  VNPay KHÔNG chấp nhận localhost/127.0.0.1                ║');
  console.error('║  Return URL hiện tại:', vnp_ReturnUrl.padEnd(35), '║');
  console.error('║                                                            ║');
  console.error('║  💡 GIẢI PHÁP:                                            ║');
  console.error('║  1. Mở file .env                                          ║');
      console.error('║  2. Set: VNP_RETURN_URL=http://42.114.148.78:5000/api/... ║');
      console.error('║  3. Set: VNP_IPN_URL=http://42.114.148.78:5000/api/...    ║');
  console.error('║  4. Restart server                                        ║');
  console.error('╚════════════════════════════════════════════════════════════╝');
  console.error('');
}

// ============================================
// Log Configuration (For Debugging)
// ============================================

console.log('');
console.log('🔐 ═══════════════════════════════════════════════════════');
console.log('   VNPay Payment Gateway Configuration');
console.log('═══════════════════════════════════════════════════════');
console.log('✅ Terminal Code:', vnp_TmnCode);
console.log('✅ Hash Secret:', vnp_HashSecret.substring(0, 8) + '...' + vnp_HashSecret.substring(24), `(${vnp_HashSecret.length} chars)`);
console.log('✅ Payment URL:', vnp_Url);
console.log(isLocalhost ? '❌' : '✅', 'Return URL:', vnp_ReturnUrl);
console.log(isLocalhost ? '❌' : '✅', 'IPN URL:', vnp_IpnUrl);
console.log('───────────────────────────────────────────────────────');
console.log('📝 Source:', process.env.VNP_RETURN_URL ? '.env file' : 'default config');
if (!isLocalhost) {
  console.log('✅ VNPay Config OK - Ready for payment processing');
} else {
  console.log('⚠️  VNPay Config ERROR - localhost detected!');
}
console.log('═══════════════════════════════════════════════════════');
console.log('');

// ============================================
// Export Configuration
// ============================================

module.exports = {
  // Merchant Credentials (VNPay đã cấp)
  vnp_TmnCode,       
  vnp_HashSecret,    
  
  // VNPay API URLs
  vnp_Url,           
  vnp_ReturnUrl,     
  vnp_IpnUrl,        
  
  // VNPay Query API (Kiểm tra trạng thái giao dịch)
  vnp_Api: 'https://sandbox.vnpayment.vn/merchant_webapi/api/transaction',
  
  // Payment Parameters
  vnp_Version: '2.1.0',    // VNPay API version
  vnp_Command: 'pay',      // Command type
  vnp_CurrCode: 'VND',     // Currency code
  vnp_Locale: 'vn',        // Language: 'vn' hoặc 'en'
  vnp_ExpireTime: 15,      // Payment timeout (phút)
};

