/**
 * Bank Transfer Controller (MOCK/TEST ONLY)
 * 
 * This is a MOCK implementation for testing bank transfer flow
 * Similar to VNPay but simpler (no real payment gateway)
 * 
 * Flow:
 * 1. User selects "Bank Transfer"
 * 2. Backend generates test payment URL
 * 3. App launches browser with test page
 * 4. User clicks "Thành công" or "Thất bại"
 * 5. Redirects back to app with result
 * 6. App processes result (similar to VNPay)
 */

const crypto = require('crypto');
const { Request } = require('mssql');
const { getPool } = require('../config/db');

class BankTransferController {
  /**
   * Create test bank transfer payment URL
   * POST /api/v2/bank-transfer/create-payment-url
   */
  async createPaymentUrl(req, res) {
    try {
      const {
        amount,
        orderInfo,
        orderId,
        bookingCode,
        userName,
        userEmail,
        userPhone,
        // ✅ NEW: Booking data for auto-confirm
        userId,
        hotelId,
        hotelName,
        roomId,
        roomType,
        checkInDate,
        checkOutDate,
        guestCount,
        nights,
        finalPrice,
        totalPrice,
      } = req.body;

      // Validate required fields
      if (!amount || !orderInfo || !orderId) {
        return res.status(400).json({
          success: false,
          message: 'Thiếu thông tin bắt buộc (amount, orderInfo, orderId)',
        });
      }

      console.log('📝 Creating Bank Transfer payment:', {
        orderId,
        amount,
        orderInfo,
        hotelId,
        userId,
      });

      // ✅ VALIDATION: Kiểm tra booking active và yêu cầu thanh toán
      if (userId && hotelId && checkInDate && checkOutDate) {
        console.log('🔍 Bank Transfer - Starting validation check:', {
          userId,
          hotelId,
          checkInDate,
          checkOutDate,
          paymentMethod: 'bank_transfer',
          amount,
          totalPrice: totalPrice || finalPrice || amount,
        });
        
        const BookingValidationService = require('../services/bookingValidationService');
        const validation = await BookingValidationService.validateBooking(
          userId,
          parseInt(hotelId),
          new Date(checkInDate),
          new Date(checkOutDate),
          'bank_transfer',
          parseFloat(amount),
          parseFloat(totalPrice || finalPrice || amount)
        );

        console.log('🔍 Bank Transfer - Validation result:', {
          isValid: validation.isValid,
          message: validation.message,
          requiresPayment: validation.requiresPayment,
          minPaymentPercentage: validation.minPaymentPercentage,
        });

        if (!validation.isValid) {
          console.log('❌ Bank Transfer - Validation failed, blocking payment creation');
          return res.status(400).json({
            success: false,
            message: validation.message,
            data: {
              requiresPayment: validation.requiresPayment,
              minPaymentPercentage: validation.minPaymentPercentage,
            },
          });
        }
        
        console.log('✅ Bank Transfer - Validation passed, proceeding with payment creation');
      } else {
        console.log('⚠️ Bank Transfer - Validation skipped:', {
          hasUserId: !!userId,
          hasHotelId: !!hotelId,
          hasCheckInDate: !!checkInDate,
          hasCheckOutDate: !!checkOutDate,
        });
      }

      // Generate unique transaction ID
      const txnRef = `BANK_${Date.now()}_${orderId}`;
      
      // Create extra_data object with FULL booking data (similar to VNPay)
      const extraData = {
        userName,
        userEmail,
        userPhone,
        orderInfo,
        txnRef,
        // ✅ Booking data for auto-confirm
        userId,
        hotelId,
        hotelName,
        roomId,
        roomType,
        checkInDate,
        checkOutDate,
        guestCount,
        nights,
        finalPrice: finalPrice || amount,
        totalPrice: totalPrice || amount,
      };
      
      // Create payment record in database (match VNPay schema)
      const pool = await getPool();
      const { Request } = require('mssql');
      const sql = require('mssql');
      const request = new Request(pool);
      
      // Generate temporary numeric booking_id (will be updated after real booking is created)
      // Use smaller number to fit SQL Server INT (max: 2,147,483,647)
      // Take last 9 digits of timestamp to ensure it fits in INT
      const tempBookingId = Math.floor(Date.now() % 2000000000); // Keep under INT max
      
      // Use 'cash' as payment_method to comply with CHECK constraint
      const paymentMethodValue = 'cash';
      
      // ✅ FIX: Explicitly specify NVARCHAR(MAX) type for extra_data to support Unicode (tiếng Việt)
      const extraDataJson = JSON.stringify(extraData);
      console.log('💾 Saving extra_data to DB (length:', extraDataJson.length, ')');
      console.log('💾 Extra data preview:', extraDataJson.substring(0, 200));
      
      await request
        .input('booking_id', tempBookingId)
        .input('order_id', orderId)
        .input('amount', amount)
        .input('status', 'pending')
        .input('payment_method', paymentMethodValue)
        .input('extra_data', sql.NVarChar(sql.MAX), extraDataJson) // ✅ Explicitly use NVARCHAR(MAX)
        .query(`
          INSERT INTO payments (booking_id, order_id, amount, status, payment_method, extra_data, created_at)
          VALUES (@booking_id, @order_id, @amount, @status, @payment_method, @extra_data, GETDATE())
        `);

      // Get base URL from environment or request
      const baseUrl = process.env.BASE_URL || 
                     process.env.PUBLIC_URL || 
                     `http://localhost:${process.env.PORT || 5000}`;

      // Create test payment URL (points to our mock bank page)
      const paymentUrl = `${baseUrl}/api/bank-transfer/test-page?` + 
        `orderId=${encodeURIComponent(orderId)}&` +
        `amount=${encodeURIComponent(amount)}&` +
        `orderInfo=${encodeURIComponent(orderInfo)}&` +
        `txnRef=${encodeURIComponent(txnRef)}`;
      
      console.log('✅ Bank Transfer URL created:', paymentUrl);

      return res.json({
        success: true,
        message: 'Tạo link thanh toán thành công',
        data: {
          paymentUrl,
          orderId,
          txnRef,
          amount,
        },
      });

    } catch (error) {
      console.error('❌ Error creating bank transfer URL:', error);
      return res.status(500).json({
        success: false,
        message: 'Lỗi tạo link thanh toán',
        error: error.message,
      });
    }
  }

