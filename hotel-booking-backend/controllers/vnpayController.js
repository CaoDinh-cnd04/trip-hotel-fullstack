/**
 * VNPay Controller - Xử lý các request liên quan đến VNPay
 */

const vnpayService = require('../services/vnpayService');
const db = require('../config/db');
const Booking = require('../models/booking');

/**
 * Tạo URL thanh toán VNPay
 * 
 * POST /api/payment/vnpay/create-payment-url
 * Body: {
 *   bookingId: number,
 *   amount: number,
 *   orderInfo: string,
 *   bankCode: string (optional),
 *   bookingData: object (optional - full booking info để tạo booking sau payment)
 * }
 */
exports.createPaymentUrl = async (req, res) => {
  try {
    const { bookingId, amount, orderInfo, bankCode, bookingData } = req.body;

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
      userId: bookingData.userId || userId, // Ưu tiên userId từ bookingData
    } : null;

    // Lấy IP address của client
    const ipAddr = req.headers['x-forwarded-for'] ||
                   req.connection.remoteAddress ||
                   req.socket.remoteAddress ||
                   req.connection.socket.remoteAddress;

    // Tạo order ID unique
    const orderId = `BOOKING_${bookingId}_${Date.now()}`;

    // Tạo payment URL
    const paymentUrl = vnpayService.createPaymentUrl({
      orderId,
      amount,
      orderInfo,
      orderType: 'billpayment',
      ipAddr,
      bankCode,
    });

    // Lưu thông tin payment vào database (optional)
    // Lưu cả booking data để tạo booking sau khi payment success
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
            VALUES (@booking_id, @order_id, @amount, 'pending', 'vnpay', @extra_data, GETDATE())
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
      data: {
        paymentUrl,
        orderId,
      },
    });
  } catch (error) {
    console.error('Error creating VNPay payment URL:', error);
    res.status(500).json({
      success: false,
      message: 'Error creating payment URL',
      error: error.message,
    });
  }
};

/**
 * Xử lý callback từ VNPay sau khi thanh toán
 * 
 * GET /api/payment/vnpay-return
 * Query params từ VNPay
 */
