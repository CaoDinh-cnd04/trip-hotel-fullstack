/**
 * VNPay Controller
 * 
 * Endpoints:
 * - POST /api/v2/vnpay/create-payment - Tạo payment URL
 * - GET  /api/payment/vnpay-return - Return URL từ VNPay
 * - POST /api/payment/vnpay-ipn - IPN callback từ VNPay
 * - GET  /api/v2/vnpay/config - Lấy cấu hình VNPay
 * - POST /api/v2/vnpay/query-transaction - Query trạng thái giao dịch
 */

const vnpayService = require('../services/vnpayService');
const vnpayConfig = require('../config/vnpay');

/**
 * Tạo payment URL
 * POST /api/v2/vnpay/create-payment
 */
exports.createPayment = async (req, res) => {
  try {
    const { bookingId, amount, orderInfo, bankCode, bookingData } = req.body;

    // Validate
    if (!bookingId || !amount || !orderInfo) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: bookingId, amount, orderInfo',
      });
    }
    
    // Kiểm tra Return URL
    const returnUrl = vnpayConfig.vnp_ReturnUrl;
    if (returnUrl.includes('localhost') || returnUrl.includes('127.0.0.1')) {
      return res.status(400).json({
        success: false,
        message: 'VNPay Sandbox không chấp nhận localhost',
        error: 'INVALID_RETURN_URL',
      });
    }

    // Lấy userId và IP
    const userId = req.user?.id || req.user?.ma_nguoi_dung || null;
    const ipAddr = req.headers['x-forwarded-for'] ||
                   req.connection.remoteAddress ||
                   req.socket.remoteAddress ||
                   '127.0.0.1';

    // Tạo order ID
    const timestamp = Date.now();
    const randomStr = Math.random().toString(36).substring(2, 8).toUpperCase();
    const orderId = `BK${bookingId}_${timestamp}_${randomStr}`;

    console.log('💳 Creating VNPay payment:');
    console.log('   Order ID:', orderId);
    console.log('   Amount:', amount, 'VND');
    console.log('   User ID:', userId || 'Guest');
    console.log('   IP:', ipAddr);

    // Tạo payment URL
    const paymentUrl = vnpayService.createPaymentUrl({
      orderId,
      amount,
      orderInfo,
      orderType: 'billpayment',
      ipAddr,
      bankCode: bankCode || '',
    });

    // Lưu payment info vào database
    try {
      const { getPool } = require('../config/db');
      const pool = await getPool();
      
      const tableCheck = await pool.request()
        .query(`
          SELECT COUNT(*) as table_exists
          FROM INFORMATION_SCHEMA.TABLES 
          WHERE TABLE_NAME = 'payments'
        `);
      
      if (tableCheck.recordset[0].table_exists > 0) {
        const enrichedBookingData = bookingData ? {
          ...bookingData,
          userId: bookingData.userId || userId,
        } : null;

        await pool.request()
          .input('booking_id', bookingId)
          .input('order_id', orderId)
          .input('amount', amount)
          .input('extra_data', enrichedBookingData ? JSON.stringify(enrichedBookingData) : null)
          .query(`
            INSERT INTO payments (booking_id, order_id, amount, status, payment_method, extra_data, created_at)
            VALUES (@booking_id, @order_id, @amount, 'pending', 'vnpay', @extra_data, GETDATE())
          `);
        console.log('✅ Payment record saved to database');
      }
    } catch (dbError) {
      console.error('⚠️ Error saving payment (non-critical):', dbError.message);
    }

    res.json({
      success: true,
      data: {
        paymentUrl,
        orderId,
      },
    });
  } catch (error) {
    console.error('❌ Error creating payment:', error);
    res.status(500).json({
      success: false,
      message: 'Error creating payment URL',
      error: error.message,
    });
  }
};

/**
 * VNPay Return URL callback
 * GET /api/payment/vnpay-return
 */
