/**
 * Auto Confirm Booking Service
 * 
 * Tự động xác nhận đặt phòng khi:
 * - Đã thanh toán >= 50% tiền (deposit)
 */

const { getPool } = require('../config/db');
const sql = require('mssql');
 * - Đã thanh toán 100% tiền
 * 
 * Và gửi email thông báo cho người đặt phòng
 */

const { getPool } = require('../config/db');
const emailService = require('./emailService');
const VipService = require('./vipService');
const sql = require('mssql');

class AutoConfirmBookingService {
  /**
   * Kiểm tra và tự động xác nhận booking sau khi thanh toán
   * 
   * @param {Object} paymentData - Thông tin payment
   * @param {string} paymentData.orderId - Order ID
   * @param {number} paymentData.amount - Số tiền đã thanh toán
   * @param {string} paymentData.paymentMethod - Phương thức thanh toán (vnpay/momo)
   * @param {string} paymentData.transactionId - Transaction ID
   * 
   * @returns {Object} - Kết quả xử lý
   */
  static async autoConfirmBookingAfterPayment(paymentData) {
    try {
      const { orderId, amount, paymentMethod, transactionId } = paymentData;
      
      console.log('🔍 Auto Confirm Booking: Checking payment...', {
        orderId,
        amount,
        paymentMethod
      });

      const pool = await getPool();

      // 1. Lấy thông tin payment record
      const paymentResult = await pool.request()
        .input('order_id', orderId)
        .query(`
          SELECT 
            p.*,
            p.extra_data,
            p.user_id,
            p.amount as payment_amount,
            (SELECT SUM(amount) FROM payments WHERE order_id LIKE @order_id + '%' AND status = 'completed') as total_paid
          FROM payments p
          WHERE p.order_id = @order_id
        `);

      if (paymentResult.recordset.length === 0) {
        console.warn('⚠️ Auto Confirm: Payment record not found for order:', orderId);
        return { success: false, message: 'Payment record not found' };
      }

      const paymentRecord = paymentResult.recordset[0];
      
      // 2. Parse booking data từ extra_data
      let bookingData = null;
      if (paymentRecord.extra_data) {
        try {
          bookingData = JSON.parse(paymentRecord.extra_data);
        } catch (e) {
          console.error('❌ Auto Confirm: Error parsing extra_data:', e);
        }
      }

      if (!bookingData) {
        console.warn('⚠️ Auto Confirm: No booking data in payment record');
        return { success: false, message: 'No booking data found' };
      }

      // 3. Tính toán số tiền đã thanh toán
      const totalPrice = bookingData.finalPrice || bookingData.totalPrice || 0;
      const totalPaid = parseFloat(paymentRecord.total_paid || amount || 0);
      const paymentPercentage = totalPrice > 0 ? (totalPaid / totalPrice) * 100 : 0;

      console.log('💰 Payment Summary:', {
        totalPrice,
        totalPaid,
        paymentPercentage: paymentPercentage.toFixed(2) + '%'
      });

      // 4. Kiểm tra điều kiện: >= 50% đã thanh toán
      if (paymentPercentage < 50) {
        console.log(`ℹ️ Auto Confirm: Payment ${paymentPercentage.toFixed(2)}% < 50%, skipping auto confirm`);
        return { 
          success: false, 
          message: 'Payment less than 50%',
          paymentPercentage 
        };
      }

      // 5. Tìm hoặc tạo booking
      let booking = null;
      const Booking = require('../models/booking');

      // Thử tìm booking theo bookingId nếu có
      if (bookingData.bookingId) {
        try {
          booking = await Booking.getById(bookingData.bookingId);
        } catch (e) {
          console.log('ℹ️ Booking not found by ID, will create new one');
        }
      }

      // Nếu chưa có booking, tạo mới
      if (!booking) {
        try {
          console.log('📝 Auto Confirm: Creating new booking...');
          
          // Đảm bảo userId có trong bookingData
          if (!bookingData.userId && paymentRecord.user_id) {
            bookingData.userId = paymentRecord.user_id;
          }

          booking = await Booking.create({
            ...bookingData,
            paymentStatus: paymentPercentage >= 100 ? 'paid' : 'partial',
            paymentMethod: paymentMethod || 'vnpay',
            paymentTransactionId: transactionId,
            bookingStatus: 'confirmed', // ✅ TỰ ĐỘNG CONFIRM
          });

          console.log('✅ Auto Confirm: Booking created:', booking.booking_code);
          
          // ✅ CẬP NHẬT TRẠNG THÁI PHÒNG KHI BOOKING ĐƯỢC TẠO VỚI STATUS CONFIRMED
          if (booking.room_id) {
            try {
              const pool = await getPool();
              await pool.request()
                .input('roomId', sql.Int, booking.room_id)
                .input('newStatus', sql.NVarChar, 'Đã thuê')
                .query(`
                  UPDATE dbo.phong
                  SET trang_thai = @newStatus
                  WHERE id = @roomId
                `);
              console.log(`✅ Auto Confirm: Room ${booking.room_id} status updated to: Đã thuê`);
            } catch (roomUpdateError) {
              console.error('⚠️ Auto Confirm: Error updating room status (non-critical):', roomUpdateError);
            }
          }
        } catch (bookingError) {
          console.error('❌ Auto Confirm: Error creating booking:', bookingError);
          return { success: false, message: 'Error creating booking', error: bookingError.message };
        }
      } else {
        // Cập nhật booking đã tồn tại
        try {
          console.log('📝 Auto Confirm: Updating existing booking...');
          
          const updateResult = await pool.request()
            .input('booking_id', booking.id || bookingData.bookingId)
            .input('payment_status', paymentPercentage >= 100 ? 'paid' : 'partial')
            .input('booking_status', 'confirmed') // ✅ TỰ ĐỘNG CONFIRM
            .query(`
              UPDATE bookings
              SET 
                payment_status = @payment_status,
                booking_status = @booking_status,
                updated_at = GETDATE()
              WHERE id = @booking_id;
              
              SELECT * FROM vw_bookings_with_cancellation WHERE id = @booking_id;
            `);

          booking = updateResult.recordset[0];
          console.log('✅ Auto Confirm: Booking updated:', booking.booking_code);
          
          // ✅ CẬP NHẬT TRẠNG THÁI PHÒNG KHI BOOKING ĐƯỢC CONFIRM
          if (booking.room_id) {
            try {
              await pool.request()
                .input('roomId', sql.Int, booking.room_id)
                .input('newStatus', sql.NVarChar, 'Đã thuê')
                .query(`
                  UPDATE dbo.phong
                  SET trang_thai = @newStatus
                  WHERE id = @roomId
                `);
              console.log(`✅ Auto Confirm: Room ${booking.room_id} status updated to: Đã thuê`);
            } catch (roomUpdateError) {
              console.error('⚠️ Auto Confirm: Error updating room status (non-critical):', roomUpdateError);
            }
          }
        } catch (updateError) {
          console.error('❌ Auto Confirm: Error updating booking:', updateError);
          return { success: false, message: 'Error updating booking', error: updateError.message };
        }
      }

      // 6. ✅ TÍCH ĐIỂM VIP CHO USER SAU KHI BOOKING ĐƯỢC XÁC NHẬN
      // Chỉ tích điểm một lần khi booking được confirm lần đầu
      if (booking && paymentRecord.user_id && totalPrice > 0) {
        try {
          // Kiểm tra xem booking đã được confirm trước đó chưa (để tránh tích điểm trùng)
          let wasAlreadyConfirmed = false;
          try {
            const bookingCheckResult = await pool.request()
              .input('booking_id', booking.id || bookingData.bookingId)
              .query(`
                SELECT booking_status, 
                       CASE WHEN vip_points_added IS NULL THEN 0 ELSE vip_points_added END as vip_points_added
                FROM bookings
                WHERE id = @booking_id
              `);

            wasAlreadyConfirmed = bookingCheckResult.recordset.length > 0 && 
                                 bookingCheckResult.recordset[0].booking_status === 'confirmed' &&
                                 bookingCheckResult.recordset[0].vip_points_added === 1;
          } catch (checkError) {
            // Nếu cột vip_points_added chưa tồn tại, bỏ qua check và tiếp tục tích điểm
            console.log('ℹ️ Auto Confirm: Could not check vip_points_added column (may not exist), will proceed to add points');
            wasAlreadyConfirmed = false;
          }

          if (wasAlreadyConfirmed) {
            console.log('ℹ️ Auto Confirm: Booking already confirmed and VIP points already added, skipping');
          } else {
            console.log('⭐ Auto Confirm: Adding VIP points for user:', paymentRecord.user_id);
            
            const vipResult = await VipService.addPointsAfterBooking(
              paymentRecord.user_id,
              totalPrice
            );

            if (vipResult) {
              console.log(`✅ Auto Confirm: Added ${vipResult.pointsAdded} VIP points. Total: ${vipResult.newTotalPoints}. Level: ${vipResult.newLevel}`);
              if (vipResult.leveledUp) {
                console.log(`🎉 Auto Confirm: User leveled up from ${vipResult.previousLevel} to ${vipResult.newLevel}!`);
              }

              // Đánh dấu đã tích điểm cho booking này (nếu cột tồn tại)
              try {
                await pool.request()
                  .input('booking_id', booking.id || bookingData.bookingId)
                  .query(`
                    UPDATE bookings
                    SET vip_points_added = 1
                    WHERE id = @booking_id
                  `);
                console.log('✅ Auto Confirm: Marked VIP points as added for booking');
              } catch (markError) {
                // Nếu cột vip_points_added chưa tồn tại, bỏ qua (không phải lỗi nghiêm trọng)
                if (markError.message && markError.message.includes('vip_points_added')) {
                  console.log('ℹ️ Auto Confirm: vip_points_added column does not exist yet. Run migration script to add it.');
                } else {
                  console.warn('⚠️ Auto Confirm: Could not mark VIP points as added (non-critical):', markError.message);
                }
                // Không throw vì điểm đã được cộng
              }
            } else {
              console.warn('⚠️ Auto Confirm: Failed to add VIP points');
            }
          }
        } catch (vipError) {
          console.error('⚠️ Auto Confirm: Error adding VIP points (non-critical):', vipError);
          // Không throw error vì booking đã được confirm
        }
      }

      // 7. Gửi email xác nhận
      if (booking && bookingData.userEmail) {
        try {
          console.log('📧 Auto Confirm: Sending confirmation email to:', bookingData.userEmail);
          
          const emailSent = await emailService.sendBookingConfirmation(
            bookingData.userEmail,
            {
              bookingCode: booking.booking_code || booking.bookingCode,
              hotelName: bookingData.hotelName || booking.hotel_name,
              roomType: bookingData.roomType || booking.room_type,
              checkInDate: bookingData.checkInDate || booking.check_in_date,
              checkOutDate: bookingData.checkOutDate || booking.check_out_date,
              nights: bookingData.nights || booking.nights,
              totalPrice: totalPrice.toLocaleString('vi-VN') + ' VNĐ',
              paymentPercentage: paymentPercentage >= 100 ? '100% (Đã thanh toán đủ)' : `${paymentPercentage.toFixed(0)}% (Đã đặt cọc)`
            }
          );

          if (emailSent) {
            console.log('✅ Auto Confirm: Confirmation email sent successfully');
          } else {
            console.warn('⚠️ Auto Confirm: Email service disabled or failed');
          }
        } catch (emailError) {
          console.error('⚠️ Auto Confirm: Error sending email (non-critical):', emailError);
          // Không throw error vì booking đã được confirm
        }
      }

      return {
        success: true,
        booking: {
          id: booking.id,
          bookingCode: booking.booking_code || booking.bookingCode,
          status: booking.booking_status || booking.bookingStatus,
          paymentStatus: booking.payment_status || booking.paymentStatus
        },
        paymentPercentage: paymentPercentage.toFixed(2),
        emailSent: bookingData.userEmail ? true : false
      };

    } catch (error) {
      console.error('❌ Auto Confirm Booking Error:', error);
      return { 
        success: false, 
        message: 'Error in auto confirm process', 
        error: error.message 
      };
    }
  }

