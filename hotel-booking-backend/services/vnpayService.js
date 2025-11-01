/**
 * VNPay Service - Xử lý tích hợp thanh toán VNPay
 * 
 * Chức năng:
 * - Tạo URL thanh toán VNPay
 * - Verify signature từ VNPay
 * - Query transaction status
 * - Refund transaction
 */

const crypto = require('crypto');
const querystring = require('qs');
const vnpayConfig = require('../config/vnpay');

class VNPayService {
  /**
   * Tạo URL thanh toán VNPay
   * 
   * @param {Object} params - Thông tin thanh toán
   * @param {string} params.orderId - Mã đơn hàng
   * @param {number} params.amount - Số tiền (VND)
   * @param {string} params.orderInfo - Thông tin đơn hàng
   * @param {string} params.orderType - Loại đơn hàng (default: 'billpayment')
   * @param {string} params.ipAddr - IP address của khách hàng
   * @param {string} params.bankCode - Mã ngân hàng (optional)
   * @returns {string} URL thanh toán VNPay
   */
  createPaymentUrl(params) {
    const {
      orderId,
      amount,
      orderInfo,
      orderType = 'billpayment',
      ipAddr,
      bankCode = '',
    } = params;

    // Validate required fields
    if (!orderId || !amount || !orderInfo) {
      throw new Error('Missing required fields: orderId, amount, orderInfo');
    }

    // Validate VNPay config
    if (!vnpayConfig.vnp_TmnCode || !vnpayConfig.vnp_HashSecret) {
      throw new Error('VNPay config missing: vnp_TmnCode or vnp_HashSecret');
    }

    // Tạo thời gian
    const date = new Date();
    const createDate = this.formatDate(date);
    
    // Tính thời gian hết hạn (15 phút)
    const expireDate = new Date(date.getTime() + vnpayConfig.vnp_ExpireTime * 60000);
    const expireDateStr = this.formatDate(expireDate);

    // Đảm bảo IP address không null/undefined
    const clientIp = ipAddr || '127.0.0.1';

    // Tạo object params cho VNPay (theo thứ tự alphabet từ đầu)
    let vnp_Params = {};

    // Add params theo thứ tự alphabet (theo yêu cầu VNPay)
    vnp_Params.vnp_Amount = String(Math.round(amount * 100)); // VNPay yêu cầu số tiền nhân 100, convert sang string
    vnp_Params.vnp_Command = vnpayConfig.vnp_Command;
    vnp_Params.vnp_CreateDate = createDate;
    vnp_Params.vnp_CurrCode = vnpayConfig.vnp_CurrCode;
    vnp_Params.vnp_ExpireDate = expireDateStr;
    vnp_Params.vnp_IpAddr = clientIp;
    vnp_Params.vnp_Locale = vnpayConfig.vnp_Locale;
    vnp_Params.vnp_OrderInfo = orderInfo;
    vnp_Params.vnp_OrderType = orderType;
    vnp_Params.vnp_ReturnUrl = vnpayConfig.vnp_ReturnUrl;
    vnp_Params.vnp_TmnCode = vnpayConfig.vnp_TmnCode;
    vnp_Params.vnp_TxnRef = orderId;
    vnp_Params.vnp_Version = vnpayConfig.vnp_Version;

    // Thêm bank code nếu có (phải thêm trước khi sort)
    if (bankCode && bankCode.trim() !== '') {
      vnp_Params.vnp_BankCode = bankCode;
    }

    // Sắp xếp params theo thứ tự alphabet (đảm bảo nhất quán)
    vnp_Params = this.sortObject(vnp_Params);

    // Tạo signature
    // Lưu ý: VNPay yêu cầu format querystring KHÔNG encode, và KHÔNG có dấu &
    const signData = querystring.stringify(vnp_Params, { encode: false });
    
    console.log('🔐 VNPay Signature Debug:');
    console.log('   Sign Data:', signData);
    console.log('   Hash Secret:', vnpayConfig.vnp_HashSecret ? `${vnpayConfig.vnp_HashSecret.substring(0, 5)}...` : 'MISSING');
    
    const hmac = crypto.createHmac('sha512', vnpayConfig.vnp_HashSecret);
    const signed = hmac.update(Buffer.from(signData, 'utf-8')).digest('hex');
    
    console.log('   Generated Hash:', signed);
    
    vnp_Params.vnp_SecureHash = signed;

    // Tạo URL - KHÔNG encode trong querystring (VNPay yêu cầu)
    const paymentUrl = vnpayConfig.vnp_Url + '?' + querystring.stringify(vnp_Params, { encode: false });

    return paymentUrl;
  }

