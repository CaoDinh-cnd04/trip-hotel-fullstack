/**
 * MoMo Service - Xử lý tích hợp thanh toán MoMo
 * 
 * Chức năng:
 * - Tạo payment request đến MoMo
 * - Verify signature từ MoMo
 * - Query transaction status
 * - Refund transaction
 */

const crypto = require('crypto');
const https = require('https');
const momoConfig = require('../config/momo');

class MoMoService {
  /**
   * Tạo payment request đến MoMo
   * 
   * @param {Object} params - Thông tin thanh toán
   * @param {string} params.orderId - Mã đơn hàng
   * @param {number} params.amount - Số tiền (VND)
   * @param {string} params.orderInfo - Thông tin đơn hàng
   * @param {string} params.extraData - Dữ liệu bổ sung (optional, base64 encoded)
   * @returns {Promise<Object>} Response từ MoMo với payUrl
   */
  async createPayment(params) {
    const {
      orderId,
      amount,
      orderInfo,
      extraData = '',
    } = params;

    // Validate required params
    if (!orderId || !amount || !orderInfo) {
      throw new Error('Missing required parameters: orderId, amount, orderInfo');
    }

    // Generate requestId (unique)
    const requestId = momoConfig.partnerCode + new Date().getTime();

    // Tạo raw signature theo format của MoMo
    const rawSignature = 
      'accessKey=' + momoConfig.accessKey +
      '&amount=' + amount +
      '&extraData=' + extraData +
      '&ipnUrl=' + momoConfig.ipnUrl +
      '&orderId=' + orderId +
      '&orderInfo=' + orderInfo +
      '&partnerCode=' + momoConfig.partnerCode +
      '&redirectUrl=' + momoConfig.returnUrl +
      '&requestId=' + requestId +
      '&requestType=' + momoConfig.requestType;

    console.log('--------------------RAW SIGNATURE----------------');
    console.log(rawSignature);

    // Tạo signature bằng HMAC SHA256
    const signature = crypto
      .createHmac('sha256', momoConfig.secretKey)
      .update(rawSignature)
      .digest('hex');

    console.log('--------------------SIGNATURE----------------');
    console.log(signature);

    // Request body gửi đến MoMo
    const requestBody = JSON.stringify({
      partnerCode: momoConfig.partnerCode,
      accessKey: momoConfig.accessKey,
      requestId: requestId,
      amount: amount.toString(),
      orderId: orderId,
      orderInfo: orderInfo,
      redirectUrl: momoConfig.returnUrl,
      ipnUrl: momoConfig.ipnUrl,
      extraData: extraData,
      requestType: momoConfig.requestType,
      signature: signature,
      lang: momoConfig.lang,
    });

    console.log('--------------------REQUEST BODY----------------');
    console.log(requestBody);

    // Gọi MoMo API
    try {
      const response = await this._sendRequest(momoConfig.apiEndpoint, requestBody);
      
      console.log('--------------------MOMO RESPONSE----------------');
      console.log(response);

      // Check response
      if (response.resultCode === 0) {
        // Success - trả về payUrl để redirect user
        return {
          success: true,
          payUrl: response.payUrl,
          deeplink: response.deeplink,
          qrCodeUrl: response.qrCodeUrl,
          requestId: requestId,
          orderId: orderId,
        };
      } else {
        // Error
        throw new Error(response.message || `MoMo error: ${response.resultCode}`);
      }
    } catch (error) {
      console.error('Error calling MoMo API:', error);
      throw error;
    }
  }

  /**
   * Verify signature từ MoMo IPN/Return
   * 
   * @param {Object} data - Data từ MoMo callback
   * @returns {boolean} True nếu signature hợp lệ
   */
  verifySignature(data) {
    const {
      partnerCode,
      orderId,
      requestId,
      amount,
      orderInfo,
      orderType,
      transId,
      resultCode,
      message,
      payType,
      responseTime,
      extraData,
      signature,
    } = data;

    // Tạo raw signature để verify
    const rawSignature =
      'accessKey=' + momoConfig.accessKey +
      '&amount=' + amount +
      '&extraData=' + extraData +
      '&message=' + message +
      '&orderId=' + orderId +
      '&orderInfo=' + orderInfo +
      '&orderType=' + orderType +
      '&partnerCode=' + partnerCode +
      '&payType=' + payType +
      '&requestId=' + requestId +
      '&responseTime=' + responseTime +
      '&resultCode=' + resultCode +
      '&transId=' + transId;

    console.log('--------------------VERIFY RAW SIGNATURE----------------');
    console.log(rawSignature);

    // Tạo signature để so sánh
    const expectedSignature = crypto
      .createHmac('sha256', momoConfig.secretKey)
      .update(rawSignature)
      .digest('hex');

    console.log('Expected Signature:', expectedSignature);
    console.log('Received Signature:', signature);

    return signature === expectedSignature;
  }

