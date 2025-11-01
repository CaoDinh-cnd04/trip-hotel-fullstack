const Booking = require('../models/booking');
const refundService = require('../services/refundService');

class BookingController {
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
        checkInDate: req.body.checkInDate,
        checkOutDate: req.body.checkOutDate,
        guestCount: req.body.guestCount,
        roomCount: req.body.roomCount,
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
      const userId = req.user?.id;
      if (!userId) {
        return res.status(401).json({
          success: false,
          message: 'Chưa đăng nhập',
        });
      }

      const { status, limit, offset } = req.query;
      const bookings = await Booking.getByUserId(userId, {
        status,
        limit: limit ? parseInt(limit) : 50,
        offset: offset ? parseInt(offset) : 0,
      });

      res.json({
        success: true,
        data: bookings,
        total: bookings.length,
      });
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
        checkInDate: req.body.checkInDate,
        checkOutDate: req.body.checkOutDate,
        guestCount: req.body.guestCount,
        roomCount: req.body.roomCount || 1,
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