  /**
   * Verify signature từ VNPay return
   * 
   * @param {Object} vnpParams - Query params từ VNPay return
   * @returns {boolean} True nếu signature hợp lệ
   */
  verifyReturnUrl(vnpParams) {
    const secureHash = vnpParams.vnp_SecureHash;

    // Xóa các params không cần thiết
    delete vnpParams.vnp_SecureHash;
    delete vnpParams.vnp_SecureHashType;

    // Sắp xếp params
    const sortedParams = this.sortObject(vnpParams);

    // Tạo signature để verify
    const signData = querystring.stringify(sortedParams, { encode: false });
    const hmac = crypto.createHmac('sha512', vnpayConfig.vnp_HashSecret);
    const signed = hmac.update(Buffer.from(signData, 'utf-8')).digest('hex');

    return secureHash === signed;
  }

  /**
   * Query transaction status từ VNPay
   * 
   * @param {Object} params - Thông tin query
   * @param {string} params.orderId - Mã đơn hàng
   * @param {string} params.transDate - Ngày giao dịch (yyyyMMddHHmmss)
   * @returns {Promise<Object>} Kết quả query
   */
  async queryTransaction(params) {
    const { orderId, transDate } = params;

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

    // Tạo secure hash
    const sortedData = this.sortObject(data);
    const signData = querystring.stringify(sortedData, { encode: false });
    const hmac = crypto.createHmac('sha512', vnpayConfig.vnp_HashSecret);
    const secureHash = hmac.update(Buffer.from(signData, 'utf-8')).digest('hex');

    data.vnp_SecureHash = secureHash;

    // Gọi API VNPay
    try {
      const response = await fetch(vnpayConfig.vnp_Api, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data),
      });

      return await response.json();
    } catch (error) {
      console.error('Error querying VNPay transaction:', error);
      throw error;
    }
  }

  /**
   * Format date theo định dạng VNPay yêu cầu (yyyyMMddHHmmss)
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
   * Sắp xếp object theo key alphabet
   */
  sortObject(obj) {
    const sorted = {};
    const keys = Object.keys(obj).sort();
    keys.forEach(key => {
      sorted[key] = obj[key];
    });
    return sorted;
  }

  /**
   * Generate request ID unique
   */
  generateRequestId() {
    return Date.now().toString() + Math.random().toString(36).substring(2, 9);
  }

  /**
   * Parse response code từ VNPay
   */
  getResponseMessage(responseCode) {
    const messages = {
      '00': 'Giao dịch thành công',
      '07': 'Trừ tiền thành công. Giao dịch bị nghi ngờ (liên quan tới lừa đảo, giao dịch bất thường).',
      '09': 'Giao dịch không thành công do: Thẻ/Tài khoản của khách hàng chưa đăng ký dịch vụ InternetBanking tại ngân hàng.',
      '10': 'Giao dịch không thành công do: Khách hàng xác thực thông tin thẻ/tài khoản không đúng quá 3 lần',
      '11': 'Giao dịch không thành công do: Đã hết hạn chờ thanh toán. Xin quý khách vui lòng thực hiện lại giao dịch.',
      '12': 'Giao dịch không thành công do: Thẻ/Tài khoản của khách hàng bị khóa.',
      '13': 'Giao dịch không thành công do Quý khách nhập sai mật khẩu xác thực giao dịch (OTP).',
      '24': 'Giao dịch không thành công do: Khách hàng hủy giao dịch',
      '51': 'Giao dịch không thành công do: Tài khoản của quý khách không đủ số dư để thực hiện giao dịch.',
      '65': 'Giao dịch không thành công do: Tài khoản của Quý khách đã vượt quá hạn mức giao dịch trong ngày.',
      '75': 'Ngân hàng thanh toán đang bảo trì.',
      '79': 'Giao dịch không thành công do: KH nhập sai mật khẩu thanh toán quá số lần quy định.',
      '99': 'Các lỗi khác (lỗi còn lại, không có trong danh sách mã lỗi đã liệt kê)',
    };

    return messages[responseCode] || 'Lỗi không xác định';
  }
}

module.exports = new VNPayService();

