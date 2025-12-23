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
const { connectToDatabase } = require('../config/db');

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
      });

      // Generate unique transaction ID
      const txnRef = `BANK_${Date.now()}_${orderId}`;
      
      // Create payment record in database
      const pool = await connectToDatabase();
      const request = new Request(pool);
      
      request.input('order_id', orderId);
      request.input('amount', amount);
      request.input('order_info', orderInfo);
      request.input('status', 'pending');
      request.input('transaction_id', txnRef);
      request.input('payment_method', 'Bank Transfer');
      request.input('user_name', userName || null);
      request.input('user_email', userEmail || null);
      request.input('user_phone', userPhone || null);
      
      await request.query(`
        INSERT INTO payments (
          order_id,
          amount,
          order_info,
          status,
          transaction_id,
          payment_method,
          user_name,
          user_email,
          user_phone,
          created_at
        ) VALUES (
          @order_id,
          @amount,
          @order_info,
          @status,
          @transaction_id,
          @payment_method,
          @user_name,
          @user_email,
          @user_phone,
          GETDATE()
        )
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
   * Display test bank transfer page (HTML)
   * GET /api/bank-transfer/test-page
   */
  async testPage(req, res) {
    const { orderId, amount, orderInfo, txnRef } = req.query;

    // Get base URL
    const baseUrl = process.env.BASE_URL || 
                   process.env.PUBLIC_URL || 
                   `http://localhost:${process.env.PORT || 5000}`;

    const html = `
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Mock Bank Transfer - Trip Hotel</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
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
      font-size: 24px;
      margin-bottom: 10px;
    }
    .test-badge {
      display: inline-block;
      background: #ff9800;
      color: white;
      padding: 4px 12px;
      border-radius: 12px;
      font-size: 12px;
      font-weight: bold;
      margin-bottom: 20px;
    }
    .info-box {
      background: #f5f5f5;
      border-radius: 12px;
      padding: 20px;
      margin-bottom: 30px;
    }
    .info-row {
      display: flex;
      justify-content: space-between;
      margin-bottom: 12px;
      font-size: 14px;
    }
    .info-row:last-child {
      margin-bottom: 0;
    }
    .label {
      color: #666;
      font-weight: 500;
    }
    .value {
      color: #333;
      font-weight: 600;
      text-align: right;
    }
    .amount {
      font-size: 32px;
      color: #667eea;
      font-weight: bold;
      text-align: center;
      margin: 20px 0;
    }
    .buttons {
      display: flex;
      gap: 15px;
    }
    button {
      flex: 1;
      padding: 16px;
      border: none;
      border-radius: 12px;
      font-size: 16px;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.3s;
    }
    .btn-success {
      background: #4caf50;
      color: white;
    }
    .btn-success:hover {
      background: #45a049;
      transform: translateY(-2px);
      box-shadow: 0 5px 15px rgba(76, 175, 80, 0.3);
    }
    .btn-failure {
      background: #f44336;
      color: white;
    }
    .btn-failure:hover {
      background: #da190b;
      transform: translateY(-2px);
      box-shadow: 0 5px 15px rgba(244, 67, 54, 0.3);
    }
    .note {
      margin-top: 20px;
      padding: 15px;
      background: #fff3cd;
      border-left: 4px solid #ffc107;
      border-radius: 4px;
      font-size: 13px;
      color: #856404;
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
      margin-top: 20px;
      color: #667eea;
    }
    .loading.active {
      display: block;
    }
    .spinner {
      display: inline-block;
      width: 30px;
      height: 30px;
      border: 3px solid #f3f3f3;
      border-top: 3px solid #667eea;
      border-radius: 50%;
      animation: spin 1s linear infinite;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">🏦</div>
      <h1>Mock Bank Transfer</h1>
      <span class="test-badge">TEST MODE</span>
    </div>

    <div class="info-box">
      <div class="info-row">
        <span class="label">Mã đơn hàng:</span>
        <span class="value">${orderId}</span>
      </div>
      <div class="info-row">
        <span class="label">Nội dung:</span>
        <span class="value">${orderInfo}</span>
      </div>
      <div class="info-row">
        <span class="label">Mã giao dịch:</span>
        <span class="value">${txnRef}</span>
      </div>
    </div>

    <div class="amount">${Number(amount).toLocaleString('vi-VN')} ₫</div>

    <div class="buttons">
      <button class="btn-success" onclick="handlePayment(true)">
        ✅ Thành công
      </button>
      <button class="btn-failure" onclick="handlePayment(false)">
        ❌ Thất bại
      </button>
    </div>

    <div class="loading" id="loading">
      <div class="spinner"></div>
      <p style="margin-top: 10px;">Đang xử lý...</p>
    </div>

    <div class="note">
      <strong>⚠️ Lưu ý:</strong>
      Đây là trang test giả lập chuyển khoản ngân hàng. Click "Thành công" để test luồng thanh toán thành công, click "Thất bại" để test luồng lỗi.
    </div>
  </div>

  <script>
    function handlePayment(success) {
      // Show loading
      document.getElementById('loading').classList.add('active');
      document.querySelectorAll('button').forEach(btn => btn.disabled = true);

      // Simulate processing delay (like real bank)
      setTimeout(() => {
        const returnUrl = '${baseUrl}/api/bank-transfer/return?' +
          'orderId=${encodeURIComponent(orderId)}' +
          '&amount=${encodeURIComponent(amount)}' +
          '&txnRef=${encodeURIComponent(txnRef)}' +
          '&responseCode=' + (success ? '00' : '99') +
          '&transactionStatus=' + (success ? '00' : '02');
        
        window.location.href = returnUrl;
      }, 1500);
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
      const { orderId, amount, txnRef, responseCode, transactionStatus } = req.query;

      console.log('🔙 Bank Transfer Return:', req.query);

      const isSuccess = responseCode === '00' && transactionStatus === '00';

      // Update payment status in database
      const pool = await connectToDatabase();
      const request = new Request(pool);

      request.input('order_id', orderId);
      request.input('status', isSuccess ? 'completed' : 'failed');
      request.input('response_code', responseCode);
      request.input('transaction_status', transactionStatus);

      await request.query(`
        UPDATE payments
        SET status = @status,
            response_code = @response_code,
            updated_at = GETDATE()
        WHERE order_id = @order_id
      `);

      if (isSuccess) {
        // Auto-confirm booking (similar to VNPay)
        const AutoConfirmBookingService = require('../services/autoConfirmBookingService');
        await AutoConfirmBookingService.autoConfirmBookingAfterPayment(orderId);
        console.log('✅ Auto-confirmed booking:', orderId);
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

      res.send(html);

    } catch (error) {
      console.error('❌ Error processing bank transfer return:', error);
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

      const pool = await connectToDatabase();
      const request = new Request(pool);
      request.input('order_id', orderId);

      const result = await request.query(`
        SELECT 
          order_id,
          amount,
          status,
          response_code,
          transaction_id,
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