exports.vnpayReturn = async (req, res) => {
  try {
    const vnpParams = req.query;

    console.log('VNPay Return Params:', vnpParams);

    // Verify signature
    const isValid = vnpayService.verifyReturnUrl(vnpParams);

    if (!isValid) {
      console.error('Invalid VNPay signature');
      return res.redirect(`${process.env.FRONTEND_URL || 'http://localhost:3000'}/payment/failed?reason=invalid_signature`);
    }

    // Lấy thông tin giao dịch
    const {
      vnp_TxnRef: orderId,
      vnp_Amount: amount,
      vnp_ResponseCode: responseCode,
      vnp_TransactionNo: transactionNo,
      vnp_BankCode: bankCode,
      vnp_TransactionStatus: transactionStatus,
      vnp_PayDate: payDate,
    } = vnpParams;

    // Parse amount (VNPay trả về số tiền * 100)
    const actualAmount = parseInt(amount) / 100;

    // Lấy response message
    const message = vnpayService.getResponseMessage(responseCode);

    // Update payment status trong database
    try {
      if (responseCode === '00') {
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
                paymentMethod: 'vnpay',
                paymentTransactionId: transactionNo,
              });
              
              bookingCode = booking.booking_code;
              console.log('✅ Booking created:', bookingCode);
            } catch (bookingError) {
              console.error('❌ Error creating booking:', bookingError);
            }
          }
          
          // Update payment status
          await pool.request()
            .input('transaction_no', transactionNo)
            .input('bank_code', bankCode)
            .input('pay_date', payDate)
            .input('response_code', responseCode)
            .input('order_id', orderId)
            .query(`
              UPDATE payments 
              SET status = 'completed', 
                  transaction_no = @transaction_no,
                  bank_code = @bank_code,
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
          ? `${process.env.FRONTEND_URL || 'http://localhost:3000'}/payment/success?orderId=${orderId}&amount=${actualAmount}&transactionNo=${transactionNo}&bookingCode=${bookingCode}`
          : `${process.env.FRONTEND_URL || 'http://localhost:3000'}/payment/success?orderId=${orderId}&amount=${actualAmount}&transactionNo=${transactionNo}`;
        
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
            .input('response_code', responseCode)
            .input('order_id', orderId)
            .query(`
              UPDATE payments 
              SET status = 'failed',
                  response_code = @response_code,
                  updated_at = GETDATE()
              WHERE order_id = @order_id
            `);
        }

        return res.redirect(`${process.env.FRONTEND_URL || 'http://localhost:3000'}/payment/failed?reason=${responseCode}&message=${encodeURIComponent(message)}`);
      }
    } catch (dbError) {
      console.error('⚠️ Error updating payment status (non-critical):', dbError.message);
      // Vẫn redirect về success/failed page vì payment đã thành công/thất bại trên VNPay
      if (responseCode === '00') {
        return res.redirect(`${process.env.FRONTEND_URL || 'http://localhost:3000'}/payment/success?orderId=${orderId}&amount=${actualAmount}&transactionNo=${transactionNo}`);
      } else {
        return res.redirect(`${process.env.FRONTEND_URL || 'http://localhost:3000'}/payment/failed?reason=${responseCode}&message=${encodeURIComponent(message)}`);
      }
    }
  } catch (error) {
    console.error('Error processing VNPay return:', error);
    return res.redirect(`${process.env.FRONTEND_URL || 'http://localhost:3000'}/payment/failed?reason=processing_error`);
  }
};

/**
 * Query trạng thái giao dịch
 * 
 * POST /api/payment/vnpay/query-transaction
 * Body: {
 *   orderId: string,
 *   transDate: string (yyyyMMddHHmmss)
 * }
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
 * Lấy danh sách ngân hàng hỗ trợ VNPay
 * 
 * GET /api/payment/vnpay/banks
 */
exports.getBankList = (req, res) => {
  const banks = [
    { code: 'VNPAYQR', name: 'Cổng thanh toán VNPAYQR' },
    { code: 'VNBANK', name: 'Thanh toán qua ứng dụng hỗ trợ VNPAYQR' },
    { code: 'INTCARD', name: 'Thanh toán qua thẻ quốc tế' },
    { code: 'VIETCOMBANK', name: 'Ngân hàng TMCP Ngoại Thương Việt Nam (Vietcombank)' },
    { code: 'VIETINBANK', name: 'Ngân hàng TMCP Công Thương Việt Nam (VietinBank)' },
    { code: 'BIDV', name: 'Ngân hàng TMCP Đầu tư và Phát triển Việt Nam (BIDV)' },
    { code: 'AGRIBANK', name: 'Ngân hàng Nông nghiệp và Phát triển Nông thôn Việt Nam (Agribank)' },
    { code: 'TECHCOMBANK', name: 'Ngân hàng TMCP Kỹ Thương Việt Nam (Techcombank)' },
    { code: 'ACB', name: 'Ngân hàng TMCP Á Châu (ACB)' },
    { code: 'VPBANK', name: 'Ngân hàng TMCP Việt Nam Thịnh Vượng (VPBank)' },
    { code: 'TPBANK', name: 'Ngân hàng TMCP Tiên Phong (TPBank)' },
    { code: 'SACOMBANK', name: 'Ngân hàng TMCP Sài Gòn Thương Tín (Sacombank)' },
    { code: 'HDBANK', name: 'Ngân hàng TMCP Phát triển TP.HCM (HDBank)' },
    { code: 'MBBANK', name: 'Ngân hàng TMCP Quân đội (MB Bank)' },
    { code: 'OCB', name: 'Ngân hàng TMCP Phương Đông (OCB)' },
    { code: 'NCB', name: 'Ngân hàng TMCP Quốc Dân (NCB)' },
    { code: 'SCB', name: 'Ngân hàng TMCP Sài Gòn (SCB)' },
    { code: 'SHB', name: 'Ngân hàng TMCP Sài Gòn - Hà Nội (SHB)' },
  ];

  res.json({
    success: true,
    data: banks,
  });
};