  /**
   * Display QR code payment page (HTML)
   * GET /api/bank-transfer/test-page
   */
  async testPage(req, res) {
    const { orderId, amount, orderInfo, txnRef } = req.query;

    // Get base URL
    const baseUrl = process.env.BASE_URL || 
                   process.env.PUBLIC_URL || 
                   `http://localhost:${process.env.PORT || 5000}`;

    // Bank account info (config này nên lưu trong .env)
    const BANK_ID = '970422'; // VietinBank (MB Bank: 970422, VCB: 970436, TCB: 970407)
    const ACCOUNT_NO = '1234567890'; // Số tài khoản
    const ACCOUNT_NAME = 'TRIP HOTEL'; // Tên tài khoản (viết hoa, không dấu)
    
    // Generate VietQR URL (chuẩn VietQR)
    const qrContent = `${orderId} ${amount}`;
    const vietQRUrl = `https://img.vietqr.io/image/${BANK_ID}-${ACCOUNT_NO}-compact2.png?` +
      `amount=${amount}&` +
      `addInfo=${encodeURIComponent(orderInfo)}&` +
      `accountName=${encodeURIComponent(ACCOUNT_NAME)}`;

    const html = `
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Chuyển khoản ngân hàng - Trip Hotel</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif;
      background: linear-gradient(135deg, #2196F3 0%, #1976D2 100%);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 20px;
    }
    .container {
      background: white;
      border-radius: 20px;
      padding: 40px;
      max-width: 500px;
      width: 100%;
      box-shadow: 0 20px 60px rgba(0,0,0,0.3);
    }
    .header {
      text-align: center;
      margin-bottom: 30px;
    }
    .logo {
      font-size: 48px;
      margin-bottom: 10px;
    }
    h1 {
      color: #333;
      font-size: 22px;
      margin-bottom: 5px;
    }
    .subtitle {
      color: #666;
      font-size: 14px;
    }
    .qr-section {
      text-align: center;
      margin: 30px 0;
      padding: 20px;
      background: #f8f9fa;
      border-radius: 12px;
    }
    .qr-code {
      width: 250px;
      height: 250px;
      margin: 0 auto 15px;
      background: white;
      padding: 15px;
      border-radius: 12px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.1);
    }
    .qr-code img {
      width: 100%;
      height: 100%;
      object-fit: contain;
    }
    .qr-note {
      font-size: 13px;
      color: #666;
      margin-top: 10px;
    }
    .bank-info {
      background: #fff;
      border: 2px solid #e0e0e0;
      border-radius: 12px;
      padding: 20px;
      margin: 20px 0;
    }
    .bank-info-row {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 15px;
      padding-bottom: 15px;
      border-bottom: 1px solid #f0f0f0;
    }
    .bank-info-row:last-child {
      margin-bottom: 0;
      padding-bottom: 0;
      border-bottom: none;
    }
    .bank-label {
      color: #666;
      font-size: 13px;
      font-weight: 500;
    }
    .bank-value {
      color: #333;
      font-size: 15px;
      font-weight: 600;
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .copy-btn {
      background: #2196F3;
      color: white;
      border: none;
      padding: 4px 8px;
      border-radius: 6px;
      font-size: 11px;
      cursor: pointer;
      transition: all 0.2s;
    }
    .copy-btn:hover {
      background: #1976D2;
    }
    .copy-btn:active {
      transform: scale(0.95);
    }
    .amount-highlight {
      text-align: center;
      margin: 25px 0;
      padding: 20px;
      background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%);
      border-radius: 12px;
      color: white;
    }
    .amount-label {
      font-size: 14px;
      opacity: 0.9;
      margin-bottom: 8px;
    }
    .amount-value {
      font-size: 36px;
      font-weight: bold;
    }
    .confirm-btn {
      width: 100%;
      padding: 16px;
      border: none;
      border-radius: 12px;
      font-size: 16px;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.3s;
      background: #4CAF50;
      color: white;
      margin-top: 20px;
    }
    .confirm-btn:hover {
      background: #45a049;
      transform: translateY(-2px);
      box-shadow: 0 5px 15px rgba(76, 175, 80, 0.3);
    }
    .confirm-btn:disabled {
      background: #ccc;
      cursor: not-allowed;
      transform: none;
    }
    .note {
      margin-top: 20px;
      padding: 15px;
      background: #e3f2fd;
      border-left: 4px solid #2196F3;
      border-radius: 4px;
      font-size: 13px;
      color: #1565C0;
    }
    .note strong {
      display: block;
      margin-bottom: 5px;
    }
    @keyframes spin {
      to { transform: rotate(360deg); }
    }
    .loading {
      display: none;
      text-align: center;
      margin-top: 15px;
      color: #2196F3;
    }
    .loading.active {
      display: block;
    }
    .spinner {
      display: inline-block;
      width: 30px;
      height: 30px;
      border: 3px solid #f3f3f3;
      border-top: 3px solid #2196F3;
      border-radius: 50%;
      animation: spin 1s linear infinite;
    }
    .copied-toast {
      position: fixed;
      top: 20px;
      right: 20px;
      background: #4CAF50;
      color: white;
      padding: 12px 20px;
      border-radius: 8px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.2);
      opacity: 0;
      transition: opacity 0.3s;
      z-index: 1000;
    }
    .copied-toast.show {
      opacity: 1;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">🏦</div>
      <h1>Chuyển khoản ngân hàng</h1>
      <p class="subtitle">Quét mã QR hoặc chuyển khoản thủ công</p>
    </div>

    <!-- QR Code Section -->
    <div class="qr-section">
      <div class="qr-code">
        <img src="${vietQRUrl}" alt="VietQR Code" onerror="this.src='data:image/svg+xml,%3Csvg xmlns=%27http://www.w3.org/2000/svg%27 viewBox=%270 0 100 100%27%3E%3Ctext y=%27.9em%27 font-size=%2750%27%3E📱%3C/text%3E%3C/svg%3E'" />
      </div>
      <p class="qr-note">📱 Quét mã QR bằng app ngân hàng để chuyển khoản</p>
    </div>

    <!-- Bank Info -->
    <div class="bank-info">
      <div class="bank-info-row">
        <span class="bank-label">Ngân hàng</span>
        <span class="bank-value">VietinBank</span>
      </div>
      <div class="bank-info-row">
        <span class="bank-label">Số tài khoản</span>
        <span class="bank-value">
          ${ACCOUNT_NO}
          <button class="copy-btn" onclick="copyText('${ACCOUNT_NO}')">Copy</button>
        </span>
      </div>
      <div class="bank-info-row">
        <span class="bank-label">Chủ tài khoản</span>
        <span class="bank-value">${ACCOUNT_NAME}</span>
      </div>
      <div class="bank-info-row">
        <span class="bank-label">Nội dung CK</span>
        <span class="bank-value">
          ${orderId}
          <button class="copy-btn" onclick="copyText('${orderId}')">Copy</button>
        </span>
      </div>
    </div>

    <!-- Amount -->
    <div class="amount-highlight">
      <div class="amount-label">Số tiền cần chuyển</div>
      <div class="amount-value">${Number(amount).toLocaleString('vi-VN')} ₫</div>
    </div>

    <!-- Confirm Button -->
    <button class="confirm-btn" id="confirmBtn" onclick="handleConfirm()">
      ✅ Tôi đã chuyển khoản
    </button>

    <div class="loading" id="loading">
      <div class="spinner"></div>
      <p style="margin-top: 10px;">Đang xác nhận...</p>
    </div>

    <div class="note">
      <strong>📝 Lưu ý quan trọng:</strong>
      • Vui lòng chuyển <strong>ĐÚNG số tiền</strong> như trên<br>
      • Điền <strong>ĐÚNG nội dung</strong> để xác nhận tự động<br>
      • Sau khi chuyển khoản, click nút "Tôi đã chuyển khoản"<br>
      • Hệ thống sẽ xác nhận và cập nhật booking
    </div>
  </div>

  <!-- Toast notification -->
  <div class="copied-toast" id="toast">✅ Đã copy!</div>

  <script>
    function copyText(text) {
      navigator.clipboard.writeText(text).then(() => {
        const toast = document.getElementById('toast');
        toast.classList.add('show');
        setTimeout(() => {
          toast.classList.remove('show');
        }, 2000);
      });
    }

    function handleConfirm() {
      const btn = document.getElementById('confirmBtn');
      const loading = document.getElementById('loading');
      
      btn.disabled = true;
      loading.classList.add('active');

      // Simulate bank verification (in real app, this would call bank API)
      setTimeout(() => {
        const returnUrl = '${baseUrl}/api/bank-transfer/return?' +
          'orderId=${encodeURIComponent(orderId)}' +
          '&amount=${encodeURIComponent(amount)}' +
          '&txnRef=${encodeURIComponent(txnRef)}' +
          '&responseCode=00' +
          '&transactionStatus=00';
        
        window.location.href = returnUrl;
      }, 2000);
    }
  </script>
</body>
</html>
    `;

    res.send(html);
  }