exports.vnpayReturn = async (req, res) => {
  try {
    const vnpParams = req.query;
    
    console.log('📥 VNPay Return URL called');
    console.log('   Params:', Object.keys(vnpParams).join(', '));

    // Verify signature
    const isValid = vnpayService.verifyReturnUrl(vnpParams);

    if (!isValid) {
      return res.status(400).json({
        success: false,
        message: 'Invalid signature',
        error: 'INVALID_SIGNATURE',
      });
    }

    const responseCode = vnpParams.vnp_ResponseCode;
    const orderId = vnpParams.vnp_TxnRef;
    const transactionNo = vnpParams.vnp_TransactionNo;
    const amount = vnpParams.vnp_Amount ? parseInt(vnpParams.vnp_Amount) / 100 : 0;
    const isSuccess = responseCode === '00';

    // Update payment status in database
    let bookingId = null;
    let extraData = null;
    
    try {
      const { getPool } = require('../config/db');
      const pool = await getPool();
      
      const tableCheck = await pool.request()
        .query(`
          SELECT COUNT(*) as table_exists
          FROM INFORMATION_SCHEMA.TABLES 
          WHERE TABLE_NAME = 'payments'
        `);
      
      if (tableCheck.recordset[0].table_exists > 0) {
        const status = isSuccess ? 'completed' : 'failed';
        
        // Get payment info trước khi update
        const paymentInfo = await pool.request()
          .input('order_id', orderId)
          .query('SELECT booking_id, extra_data FROM payments WHERE order_id = @order_id');
        
        if (paymentInfo.recordset.length > 0) {
          bookingId = paymentInfo.recordset[0].booking_id;
          extraData = paymentInfo.recordset[0].extra_data;
        }
        
        await pool.request()
          .input('order_id', orderId)
          .input('status', status)
          .input('transaction_no', transactionNo || null)
          .input('response_code', responseCode)
          .input('bank_code', vnpParams.vnp_BankCode || null)
          .input('pay_date', vnpParams.vnp_PayDate || null)
          .query(`
            UPDATE payments 
            SET status = @status,
                transaction_no = @transaction_no,
                response_code = @response_code,
                bank_code = @bank_code,
                pay_date = @pay_date,
                updated_at = GETDATE()
            WHERE order_id = @order_id
          `);
        console.log('✅ Payment status updated in database');
      }
    } catch (dbError) {
      console.error('⚠️ Error updating payment (non-critical):', dbError.message);
    }
    
    // Auto confirm booking và gửi email nếu thanh toán thành công
    if (isSuccess && bookingId) {
      try {
        const AutoConfirmBookingService = require('../services/autoConfirmBookingService');
        
        // Parse extra_data để lấy thông tin booking
        let bookingData = {};
        if (extraData) {
          try {
            bookingData = typeof extraData === 'string' ? JSON.parse(extraData) : extraData;
          } catch (e) {
            console.error('⚠️ Cannot parse extra_data:', e);
          }
        }
        
        console.log('🔄 Auto confirming booking...');
        await AutoConfirmBookingService.autoConfirmBookingAfterPayment({
          orderId: orderId,
          amount: amount,
          paymentMethod: 'vnpay',
          transactionId: transactionNo,
          bookingId: bookingId,
          bookingData: bookingData,
        });
        
        console.log('✅ Booking auto-confirmed and email sent');
      } catch (confirmError) {
        console.error('⚠️ Error auto-confirming booking (non-critical):', confirmError.message);
      }
    }

    // Redirect về app với deep link
    const message = vnpayService.getResponseMessage(responseCode);
    
    // Tạo deep link về app (match với AndroidManifest: vnpaypayment://return)
    const appScheme = 'vnpaypayment://return';
    const params = new URLSearchParams({
      vnp_ResponseCode: responseCode,
      vnp_TxnRef: orderId,
      vnp_Amount: (amount * 100).toString(), // VNPay format
      vnp_TransactionNo: transactionNo || '',
      vnp_BankCode: vnpParams.vnp_BankCode || '',
      vnp_PayDate: vnpParams.vnp_PayDate || '',
      vnp_SecureHash: vnpParams.vnp_SecureHash || '',
    });
    
    const deepLink = `${appScheme}?${params.toString()}`;
    
    // Trả về HTML với auto redirect về app
    const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${isSuccess ? 'Thanh toán thành công' : 'Thanh toán thất bại'}</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      margin: 0;
      background: ${isSuccess ? 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)' : 'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)'};
    }
    .container {
      text-align: center;
      background: white;
      padding: 40px;
      border-radius: 20px;
      box-shadow: 0 20px 60px rgba(0,0,0,0.3);
      max-width: 400px;
    }
    .icon {
      font-size: 80px;
      margin-bottom: 20px;
    }
    h1 {
      color: #333;
      margin: 0 0 10px 0;
      font-size: 24px;
    }
    p {
      color: #666;
      margin: 10px 0;
      line-height: 1.6;
    }
    .amount {
      font-size: 32px;
      font-weight: bold;
      color: ${isSuccess ? '#10b981' : '#ef4444'};
      margin: 20px 0;
    }
    .info {
      background: #f3f4f6;
      padding: 15px;
      border-radius: 10px;
      margin: 20px 0;
      text-align: left;
    }
    .info-row {
      display: flex;
      justify-content: space-between;
      padding: 8px 0;
      border-bottom: 1px solid #e5e7eb;
    }
    .info-row:last-child {
      border-bottom: none;
    }
    .label {
      color: #6b7280;
      font-size: 14px;
    }
    .value {
      color: #111827;
      font-weight: 500;
      font-size: 14px;
    }
    .redirect-message {
      color: #9ca3af;
      font-size: 14px;
      margin-top: 20px;
    }
    .spinner {
      display: inline-block;
      width: 20px;
      height: 20px;
      border: 3px solid #f3f3f3;
      border-top: 3px solid #3498db;
      border-radius: 50%;
      animation: spin 1s linear infinite;
      margin-right: 10px;
      vertical-align: middle;
    }
    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="icon">${isSuccess ? '✅' : '❌'}</div>
    <h1>${isSuccess ? 'Thanh Toán Thành Công!' : 'Thanh Toán Thất Bại'}</h1>
    <p>${message}</p>
    <div class="amount">${amount.toLocaleString('vi-VN')} VNĐ</div>
    <div class="info">
      <div class="info-row">
        <span class="label">Mã đơn hàng:</span>
        <span class="value">${orderId}</span>
      </div>
      ${transactionNo ? `
      <div class="info-row">
        <span class="label">Mã GD VNPay:</span>
        <span class="value">${transactionNo}</span>
      </div>
      ` : ''}
      <div class="info-row">
        <span class="label">Thời gian:</span>
        <span class="value">${new Date().toLocaleString('vi-VN')}</span>
      </div>
    </div>
    ${isSuccess ? '<p><strong>✨ Đặt phòng thành công!</strong><br>Email xác nhận đã được gửi đến hộp thư của bạn.</p>' : ''}
    <div class="redirect-message">
      <div class="spinner"></div>
      Đang chuyển về ứng dụng...
    </div>
  </div>
  
  <script>
    // Try to open app với deep link
    window.location.href = '${deepLink}';
    
    // Fallback: Close window sau 3 giây nếu không mở được app
    setTimeout(function() {
      // Nếu là mobile browser, có thể close window
      if (window.close) {
        window.close();
      }
      // Hoặc redirect về trang chủ
      // window.location.href = 'https://yourapp.com';
    }, 3000);
  </script>
