/**
 * MoMo Controller - Xử lý các request liên quan đến MoMo
 */

const momoService = require('../services/momoService');
const momoConfig = require('../config/momo');
const db = require('../config/db');
const Booking = require('../models/booking');

/**
 * Tạo URL thanh toán MoMo (giống VNPay)
 * 
 * POST /api/payment/momo/create-payment-url
 * Body: {
 *   bookingId: number,
 *   amount: number,
 *   orderInfo: string,
 *   bookingData: object (optional - full booking info để tạo booking sau payment)
 * }
 */
exports.createPaymentUrl = async (req, res) => {
  try {
    const { bookingId, amount, orderInfo, bookingData } = req.body;

    // Validate
    if (!bookingId || !amount || !orderInfo) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: bookingId, amount, orderInfo',
      });
    }
    
    // Kiểm tra Return URL
    const momoConfig = require('../config/momo');
    const returnUrl = momoConfig.returnUrl;
    
    if (returnUrl.includes('localhost') || returnUrl.includes('127.0.0.1')) {
      console.error('❌ MoMo Return URL đang là localhost!');
      return res.status(400).json({
        success: false,
        message: 'MoMo không chấp nhận localhost làm Return URL. Vui lòng set MOMO_RETURN_URL trong file .env với IP public hoặc domain công khai.',
        error: 'INVALID_RETURN_URL',
        currentReturnUrl: returnUrl,
        hint: 'Nếu dùng IP public, đảm bảo đã setup port forwarding và IP có thể truy cập từ internet.',
      });
    }
    
    // Log thông tin Return URL để debug
    console.log('💗 ===== MoMo Create Payment =====');
    console.log('📋 MoMo Return URL:', returnUrl);
    console.log('📋 MoMo IPN URL:', momoConfig.ipnUrl);
    console.log('📋 Order ID:', `BOOKING_${bookingId}_${Date.now()}`);
    console.log('📋 Amount:', amount, 'VND');
    console.log('💡 Lưu ý về MoMo:');
    console.log('   - MoMo KHÔNG cần đăng ký IP/URL trong merchant portal');
    console.log('   - Chỉ cần đảm bảo Return URL và IPN URL accessible từ internet');
    console.log('   - Nếu gặp lỗi, kiểm tra:');
    console.log('     1. IP/domain có thể truy cập từ internet không');
    console.log('     2. Port forwarding đã setup đúng chưa (nếu dùng IP)');
    console.log('     3. Firewall đã mở port 5000 chưa');
    
    // Lấy userId từ JWT token nếu có
    let userId = null;
    if (req.user) {
      userId = req.user.id || req.user.ma_nguoi_dung;
    }
    
    // Thêm userId vào bookingData
    const enrichedBookingData = bookingData ? {
      ...bookingData,
      userId: bookingData.userId || userId,
    } : null;

    // Validate amount
    if (amount < 1000 || amount > 50000000) {
      return res.status(400).json({
        success: false,
        message: 'Amount must be between 1,000 and 50,000,000 VND',
      });
    }

    // Tạo order ID unique
    const orderId = `BOOKING_${bookingId}_${Date.now()}`;

    // Tạo payment URL từ MoMo service
    const paymentResult = await momoService.createPaymentUrl({
      orderId,
      amount,
      orderInfo,
    });

    const paymentUrl = paymentResult.paymentUrl;
    const qrCodeUrl = paymentResult.qrCodeUrl;
    const deeplink = paymentResult.deeplink;

    // Lưu thông tin payment vào database (với booking data)
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
        await pool.request()
          .input('booking_id', bookingId)
          .input('order_id', orderId)
          .input('amount', amount)
          .input('extra_data', enrichedBookingData ? JSON.stringify(enrichedBookingData) : null)
          .query(`
            INSERT INTO payments (booking_id, order_id, amount, status, payment_method, extra_data, created_at)
            VALUES (@booking_id, @order_id, @amount, 'pending', 'momo', @extra_data, GETDATE())
          `);
        console.log('✅ MoMo payment record saved to database');
      } else {
        console.warn('⚠️ Payments table does not exist, skipping database save');
      }
    } catch (dbError) {
      console.error('⚠️ Error saving payment to database (non-critical):', dbError.message);
    }

    res.json({
      success: true,
      data: {
        paymentUrl,
        qrCodeUrl: qrCodeUrl || null,
        deeplink: deeplink || null,
        orderId,
      },
    });
    } catch (error) {
      console.error('❌ Error creating MoMo payment URL:', error);
      
      // Xác định HTTP status code dựa trên loại lỗi
      let statusCode = 500;
      let errorMessage = error.message || 'Error creating payment URL';
      
      // Nếu là lỗi từ MoMo server (502, timeout, etc.)
      if (error.message.includes('502') || error.message.includes('Bad Gateway')) {
        statusCode = 503; // Service Unavailable
        errorMessage = 'MoMo payment gateway đang tạm thời không khả dụng. Vui lòng thử lại sau hoặc sử dụng phương thức thanh toán khác.';
      } else if (error.message.includes('timeout')) {
        statusCode = 504; // Gateway Timeout
        errorMessage = 'MoMo API request timeout. Vui lòng thử lại sau.';
      } else if (error.message.includes('ECONNREFUSED') || error.message.includes('ENOTFOUND')) {
        statusCode = 503;
        errorMessage = 'Không thể kết nối đến MoMo API. Vui lòng thử lại sau.';
      }
      
      res.status(statusCode).json({
        success: false,
        message: errorMessage,
        error: error.message,
        errorType: error.constructor.name,
        timestamp: new Date().toISOString(),
        suggestion: 'Vui lòng thử lại sau hoặc sử dụng phương thức thanh toán khác (VNPay).',
      });
    }
};

