/**
 * Utility để tự động lấy public URL
 * Hỗ trợ nhiều cách: IP public, Cloudflare Tunnel, hoặc service khác
 */

const https = require('https');
const http = require('http');

/**
 * Lấy IP public từ service bên ngoài
 */
async function getPublicIP() {
  return new Promise((resolve, reject) => {
    https.get('https://api.ipify.org?format=json', (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          resolve(json.ip);
        } catch (e) {
          reject(e);
        }
      });
    }).on('error', (err) => {
      reject(err);
    });
  });
}

/**
 * Tạo public URL từ IP public
 * Lưu ý: Cần port forwarding trên router để hoạt động
 */
async function getPublicUrlFromIP(port = 5000) {
  try {
    const publicIP = await getPublicIP();
    return `http://${publicIP}:${port}`;
  } catch (error) {
    console.error('❌ Không thể lấy IP public:', error.message);
    return null;
  }
}

/**
 * Kiểm tra xem URL có phải localhost không
 */
function isLocalhost(url) {
  if (!url) return true;
  return url.includes('localhost') || 
         url.includes('127.0.0.1') || 
         url.includes('::1') ||
         url.startsWith('http://localhost') ||
         url.startsWith('https://localhost');
}

/**
 * Tự động tạo public URL
 * Thử các cách theo thứ tự:
 * 1. Từ environment variable (nếu đã set)
 * 2. Từ IP public (nếu có)
 * 3. Trả về null nếu không có
 */
async function getAutoPublicUrl(envUrl, port = 5000) {
  // Nếu đã có URL trong env và không phải localhost
  if (envUrl && !isLocalhost(envUrl)) {
    return envUrl;
  }
  
  // Thử lấy từ IP public
  const ipUrl = await getPublicUrlFromIP(port);
  if (ipUrl) {
    console.log('✅ Tự động detect IP public:', ipUrl);
    return ipUrl;
  }
  
  return null;
}

module.exports = {
  getPublicIP,
  getPublicUrlFromIP,
  isLocalhost,
  getAutoPublicUrl,
};
