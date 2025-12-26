const sql = require('mssql');
const { getPool } = require('../config/db');

class Booking {
  /**
   * Tạo mã booking tự động
   */
  static async generateBookingCode() {
    const date = new Date();
    const dateStr = date.toISOString().split('T')[0].replace(/-/g, '');
    const random = Math.floor(Math.random() * 10000).toString().padStart(4, '0');
    return `BOOK-${dateStr}-${random}`;
  }

  /**
   * Tạo booking mới sau khi thanh toán thành công
   */
  static async create(bookingData) {
    try {
      const pool = getPool();
      const bookingCode = await this.generateBookingCode();
      
      const result = await pool.request()
        .input('booking_code', sql.NVarChar(50), bookingCode)
        .input('user_id', sql.Int, bookingData.userId)
        .input('user_email', sql.NVarChar(255), bookingData.userEmail)
        .input('user_name', sql.NVarChar(255), bookingData.userName)
        .input('user_phone', sql.NVarChar(50), bookingData.userPhone)
        .input('hotel_id', sql.Int, bookingData.hotelId)
        .input('hotel_name', sql.NVarChar(500), bookingData.hotelName)
        .input('room_id', sql.Int, bookingData.roomId)
        .input('room_number', sql.NVarChar(50), bookingData.roomNumber)
        .input('room_type', sql.NVarChar(255), bookingData.roomType)
        .input('check_in_date', sql.Date, bookingData.checkInDate)
        .input('check_out_date', sql.Date, bookingData.checkOutDate)
        .input('guest_count', sql.Int, bookingData.guestCount || 1)
        .input('room_count', sql.Int, bookingData.roomCount || 1)
        .input('nights', sql.Int, bookingData.nights)
        .input('room_price', sql.Decimal(18, 2), bookingData.roomPrice)
        .input('total_price', sql.Decimal(18, 2), bookingData.totalPrice)
        .input('discount_amount', sql.Decimal(18, 2), bookingData.discountAmount || 0)
        .input('final_price', sql.Decimal(18, 2), bookingData.finalPrice)
        .input('payment_method', sql.NVarChar(50), bookingData.paymentMethod)
        .input('payment_status', sql.NVarChar(50), bookingData.paymentStatus || 'paid')
        .input('booking_status', sql.NVarChar(50), bookingData.bookingStatus || 'confirmed')
        .input('payment_transaction_id', sql.NVarChar(255), bookingData.paymentTransactionId)
        .input('payment_date', sql.DateTime, new Date())
        .input('cancellation_allowed', sql.Bit, bookingData.cancellationAllowed !== false ? 1 : 0)
        .input('special_requests', sql.NVarChar(sql.MAX), bookingData.specialRequests || null)
        .query(`
          INSERT INTO bookings (
            booking_code, user_id, user_email, user_name, user_phone,
            hotel_id, hotel_name, room_id, room_number, room_type,
            check_in_date, check_out_date, guest_count, room_count, nights,
            room_price, total_price, discount_amount, final_price,
            payment_method, payment_status, booking_status, payment_transaction_id, payment_date,
            cancellation_allowed, special_requests
          ) VALUES (
            @booking_code, @user_id, @user_email, @user_name, @user_phone,
            @hotel_id, @hotel_name, @room_id, @room_number, @room_type,
            @check_in_date, @check_out_date, @guest_count, @room_count, @nights,
            @room_price, @total_price, @discount_amount, @final_price,
            @payment_method, @payment_status, @booking_status, @payment_transaction_id, @payment_date,
            @cancellation_allowed, @special_requests
          );
          SELECT * FROM vw_bookings_with_cancellation WHERE booking_code = @booking_code;
        `);
      
      // NOTE: Room status update disabled due to CHECK constraint
      // Room availability is managed through booking records
      // No need to update room status directly
      console.log(`✅ Booking created successfully for room ${bookingData.roomId}`);

      const booking = result.recordset[0];

      // ✅ Cộng VIP points sau khi booking thành công và đã thanh toán
      // Lấy userId từ nhiều nguồn để đảm bảo luôn có giá trị
      let userId = bookingData.userId;
      if (!userId && booking) {
        userId = booking.user_id;
      }
      if (!userId && bookingData.user_id) {
        userId = bookingData.user_id;
      }
      
      // Lấy finalPrice từ nhiều nguồn
      let finalPrice = bookingData.finalPrice;
      if (!finalPrice || finalPrice <= 0) {
        finalPrice = bookingData.totalPrice;
      }
      if (!finalPrice || finalPrice <= 0) {
        finalPrice = booking?.final_price;
      }
      if (!finalPrice || finalPrice <= 0) {
        finalPrice = booking?.total_price;
      }
      if (!finalPrice || finalPrice <= 0) {
        finalPrice = 0;
      }
      
      console.log(`🔍 VIP Points Check: paymentStatus=${bookingData.paymentStatus}, userId=${userId}, finalPrice=${finalPrice}`);
      
      if (bookingData.paymentStatus === 'paid' && userId) {
        try {
          const VipService = require('../services/vipService');
          console.log(`💰 Attempting to add VIP points: userId=${userId}, finalPrice=${finalPrice}`);
          
          const vipResult = await VipService.addPointsAfterBooking(
            userId,
            finalPrice
          );
          
          if (vipResult) {
            console.log(`✅ VIP points added: +${vipResult.pointsAdded} points. Total: ${vipResult.newTotalPoints}. Level: ${vipResult.newLevel}`);
            if (vipResult.leveledUp) {
              console.log(`🎉 User ${userId} leveled up from ${vipResult.previousLevel} to ${vipResult.newLevel}!`);
            }
          } else {
            console.warn(`⚠️ VIP points not added: vipResult is null for userId=${userId}, finalPrice=${finalPrice}`);
          }
        } catch (vipError) {
          console.error('⚠️ Error adding VIP points (non-critical):', vipError);
          console.error('⚠️ Stack trace:', vipError.stack);
          // Không throw error vì booking đã tạo thành công
        }
      } else {
        console.warn(`⚠️ VIP points skipped: paymentStatus=${bookingData.paymentStatus}, userId=${userId}`);
      }

      return booking;
    } catch (error) {
      console.error('❌ Error creating booking:', error);
      throw error;
    }
  }