  /**
   * Kiểm tra và cập nhật booking status dựa trên tổng số tiền đã thanh toán
   * (Dùng cho trường hợp thanh toán nhiều lần - deposit + full payment)
   */
  static async checkAndUpdateBookingStatus(bookingId) {
    try {
      const pool = await getPool();

      // Lấy thông tin booking
      const bookingResult = await pool.request()
        .input('booking_id', bookingId)
        .query(`
          SELECT * FROM vw_bookings_with_cancellation WHERE id = @booking_id
        `);

      if (bookingResult.recordset.length === 0) {
        return { success: false, message: 'Booking not found' };
      }

      const booking = bookingResult.recordset[0];

      // Tính tổng số tiền đã thanh toán
      const paymentsResult = await pool.request()
        .input('booking_id', bookingId)
        .query(`
          SELECT SUM(amount) as total_paid
          FROM payments
          WHERE extra_data LIKE '%"bookingId":' + CAST(@booking_id AS VARCHAR) + '%'
            AND status = 'completed'
        `);

      const totalPaid = parseFloat(paymentsResult.recordset[0]?.total_paid || 0);
      const totalPrice = parseFloat(booking.final_price || booking.total_price || 0);
      const paymentPercentage = totalPrice > 0 ? (totalPaid / totalPrice) * 100 : 0;

      // Nếu đã thanh toán >= 50% và booking chưa được confirm
      if (paymentPercentage >= 50 && booking.booking_status !== 'confirmed') {
        await pool.request()
          .input('booking_id', bookingId)
          .input('payment_status', paymentPercentage >= 100 ? 'paid' : 'partial')
          .query(`
            UPDATE bookings
            SET 
              booking_status = 'confirmed',
              payment_status = @payment_status,
              updated_at = GETDATE()
            WHERE id = @booking_id
          `);

        console.log(`✅ Auto confirmed booking ${bookingId} (${paymentPercentage.toFixed(2)}% paid)`);
        return { success: true, confirmed: true, paymentPercentage };
      }

      return { success: true, confirmed: false, paymentPercentage };
    } catch (error) {
      console.error('❌ Error checking booking status:', error);
      return { success: false, error: error.message };
    }
  }
}

module.exports = AutoConfirmBookingService;

