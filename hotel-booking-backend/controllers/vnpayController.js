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

    // ✅ VALIDATION: Kiểm tra booking active và yêu cầu thanh toán
    if (userId && bookingData && bookingData.hotelId && bookingData.checkInDate && bookingData.checkOutDate) {
      console.log('🔍 VNPay - Starting validation check:', {
        userId,
        hotelId: bookingData.hotelId,
        checkInDate: bookingData.checkInDate,
        checkOutDate: bookingData.checkOutDate,
        paymentMethod: 'vnpay',
        amount,
        totalPrice: bookingData.totalPrice || bookingData.finalPrice || amount,
      });
      
      const BookingValidationService = require('../services/bookingValidationService');
      const validation = await BookingValidationService.validateBooking(
        userId,
        parseInt(bookingData.hotelId),
        new Date(bookingData.checkInDate),
        new Date(bookingData.checkOutDate),
        'vnpay',
        parseFloat(amount),
        parseFloat(bookingData.totalPrice || bookingData.finalPrice || amount)
      );

      console.log('🔍 VNPay - Validation result:', {
        isValid: validation.isValid,
        message: validation.message,
        requiresPayment: validation.requiresPayment,
        minPaymentPercentage: validation.minPaymentPercentage,
      });

      if (!validation.isValid) {
        console.log('❌ VNPay - Validation failed, blocking payment creation');
        return res.status(400).json({
          success: false,
          message: validation.message,
          data: {
            requiresPayment: validation.requiresPayment,
            minPaymentPercentage: validation.minPaymentPercentage,
          },
        });
      }
      
      console.log('✅ VNPay - Validation passed, proceeding with payment creation');
    } else {
      console.log('⚠️ VNPay - Validation skipped:', {
        hasUserId: !!userId,
        hasBookingData: !!bookingData,
        hasHotelId: !!(bookingData && bookingData.hotelId),
        hasCheckInDate: !!(bookingData && bookingData.checkInDate),
        hasCheckOutDate: !!(bookingData && bookingData.checkOutDate),
      });
    }

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

        // ✅ FIX: Use NVARCHAR(MAX) for extra_data to support Unicode (tiếng Việt)
        const sql = require('mssql');
        const extraDataJson = enrichedBookingData ? JSON.stringify(enrichedBookingData) : null;
        
        console.log('💾 Saving VNPay payment to DB (extra_data length:', extraDataJson?.length || 0, ')');
        
        await pool.request()
          .input('booking_id', bookingId)
          .input('order_id', orderId)
          .input('amount', amount)
          .input('extra_data', sql.NVarChar(sql.MAX), extraDataJson) // ✅ Explicitly use NVARCHAR(MAX)
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
    // ✅ FIX: Gọi auto-confirm ngay cả khi bookingId là null (sẽ tạo booking mới từ extra_data)
    if (isSuccess) {
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
    
    // ✅ FIX: Sử dụng HTTP 302 Redirect thay vì JavaScript
    // WebView Android sẽ intercept redirect này và trigger deep link
    console.log('🔗 Redirecting to deep link:', deepLink);
    res.redirect(302, deepLink);
    return;
    
    // Fallback HTML nếu redirect không hoạt động (commented out)
    /*
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
    // Improved deep link handler với multiple fallback methods
    (function() {
      const deepLink = '${deepLink}';
      let appOpened = false;
      
      // Method 1: Try iframe (works better on Android)
      function tryIframe() {
        const iframe = document.createElement('iframe');
        iframe.style.display = 'none';
        iframe.src = deepLink;
        document.body.appendChild(iframe);
        setTimeout(() => document.body.removeChild(iframe), 1000);
      }
      
      // Method 2: Direct location change
      function tryLocation() {
        window.location.href = deepLink;
      }
      
      // Method 3: Create and click hidden link
      function tryLink() {
        const link = document.createElement('a');
        link.href = deepLink;
        link.style.display = 'none';
        document.body.appendChild(link);
        link.click();
        setTimeout(() => document.body.removeChild(link), 500);
      }
      
      // Detect if app opened successfully
      const start = Date.now();
      document.addEventListener('visibilitychange', () => {
        if (document.hidden) {
          appOpened = true;
        }
      });
      
      window.addEventListener('blur', () => {
        appOpened = true;
      });
      
      // Try all methods
      setTimeout(() => {
        tryIframe();
        setTimeout(() => tryLocation(), 500);
        setTimeout(() => tryLink(), 1000);
      }, 500);
      
      // Fallback after 3 seconds if app not opened
      setTimeout(() => {
        if (!appOpened) {
          const elapsed = Date.now() - start;
          // If still on page after 3s, app probably didn't open
          if (elapsed > 2500) {
            // Show button to open app manually
            document.getElementById('manualOpen').style.display = 'block';
            document.querySelector('.redirect-message').innerHTML = 
              '<div style="color: #666;">Không tự động mở được app?<br>Nhấn nút bên dưới để mở thủ công</div>';
          }
        }
      }, 3000);
      
      // Auto close window if opened in new tab (after 5s)
      setTimeout(() => {
        if (appOpened) {
          window.close();
        }
      }, 5000);
    })();
    
    function openAppManually() {
      window.location.href = '${deepLink}';
      setTimeout(() => window.close(), 1000);
    }
  </script>
  
  <!-- Manual open button (hidden by default) -->
  <div id="manualOpen" style="display: none; text-align: center; margin-top: 20px;">
    <button onclick="openAppManually()" style="
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      border: none;
      padding: 15px 40px;
      font-size: 16px;
      border-radius: 25px;
      cursor: pointer;
      box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
      font-weight: 600;
    ">
      📱 Mở Ứng Dụng
    </button>
  </div>
</body>
</html>
    `;
    
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.send(html);
    */
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
          .query('SELECT booking_id, extra_data, amount FROM payments WHERE order_id = @order_id');
        
        if (paymentInfo.recordset.length > 0) {
          bookingId = paymentInfo.recordset[0].booking_id;
          extraData = paymentInfo.recordset[0].extra_data;
          const paymentAmount = paymentInfo.recordset[0].amount || amount;
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
        console.log('✅ Payment status updated via IPN');
      }
    } catch (dbError) {
      console.error('⚠️ Error updating payment via IPN:', dbError.message);
    }

    // ✅ AUTO-CONFIRM BOOKING nếu thanh toán thành công
    if (isSuccess) {
      try {
        const AutoConfirmBookingService = require('../services/autoConfirmBookingService');
        
        // Parse extra_data để lấy thông tin booking
        let bookingData = {};
        if (extraData) {
          try {
            bookingData = typeof extraData === 'string' ? JSON.parse(extraData) : extraData;
          } catch (e) {
            console.error('⚠️ IPN: Cannot parse extra_data:', e);
          }
        }
        
        console.log('🔄 IPN: Auto confirming booking...');
        await AutoConfirmBookingService.autoConfirmBookingAfterPayment({
          orderId: orderId,
          amount: amount,
          paymentMethod: 'vnpay',
          transactionId: transactionNo,
          bookingId: bookingId,
          bookingData: bookingData,
        });
        
        console.log('✅ IPN: Booking auto-confirmed');
      } catch (confirmError) {
        console.error('⚠️ IPN: Error auto-confirming booking (non-critical):', confirmError.message);
      }
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

/**
 * Get booking information by order ID (after successful payment)
 * GET /api/v2/payment/booking-info/:orderId
 * 
 * Supports:
 * - VNPay/Bank Transfer: orderId is payment.order_id
 * - Cash booking: orderId is booking.booking_code (no payment record)
 */
exports.getBookingInfoByOrderId = async (req, res) => {
  try {
    const { orderId } = req.params;

    if (!orderId) {
      return res.status(400).json({
        success: false,
        message: 'Order ID is required',
      });
    }

    const { getPool } = require('../config/db');
    const Booking = require('../models/booking');
    const pool = await getPool();

    console.log('🔍 Getting booking info for orderId:', orderId);

    // 1. Try to get payment record first (for VNPay/Bank Transfer)
    const paymentResult = await pool.request()
      .input('order_id', orderId)
      .query(`
        SELECT TOP 1
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
          created_at
        FROM payments
        WHERE order_id = @order_id
        ORDER BY created_at DESC
      `);

    let payment = null;
    let booking = null;

    if (paymentResult.recordset.length > 0) {
      // ✅ Found payment record (VNPay/Bank Transfer)
      payment = paymentResult.recordset[0];
      console.log('✅ Found payment record:', payment.order_id);

      // Get booking info if booking_id exists
      if (payment.booking_id) {
        try {
          booking = await Booking.getById(payment.booking_id);
          if (booking) {
            console.log('✅ Found booking by booking_id:', booking.id);
          }
        } catch (bookingError) {
          console.error('⚠️ Error getting booking by booking_id:', bookingError);
        }
      }

      // If no booking found, try to get from extra_data or find by matching criteria
      if (!booking && payment.extra_data) {
        try {
          let extraData = payment.extra_data;
          if (Array.isArray(extraData)) {
            extraData = extraData[0];
          }
          if (typeof extraData === 'string') {
            extraData = JSON.parse(extraData);
          }
          
          // Try to get booking by bookingId from extra_data
          if (extraData.bookingId) {
            try {
              booking = await Booking.getById(extraData.bookingId);
              if (booking) {
                console.log('✅ Found booking by bookingId from extra_data:', booking.id);
              }
            } catch (e) {
              console.error('⚠️ Error getting booking from extra_data.bookingId:', e);
            }
          }
          
          // ✅ FALLBACK: Nếu không có bookingId, tìm booking mới nhất của user với cùng hotel/room/check-in date
          if (!booking && extraData.userId && extraData.hotelId && extraData.roomId && extraData.checkInDate) {
            try {
              console.log('🔍 Trying to find booking by matching criteria...');
              const bookingResult = await pool.request()
                .input('user_id', sql.Int, extraData.userId)
                .input('hotel_id', sql.Int, extraData.hotelId)
                .input('room_id', sql.Int, extraData.roomId)
                .input('check_in_date', sql.Date, new Date(extraData.checkInDate))
                .query(`
                  SELECT TOP 1 *
                  FROM bookings
                  WHERE user_id = @user_id
                    AND hotel_id = @hotel_id
                    AND room_id = @room_id
                    AND CAST(check_in_date AS DATE) = CAST(@check_in_date AS DATE)
                    AND booking_status = 'confirmed'
                  ORDER BY created_at DESC
                `);
              
              if (bookingResult.recordset.length > 0) {
                booking = bookingResult.recordset[0];
                console.log('✅ Found booking by matching criteria:', booking.id, booking.booking_code);
                
                // Cập nhật booking_id vào payment record để lần sau tìm nhanh hơn
                try {
                  await pool.request()
                    .input('order_id', orderId)
                    .input('booking_id', sql.Int, booking.id)
                    .query(`
                      UPDATE payments
                      SET booking_id = @booking_id
                      WHERE order_id = @order_id AND booking_id IS NULL
                    `);
                  console.log('✅ Updated payment record with booking_id for future lookups');
                } catch (updateError) {
                  console.error('⚠️ Error updating payment record (non-critical):', updateError);
                }
              }
            } catch (findError) {
              console.error('⚠️ Error finding booking by matching criteria:', findError);
            }
          }
        } catch (parseError) {
          console.error('⚠️ Error parsing extra_data:', parseError);
        }
      }
    } else {
      // ❌ No payment record found - might be cash booking
      // Try to find booking by booking_code (orderId might be booking_code)
      console.log('⚠️ No payment record found, trying to find booking by booking_code...');
      try {
        booking = await Booking.getByCode(orderId);
        if (booking) {
          console.log('✅ Found booking by booking_code (Cash booking):', booking.booking_code);
          
          // Create a mock payment object for cash booking
          payment = {
            order_id: orderId,
            amount: booking.final_price || booking.total_price,
            status: booking.payment_status === 'paid' ? 'success' : 'pending',
            payment_method: booking.payment_method || 'cash',
            transaction_no: null,
            response_code: null,
            bank_code: null,
            pay_date: booking.payment_date || booking.created_at,
            created_at: booking.created_at,
          };
        }
      } catch (bookingError) {
        console.error('⚠️ Error getting booking by booking_code:', bookingError);
      }
    }

    // If still no booking found, return error
    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found',
        orderId: orderId,
      });
    }

    // Return combined payment + booking info
    res.json({
      success: true,
      data: {
        payment: payment ? {
          orderId: payment.order_id,
          amount: payment.amount,
          status: payment.status,
          paymentMethod: payment.payment_method,
          transactionNo: payment.transaction_no,
          bankCode: payment.bank_code,
          payDate: payment.pay_date,
          createdAt: payment.created_at,
        } : null,
        booking: {
          id: booking.id,
          bookingCode: booking.booking_code,
          hotelId: booking.hotel_id,
          hotelName: booking.hotel_name,
          roomId: booking.room_id,
          roomNumber: booking.room_number,
          roomType: booking.room_type,
          checkInDate: booking.check_in_date,
          checkOutDate: booking.check_out_date,
          guestCount: booking.guest_count,
          nights: booking.nights,
          totalPrice: booking.total_price,
          finalPrice: booking.final_price,
          discountAmount: booking.discount_amount,
          paymentMethod: booking.payment_method,
          paymentStatus: booking.payment_status,
          bookingStatus: booking.booking_status,
          createdAt: booking.created_at,
        },
      },
    });
  } catch (error) {
    console.error('❌ Error getting booking info:', error);
    res.status(500).json({
      success: false,
      message: 'Error getting booking information',
      error: error.message,
    });
  }
};

