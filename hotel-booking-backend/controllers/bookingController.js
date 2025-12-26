const Booking = require('../models/booking');
const refundService = require('../services/refundService');
const { getPool } = require('../config/db');
const sql = require('mssql');

class BookingController {
  /**
   * ✅ Helper: Kiểm tra số phòng available cho một loại phòng trong khoảng thời gian
   * @param {number} hotelId - ID khách sạn
   * @param {number} roomId - ID phòng (để lấy loai_phong_id)
   * @param {Date} checkInDate - Ngày check-in
   * @param {Date} checkOutDate - Ngày check-out
   * @returns {Promise<{available_rooms: number, total_rooms: number, booked_rooms: number}>}
   */
  async checkRoomAvailability(hotelId, roomId, checkInDate, checkOutDate) {
    try {
      const pool = getPool();
      
      // Lấy loai_phong_id từ roomId
      const roomInfo = await pool.request()
        .input('roomId', sql.Int, roomId)
        .query('SELECT loai_phong_id FROM dbo.phong WHERE id = @roomId');
      
      if (!roomInfo.recordset || roomInfo.recordset.length === 0) {
        throw new Error('Không tìm thấy thông tin phòng');
      }
      
      const loaiPhongId = roomInfo.recordset[0].loai_phong_id;
      
      // Đếm số phòng available
      const query = `
        WITH RoomCounts AS (
          -- Tổng số phòng của loại này
          SELECT COUNT(DISTINCT p.id) as total_rooms
          FROM dbo.phong p
          WHERE p.khach_san_id = @hotelId
            AND p.loai_phong_id = @loaiPhongId
        ),
        BookedCounts AS (
          -- Số phòng đã được đặt (confirmed, in_progress, checked_in, pending)
          -- Bao gồm cả pending để tránh overbooking
          SELECT COUNT(DISTINCT b.room_id) as booked_rooms
          FROM dbo.bookings b
          INNER JOIN dbo.phong p ON b.room_id = p.id
          WHERE p.khach_san_id = @hotelId
            AND p.loai_phong_id = @loaiPhongId
            AND b.booking_status IN ('confirmed', 'in_progress', 'checked_in', 'pending')
            AND (
              (b.check_in_date < @checkOutDate AND b.check_out_date > @checkInDate)
            )
        )
        SELECT 
          rc.total_rooms,
          ISNULL(bc.booked_rooms, 0) as booked_rooms,
          (rc.total_rooms - ISNULL(bc.booked_rooms, 0)) as available_rooms
        FROM RoomCounts rc
        CROSS JOIN BookedCounts bc
      `;
      
      const result = await pool.request()
        .input('hotelId', sql.Int, hotelId)
        .input('loaiPhongId', sql.Int, loaiPhongId)
        .input('checkInDate', sql.Date, checkInDate)
        .input('checkOutDate', sql.Date, checkOutDate)
        .query(query);
      
      if (!result.recordset || result.recordset.length === 0) {
        return { available_rooms: 0, total_rooms: 0, booked_rooms: 0 };
      }
      
      return {
        available_rooms: parseInt(result.recordset[0].available_rooms || 0),
        total_rooms: parseInt(result.recordset[0].total_rooms || 0),
        booked_rooms: parseInt(result.recordset[0].booked_rooms || 0),
      };
    } catch (error) {
      console.error('❌ Error checking room availability:', error);
      throw error;
    }
  }
  /**
   * Tạo booking mới
   * POST /api/bookings
   */
  async createBooking(req, res) {
    try {
      const userId = req.user?.id || req.user?.ma_nguoi_dung;
      if (!userId) {
        return res.status(401).json({
          success: false,
          message: 'Chưa đăng nhập',
        });
      }

      // ✅ VALIDATION: Kiểm tra số phòng available trước khi đặt
      const roomCount = req.body.roomCount || 1;
      const checkInDate = req.body.checkInDate;
      const checkOutDate = req.body.checkOutDate;
      const hotelId = req.body.hotelId;
      const roomId = req.body.roomId;
      
      if (!checkInDate || !checkOutDate || !hotelId || !roomId) {
        return res.status(400).json({
          success: false,
          message: 'Thiếu thông tin bắt buộc: checkInDate, checkOutDate, hotelId, roomId',
        });
      }
      
      // Kiểm tra số phòng available
      const availability = await this.checkRoomAvailability(
        hotelId,
        roomId,
        checkInDate,
        checkOutDate
      );
      
      console.log('📊 Room availability check:', {
        hotelId,
        roomId,
        checkInDate,
        checkOutDate,
        requestedRooms: roomCount,
        availableRooms: availability.available_rooms,
        totalRooms: availability.total_rooms,
        bookedRooms: availability.booked_rooms,
      });
      
      // Kiểm tra nếu số phòng yêu cầu vượt quá số phòng available
      if (roomCount > availability.available_rooms) {
        return res.status(400).json({
          success: false,
          message: `Không đủ phòng trống. Hiện tại chỉ còn ${availability.available_rooms} phòng, nhưng bạn yêu cầu ${roomCount} phòng.`,
          data: {
            available_rooms: availability.available_rooms,
            requested_rooms: roomCount,
            total_rooms: availability.total_rooms,
            booked_rooms: availability.booked_rooms,
          },
        });
      }

      const bookingData = {
        userId,
        userEmail: req.user.email,
        userName: req.user.ho_ten || req.user.ten || req.user.name,
        userPhone: req.body.userPhone || req.user.sdt,
        hotelId: req.body.hotelId,
        hotelName: req.body.hotelName,
        roomId: req.body.roomId,
        roomNumber: req.body.roomNumber,
        roomType: req.body.roomType,
        checkInDate: checkInDate,
        checkOutDate: checkOutDate,
        guestCount: req.body.guestCount,
        roomCount: roomCount,
        nights: req.body.nights,
        roomPrice: req.body.roomPrice,
        totalPrice: req.body.totalPrice,
        discountAmount: req.body.discountAmount || 0,
        finalPrice: req.body.finalPrice,
        paymentMethod: req.body.paymentMethod,
        // Tiền mặt = pending, Online = paid
        paymentStatus: req.body.paymentMethod === 'cash' ? 'pending' : (req.body.paymentStatus || 'paid'),
        paymentTransactionId: req.body.paymentTransactionId,
        cancellationAllowed: req.body.cancellationAllowed !== false,
        specialRequests: req.body.specialRequests,
      };

      const booking = await Booking.create(bookingData);

      res.json({
        success: true,
        message: req.body.paymentMethod === 'cash' 
          ? 'Đặt phòng thành công - Vui lòng thanh toán tiền mặt khi nhận phòng'
          : 'Đặt phòng thành công',
        data: booking,
      });
    } catch (error) {
      console.error('❌ Error creating booking:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi tạo booking',
        error: error.message,
      });
    }
  }

  /**
   * Lấy danh sách bookings của user
   * GET /api/bookings
   */
  async getMyBookings(req, res) {
    try {
      // ✅ FIX: Lấy userId từ nhiều nguồn để đảm bảo khớp với createCashBooking
      const userId = req.user?.id || req.user?.ma_nguoi_dung;
      if (!userId) {
        return res.status(401).json({
          success: false,
          message: 'Chưa đăng nhập',
        });
      }

      const { status, limit, offset } = req.query;
      
      // Log để debug
      console.log('📋 Getting bookings for user:', userId);
      console.log('📋 User object keys:', Object.keys(req.user || {}));
      console.log('📋 req.user.id:', req.user?.id);
      console.log('📋 req.user.ma_nguoi_dung:', req.user?.ma_nguoi_dung);
      console.log('📋 Query params:', { status, limit, offset });
      
      const bookings = await Booking.getByUserId(userId, {
        status,
        limit: limit ? parseInt(limit) : 50,
        offset: offset ? parseInt(offset) : 0,
      });

      // Log kết quả
      console.log('📋 Found bookings:', bookings.length);
      if (bookings.length > 0) {
        console.log('📋 Sample booking:', {
          id: bookings[0].id,
          booking_code: bookings[0].booking_code,
          user_id: bookings[0].user_id,
          booking_status: bookings[0].booking_status,
          payment_status: bookings[0].payment_status,
          payment_method: bookings[0].payment_method,
          hotel_name: bookings[0].hotel_name,
        });
      } else {
        console.log('⚠️ No bookings found for user:', userId);
        // Debug: Kiểm tra xem có booking nào trong database không
        const { getPool } = require('../config/db');
        const sql = require('mssql');
        const pool = await getPool();
        
        // Kiểm tra cả bảng bookings (mới) và phieu_dat_phong (cũ)
        const debugResult = await pool.request()
          .input('user_id', sql.Int, userId)
          .query(`
            SELECT 
              (SELECT COUNT(*) FROM bookings WHERE user_id = @user_id) as bookings_count,
              (SELECT COUNT(*) FROM phieu_dat_phong WHERE nguoi_dung_id = @user_id) as phieu_dat_phong_count
          `);
        console.log('📋 Total bookings in DB for user:', {
          bookings_table: debugResult.recordset[0].bookings_count,
          phieu_dat_phong_table: debugResult.recordset[0].phieu_dat_phong_count,
        });
        
        // Kiểm tra xem có booking nào với user_id khác không
        const allBookingsCheck = await pool.request()
          .query('SELECT TOP 5 user_id, booking_code, booking_status FROM bookings ORDER BY created_at DESC');
        console.log('📋 Recent bookings (for debugging):', allBookingsCheck.recordset);
      }

      const response = {
        success: true,
        data: bookings,
        total: bookings.length,
      };
      
      console.log('📋 Response summary:', {
        success: response.success,
        total: response.total,
        dataLength: response.data.length,
        firstBookingKeys: response.data.length > 0 ? Object.keys(response.data[0]) : []
      });
      
      if (bookings.length > 0) {
        console.log('📋 First booking full data:');
        console.log(JSON.stringify(bookings[0], null, 2));
      }
      
      res.json(response);
    } catch (error) {
      console.error('❌ Error getting bookings:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi lấy danh sách booking',
        error: error.message,
      });
    }
  }

  /**
   * Lấy chi tiết booking
   * GET /api/bookings/:id
   */
  async getBookingDetail(req, res) {
    try {
      const userId = req.user?.id;
      if (!userId) {
        return res.status(401).json({
          success: false,
          message: 'Chưa đăng nhập',
        });
      }

      const bookingId = parseInt(req.params.id);
      const booking = await Booking.getById(bookingId);

      if (!booking) {
        return res.status(404).json({
          success: false,
          message: 'Không tìm thấy booking',
        });
      }

      // Kiểm tra quyền
      if (booking.user_id !== userId) {
        return res.status(403).json({
          success: false,
          message: 'Bạn không có quyền xem booking này',
        });
      }

      res.json({
        success: true,
        data: booking,
      });
    } catch (error) {
      console.error('❌ Error getting booking detail:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi lấy chi tiết booking',
        error: error.message,
      });
    }
  }

  /**
   * Hủy booking (chỉ trong 5 phút)
   * POST /api/bookings/:id/cancel
   */
  async cancelBooking(req, res) {
    try {
      const userId = req.user?.id;
      if (!userId) {
        return res.status(401).json({
          success: false,
          message: 'Chưa đăng nhập',
        });
      }

      const bookingId = parseInt(req.params.id);
      const { reason } = req.body;

      // Hủy booking
      const booking = await Booking.cancel(bookingId, userId, reason);

      // Tự động xử lý hoàn tiền
      const refundResult = await refundService.processRefund(bookingId);

      res.json({
        success: true,
        message: 'Hủy booking thành công',
        data: {
          booking,
          refund: refundResult,
        },
      });
    } catch (error) {
      console.error('❌ Error cancelling booking:', error);
      res.status(400).json({
        success: false,
        message: error.message,
      });
    }
  }

  /**
   * Lấy thống kê bookings
   * GET /api/bookings/stats
   */
  async getBookingStats(req, res) {
    try {
      const userId = req.user?.id;
      if (!userId) {
        return res.status(401).json({
          success: false,
          message: 'Chưa đăng nhập',
        });
      }

      const stats = await Booking.getStats(userId);

      res.json({
        success: true,
        data: stats,
      });
    } catch (error) {
      console.error('❌ Error getting stats:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi lấy thống kê',
        error: error.message,
      });
    }
  }

  /**
   * Tạo booking thanh toán tiền mặt
   * POST /api/bookings/cash
   */
  /**
   * Kiểm tra validation trước khi đặt phòng
   * GET /api/bookings/validate
   * @query hotelId, checkInDate, checkOutDate, paymentMethod, paymentAmount, totalPrice
   */
  async validateBooking(req, res) {
    try {
      const userId = req.user?.id || req.user?.ma_nguoi_dung;
      if (!userId) {
        return res.status(401).json({
          success: false,
          message: 'Chưa đăng nhập',
        });
      }

      const { hotelId, checkInDate, checkOutDate, paymentMethod, paymentAmount, totalPrice } = req.query;

      if (!hotelId || !checkInDate || !checkOutDate) {
        return res.status(400).json({
          success: false,
          message: 'Thiếu thông tin bắt buộc: hotelId, checkInDate, checkOutDate',
        });
      }

      const BookingValidationService = require('../services/bookingValidationService');
      const validation = await BookingValidationService.validateBooking(
        userId,
        parseInt(hotelId),
        new Date(checkInDate),
        new Date(checkOutDate),
        paymentMethod || 'cash',
        parseFloat(paymentAmount || 0),
        parseFloat(totalPrice || 0)
      );

      res.json({
        success: true,
        data: validation,
      });
    } catch (error) {
      console.error('Error validating booking:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi kiểm tra validation',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined,
      });
    }
  }

  /**
   * Kiểm tra xem user có booking active ở khách sạn khác không (để ẩn nút đặt phòng)
   * GET /api/bookings/check-active
   * @query hotelId (optional) - Nếu có, kiểm tra xem có booking ở khách sạn khác không
   */
  async checkActiveBooking(req, res) {
    try {
      const userId = req.user?.id || req.user?.ma_nguoi_dung;
      if (!userId) {
        return res.status(401).json({
          success: false,
          message: 'Chưa đăng nhập',
        });
      }

      const { hotelId } = req.query;
      const BookingValidationService = require('../services/bookingValidationService');
      
      // Lấy tất cả bookings chưa checkout
      const { conflictingBookings } = await BookingValidationService.checkActiveBookings(
        userId,
        new Date(), // Dummy dates, không dùng trong logic mới
        new Date()
      );

      // Nếu có hotelId, kiểm tra xem có booking ở khách sạn khác không
      if (hotelId) {
        const currentHotelId = parseInt(hotelId);
        
        console.log('🔍 Check active booking:', {
          userId,
          currentHotelId,
          currentHotelIdType: typeof currentHotelId,
          conflictingBookingsCount: conflictingBookings.length,
          conflictingBookings: conflictingBookings.map(b => ({
            bookingId: b.id,
            hotelId: b.hotel_id,
            hotelIdType: typeof b.hotel_id,
            hotelName: b.hotel_name,
            checkOut: b.check_out_date,
          })),
        });

        const otherHotelBookings = conflictingBookings.filter(
          booking => {
            const bookingHotelId = parseInt(booking.hotel_id);
            const isDifferent = bookingHotelId !== currentHotelId;
            console.log(`   - Booking ${booking.id}: hotelId=${bookingHotelId} (${typeof booking.hotel_id}) vs current=${currentHotelId} (${typeof currentHotelId}) => ${isDifferent ? 'DIFFERENT' : 'SAME'}`);
            return isDifferent;
          }
        );

        const sameHotelBookings = conflictingBookings.filter(
          booking => {
            const bookingHotelId = parseInt(booking.hotel_id);
            const isSame = bookingHotelId === currentHotelId;
            console.log(`   - Booking ${booking.id}: hotelId=${bookingHotelId} (${typeof booking.hotel_id}) vs current=${currentHotelId} (${typeof currentHotelId}) => ${isSame ? 'SAME' : 'DIFFERENT'}`);
            return isSame;
          }
        );

        console.log('🔍 Filter results:', {
          otherHotelBookingsCount: otherHotelBookings.length,
          sameHotelBookingsCount: sameHotelBookings.length,
        });

        // ✅ ƯU TIÊN: Nếu có booking ở CÙNG khách sạn → cho phép đặt nhưng chỉ VNPay/Bank Transfer, yêu cầu >= 50%
        // (Ngay cả khi có booking ở hotel khác, vẫn cho phép đặt thêm phòng ở cùng hotel)
        if (sameHotelBookings.length > 0) {
          console.log('✅ Allowing: User has booking at same hotel, can book more rooms with online payment');
          return res.json({
            success: true,
            data: {
              hasActiveBooking: true,
              hasOtherHotelBooking: otherHotelBookings.length > 0, // Có booking ở hotel khác nhưng vẫn cho phép đặt cùng hotel
              hasSameHotelBooking: true,
              canBook: true, // ✅ Cho phép đặt thêm phòng
              requiresOnlinePayment: true, // ✅ Yêu cầu thanh toán online
              minPaymentPercentage: 50, // ✅ Tối thiểu 50%
              message: 'Bạn đang có đặt phòng tại khách sạn này. Để đặt thêm phòng, vui lòng sử dụng thanh toán VNPay hoặc chuyển khoản ngân hàng (tối thiểu 50% tổng giá trị).',
              sameHotelBooking: {
                hotelId: sameHotelBookings[0].hotel_id,
                hotelName: sameHotelBookings[0].hotel_name,
                checkOutDate: sameHotelBookings[0].check_out_date,
              },
            },
          });
        }

        // Nếu có booking ở khách sạn KHÁC → không cho đặt hotel khác
        if (otherHotelBookings.length > 0) {
          const otherHotel = otherHotelBookings[0];
          const checkOutDateStr = new Date(otherHotel.check_out_date).toLocaleDateString('vi-VN');
          console.log('❌ Blocking: User has booking at other hotel:', otherHotel.hotel_name);
          return res.json({
            success: true,
            data: {
              hasActiveBooking: true,
              hasOtherHotelBooking: true,
              hasSameHotelBooking: false,
              canBook: false,
              message: `Bạn đang có đặt phòng tại ${otherHotel.hotel_name} (đến ngày ${checkOutDateStr}). Vui lòng đợi đến sau ngày checkout để đặt khách sạn khác.`,
              activeBooking: {
                hotelId: otherHotel.hotel_id,
                hotelName: otherHotel.hotel_name,
                checkOutDate: otherHotel.check_out_date,
              },
            },
          });
        }
      }

      // Nếu không có booking nào, cho phép đặt bình thường
      res.json({
        success: true,
        data: {
          hasActiveBooking: conflictingBookings.length > 0,
          hasOtherHotelBooking: false,
          hasSameHotelBooking: false,
          canBook: true,
          requiresOnlinePayment: false,
          minPaymentPercentage: 0,
          message: 'Bạn có thể đặt phòng',
        },
      });
    } catch (error) {
      console.error('Error checking active booking:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi kiểm tra booking active',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined,
      });
    }
  }

  async createCashBooking(req, res) {
    try {
      const userId = req.user?.id || req.user?.ma_nguoi_dung;
      if (!userId) {
        return res.status(401).json({
          success: false,
          message: 'Chưa đăng nhập',
        });
      }

      // Calculate room price from total amount and nights
      const totalAmount = req.body.totalAmount || 0;
      const nights = req.body.nights || 1;
      const roomPrice = totalAmount / nights;

      // ✅ VALIDATION: Kiểm tra số phòng available trước khi đặt
      const roomCount = req.body.roomCount || 1;
      const checkInDate = req.body.checkInDate;
      const checkOutDate = req.body.checkOutDate;
      const hotelId = req.body.hotelId;
      const roomId = req.body.roomId;
      
      if (!checkInDate || !checkOutDate || !hotelId || !roomId) {
        return res.status(400).json({
          success: false,
          message: 'Thiếu thông tin bắt buộc: checkInDate, checkOutDate, hotelId, roomId',
        });
      }
      
      // Kiểm tra số phòng available
      const availability = await this.checkRoomAvailability(
        hotelId,
        roomId,
        checkInDate,
        checkOutDate
      );
      
      console.log('📊 Cash booking - Room availability check:', {
        hotelId,
        roomId,
        checkInDate,
        checkOutDate,
        requestedRooms: roomCount,
        availableRooms: availability.available_rooms,
        totalRooms: availability.total_rooms,
        bookedRooms: availability.booked_rooms,
      });
      
      // Kiểm tra nếu số phòng yêu cầu vượt quá số phòng available
      if (roomCount > availability.available_rooms) {
        return res.status(400).json({
          success: false,
          message: `Không đủ phòng trống. Hiện tại chỉ còn ${availability.available_rooms} phòng, nhưng bạn yêu cầu ${roomCount} phòng.`,
          data: {
            available_rooms: availability.available_rooms,
            requested_rooms: roomCount,
            total_rooms: availability.total_rooms,
            booked_rooms: availability.booked_rooms,
          },
        });
      }

      // ✅ VALIDATION: Kiểm tra booking active và yêu cầu thanh toán
      console.log('🔍 Cash booking - Starting validation check:', {
        userId,
        hotelId,
        checkInDate,
        checkOutDate,
        paymentMethod: 'cash',
        totalAmount,
      });
      
      const BookingValidationService = require('../services/bookingValidationService');
      const validation = await BookingValidationService.validateBooking(
        userId,
        parseInt(hotelId),
        new Date(checkInDate),
        new Date(checkOutDate),
        'cash', // Payment method
        0, // Payment amount (cash = 0)
        parseFloat(totalAmount) // Total price
      );

      console.log('🔍 Cash booking - Validation result:', {
        isValid: validation.isValid,
        message: validation.message,
        requiresPayment: validation.requiresPayment,
        minPaymentPercentage: validation.minPaymentPercentage,
      });

      if (!validation.isValid) {
        console.log('❌ Cash booking - Validation failed, blocking booking creation');
        return res.status(400).json({
          success: false,
          message: validation.message,
          data: {
            requiresPayment: validation.requiresPayment,
            minPaymentPercentage: validation.minPaymentPercentage,
          },
        });
      }
      
      console.log('✅ Cash booking - Validation passed, proceeding with booking creation');

      const bookingData = {
        userId,
        userEmail: req.body.userEmail || req.user.email,
        userName: req.body.userName || req.user.ho_ten || req.user.ten || req.user.name,
        userPhone: req.body.userPhone || req.user.sdt,
        hotelId: req.body.hotelId,
        hotelName: req.body.hotelName,
        roomId: req.body.roomId,
        roomNumber: req.body.roomNumber,
        roomType: req.body.roomType,
        checkInDate: checkInDate,
        checkOutDate: checkOutDate,
        guestCount: req.body.guestCount,
        roomCount: roomCount,
        nights: nights,
        roomPrice: roomPrice, // Calculated from totalAmount / nights
        totalPrice: totalAmount, // Total amount including all fees
        finalPrice: totalAmount, // Final price after any discounts
        discountAmount: 0, // No discount for cash bookings by default
        totalAmount: totalAmount,
        paymentMethod: 'Cash',
        paymentStatus: 'pending', // Cash payment is pending until check-in
        bookingStatus: 'pending', // Booking is pending confirmation
        cancellationAllowed: false, // ✅ Cash bookings = Non-refundable = No cancellation
        specialRequests: req.body.specialRequests || '',
      };

      const newBooking = await Booking.create(bookingData);

      // ✅ Gửi email thông báo cho hotel manager khi có đặt phòng tiền mặt
      try {
        const emailService = require('../services/emailService');
        const { getPool } = require('../config/db');
        const sql = require('mssql');
        const pool = await getPool();
        
        // Lấy thông tin hotel manager
        const managerResult = await pool.request()
          .input('hotelId', sql.Int, req.body.hotelId)
          .query(`
            SELECT 
              nd.id as manager_id,
              nd.email as manager_email,
              nd.ho_ten as manager_name,
              ks.ten as hotel_name
            FROM dbo.khach_san ks
            INNER JOIN dbo.nguoi_dung nd ON ks.nguoi_quan_ly_id = nd.id
            WHERE ks.id = @hotelId
          `);
        
        if (managerResult.recordset.length > 0) {
          const manager = managerResult.recordset[0];
          const checkInDate = new Date(req.body.checkInDate).toLocaleDateString('vi-VN');
          const checkOutDate = new Date(req.body.checkOutDate).toLocaleDateString('vi-VN');
          
          const emailSubject = `🔔 Đặt phòng mới - ${manager.hotel_name}`;
          const emailHTML = `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
              <h2 style="color: #2c3e50;">🔔 Đặt phòng mới</h2>
              <p>Xin chào <strong>${manager.manager_name}</strong>,</p>
              <p>Bạn có một đặt phòng mới tại <strong>${manager.hotel_name}</strong>:</p>
              <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                <p><strong>Mã đặt phòng:</strong> ${newBooking.booking_code}</p>
                <p><strong>Khách hàng:</strong> ${req.body.userName || 'N/A'}</p>
                <p><strong>Email:</strong> ${req.body.userEmail || 'N/A'}</p>
                <p><strong>Số điện thoại:</strong> ${req.body.userPhone || 'N/A'}</p>
                <p><strong>Loại phòng:</strong> ${req.body.roomType || 'N/A'}</p>
                <p><strong>Số phòng:</strong> ${req.body.roomNumber || 'N/A'}</p>
                <p><strong>Ngày nhận phòng:</strong> ${checkInDate}</p>
                <p><strong>Ngày trả phòng:</strong> ${checkOutDate}</p>
                <p><strong>Số đêm:</strong> ${nights}</p>
                <p><strong>Số khách:</strong> ${req.body.guestCount || 1}</p>
                <p><strong>Tổng tiền:</strong> ${totalAmount.toLocaleString('vi-VN')} VNĐ</p>
                <p><strong>Phương thức thanh toán:</strong> Tiền mặt (chờ thanh toán khi nhận phòng)</p>
                <p><strong>Trạng thái:</strong> <span style="color: #ff9800;">Chờ xác nhận</span></p>
              </div>
              <p>Vui lòng xác nhận hoặc từ chối đặt phòng này trong hệ thống quản lý.</p>
              <p style="color: #666; font-size: 12px; margin-top: 30px;">Email này được gửi tự động từ hệ thống quản lý khách sạn.</p>
            </div>
          `;
          
          await emailService.sendEmail(manager.manager_email, emailSubject, emailHTML);
          console.log(`✅ Email notification sent to hotel manager: ${manager.manager_email}`);
        }
      } catch (emailError) {
        console.error('⚠️ Error sending email to hotel manager (non-critical):', emailError);
        // Không throw error vì booking đã tạo thành công
      }

      res.status(201).json({
        success: true,
        message: 'Đặt phòng thành công (chờ xác nhận thanh toán tiền mặt)',
        data: newBooking,
      });
    } catch (error) {
      console.error('Error creating cash booking:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi tạo đặt phòng tiền mặt',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined,
      });
    }
  }
}

module.exports = new BookingController();

