/**
 * VNPay Service - Theo đúng tài liệu VNPay chính thức
 * 
 * Tài liệu: https://sandbox.vnpayment.vn/apis/docs/thanh-toan-pay/pay.html
 * Version: 2.1.0
 * Algorithm: HMAC SHA512
 */

const crypto = require('crypto');
const querystring = require('querystring');
const vnpayConfig = require('../config/vnpay');

class VNPayService {
  /**
   * Tạo URL thanh toán VNPay
   * 
   * @param {Object} params
   * @param {string} params.orderId - Mã đơn hàng (unique)
   * @param {number} params.amount - Số tiền (VND)
   * @param {string} params.orderInfo - Mô tả đơn hàng
   * @param {string} params.ipAddr - IP address của khách hàng
   * @param {string} params.bankCode - Mã ngân hàng (optional)
   * @returns {string} URL thanh toán VNPay
   */
  createPaymentUrl(params) {
    const { orderId, amount, orderInfo, orderType = 'billpayment', ipAddr, bankCode = '' } = params;

    // Validate
    if (!orderId || !amount || !orderInfo) {
      throw new Error('Missing required fields: orderId, amount, orderInfo');
    }

    if (!vnpayConfig.vnp_TmnCode || !vnpayConfig.vnp_HashSecret) {
      throw new Error('VNPay config missing: vnp_TmnCode or vnp_HashSecret');
    }

    // Set timezone
    process.env.TZ = 'Asia/Ho_Chi_Minh';

    // Tạo thời gian
    const date = new Date();
    const createDate = this.formatDate(date);
    const expireDate = new Date(date.getTime() + vnpayConfig.vnp_ExpireTime * 60000);
    const expireDateStr = this.formatDate(expireDate);

    // Lấy IP address
    let clientIp = ipAddr || '127.0.0.1';
    if (clientIp.startsWith('::ffff:')) {
      clientIp = clientIp.substring(7);
    }
    if (clientIp === '::1') {
      clientIp = '127.0.0.1';
    }

    // Tạo các tham số VNPay
    const vnp_Params = {
      vnp_Version: vnpayConfig.vnp_Version,
      vnp_Command: vnpayConfig.vnp_Command,
      vnp_TmnCode: vnpayConfig.vnp_TmnCode,
      vnp_Amount: String(Math.round(amount * 100)), // VNPay yêu cầu * 100
      vnp_CurrCode: vnpayConfig.vnp_CurrCode,
      vnp_TxnRef: orderId,
      vnp_OrderInfo: this.sanitizeOrderInfo(orderInfo),
      vnp_OrderType: orderType,
      vnp_Locale: vnpayConfig.vnp_Locale,
      vnp_ReturnUrl: vnpayConfig.vnp_ReturnUrl,
      vnp_IpAddr: clientIp,
      vnp_CreateDate: createDate,
      vnp_ExpireDate: expireDateStr,
    };

    // Thêm bankCode nếu có
    if (bankCode && bankCode.trim() !== '') {
      vnp_Params['vnp_BankCode'] = bankCode.trim();
    }

    // Sắp xếp params theo alphabet (QUAN TRỌNG!)
    const sortedParams = this.sortObject(vnp_Params);

    // Tạo query string để tạo signature
    // Fix: Dùng URLSearchParams thay vì querystring (deprecated)
    const signData = new URLSearchParams(sortedParams).toString();

    // Tạo HMAC SHA512 signature
    const hmac = crypto.createHmac('sha512', vnpayConfig.vnp_HashSecret);
    const signed = hmac.update(signData, 'utf-8').digest('hex');

    // Thêm signature vào params
    sortedParams['vnp_SecureHash'] = signed;

    // Tạo payment URL với URLSearchParams
    const paymentQueryString = new URLSearchParams(sortedParams).toString();
    const vnpUrl = vnpayConfig.vnp_Url + '?' + paymentQueryString;

    console.log('✅ VNPay Payment URL created');
    console.log('   Order ID:', orderId);
    console.log('   Amount:', amount, 'VND');
    console.log('   Signature:', signed.substring(0, 40) + '...');

    return vnpUrl;
  }