  /**
   * Lấy danh sách bookings của user
   */
  static async getByUserId(userId, options = {}) {
    try {
      const pool = getPool();
      const { status, limit = 50, offset = 0 } = options;

      // ⚠️ SỬA LỖI: Query trực tiếp từ bảng bookings thay vì view
      // View có thể có filter hoặc join thiếu dữ liệu
      // Đảm bảo hiển thị TẤT CẢ bookings, kể cả pending
      // ✅ FIX: Sử dụng GROUP BY để đảm bảo chỉ 1 row cho mỗi booking
      // ✅ FIX: Đặt điều kiện status vào WHERE clause, không phải sau GROUP BY
      let query = `
        SELECT 
          b.id,
          b.booking_code,
          b.user_id,
          b.user_email,
          b.user_name,
          b.user_phone,
          b.hotel_id,
          MAX(ISNULL(ks.ten, b.hotel_name)) as hotel_name,
          MAX(ISNULL(ks.hinh_anh, '')) as hotel_image,
          MAX(ISNULL(ks.dia_chi, '')) as hotel_address,
          b.room_id,
          b.room_number,
          b.room_type,
          b.check_in_date,
          b.check_out_date,
          b.guest_count,
          b.room_count,
          b.nights,
          b.room_price,
          b.total_price,
          b.discount_amount,
          b.final_price,
          b.payment_method,
          b.payment_status,
          b.payment_transaction_id,
          b.payment_date,
          b.refund_status,
          b.refund_amount,
          b.refund_transaction_id,
          b.refund_date,
          b.refund_reason,
          b.booking_status,
          b.cancellation_allowed,
          b.created_at,
          b.updated_at,
          b.cancelled_at,
          b.special_requests,
          b.admin_notes,
          b.vip_points_added,
          MAX(CASE 
            WHEN b.booking_status = 'pending' AND b.cancellation_allowed = 1 
              AND DATEDIFF(hour, GETDATE(), b.check_in_date) >= 24 
            THEN 1 
            ELSE 0 
          END) as can_cancel
        FROM bookings b
        LEFT JOIN khach_san ks ON b.hotel_id = ks.id
        WHERE b.user_id = @user_id
      `;

      // ⚠️ QUAN TRỌNG: Đặt điều kiện status vào WHERE clause TRƯỚC GROUP BY
      // Không filter theo status nếu không có yêu cầu
      // Hoặc nếu status = 'all' hoặc null, hiển thị tất cả
      if (status && status !== 'all' && status !== '') {
        query += ` AND b.booking_status = @status`;
      }

      query += `
        GROUP BY 
          b.id, b.booking_code, b.user_id, b.user_email, b.user_name, b.user_phone,
          b.hotel_id, b.room_id, b.room_number, b.room_type, b.check_in_date, b.check_out_date,
          b.guest_count, b.room_count, b.nights, b.room_price, b.total_price, b.discount_amount,
          b.final_price, b.payment_method, b.payment_status, b.payment_transaction_id, b.payment_date,
          b.refund_status, b.refund_amount, b.refund_transaction_id, b.refund_date, b.refund_reason,
          b.booking_status, b.cancellation_allowed, b.created_at, b.updated_at, b.cancelled_at,
          b.special_requests, b.admin_notes, b.vip_points_added
        ORDER BY b.created_at DESC 
        OFFSET @offset ROWS 
        FETCH NEXT @limit ROWS ONLY
      `;

      const request = pool.request()
        .input('user_id', sql.Int, userId)
        .input('limit', sql.Int, limit)
        .input('offset', sql.Int, offset);

      if (status && status !== 'all' && status !== '') {
        request.input('status', sql.NVarChar(50), status);
      }

      const result = await request.query(query);
      
      // ✅ FIX: Normalize dữ liệu để đảm bảo các field là string, không phải array
      const normalizedBookings = result.recordset.map(booking => {
        const normalized = { ...booking };
        
        // Normalize các field có thể là array thành string
        if (Array.isArray(normalized.hotel_name)) {
          normalized.hotel_name = normalized.hotel_name[0] || normalized.hotel_name || '';
        }
        if (Array.isArray(normalized.hotel_image)) {
          normalized.hotel_image = normalized.hotel_image[0] || normalized.hotel_image || '';
        }
        if (Array.isArray(normalized.hotel_address)) {
          normalized.hotel_address = normalized.hotel_address[0] || normalized.hotel_address || '';
        }
        if (Array.isArray(normalized.refund_status)) {
          normalized.refund_status = normalized.refund_status[0] || normalized.refund_status || null;
        }
        if (Array.isArray(normalized.refund_reason)) {
          normalized.refund_reason = normalized.refund_reason[0] || normalized.refund_reason || null;
        }
        if (Array.isArray(normalized.cancelled_at)) {
          normalized.cancelled_at = normalized.cancelled_at[0] || normalized.cancelled_at || null;
        }
        
        return normalized;
      });
      
      // Log để debug
      console.log('📋 Query result:', {
        userId,
        status,
        limit,
        offset,
        found: normalizedBookings.length,
        sample: normalizedBookings.length > 0 ? {
          id: normalizedBookings[0].id,
          booking_code: normalizedBookings[0].booking_code,
          booking_status: normalizedBookings[0].booking_status,
          payment_method: normalizedBookings[0].payment_method,
          hotel_name: normalizedBookings[0].hotel_name,
          hotel_name_type: typeof normalizedBookings[0].hotel_name,
          is_hotel_name_array: Array.isArray(normalizedBookings[0].hotel_name),
        } : null,
      });
      
      return normalizedBookings;
    } catch (error) {
      console.error('❌ Error getting user bookings:', error);
      throw error;
    }
  }

