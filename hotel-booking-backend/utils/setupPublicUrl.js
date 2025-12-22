/**
 * Script để tự động setup public URL
 * Chạy: node utils/setupPublicUrl.js
 */

const { getPublicIP, getPublicUrlFromIP } = require('./getPublicUrl');
const fs = require('fs');
const path = require('path');

async function setupPublicUrl() {
  console.log('🔍 Đang kiểm tra IP public...');
  
  try {
    const publicIP = await getPublicIP();
    console.log('✅ IP public của bạn:', publicIP);
    
    const publicUrl = `http://${publicIP}:5000`;
    console.log('📋 Public URL:', publicUrl);
    
    // Đọc file .env
    const envPath = path.join(__dirname, '..', '.env');
    let envContent = '';
    
    if (fs.existsSync(envPath)) {
      envContent = fs.readFileSync(envPath, 'utf8');
    } else {
      // Nếu không có .env, tạo từ template
      const templatePath = path.join(__dirname, '..', 'env.template');
      if (fs.existsSync(templatePath)) {
        envContent = fs.readFileSync(templatePath, 'utf8');
      } else {
        console.error('❌ Không tìm thấy file .env hoặc env.template');
        return;
      }
    }
    
    // Thay thế localhost bằng IP public (chỉ thay nếu đang là localhost)
    let updatedContent = envContent;
    
    // Thay VNPay URLs
    updatedContent = updatedContent.replace(
      /VNP_RETURN_URL=http:\/\/localhost:5000\/api\/payment\/vnpay-return/g,
      `VNP_RETURN_URL=${publicUrl}/api/payment/vnpay-return`
    );
    updatedContent = updatedContent.replace(
      /VNP_IPN_URL=http:\/\/localhost:5000\/api\/payment\/vnpay-ipn/g,
      `VNP_IPN_URL=${publicUrl}/api/payment/vnpay-ipn`
    );
    
    // Thay MoMo URLs
    updatedContent = updatedContent.replace(
      /MOMO_RETURN_URL=http:\/\/localhost:5000\/api\/payment\/momo-return/g,
      `MOMO_RETURN_URL=${publicUrl}/api/payment/momo-return`
    );
    updatedContent = updatedContent.replace(
      /MOMO_IPN_URL=http:\/\/localhost:5000\/api\/payment\/momo-ipn/g,
      `MOMO_IPN_URL=${publicUrl}/api/payment/momo-ipn`
    );
    
    // Ghi lại file .env
    fs.writeFileSync(envPath, updatedContent, 'utf8');
    
    console.log('✅ Đã cập nhật file .env với IP public!');
    console.log('⚠️ LƯU Ý: Bạn cần setup port forwarding trên router để port 5000 có thể truy cập từ internet.');
    console.log('   - External Port: 5000');
    console.log('   - Internal IP: IP máy bạn (ví dụ: 192.168.1.100)');
    console.log('   - Internal Port: 5000');
    console.log('   - Protocol: TCP');
    console.log('');
    console.log('📋 Sau đó restart backend server để áp dụng thay đổi.');
    
  } catch (error) {
    console.error('❌ Lỗi:', error.message);
    console.log('');
    console.log('💡 Giải pháp thay thế:');
    console.log('   1. Dùng Cloudflare Tunnel (miễn phí):');
    console.log('      - Download: https://github.com/cloudflare/cloudflared/releases');
    console.log('      - Chạy: cloudflared tunnel --url http://localhost:5000');
    console.log('      - Copy URL và set vào .env');
    console.log('');
    console.log('   2. Deploy backend lên server có domain công khai');
  }
}

// Chạy script
if (require.main === module) {
  setupPublicUrl();
}

module.exports = { setupPublicUrl };
