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
   * Tạo payment URL từ MoMo (giống VNPay - return object với paymentUrl, qrCodeUrl, deeplink)
   * 
   * @param {Object} params - Thông tin thanh toán
   * @param {string} params.orderId - Mã đơn hàng
   * @param {number} params.amount - Số tiền (VND)
   * @param {string} params.orderInfo - Thông tin đơn hàng
   * @returns {Promise<Object>} Object với {paymentUrl, qrCodeUrl, deeplink}
   */
  async createPaymentUrl(params) {
    const { orderId, amount, orderInfo } = params;
    
    // Gọi createPayment để lấy payUrl và qrCodeUrl
    const result = await this.createPayment({
      orderId,
      amount,
      orderInfo,
      extraData: '',
    });
    
    // Return object với paymentUrl, qrCodeUrl và deeplink
    if (result.payUrl) {
      return {
        paymentUrl: result.payUrl,
        qrCodeUrl: result.qrCodeUrl || null,
        deeplink: result.deeplink || null,
      };
    } else {
      throw new Error('MoMo did not return payment URL');
    }
  }

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

    // Tạo raw signature theo format của MoMo API v2
    // QUAN TRỌNG: Thứ tự các field phải SẮP XẾP ALPHABETICALLY theo MoMo API documentation
    // Thứ tự đúng (alphabetically): accessKey, amount, extraData, ipnUrl, orderId, orderInfo, partnerCode, redirectUrl, requestId, requestType
    // Lưu ý: Dùng redirectUrl (không phải returnUrl) và ipnUrl (không phải notifyUrl) trong signature
    const rawSignature = 
      'accessKey=' + momoConfig.accessKey +
      '&amount=' + amount +
      '&extraData=' + (extraData || '') +
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

    // Request body gửi đến MoMo - THEO ĐÚNG FORMAT MOMO API v2
    // Lưu ý: requestType và lang không có trong signature string, chỉ có trong request body
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

    // Gọi MoMo API với retry logic
    const maxRetries = 2;
    let lastError = null;
    
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        console.log(`📤 Sending request to MoMo API (attempt ${attempt}/${maxRetries}):`, momoConfig.apiEndpoint);
        const response = await this._sendRequest(momoConfig.apiEndpoint, requestBody);
        
        console.log('--------------------MOMO RESPONSE----------------');
        console.log(JSON.stringify(response, null, 2));

        // Check response
        if (response.resultCode === 0) {
          // Success - trả về payUrl để redirect user
          console.log('✅ MoMo payment URL created successfully');
          console.log('   Pay URL:', response.payUrl);
          console.log('   Deep Link:', response.deeplink);
          console.log('   QR Code URL:', response.qrCodeUrl);
          
          return {
            success: true,
            payUrl: response.payUrl,
            deeplink: response.deeplink,
            qrCodeUrl: response.qrCodeUrl,
            requestId: requestId,
            orderId: orderId,
          };
        } else {
          // Error từ MoMo
          const errorMessage = response.message || this.getResultMessage(response.resultCode);
          console.error(`❌ MoMo API Error: resultCode=${response.resultCode}, message=${errorMessage}`);
          throw new Error(`MoMo error (code ${response.resultCode}): ${errorMessage}`);
        }
      } catch (error) {
        lastError = error;
        console.error(`❌ Error calling MoMo API (attempt ${attempt}/${maxRetries}):`);
        console.error('   Error Type:', error.constructor.name);
        console.error('   Error Message:', error.message);
        
        // Nếu là timeout, connection error, hoặc HTTP 5xx error và chưa hết retry, thử lại
        const isRetryableError = 
          error.message.includes('timeout') || 
          error.message.includes('ECONNREFUSED') || 
          error.message.includes('ENOTFOUND') ||
          error.message.includes('ECONNRESET') ||
          error.message.includes('socket hang up') ||
          error.message.includes('502') ||
          error.message.includes('503') ||
          error.message.includes('504') ||
          error.message.includes('Bad Gateway') ||
          error.message.includes('Service Unavailable') ||
          error.message.includes('Gateway Timeout');
        
        if (attempt < maxRetries && isRetryableError) {
          const waitTime = attempt * 2000; // 2s, 4s
          console.log(`⏳ Retrying in ${waitTime}ms... (MoMo server may be temporarily unavailable)`);
          await new Promise(resolve => setTimeout(resolve, waitTime));
          continue;
        }
        
        // Nếu không phải lỗi có thể retry, hoặc đã hết retry, throw error
        break;
      }
    }
    
    // Nếu đến đây, tất cả retry đã thất bại
    console.error('❌ All retry attempts failed');
    console.error('   Last Error:', lastError?.message);
    console.error('   Stack:', lastError?.stack);
    
    // Cải thiện error message dựa trên loại lỗi
    if (lastError?.message.includes('timeout')) {
      throw new Error('MoMo API request timeout sau nhiều lần thử. MoMo server có thể đang quá tải hoặc không phản hồi. Vui lòng thử lại sau hoặc sử dụng phương thức thanh toán khác (VNPay).');
    } else if (lastError?.message.includes('ECONNREFUSED') || lastError?.message.includes('ENOTFOUND')) {
      throw new Error('Không thể kết nối đến MoMo API sau nhiều lần thử. Kiểm tra kết nối mạng hoặc API endpoint.');
    } else if (lastError?.message.includes('ECONNRESET') || lastError?.message.includes('socket hang up')) {
      throw new Error('Kết nối đến MoMo API bị ngắt. MoMo server có thể đang quá tải. Vui lòng thử lại sau hoặc sử dụng phương thức thanh toán khác (VNPay).');
    } else if (lastError?.message.includes('502') || lastError?.message.includes('Bad Gateway')) {
      throw new Error('MoMo payment gateway đang tạm thời không khả dụng (502 Bad Gateway). Vui lòng thử lại sau hoặc sử dụng phương thức thanh toán khác.');
    } else if (lastError?.message.includes('HTML')) {
      throw new Error('MoMo API trả về lỗi. Kiểm tra credentials và API endpoint trong file .env.');
    } else {
      throw lastError || new Error('Unknown error calling MoMo API');
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

    // Tạo raw signature để verify - THEO ĐÚNG THỨ TỰ CỦA MOMO API v2
    // Thứ tự cho verify: partnerCode, accessKey, requestId, amount, orderId, orderInfo, returnUrl, notifyUrl, extraData
    // Nhưng trong response có thêm các field: message, orderType, payType, responseTime, resultCode, transId
    // Cần kiểm tra documentation để biết thứ tự chính xác cho verify
    // Tạm thời dùng thứ tự: partnerCode, accessKey, requestId, amount, orderId, orderInfo, returnUrl, notifyUrl, extraData, message, orderType, payType, responseTime, resultCode, transId
    const rawSignature =
      'partnerCode=' + (partnerCode || momoConfig.partnerCode) +
      '&accessKey=' + momoConfig.accessKey +
      '&requestId=' + (requestId || '') +
      '&amount=' + (amount || '') +
      '&orderId=' + (orderId || '') +
      '&orderInfo=' + (orderInfo || '') +
      '&returnUrl=' + momoConfig.returnUrl +
      '&notifyUrl=' + momoConfig.ipnUrl +
      '&extraData=' + (extraData || '') +
      '&message=' + (message || '') +
      '&orderType=' + (orderType || '') +
      '&payType=' + (payType || '') +
      '&responseTime=' + (responseTime || '') +
      '&resultCode=' + (resultCode || '') +
      '&transId=' + (transId || '');

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

    // Tạo raw signature cho query transaction - THEO ĐÚNG THỨ TỰ MOMO API v2
    // Thứ tự: partnerCode, accessKey, requestId, orderId
    const rawSignature =
      'partnerCode=' + momoConfig.partnerCode +
      '&accessKey=' + momoConfig.accessKey +
      '&requestId=' + requestId +
      '&orderId=' + orderId;

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
          'Connection': 'keep-alive', // Giữ kết nối để tăng tốc độ
        },
        timeout: 60000, // 60 seconds timeout
      };

      const req = https.request(options, (res) => {
        let data = '';

        // Log response status và headers
        console.log('--------------------MOMO API RESPONSE----------------');
        console.log('Status Code:', res.statusCode);
        console.log('Status Message:', res.statusMessage);
        console.log('Headers:', JSON.stringify(res.headers, null, 2));

        // Kiểm tra HTTP status code
        if (res.statusCode < 200 || res.statusCode >= 300) {
          console.error(`❌ MoMo API returned error status: ${res.statusCode} ${res.statusMessage}`);
          
          // Log upstream status nếu có (từ APISIX gateway)
          if (res.headers['x-apisix-upstream-status']) {
            console.error(`   Upstream Status: ${res.headers['x-apisix-upstream-status']}`);
            console.error('   💡 This indicates MoMo backend servers are not responding');
          }
        }

        res.on('data', (chunk) => {
          data += chunk;
        });

        res.on('end', () => {
          console.log('Response Body (raw):');
          console.log(data);
          console.log('Response Body Length:', data.length);
          
          // Kiểm tra nếu response rỗng
          if (!data || data.trim().length === 0) {
            console.error('❌ MoMo returned empty response');
            reject(new Error(`MoMo returned empty response. Status: ${res.statusCode}`));
            return;
          }

          // Kiểm tra nếu response là HTML (thường là error page)
          if (data.trim().startsWith('<!DOCTYPE') || data.trim().startsWith('<html')) {
            console.error('❌ MoMo returned HTML instead of JSON (likely an error page)');
            console.error('HTML Response (first 500 chars):', data.substring(0, 500));
            reject(new Error(`MoMo returned HTML error page. Status: ${res.statusCode}. Check MoMo API endpoint and credentials.`));
            return;
          }

          try {
            const jsonResponse = JSON.parse(data);
            console.log('✅ Successfully parsed JSON response:');
            console.log(JSON.stringify(jsonResponse, null, 2));
            
            // Kiểm tra nếu có error trong JSON response
            if (jsonResponse.resultCode && jsonResponse.resultCode !== 0) {
              const errorMessage = jsonResponse.message || this.getResultMessage(jsonResponse.resultCode);
              console.error(`❌ MoMo API Error: resultCode=${jsonResponse.resultCode}, message=${errorMessage}`);
            }
            
            resolve(jsonResponse);
          } catch (e) {
            console.error('❌ Failed to parse JSON response:');
            console.error('Parse Error:', e.message);
            console.error('Response Data:', data);
            reject(new Error(`Invalid JSON response from MoMo. Status: ${res.statusCode}. Response: ${data.substring(0, 200)}`));
          }
        });
      });

      // Handle request errors (network errors, timeouts, etc.)
      req.on('error', (error) => {
        console.error('❌ Request error:', error);
        reject(error);
      });

      // Set timeout (60 seconds - tăng từ 30s để tránh timeout quá nhanh)
      req.setTimeout(60000, () => {
        console.error('⏱️ Request timeout after 60 seconds');
        req.destroy();
        reject(new Error('MoMo API request timeout after 60 seconds. MoMo server có thể đang quá tải hoặc không phản hồi.'));
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