  /**
   * Lấy chi tiết booking theo ID
   */
  static async getById(bookingId) {
    try {
      const pool = getPool();
      const result = await pool.request()
        .input('id', sql.Int, bookingId)
        .query('SELECT * FROM vw_bookings_with_cancellation WHERE id = @id');

      return result.recordset[0];
    } catch (error) {
      console.error('❌ Error getting booking by ID:', error);
      throw error;
    }
  }

  /**
   * Lấy booking theo mã
   */
  static async getByCode(bookingCode) {
    try {
      const pool = getPool();
      const result = await pool.request()
        .input('code', sql.NVarChar(50), bookingCode)
        .query('SELECT * FROM vw_bookings_with_cancellation WHERE booking_code = @code');

      return result.recordset[0];
    } catch (error) {
      console.error('❌ Error getting booking by code:', error);
      throw error;
    }
  }

  /**
   * Hủy booking (cho phép hủy trước 24h check-in nếu cancellation_allowed = true)
   */
  static async cancel(bookingId, userId, reason = '') {
    try {
      const pool = await getPool();
      
      // Kiểm tra quyền và thời gian
      const booking = await this.getById(bookingId);
      
      if (!booking) {
        throw new Error('Không tìm thấy đơn đặt phòng');
      }

      if (booking.user_id !== userId) {
        throw new Error('Bạn không có quyền hủy đơn đặt phòng này');
      }

      // ✅ CHECK CANCELLATION POLICY FIRST!
      if (!booking.cancellation_allowed) {
        throw new Error('Đơn đặt phòng này không cho phép hủy theo chính sách khách sạn (giá ưu đãi không hoàn tiền)');
      }

      // ✅ CHECK TIME: Must cancel at least 24h before check-in
      const checkInDate = new Date(booking.check_in_date);
      const now = new Date();
      const hoursUntilCheckIn = (checkInDate - now) / (1000 * 60 * 60);
      
      if (hoursUntilCheckIn < 24) {
        throw new Error('Chỉ có thể hủy phòng trước 24 giờ so với thời gian nhận phòng');
      }

      // Allow cancelling both pending and confirmed bookings
      if (!['pending', 'confirmed'].includes(booking.booking_status)) {
        throw new Error('Đơn đặt phòng này không thể hủy');
      }

      // Cập nhật trạng thái
      const result = await pool.request()
        .input('id', sql.Int, bookingId)
        .input('reason', sql.NVarChar(500), reason)
        .query(`
          UPDATE bookings
          SET 
            booking_status = 'cancelled',
            cancelled_at = GETDATE(),
            refund_status = 'requested',
            refund_reason = @reason,
            updated_at = GETDATE()
          WHERE id = @id;
          
          SELECT * FROM vw_bookings_with_cancellation WHERE id = @id;
        `);
      
      // NOTE: Room status update disabled due to CHECK constraint
      // Room availability is managed through booking records
      console.log(`✅ Booking cancelled for room ${booking.room_id}`);

      return result.recordset[0];
    } catch (error) {
      console.error('❌ Error cancelling booking:', error);
      throw error;
    }
  }