  /**
   * Verify signature từ VNPay return
   * 
   * @param {Object} vnpParams - Params từ VNPay return
   * @returns {boolean} true nếu signature hợp lệ
   */
  verifyReturnUrl(vnpParams) {
    const secureHash = vnpParams.vnp_SecureHash;

    if (!secureHash) {
      console.error('❌ Missing vnp_SecureHash');
      return false;
    }

    // Tạo bản copy và xóa signature fields
    const paramsCopy = { ...vnpParams };
    delete paramsCopy.vnp_SecureHash;
    delete paramsCopy.vnp_SecureHashType;

    // Sắp xếp params
    const sortedParams = this.sortObject(paramsCopy);

    // Tạo query string để verify (giống createPaymentUrl)
    const signData = new URLSearchParams(sortedParams).toString();

    // Tạo signature để verify
    const hmac = crypto.createHmac('sha512', vnpayConfig.vnp_HashSecret);
    const signed = hmac.update(signData, 'utf-8').digest('hex');

    const isValid = secureHash === signed;

    if (!isValid) {
      console.error('❌ Signature mismatch');
      console.error('   Received:', secureHash);
      console.error('   Calculated:', signed);
      console.error('   SignData:', signData);
    } else {
      console.log('✅ Signature verified');
    }

    return isValid;
  }