  /**
   * Handle return from bank transfer (like VNPay return)
   * GET /api/bank-transfer/return
   */
  async bankTransferReturn(req, res) {
    try {
      // Support both GET (callback) and POST (manual confirmation)
      const params = req.method === 'POST' ? req.body : req.query;
      const { orderId, amount, txnRef, responseCode, transactionStatus, success } = params;

      console.log('🔙 Bank Transfer Return:', { method: req.method, params });

      // For POST (manual confirmation), success is explicitly set
      // For GET (callback), check responseCode and transactionStatus
      const isSuccess = req.method === 'POST' 
        ? (success === 'true' || success === true)
        : (responseCode === '00' && transactionStatus === '00');

      // Get payment record from database first to get amount and txnRef
      const pool = await getPool();
      
      // 1. Get existing payment record
      const getPaymentRequest = new Request(pool);
      getPaymentRequest.input('order_id', orderId);
      const paymentResult = await getPaymentRequest.query(`
        SELECT amount, transaction_no, extra_data
        FROM payments
        WHERE order_id = @order_id
      `);

      if (paymentResult.recordset.length === 0) {
        throw new Error('Payment record not found for orderId: ' + orderId);
      }

      const paymentRecord = paymentResult.recordset[0];
      const paymentAmount = amount || paymentRecord.amount; // Use param if available, else from DB
      const paymentTxnRef = txnRef || paymentRecord.transaction_no || orderId; // Use param if available, else from DB

      console.log('💰 Payment info:', {
        orderId,
        amount: paymentAmount,
        txnRef: paymentTxnRef,
        fromParams: { amount, txnRef },
        fromDB: { amount: paymentRecord.amount, txnRef: paymentRecord.transaction_no }
      });

      // 2. Update payment status in database
      const updateRequest = new Request(pool);
      updateRequest.input('order_id', orderId);
      updateRequest.input('status', isSuccess ? 'completed' : 'failed');
      updateRequest.input('response_code', responseCode || '00'); // Default to '00' for manual confirmation
      updateRequest.input('transaction_status', transactionStatus || '00');

      await updateRequest.query(`
        UPDATE payments
        SET status = @status,
            response_code = @response_code,
            updated_at = GETDATE()
        WHERE order_id = @order_id
      `);

      if (isSuccess) {
        // Auto-confirm booking (similar to VNPay)
        try {
          const AutoConfirmBookingService = require('../services/autoConfirmBookingService');
          
          // Get extra_data từ payment record
          let bookingData = {};
          let bookingId = null;
          
          const paymentInfo = await pool.request()
            .input('order_id', orderId)
            .query('SELECT booking_id, extra_data FROM payments WHERE order_id = @order_id');
          
          if (paymentInfo.recordset.length > 0) {
            bookingId = paymentInfo.recordset[0].booking_id;
            const extraData = paymentInfo.recordset[0].extra_data;
            
            if (extraData) {
              try {
                bookingData = typeof extraData === 'string' ? JSON.parse(extraData) : extraData;
              } catch (e) {
                console.error('⚠️ Bank Transfer: Cannot parse extra_data:', e);
              }
            }
          }
          
          await AutoConfirmBookingService.autoConfirmBookingAfterPayment({
            orderId: orderId,
            amount: paymentAmount,
            paymentMethod: 'bank_transfer',
            transactionId: paymentTxnRef,
            bookingId: bookingId,
            bookingData: bookingData,
          });
          console.log('✅ Auto-confirmed booking:', orderId);
        } catch (confirmError) {
          console.error('⚠️ Bank Transfer: Error auto-confirming booking (non-critical):', confirmError.message);
        }
      }

      // Redirect to app with deep link
      const deepLink = `banktransfer://return?` +
        `orderId=${encodeURIComponent(orderId)}&` +
        `success=${isSuccess}&` +
        `responseCode=${responseCode}`;

      // Send HTML with redirect
      const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Đang chuyển về app...</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      margin: 0;
      background: ${isSuccess ? '#4caf50' : '#f44336'};
      color: white;
    }
    .container {
      text-align: center;
      padding: 40px;
    }
    .icon {
      font-size: 80px;
      margin-bottom: 20px;
    }
    h1 {
      font-size: 24px;
      margin-bottom: 10px;
    }
    p {
      font-size: 16px;
      opacity: 0.9;
    }
    .spinner {
      display: inline-block;
      width: 40px;
      height: 40px;
      border: 4px solid rgba(255,255,255,0.3);
      border-top: 4px solid white;
      border-radius: 50%;
      animation: spin 1s linear infinite;
      margin-top: 20px;
    }
    @keyframes spin {
      to { transform: rotate(360deg); }
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="icon">${isSuccess ? '✅' : '❌'}</div>
    <h1>${isSuccess ? 'Thanh toán thành công!' : 'Thanh toán thất bại'}</h1>
    <p>Đang chuyển về ứng dụng...</p>
    <div class="spinner"></div>
  </div>
  <script>
    // Try to redirect to app
    setTimeout(() => {
      window.location.href = '${deepLink}';
      
      // Fallback: close window after 3 seconds
      setTimeout(() => {
        window.close();
      }, 3000);
    }, 1000);
  </script>
</body>
</html>
      `;

      // For POST requests (manual confirmation), return JSON
      if (req.method === 'POST') {
        return res.json({
          success: true,
          message: isSuccess ? 'Thanh toán thành công' : 'Thanh toán thất bại',
          data: {
            orderId,
            isSuccess,
          },
        });
      }

      // For GET requests (callback), return HTML
      res.send(html);

    } catch (error) {
      console.error('❌ Error processing bank transfer return:', error);
      
      // For POST requests, return JSON error
      if (req.method === 'POST') {
        return res.status(500).json({
          success: false,
          message: 'Lỗi xử lý thanh toán',
          error: error.message,
        });
      }
      
      // For GET requests, return HTML error
      res.status(500).send(`
        <html>
          <body style="font-family: Arial; text-align: center; padding: 50px;">
            <h1>❌ Lỗi xử lý thanh toán</h1>
            <p>${error.message}</p>
          </body>
        </html>
      `);
    }
  }

  /**
   * Get payment status by order ID
   * GET /api/v2/bank-transfer/payment-status/:orderId
   */
  async getPaymentStatus(req, res) {
    try {
      const { orderId } = req.params;

      const pool = await getPool();
      const request = new Request(pool);
      request.input('order_id', orderId);

      const result = await request.query(`
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
          message: 'Không tìm thấy giao dịch',
        });
      }

      return res.json({
        success: true,
        data: result.recordset[0],
      });

    } catch (error) {
      console.error('❌ Error getting payment status:', error);
      return res.status(500).json({
        success: false,
        message: 'Lỗi lấy thông tin thanh toán',
        error: error.message,
      });
    }
  }
}

module.exports = new BankTransferController();