/**
 * Tạo payment request đến MoMo (legacy - giữ để tương thích)
 * 
 * POST /api/payment/momo/create-payment
 * Body: {
 *   bookingId: number,
 *   amount: number,
 *   orderInfo: string,
 *   extraData: string (optional, base64),
 *   bookingData: object (optional)
 * }
 */
exports.createPayment = async (req, res) => {
  try {
    const { bookingId, amount, orderInfo, extraData, bookingData } = req.body;

    // Validate
    if (!bookingId || !amount || !orderInfo) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: bookingId, amount, orderInfo',
      });
    }

    // Tạo order ID unique
    const orderId = `BOOKING_${bookingId}_${Date.now()}`;

    // Gọi createPaymentUrl và trả về format cũ
    const paymentResult = await momoService.createPaymentUrl({
      orderId,
      amount,
      orderInfo,
    });

    // Trả về format giống như trước (có payUrl, deeplink, qrCodeUrl)
    res.json({
      success: true,
      data: {
        payUrl: paymentResult.paymentUrl,
        qrCodeUrl: paymentResult.qrCodeUrl || null,
        deeplink: paymentResult.deeplink || null,
        requestId: momoConfig.partnerCode + Date.now(),
        orderId: orderId,
      },
    });
  } catch (error) {
    console.error('Error creating MoMo payment:', error);
    res.status(500).json({
      success: false,
      message: 'Error creating payment',
      error: error.message,
    });
  }
};

/**
 * Xử lý return URL từ MoMo sau khi user thanh toán
 * 
 * GET /api/payment/momo-return
 * Query params từ MoMo
 */