  /**
   * Query transaction status
   * 
   * @param {Object} params
   * @param {string} params.orderId - Mã đơn hàng
   * @param {string} params.transDate - Ngày giao dịch (yyyyMMddHHmmss)
   * @returns {Promise<Object>} Kết quả query từ VNPay
   */
  async queryTransaction(params) {
    const { orderId, transDate } = params;
    process.env.TZ = 'Asia/Ho_Chi_Minh';
    const date = new Date();
    const createDate = this.formatDate(date);
    const requestId = this.generateRequestId();

    const data = {
      vnp_RequestId: requestId,
      vnp_Version: vnpayConfig.vnp_Version,
      vnp_Command: 'querydr',
      vnp_TmnCode: vnpayConfig.vnp_TmnCode,
      vnp_TxnRef: orderId,
      vnp_OrderInfo: `Query transaction ${orderId}`,
      vnp_TransactionDate: transDate,
      vnp_CreateDate: createDate,
      vnp_IpAddr: '127.0.0.1',
    };

    const sortedData = this.sortObject(data);
    const hashData = new URLSearchParams(sortedData).toString();
    
    const hmac = crypto.createHmac('sha512', vnpayConfig.vnp_HashSecret);
    const secureHash = hmac.update(hashData, 'utf-8').digest('hex');
    data.vnp_SecureHash = secureHash;

    try {
      const response = await fetch(vnpayConfig.vnp_Api, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      });
      return await response.json();
    } catch (error) {
      console.error('Error querying VNPay transaction:', error);
      throw error;
    }
  }

  /**
   * Sắp xếp object theo alphabet
   * 
   * @param {Object} obj - Object cần sắp xếp
   * @returns {Object} Object đã sắp xếp
   */
  sortObject(obj) {
    const sorted = {};
    const keys = Object.keys(obj).sort();
    
    for (const key of keys) {
      const value = obj[key];
      if (value !== null && value !== undefined && value !== '') {
        sorted[key] = String(value);
      }
    }
    
    return sorted;
  }

  /**
   * Sanitize orderInfo - Loại bỏ dấu tiếng Việt và ký tự đặc biệt
   * 
   * @param {string} orderInfo - Mô tả đơn hàng
   * @returns {string} Mô tả đã được sanitize
   */
  sanitizeOrderInfo(orderInfo) {
    if (!orderInfo) return '';
    
    let sanitized = String(orderInfo);
    
    // Chuyển tiếng Việt có dấu sang không dấu
    sanitized = this.removeVietnameseAccents(sanitized);
    
    // Loại bỏ ký tự đặc biệt, chỉ giữ lại: a-z, A-Z, 0-9, space, -, ., _
    sanitized = sanitized
      .replace(/[^a-zA-Z0-9\s\-._]/g, '')
      .replace(/\s+/g, ' ')
      .trim();
    
    // Giới hạn độ dài
    if (sanitized.length > 255) {
      sanitized = sanitized.substring(0, 255);
    }
    
    return sanitized;
  }

  /**
   * Chuyển tiếng Việt có dấu sang không dấu
   */
  removeVietnameseAccents(str) {
    if (!str) return '';
    
    const accentMap = {
      'à': 'a', 'á': 'a', 'ạ': 'a', 'ả': 'a', 'ã': 'a',
      'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ậ': 'a', 'ẩ': 'a', 'ẫ': 'a',
      'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ặ': 'a', 'ẳ': 'a', 'ẵ': 'a',
      'è': 'e', 'é': 'e', 'ẹ': 'e', 'ẻ': 'e', 'ẽ': 'e',
      'ê': 'e', 'ề': 'e', 'ế': 'e', 'ệ': 'e', 'ể': 'e', 'ễ': 'e',
      'ì': 'i', 'í': 'i', 'ị': 'i', 'ỉ': 'i', 'ĩ': 'i',
      'ò': 'o', 'ó': 'o', 'ọ': 'o', 'ỏ': 'o', 'õ': 'o',
      'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ộ': 'o', 'ổ': 'o', 'ỗ': 'o',
      'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ợ': 'o', 'ở': 'o', 'ỡ': 'o',
      'ù': 'u', 'ú': 'u', 'ụ': 'u', 'ủ': 'u', 'ũ': 'u',
      'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ự': 'u', 'ử': 'u', 'ữ': 'u',
      'ỳ': 'y', 'ý': 'y', 'ỵ': 'y', 'ỷ': 'y', 'ỹ': 'y',
      'đ': 'd',
      'À': 'A', 'Á': 'A', 'Ạ': 'A', 'Ả': 'A', 'Ã': 'A',
      'Â': 'A', 'Ầ': 'A', 'Ấ': 'A', 'Ậ': 'A', 'Ẩ': 'A', 'Ẫ': 'A',
      'Ă': 'A', 'Ằ': 'A', 'Ắ': 'A', 'Ặ': 'A', 'Ẳ': 'A', 'Ẵ': 'A',
      'È': 'E', 'É': 'E', 'Ẹ': 'E', 'Ẻ': 'E', 'Ẽ': 'E',
      'Ê': 'E', 'Ề': 'E', 'Ế': 'E', 'Ệ': 'E', 'Ể': 'E', 'Ễ': 'E',
      'Ì': 'I', 'Í': 'I', 'Ị': 'I', 'Ỉ': 'I', 'Ĩ': 'I',
      'Ò': 'O', 'Ó': 'O', 'Ọ': 'O', 'Ỏ': 'O', 'Õ': 'O',
      'Ô': 'O', 'Ồ': 'O', 'Ố': 'O', 'Ộ': 'O', 'Ổ': 'O', 'Ỗ': 'O',
      'Ơ': 'O', 'Ờ': 'O', 'Ớ': 'O', 'Ợ': 'O', 'Ở': 'O', 'Ỡ': 'O',
      'Ù': 'U', 'Ú': 'U', 'Ụ': 'U', 'Ủ': 'U', 'Ũ': 'U',
      'Ư': 'U', 'Ừ': 'U', 'Ứ': 'U', 'Ự': 'U', 'Ử': 'U', 'Ữ': 'U',
      'Ỳ': 'Y', 'Ý': 'Y', 'Ỵ': 'Y', 'Ỷ': 'Y', 'Ỹ': 'Y',
      'Đ': 'D',
    };
    
    return str.split('').map(char => accentMap[char] || char).join('');
  }

  /**
   * Format date yyyyMMddHHmmss
   */
  formatDate(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hour = String(date.getHours()).padStart(2, '0');
    const minute = String(date.getMinutes()).padStart(2, '0');
    const second = String(date.getSeconds()).padStart(2, '0');
    return `${year}${month}${day}${hour}${minute}${second}`;
  }

  /**
   * Generate request ID
   */
  generateRequestId() {
    return Date.now().toString() + Math.random().toString(36).substring(2, 9);
  }

  /**
   * Get response message từ response code
   */
  getResponseMessage(responseCode) {
    const messages = {
      '00': 'Giao dịch thành công',
      '07': 'Trừ tiền thành công. Giao dịch bị nghi ngờ.',
      '09': 'Thẻ/Tài khoản chưa đăng ký InternetBanking.',
      '10': 'Xác thực thông tin thẻ/tài khoản không đúng quá 3 lần',
      '11': 'Đã hết hạn chờ thanh toán',
      '12': 'Thẻ/Tài khoản bị khóa',
      '13': 'Nhập sai mật khẩu OTP',
      '24': 'Khách hàng hủy giao dịch',
      '51': 'Tài khoản không đủ số dư',
      '65': 'Vượt quá hạn mức giao dịch trong ngày',
      '75': 'Ngân hàng thanh toán đang bảo trì',
      '79': 'Nhập sai mật khẩu thanh toán quá số lần quy định',
      '99': 'Timeout/Lỗi VNPAY - VNPay không thể gọi về Return URL hoặc có lỗi hệ thống.',
    };
    return messages[responseCode] || 'Lỗi không xác định';
  }
}

module.exports = new VNPayService();