  /**
   * Cập nhật trạng thái hoàn tiền
   */
  static async updateRefundStatus(bookingId, refundData) {
    try {
      const pool = getPool();
      
      const result = await pool.request()
        .input('id', sql.Int, bookingId)
        .input('refund_status', sql.NVarChar(50), refundData.status)
        .input('refund_amount', sql.Decimal(18, 2), refundData.amount)
        .input('refund_transaction_id', sql.NVarChar(255), refundData.transactionId)
        .query(`
          UPDATE bookings
          SET 
            refund_status = @refund_status,
            refund_amount = @refund_amount,
            refund_transaction_id = @refund_transaction_id,
            refund_date = GETDATE(),
            updated_at = GETDATE()
          WHERE id = @id;
          
          SELECT * FROM vw_bookings_with_cancellation WHERE id = @id;
        `);

      return result.recordset[0];
    } catch (error) {
      console.error('❌ Error updating refund status:', error);
      throw error;
    }
  }

  /**
   * Lấy thống kê bookings
   */
  static async getStats(userId) {
    try {
      const pool = getPool();
      const result = await pool.request()
        .input('user_id', sql.Int, userId)
        .query(`
          SELECT 
            COUNT(*) AS total_bookings,
            SUM(CASE WHEN booking_status = 'confirmed' THEN 1 ELSE 0 END) AS confirmed_bookings,
            SUM(CASE WHEN booking_status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled_bookings,
            SUM(CASE WHEN booking_status = 'completed' THEN 1 ELSE 0 END) AS completed_bookings,
            SUM(final_price) AS total_spent,
            SUM(CASE WHEN booking_status = 'cancelled' THEN refund_amount ELSE 0 END) AS total_refunded
          FROM bookings
          WHERE user_id = @user_id
        `);

      return result.recordset[0];
    } catch (error) {
      console.error('❌ Error getting booking stats:', error);
      throw error;
    }
  }
}

module.exports = Booking;

