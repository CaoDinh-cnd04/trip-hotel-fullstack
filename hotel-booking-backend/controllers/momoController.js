/**
 * MoMo Controller - Xử lý các request liên quan đến MoMo
 */

const momoService = require('../services/momoService');
const db = require('../config/db');
const Booking = require('../models/booking');

/**
 * Tạo payment request đến MoMo
 * 
 * POST /api/payment/momo/create-payment
 * Body: {
 *   bookingId: number,
 *   amount: number,
 *   orderInfo: string,
 *   extraData: string (optional, base64),
 *   bookingData: object (optional - full booking info để tạo booking sau payment)
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

    // Tạo payment request đến MoMo
    const result = await momoService.createPayment({
      orderId,
      amount,
      orderInfo,
      extraData: extraData || '',
    });

    // Lưu thông tin payment vào database (với booking data)
    try {
      const { getPool } = require('../config/db');
      const pool = await getPool();
      
      // Kiểm tra xem table payments có tồn tại không
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
        console.log('✅ Payment record saved to database');
      } else {
        console.warn('⚠️ Payments table does not exist, skipping database save');
      }
    } catch (dbError) {
      console.error('⚠️ Error saving payment to database (non-critical):', dbError.message);
      // Continue anyway, không block payment flow
    }

    res.json({
      success: true,
      data: result,
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
    const momoData = req.query;

    console.log('MoMo Return Data:', momoData);

    // Verify signature
    const isValid = momoService.verifySignature(momoData);

    if (!isValid) {
      console.error('Invalid MoMo signature');
      return res.redirect(`${process.env.FRONTEND_URL || 'http://localhost:3000'}/payment/failed?reason=invalid_signature`);
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
        
        // Kiểm tra xem table payments có tồn tại không
        const tableCheck = await pool.request()
          .query(`
            SELECT COUNT(*) as table_exists
            FROM INFORMATION_SCHEMA.TABLES 
            WHERE TABLE_NAME = 'payments'
          `);
        
        let bookingCode = null;
        
        if (tableCheck.recordset[0].table_exists > 0) {
          // Lấy booking data từ payment record
          const paymentResult = await pool.request()
            .input('order_id', orderId)
            .query(`SELECT extra_data FROM payments WHERE order_id = @order_id`);
          
          // Tạo booking nếu có extra_data (booking info)
          if (paymentResult.recordset.length > 0 && paymentResult.recordset[0].extra_data) {
            try {
              const bookingData = JSON.parse(paymentResult.recordset[0].extra_data);
              
              // Tạo booking vào database
              const booking = await Booking.create({
                ...bookingData,
                paymentStatus: 'paid',
                paymentMethod: 'momo',
                paymentTransactionId: transId,
              });
              
              bookingCode = booking.booking_code;
              console.log('✅ Booking created:', bookingCode);
            } catch (bookingError) {
              console.error('❌ Error creating booking:', bookingError);
            }
          }
          
          // Update payment status
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
        } else {
          console.warn('⚠️ Payments table does not exist, skipping database update');
        }

        // Redirect đến success page với booking code nếu có
        const successUrl = bookingCode 
          ? `${process.env.FRONTEND_URL || 'http://localhost:3000'}/payment/success?orderId=${orderId}&amount=${actualAmount}&transactionNo=${transId}&bookingCode=${bookingCode}`
          : `${process.env.FRONTEND_URL || 'http://localhost:3000'}/payment/success?orderId=${orderId}&amount=${actualAmount}&transactionNo=${transId}`;
        
        return res.redirect(successUrl);
      } else {
        // Thanh toán thất bại
        const { getPool } = require('../config/db');
        const pool = await getPool();
        
        // Kiểm tra table tồn tại trước khi update
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

        return res.redirect(`${process.env.FRONTEND_URL || 'http://localhost:3000'}/payment/failed?reason=${resultCode}&message=${encodeURIComponent(resultMessage)}`);
      }
    } catch (dbError) {
      console.error('⚠️ Error updating payment status (non-critical):', dbError.message);
      // Vẫn redirect về success/failed page vì payment đã thành công/thất bại trên MoMo
      if (resultCode === '0') {
        return res.redirect(`${process.env.FRONTEND_URL || 'http://localhost:3000'}/payment/success?orderId=${orderId}&amount=${actualAmount}&transactionNo=${transId}`);
      } else {
        return res.redirect(`${process.env.FRONTEND_URL || 'http://localhost:3000'}/payment/failed?reason=${resultCode}&message=${encodeURIComponent(resultMessage)}`);
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
    const momoData = req.body;

    console.log('MoMo IPN Data:', momoData);

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

