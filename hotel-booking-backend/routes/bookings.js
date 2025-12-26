const express = require('express');
const router = express.Router();
const bookingController = require('../controllers/bookingController');
const { authenticateToken } = require('../middleware/auth');

// Tất cả routes đều yêu cầu authentication
router.use(authenticateToken);

/**
 * @route   POST /api/bookings
 * @desc    Tạo booking mới
 * @access  Private
 */
router.post('/', (req, res) => bookingController.createBooking(req, res));

/**
 * @route   POST /api/bookings/cash
 * @desc    Tạo booking thanh toán tiền mặt
 * @access  Private
 */
router.post('/cash', (req, res) => bookingController.createCashBooking(req, res));

/**
 * @route   GET /api/bookings/validate
 * @desc    Kiểm tra validation trước khi đặt phòng
 * @access  Private
 * @query   hotelId, checkInDate, checkOutDate, paymentMethod, paymentAmount, totalPrice
 */
router.get('/validate', (req, res) => bookingController.validateBooking(req, res));

/**
 * @route   GET /api/bookings/check-active
 * @desc    Kiểm tra xem user có booking active ở khách sạn khác không (để ẩn nút đặt phòng)
 * @access  Private
 * @query   hotelId (optional)
 */
router.get('/check-active', (req, res) => bookingController.checkActiveBooking(req, res));

/**
 * @route   GET /api/bookings
 * @desc    Lấy danh sách bookings của user
 * @access  Private
 * @query   status, limit, offset
 */
router.get('/', (req, res) => bookingController.getMyBookings(req, res));

/**
 * @route   GET /api/bookings/stats
 * @desc    Lấy thống kê bookings
 * @access  Private
 */
router.get('/stats', (req, res) => bookingController.getBookingStats(req, res));

/**
 * @route   GET /api/bookings/:id
 * @desc    Lấy chi tiết booking
 * @access  Private
 */
router.get('/:id', (req, res) => bookingController.getBookingDetail(req, res));

/**
 * @route   POST /api/bookings/:id/cancel
 * @desc    Hủy booking (chỉ trong 5 phút)
 * @access  Private
 */
router.post('/:id/cancel', (req, res) => bookingController.cancelBooking(req, res));

/**
 * @route   POST /api/bookings/system/update-status
 * @desc    Trigger manual booking status update (TEST/DEBUG)
 * @access  Private
 */
router.post('/system/update-status', async (req, res) => {
  try {
    const { runAllBookingUpdates } = require('../services/bookingStatusScheduler');
    await runAllBookingUpdates();
    
    res.json({
      success: true,
      message: 'Đã chạy cập nhật trạng thái booking thành công',
      note: 'Booking status scheduler đã được trigger thủ công'
    });
  } catch (error) {
    console.error('❌ Error triggering booking status update:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi cập nhật trạng thái booking',
      error: error.message
    });
  }
});

module.exports = router;