  /**
   * Query transaction status từ MoMo
   * 
   * @param {Object} params - Thông tin query
   * @param {string} params.orderId - Mã đơn hàng
   * @param {string} params.requestId - Request ID từ lúc tạo payment
   * @returns {Promise<Object>} Kết quả query
   */
  async queryTransaction(params) {
    const { orderId, requestId } = params;

    // Tạo raw signature
    const rawSignature =
      'accessKey=' + momoConfig.accessKey +
      '&orderId=' + orderId +
      '&partnerCode=' + momoConfig.partnerCode +
      '&requestId=' + requestId;

    const signature = crypto
      .createHmac('sha256', momoConfig.secretKey)
      .update(rawSignature)
      .digest('hex');

    const requestBody = JSON.stringify({
      partnerCode: momoConfig.partnerCode,
      accessKey: momoConfig.accessKey,
      requestId: requestId,
      orderId: orderId,
      signature: signature,
      lang: momoConfig.lang,
    });

    // MoMo query endpoint
    const queryEndpoint = 'https://test-payment.momo.vn/v2/gateway/api/query';

    try {
      const response = await this._sendRequest(queryEndpoint, requestBody);
      return response;
    } catch (error) {
      console.error('Error querying MoMo transaction:', error);
      throw error;
    }
  }

  /**
   * Gửi HTTPS request đến MoMo
   * 
   * @param {string} url - MoMo API endpoint
   * @param {string} body - Request body (JSON string)
   * @returns {Promise<Object>} Response từ MoMo
   */
  _sendRequest(url, body) {
    return new Promise((resolve, reject) => {
      const urlObj = new URL(url);
      
      const options = {
        hostname: urlObj.hostname,
        port: 443,
        path: urlObj.pathname,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(body),
        },
      };

      const req = https.request(options, (res) => {
        let data = '';

        res.on('data', (chunk) => {
          data += chunk;
        });

        res.on('end', () => {
          try {
            const jsonResponse = JSON.parse(data);
            resolve(jsonResponse);
          } catch (e) {
            reject(new Error('Invalid JSON response from MoMo'));
          }
        });
      });

      req.on('error', (error) => {
        reject(error);
      });

      req.write(body);
      req.end();
    });
  }

  /**
   * Parse result code từ MoMo
   * 
   * @param {number} resultCode - Result code từ MoMo
   * @returns {string} Thông báo tương ứng
   */
  getResultMessage(resultCode) {
    const messages = {
      0: 'Giao dịch thành công',
      9000: 'Giao dịch được khởi tạo, chờ người dùng xác nhận thanh toán',
      8000: 'Giao dịch đang được xử lý',
      7000: 'Giao dịch đang chờ thanh toán',
      1000: 'Giao dịch đã được khởi tạo, chờ người dùng xác nhận thanh toán',
      11: 'Truy cập bị từ chối',
      12: 'Phiên bản API không được hỗ trợ cho yêu cầu này',
      13: 'Xác thực dữ liệu thất bại',
      20: 'Số tiền không hợp lệ',
      21: 'Số tiền thanh toán không hợp lệ',
      40: 'RequestId bị trùng',
      41: 'OrderId bị trùng',
      42: 'OrderId không hợp lệ hoặc không được tìm thấy',
      43: 'Yêu cầu bị từ chối vì xung đột trong quá trình xử lý giao dịch',
      1001: 'Giao dịch thanh toán thất bại do tài khoản người dùng không đủ tiền',
      1002: 'Giao dịch bị từ chối do nhà phát hành tài khoản thanh toán',
      1003: 'Giao dịch bị hủy',
      1004: 'Giao dịch thất bại do số tiền thanh toán vượt quá hạn mức thanh toán của người dùng',
      1005: 'Giao dịch thất bại do url hoặc QR code đã hết hạn',
      1006: 'Giao dịch thất bại do người dùng đã từ chối xác nhận thanh toán',
      1007: 'Giao dịch bị từ chối vì tài khoản người dùng đang ở trạng thái tạm khóa',
      1026: 'Giao dịch bị hạn chế theo thể lệ chương trình KM',
      1080: 'Giao dịch hoàn tiền bị từ chối. Giao dịch thanh toán ban đầu không được tìm thấy',
      1081: 'Giao dịch hoàn tiền bị từ chối. Giao dịch thanh toán ban đầu đã được hoàn',
      2001: 'Giao dịch thất bại do sai thông tin liên kết',
      2007: 'Giao dịch thất bại do liên kết thanh toán không tồn tại hoặc đã hết hạn',
      3001: 'Liên kết thanh toán bị từ chối vì người dùng chưa đăng ký dịch vụ',
      3002: 'Tài khoản chưa được kích hoạt',
      3003: 'Tài khoản đang bị khóa',
      4001: 'Giao dịch bị hạn chế theo thể lệ chương trình KM',
      4010: 'Giao dịch bị hạn chế do OTP chưa được gửi hoặc đã hết hạn',
      4011: 'Giao dịch bị từ chối vì OTP không hợp lệ',
      4100: 'Giao dịch thất bại do người dùng không xác nhận thanh toán',
      10: 'Hệ thống đang được bảo trì',
      99: 'Lỗi không xác định',
    };

    return messages[resultCode] || `Lỗi không xác định (code: ${resultCode})`;
  }
}

module.exports = new MoMoService();