</body>
</html>
    `;
    
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.send(html);
  } catch (error) {
    console.error('❌ Error processing VNPay return:', error);
    res.status(500).json({
      success: false,
      message: 'Error processing payment return',
      error: error.message,
    });
  }
};

/**
 * VNPay IPN callback (server-to-server)
 * POST /api/payment/vnpay-ipn
 */
exports.vnpayIPN = async (req, res) => {
  try {
    const vnpParams = req.body || req.query;
    
    console.log('📥 VNPay IPN called');
    console.log('   Params:', Object.keys(vnpParams).join(', '));

    // Verify signature
    const isValid = vnpayService.verifyReturnUrl(vnpParams);

    if (!isValid) {
      return res.status(400).json({
        RspCode: '97',
        Message: 'Invalid signature',
      });
    }

    const responseCode = vnpParams.vnp_ResponseCode;
    const orderId = vnpParams.vnp_TxnRef;
    const transactionNo = vnpParams.vnp_TransactionNo;

    // Update payment status in database
    try {
      const { getPool } = require('../config/db');
      const pool = await getPool();
      
      const tableCheck = await pool.request()
        .query(`
          SELECT COUNT(*) as table_exists
          FROM INFORMATION_SCHEMA.TABLES 
          WHERE TABLE_NAME = 'payments'
        `);
      
      if (tableCheck.recordset[0].table_exists > 0) {
        const status = responseCode === '00' ? 'completed' : 'failed';
        
        await pool.request()
          .input('order_id', orderId)
          .input('status', status)
          .input('transaction_no', transactionNo || null)
          .input('response_code', responseCode)
          .input('bank_code', vnpParams.vnp_BankCode || null)
          .input('pay_date', vnpParams.vnp_PayDate || null)
          .query(`
            UPDATE payments 
            SET status = @status,
                transaction_no = @transaction_no,
                response_code = @response_code,
                bank_code = @bank_code,
                pay_date = @pay_date,
                updated_at = GETDATE()
            WHERE order_id = @order_id
          `);
        console.log('✅ Payment status updated via IPN');
      }
    } catch (dbError) {
      console.error('⚠️ Error updating payment via IPN:', dbError.message);
    }

    // Return success response to VNPay
    res.json({
      RspCode: '00',
      Message: 'Success',
    });
  } catch (error) {
    console.error('❌ Error processing VNPay IPN:', error);
    res.status(500).json({
      RspCode: '99',
      Message: 'Error processing IPN',
    });
  }
};

/**
 * Lấy cấu hình VNPay
 * GET /api/v2/vnpay/config
 */
exports.getConfig = (req, res) => {
  try {
    res.json({
      success: true,
      data: {
        returnUrl: vnpayConfig.vnp_ReturnUrl,
        ipnUrl: vnpayConfig.vnp_IpnUrl,
        tmnCode: vnpayConfig.vnp_TmnCode,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error getting config',
      error: error.message,
    });
  }
};

/**
 * Get payment status by order ID
 * GET /api/v2/vnpay/payment-status/:orderId
 */
exports.getPaymentStatus = async (req, res) => {
  try {
    const { orderId } = req.params;

    if (!orderId) {
      return res.status(400).json({
        success: false,
        message: 'Order ID is required',
      });
    }

    const { getPool } = require('../config/db');
    const pool = await getPool();
    
    // Check if payments table exists
    const tableCheck = await pool.request()
      .query(`
        SELECT COUNT(*) as table_exists
        FROM INFORMATION_SCHEMA.TABLES 
        WHERE TABLE_NAME = 'payments'
      `);
    
    if (tableCheck.recordset[0].table_exists === 0) {
      return res.status(404).json({
        success: false,
        message: 'Payments table not found',
      });
    }

    // Query payment status
    const result = await pool.request()
      .input('order_id', orderId)
      .query(`
        SELECT 
          booking_id,
          order_id,
          amount,
          status,
          payment_method,
          transaction_no,
          response_code,
          bank_code,
          pay_date,
          extra_data,
          created_at,
          updated_at
        FROM payments
        WHERE order_id = @order_id
      `);

    if (result.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Payment not found',
      });
    }

    const payment = result.recordset[0];
    
    // Parse extra_data if it exists
    if (payment.extra_data) {
      try {
        payment.extra_data = JSON.parse(payment.extra_data);
      } catch (e) {
        // Keep as string if can't parse
      }
    }

    res.json({
      success: true,
      data: payment,
    });
  } catch (error) {
    console.error('❌ Error getting payment status:', error);
    res.status(500).json({
      success: false,
      message: 'Error getting payment status',
      error: error.message,
    });
  }
};

/**
 * Query transaction status
 * POST /api/v2/vnpay/query-transaction
 */
exports.queryTransaction = async (req, res) => {
  try {
    const { orderId, transDate } = req.body;

    if (!orderId || !transDate) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: orderId, transDate',
      });
    }

    const result = await vnpayService.queryTransaction({
      orderId,
      transDate,
    });

    res.json({
      success: true,
      data: result,
    });
  } catch (error) {
    console.error('Error querying VNPay transaction:', error);
    res.status(500).json({
      success: false,
      message: 'Error querying transaction',
      error: error.message,
    });
  }
};

