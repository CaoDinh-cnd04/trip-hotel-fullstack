/**
 * Booking Validation Service
 * 
 * Kiểm tra và validate booking để tránh spam đặt phòng:
 * - Một user chỉ được đặt 1 khách sạn từ lúc đặt phòng (created_at) cho đến khi checkout (check_out_date)
 * - Logic tính từ lúc đặt phòng, không phải từ ngày check-in
 * - Khi hết ngày checkout thì mới được tiếp tục đặt khách sạn khác
 * - Chỉ được đặt thêm phòng ở cùng khách sạn, nhưng yêu cầu thanh toán VNPay/Bank Transfer >= 50%
 */

const { getPool } = require('../config/db');
const sql = require('mssql');

class BookingValidationService {
  /**
   * Kiểm tra xem user có booking nào đang active không (tính từ lúc đặt phòng, không phải từ ngày check-in)
   * Logic: Kiểm tra tất cả bookings có status hợp lệ và chưa đến ngày checkout (check_out_date >= today)
   * @param {number} userId - User ID
   * @param {Date} checkInDate - Ngày check-in của booking mới (không dùng trong logic này)
   * @param {Date} checkOutDate - Ngày check-out của booking mới (không dùng trong logic này)
   * @returns {Promise<{hasActiveBooking: boolean, activeBookings: Array, conflictingBookings: Array}>}
   */
  static async checkActiveBookings(userId, checkInDate, checkOutDate) {
    try {
      const pool = await getPool();
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      
      // ✅ FIX: Logic mới - Tính từ lúc đặt phòng (created_at), không phải từ ngày check-in
      // Lấy tất cả bookings của user có status hợp lệ và chưa đến ngày checkout
      // Không quan trọng ngày check-in, chỉ cần check_out_date >= today
      const result = await pool.request()
        .input('user_id', sql.Int, userId)
        .input('today', sql.Date, today)
        .query(`
          SELECT 
            b.id,
            b.booking_code,
            b.hotel_id,
            b.room_id,
            b.check_in_date,
            b.check_out_date,
            b.booking_status,
            b.payment_status,
            b.payment_method,
            b.created_at,
            ks.ten as hotel_name
          FROM bookings b
          INNER JOIN khach_san ks ON b.hotel_id = ks.id
          WHERE b.user_id = @user_id
            AND b.booking_status IN ('pending', 'confirmed', 'in_progress', 'checked_in')
            AND CAST(b.check_out_date AS DATE) >= @today
          ORDER BY b.created_at DESC
        `);
      
      const conflictingBookings = result.recordset || [];
      
      // Lấy tất cả bookings active (check-in <= today <= check-out) để hiển thị thông tin
      const activeResult = await pool.request()
        .input('user_id', sql.Int, userId)
        .input('today', sql.Date, today)
        .query(`
          SELECT 
            b.id,
            b.booking_code,
            b.hotel_id,
            b.room_id,
            b.check_in_date,
            b.check_out_date,
            b.booking_status,
            b.payment_status,
            b.payment_method,
            b.created_at,
            ks.ten as hotel_name
          FROM bookings b
          INNER JOIN khach_san ks ON b.hotel_id = ks.id
          WHERE b.user_id = @user_id
            AND b.booking_status IN ('pending', 'confirmed', 'in_progress', 'checked_in')
            AND CAST(b.check_in_date AS DATE) <= @today
            AND CAST(b.check_out_date AS DATE) >= @today
          ORDER BY b.check_in_date DESC
        `);
      
      const activeBookings = activeResult.recordset || [];
      
      console.log('🔍 Booking validation check (tính từ lúc đặt phòng):', {
        userId,
        today: today.toISOString(),
        conflictingBookingsCount: conflictingBookings.length,
        activeBookingsCount: activeBookings.length,
        conflictingHotels: conflictingBookings.map(b => ({ 
          hotelId: b.hotel_id, 
          hotelName: b.hotel_name, 
          checkIn: b.check_in_date, 
          checkOut: b.check_out_date,
          created_at: b.created_at,
          status: b.booking_status
        })),
      });
      
      return {
        hasActiveBooking: activeBookings.length > 0,
        activeBookings: activeBookings,
        conflictingBookings: conflictingBookings, // ✅ Tất cả bookings chưa checkout (tính từ lúc đặt phòng)
      };
    } catch (error) {
      console.error('❌ Error checking active bookings:', error);
      throw error;
    }
  }

  /**
   * Kiểm tra xem user có booking active ở khách sạn khác không (tính từ lúc đặt phòng)
   * @param {number} userId - User ID
   * @param {number} hotelId - Hotel ID của booking mới
   * @param {Date} checkInDate - Ngày check-in của booking mới (không dùng)
   * @param {Date} checkOutDate - Ngày check-out của booking mới (không dùng)
   * @returns {Promise<{hasOtherHotelBooking: boolean, otherHotelBookings: Array}>}
   */
  static async checkOtherHotelBookings(userId, hotelId, checkInDate, checkOutDate) {
    try {
      const { activeBookings, conflictingBookings } = await this.checkActiveBookings(userId, checkInDate, checkOutDate);
      
      // Lọc ra các booking ở khách sạn khác (bất kỳ booking nào chưa checkout)
      const otherHotelBookings = conflictingBookings.filter(
        booking => booking.hotel_id !== hotelId
      );
      
      console.log('🔍 Check other hotel bookings:', {
        userId,
        currentHotelId: hotelId,
        otherHotelBookingsCount: otherHotelBookings.length,
        otherHotels: otherHotelBookings.map(b => ({ hotelId: b.hotel_id, hotelName: b.hotel_name, checkOut: b.check_out_date })),
      });
      
      return {
        hasOtherHotelBooking: otherHotelBookings.length > 0,
        otherHotelBookings: otherHotelBookings,
      };
    } catch (error) {
      console.error('❌ Error checking other hotel bookings:', error);
      throw error;
    }
  }