exports.momoReturn = async (req, res) => {
  try {
    console.log('');
    console.log('💗 ===== MoMo Return Callback =====');
    console.log('⏰ Time:', new Date().toISOString());
    console.log('📍 URL:', req.originalUrl);
    console.log('📥 Query Params:', req.query);
    console.log('📥 Query Params Count:', Object.keys(req.query).length);
    console.log('═══════════════════════════════════════════════════════');
    
    const momoData = req.query;

    console.log('📋 MoMo Return Data:', momoData);

    // Verify signature
    const isValid = momoService.verifySignature(momoData);

    if (!isValid) {
      console.error('Invalid MoMo signature');
      // Trả về HTML với params để Flutter app có thể detect
      return res.send(`
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>MoMo Payment Error</title>
</head>
<body>
  <div style="text-align: center; padding: 20px;">
    <h1 style="color: #dc3545;">❌ Lỗi xác thực chữ ký</h1>
    <p>Vui lòng đợi...</p>
    <script>
      // Giữ nguyên URL với params để Flutter app detect
      if (window.location.search.includes('resultCode')) {
        window.location.href = window.location.href;
      }
    </script>
  </div>
</body>
</html>
      `);
    }

    // Lấy thông tin giao dịch
    const {
      orderId,
      amount,
      resultCode,
      transId,
      payType,
      responseTime,
      message,
    } = momoData;

    // Parse amount
    const actualAmount = parseInt(amount);

    // Get message
    const resultMessage = momoService.getResultMessage(parseInt(resultCode));

    // Update payment status trong database
    try {
      if (resultCode === '0') {
        // Thanh toán thành công
        const { getPool } = require('../config/db');
        const pool = await getPool();
        
        const tableCheck = await pool.request()
          .query(`
            SELECT COUNT(*) as table_exists
            FROM INFORMATION_SCHEMA.TABLES 
            WHERE TABLE_NAME = 'payments'
          `);
        
        let bookingCode = null;
        
        if (tableCheck.recordset[0].table_exists > 0) {
          // Lấy booking data từ payment record (bao gồm cả user_id nếu có)
          const paymentResult = await pool.request()
            .input('order_id', orderId)
            .query(`SELECT extra_data, user_id FROM payments WHERE order_id = @order_id`);
          
          if (paymentResult.recordset.length > 0 && paymentResult.recordset[0].extra_data) {
            try {
              const bookingData = JSON.parse(paymentResult.recordset[0].extra_data);
              
              // Đảm bảo userId có trong bookingData
              // Nếu không có, thử lấy từ payment record hoặc từ request
              if (!bookingData.userId) {
                // Thử lấy từ payment record nếu có
                const paymentRecord = paymentResult.recordset[0];
                if (paymentRecord.user_id) {
                  bookingData.userId = paymentRecord.user_id;
                } else if (req.user?.id || req.user?.ma_nguoi_dung) {
                  bookingData.userId = req.user.id || req.user.ma_nguoi_dung;
                }
              }
              
              console.log(`📝 MoMo: Creating booking with userId=${bookingData.userId}, finalPrice=${bookingData.finalPrice || bookingData.totalPrice}`);
              
              const booking = await Booking.create({
                ...bookingData,
                paymentStatus: 'paid',
                paymentMethod: 'momo',
                paymentTransactionId: transId,
              });
              
              bookingCode = booking.booking_code;
              console.log('✅ MoMo booking created:', bookingCode);
            } catch (bookingError) {
              console.error('❌ Error creating booking:', bookingError);
            }
          }
          
          await pool.request()
            .input('transaction_no', transId)
            .input('pay_date', responseTime)
            .input('response_code', resultCode)
            .input('order_id', orderId)
            .query(`
              UPDATE payments 
              SET status = 'completed', 
                  transaction_no = @transaction_no,
                  pay_date = @pay_date,
                  response_code = @response_code,
                  updated_at = GETDATE()
              WHERE order_id = @order_id
            `);

          // ✅ TỰ ĐỘNG XÁC NHẬN BOOKING NẾU ĐÃ THANH TOÁN >= 50%
          try {
            const AutoConfirmBookingService = require('../services/autoConfirmBookingService');
            // Parse amount từ orderId hoặc lấy từ payment record
            const paymentAmountResult = await pool.request()
              .input('order_id', orderId)
              .query(`SELECT amount FROM payments WHERE order_id = @order_id`);
            
            const paymentAmount = paymentAmountResult.recordset[0]?.amount || 0;
            
            const autoConfirmResult = await AutoConfirmBookingService.autoConfirmBookingAfterPayment({
              orderId,
              amount: paymentAmount,
              paymentMethod: 'momo',
              transactionId: transId
            });

            if (autoConfirmResult.success) {
              console.log('✅ MoMo: Auto confirmed booking:', autoConfirmResult.booking?.bookingCode);
              if (autoConfirmResult.emailSent) {
                console.log('📧 MoMo: Confirmation email sent to customer');
              }
            } else {
              console.log('ℹ️ MoMo: Auto confirm skipped:', autoConfirmResult.message);
            }
          } catch (autoConfirmError) {
            console.error('⚠️ MoMo: Auto confirm error (non-critical):', autoConfirmError);
            // Không throw error vì payment đã thành công
          }
        } else {
          console.warn('⚠️ Payments table does not exist, skipping database update');
        }

        // Trả về HTML page - GIỮ NGUYÊN URL với query params để Flutter app có thể detect
        return res.send(`
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>MoMo Payment Result</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      margin: 0;
      background: #f5f5f5;
    }
    .container {
      text-align: center;
      padding: 20px;
    }
    .success { color: #28a745; }
  </style>
</head>
<body>
  <div class="container">
    <h1 class="success">✅ Thanh toán thành công!</h1>
    <p>Đang xử lý...</p>
    <script>
      // URL đã có đầy đủ params từ MoMo, Flutter app sẽ detect được
      console.log('MoMo payment success URL:', window.location.href);
    </script>
  </div>
</body>
</html>
        `);
      } else {
        // Thanh toán thất bại
        const { getPool } = require('../config/db');
        const pool = await getPool();
        
        const tableCheck = await pool.request()
          .query(`
            SELECT COUNT(*) as table_exists
            FROM INFORMATION_SCHEMA.TABLES 
            WHERE TABLE_NAME = 'payments'
          `);
        
        if (tableCheck.recordset[0].table_exists > 0) {
          await pool.request()
            .input('response_code', resultCode)
            .input('order_id', orderId)
            .query(`
              UPDATE payments 
              SET status = 'failed',
                  response_code = @response_code,
                  updated_at = GETDATE()
              WHERE order_id = @order_id
            `);
        }

        // Trả về HTML với params để Flutter app có thể detect
        return res.send(`
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>MoMo Payment Result</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      margin: 0;
      background: #f5f5f5;
    }
    .container {
      text-align: center;
      padding: 20px;
    }
    .error { color: #dc3545; }
  </style>
</head>
<body>
  <div class="container">
    <h1 class="error">❌ Thanh toán thất bại</h1>
    <p>${resultMessage}</p>
    <script>
      // Giữ nguyên URL với params để Flutter app detect
      window.location.href = window.location.href;
    </script>
  </div>
</body>
</html>
        `);
      }
    } catch (dbError) {
      console.error('⚠️ Error updating payment status (non-critical):', dbError.message);
      // Vẫn trả về HTML với params để Flutter app có thể detect
      if (resultCode === '0') {
        return res.send(`
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>MoMo Payment Result</title>
</head>
<body>
  <div style="text-align: center; padding: 20px;">
    <h1 style="color: #28a745;">✅ Thanh toán thành công!</h1>
    <p>Vui lòng đợi...</p>
    <script>
      window.location.href = window.location.href;
    </script>
  </div>
</body>
</html>
        `);
      } else {
        return res.send(`
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>MoMo Payment Result</title>
</head>
<body>
  <div style="text-align: center; padding: 20px;">
    <h1 style="color: #dc3545;">❌ Thanh toán thất bại</h1>
    <p>${resultMessage}</p>
    <script>
      window.location.href = window.location.href;
    </script>
  </div>
</body>
</html>
        `);
      }
    }
  } catch (error) {
    console.error('Error processing MoMo return:', error);
    return res.redirect(`${process.env.FRONTEND_URL || 'http://localhost:3000'}/payment/failed?reason=processing_error`);
  }
};

