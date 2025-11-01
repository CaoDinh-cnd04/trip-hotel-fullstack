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
router.post('/', bookingController.createBooking);

/**
 * @route   POST /api/bookings/cash
 * @desc    Tạo booking thanh toán tiền mặt
 * @access  Private
 */
router.post('/cash', bookingController.createCashBooking);

/**
 * @route   GET /api/bookings
 * @desc    Lấy danh sách bookings của user
 * @access  Private
 * @query   status, limit, offset
 */
router.get('/', bookingController.getMyBookings);

/**
 * @route   GET /api/bookings/stats
 * @desc    Lấy thống kê bookings
 * @access  Private
 */
router.get('/stats', bookingController.getBookingStats);

/**
 * @route   GET /api/bookings/:id
 * @desc    Lấy chi tiết booking
 * @access  Private
 */
router.get('/:id', bookingController.getBookingDetail);

/**
 * @route   POST /api/bookings/:id/cancel
 * @desc    Hủy booking (chỉ trong 5 phút)
 * @access  Private
 */
router.post('/:id/cancel', bookingController.cancelBooking);

module.exports = router;