  /**
   * Kiểm tra xem user có booking active ở cùng khách sạn không (tính từ lúc đặt phòng)
   * @param {number} userId - User ID
   * @param {number} hotelId - Hotel ID
   * @param {Date} checkInDate - Ngày check-in của booking mới (không dùng)
   * @param {Date} checkOutDate - Ngày check-out của booking mới (không dùng)
   * @returns {Promise<{hasSameHotelBooking: boolean, sameHotelBookings: Array}>}
   */
  static async checkSameHotelBookings(userId, hotelId, checkInDate, checkOutDate) {
    try {
      const { activeBookings, conflictingBookings } = await this.checkActiveBookings(userId, checkInDate, checkOutDate);
      
      // Lọc ra các booking ở cùng khách sạn (bất kỳ booking nào chưa checkout)
      const sameHotelBookings = conflictingBookings.filter(
        booking => booking.hotel_id === hotelId
      );
      
      console.log('🔍 Check same hotel bookings:', {
        userId,
        hotelId,
        sameHotelBookingsCount: sameHotelBookings.length,
        sameHotelBookings: sameHotelBookings.map(b => ({ bookingCode: b.booking_code, checkOut: b.check_out_date })),
      });
      
      return {
        hasSameHotelBooking: sameHotelBookings.length > 0,
        sameHotelBookings: sameHotelBookings,
      };
    } catch (error) {
      console.error('❌ Error checking same hotel bookings:', error);
      throw error;
    }
  }

  /**
   * Validate booking trước khi tạo
   * @param {number} userId - User ID
   * @param {number} hotelId - Hotel ID
   * @param {Date} checkInDate - Ngày check-in
   * @param {Date} checkOutDate - Ngày check-out
   * @param {string} paymentMethod - Phương thức thanh toán (vnpay, bank_transfer, cash)
   * @param {number} paymentAmount - Số tiền thanh toán
   * @param {number} totalPrice - Tổng giá booking
   * @returns {Promise<{isValid: boolean, message: string, requiresPayment: boolean, minPaymentPercentage: number}>}
   */
  static async validateBooking(userId, hotelId, checkInDate, checkOutDate, paymentMethod, paymentAmount, totalPrice) {
    try {
      // ✅ ƯU TIÊN: Kiểm tra booking active ở CÙNG khách sạn trước
      // (Ngay cả khi có booking ở hotel khác, vẫn cho phép đặt thêm phòng ở cùng hotel với điều kiện)
      const { hasSameHotelBooking } = await this.checkSameHotelBookings(
        userId, hotelId, checkInDate, checkOutDate
      );
      
      if (hasSameHotelBooking) {
        // Nếu đặt cùng khách sạn, yêu cầu thanh toán VNPay/Bank Transfer >= 50%
        if (paymentMethod === 'cash') {
          return {
            isValid: false,
            message: 'Bạn đang có đặt phòng tại khách sạn này. Để đặt thêm phòng, vui lòng sử dụng thanh toán VNPay hoặc chuyển khoản ngân hàng (tối thiểu 50% tổng giá trị).',
            requiresPayment: true,
            minPaymentPercentage: 50,
          };
        }
        
        // Kiểm tra số tiền thanh toán >= 50%
        const paymentPercentage = totalPrice > 0 ? (paymentAmount / totalPrice) * 100 : 0;
        if (paymentPercentage < 50) {
          return {
            isValid: false,
            message: `Bạn đang có đặt phòng tại khách sạn này. Để đặt thêm phòng, vui lòng thanh toán tối thiểu 50% tổng giá trị (${(totalPrice * 0.5).toLocaleString('vi-VN')} VNĐ).`,
            requiresPayment: true,
            minPaymentPercentage: 50,
            currentPaymentPercentage: paymentPercentage.toFixed(2),
          };
        }
        
        // ✅ Nếu đáp ứng điều kiện thanh toán, cho phép đặt thêm phòng ở cùng hotel
        return {
          isValid: true,
          message: 'Booking hợp lệ - đặt thêm phòng ở cùng khách sạn',
          requiresPayment: false,
          minPaymentPercentage: 0,
        };
      }
      
      // 2. Kiểm tra booking active ở khách sạn KHÁC → không cho đặt hotel khác
      const { hasOtherHotelBooking, otherHotelBookings } = await this.checkOtherHotelBookings(
        userId, hotelId, checkInDate, checkOutDate
      );
      
      if (hasOtherHotelBooking) {
        const otherHotel = otherHotelBookings[0];
        const checkOutDateStr = new Date(otherHotel.check_out_date).toLocaleDateString('vi-VN');
        return {
          isValid: false,
          message: `Bạn đang có đặt phòng tại ${otherHotel.hotel_name} (đến ngày ${checkOutDateStr}). Vui lòng đợi đến sau ngày checkout để đặt khách sạn khác.`,
          requiresPayment: false,
          minPaymentPercentage: 0,
        };
      }
      
      // 3. Nếu không có booking active nào, cho phép đặt bình thường
      return {
        isValid: true,
        message: 'Booking hợp lệ',
        requiresPayment: false,
        minPaymentPercentage: 0,
      };
    } catch (error) {
      console.error('❌ Error validating booking:', error);
      return {
        isValid: false,
        message: 'Lỗi khi kiểm tra booking: ' + error.message,
        requiresPayment: false,
        minPaymentPercentage: 0,
      };
    }
  }
}

module.exports = BookingValidationService;