/**
 * Xử lý IPN (Instant Payment Notification) từ MoMo
 * 
 * POST /api/payment/momo-ipn
 * Body: JSON data từ MoMo
 */
exports.momoIPN = async (req, res) => {
  try {
    console.log('');
    console.log('💗 ===== MoMo IPN Callback =====');
    console.log('⏰ Time:', new Date().toISOString());
    console.log('📍 URL:', req.originalUrl);
    console.log('🔧 Method:', req.method);
    console.log('📥 Body:', req.body);
    console.log('📥 Query:', req.query);
    console.log('═══════════════════════════════════════════════════════');
    
    const momoData = req.body || req.query;

    console.log('📋 MoMo IPN Data:', momoData);
    console.log('📋 MoMo IPN Data Count:', Object.keys(momoData).length);

    // Verify signature
    const isValid = momoService.verifySignature(momoData);

    if (!isValid) {
      console.error('Invalid MoMo IPN signature');
      return res.status(400).json({
        success: false,
        message: 'Invalid signature',
      });
    }

    const {
      orderId,
      amount,
      resultCode,
      transId,
      responseTime,
    } = momoData;

    // Update database
    try {
      const { getPool } = require('../config/db');
      const pool = await getPool();
      
      // Kiểm tra table payments có tồn tại không
      const tableCheck = await pool.request()
        .query(`
          SELECT COUNT(*) as table_exists
          FROM INFORMATION_SCHEMA.TABLES 
          WHERE TABLE_NAME = 'payments'
        `);
      
      if (tableCheck.recordset[0].table_exists > 0) {
        if (resultCode === 0) {
          // Success
          await pool.request()
            .input('transaction_no', transId)
            .input('pay_date', responseTime)
            .input('response_code', resultCode.toString())
            .input('order_id', orderId)
            .query(`
              UPDATE payments 
              SET status = 'completed', 
                  transaction_no = @transaction_no,
                  pay_date = @pay_date,
                  response_code = @response_code,
                  updated_at = GETDATE()
              WHERE order_id = @order_id
            `);

          // Update booking
          const bookingIdMatch = orderId.match(/BOOKING_(\d+)_/);
          if (bookingIdMatch) {
            const bookingId = bookingIdMatch[1];
            try {
              await pool.request()
                .input('booking_id', bookingId)
                .query(`
                  UPDATE phieudatphg 
                  SET trang_thai = 'confirmed', 
                      payment_status = 'paid',
                      updated_at = GETDATE()
                  WHERE id = @booking_id
                `);
            } catch (bookingUpdateError) {
              console.error('⚠️ Error updating booking status (non-critical):', bookingUpdateError.message);
            }
          }

          // ✅ TỰ ĐỘNG XÁC NHẬN BOOKING NẾU ĐÃ THANH TOÁN >= 50% (IPN)
          try {
            const AutoConfirmBookingService = require('../services/autoConfirmBookingService');
            const paymentAmountResult = await pool.request()
              .input('order_id', orderId)
              .query(`SELECT amount FROM payments WHERE order_id = @order_id`);
            
            const paymentAmount = paymentAmountResult.recordset[0]?.amount || 0;
            
            const autoConfirmResult = await AutoConfirmBookingService.autoConfirmBookingAfterPayment({
              orderId,
              amount: paymentAmount,
              paymentMethod: 'momo',
              transactionId: transId
            });

            if (autoConfirmResult.success) {
              console.log('✅ MoMo IPN: Auto confirmed booking:', autoConfirmResult.booking?.bookingCode);
              if (autoConfirmResult.emailSent) {
                console.log('📧 MoMo IPN: Confirmation email sent to customer');
              }
            }
          } catch (autoConfirmError) {
            console.error('⚠️ MoMo IPN: Auto confirm error (non-critical):', autoConfirmError);
          }
        } else {
          // Failed
          await pool.request()
            .input('response_code', resultCode.toString())
            .input('order_id', orderId)
            .query(`
              UPDATE payments 
              SET status = 'failed',
                  response_code = @response_code,
                  updated_at = GETDATE()
              WHERE order_id = @order_id
            `);
        }
      } else {
        console.warn('⚠️ Payments table does not exist, skipping database update in IPN');
      }

      // Respond to MoMo
      res.status(200).json({
        success: true,
        message: 'IPN processed successfully',
      });
    } catch (dbError) {
      console.error('⚠️ Error updating payment in IPN (non-critical):', dbError.message);
      // Vẫn respond success để MoMo không retry
      res.status(200).json({
        success: true,
        message: 'IPN processed (database update skipped)',
      });
    }
  } catch (error) {
    console.error('Error processing MoMo IPN:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
    });
  }
};

/**
 * Query trạng thái giao dịch
 * 
 * POST /api/payment/momo/query-transaction
 * Body: {
 *   orderId: string,
 *   requestId: string
 * }
 */
exports.queryTransaction = async (req, res) => {
  try {
    const { orderId, requestId } = req.body;

    if (!orderId || !requestId) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: orderId, requestId',
      });
    }

    const result = await momoService.queryTransaction({
      orderId,
      requestId,
    });

    res.json({
      success: true,
      data: result,
    });
  } catch (error) {
    console.error('Error querying MoMo transaction:', error);
    res.status(500).json({
      success: false,
      message: 'Error querying transaction',
      error: error.message,
    });
  }
};

