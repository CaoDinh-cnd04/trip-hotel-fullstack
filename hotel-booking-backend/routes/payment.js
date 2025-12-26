/**
 * Payment Routes (Common for all payment methods)
 */

const express = require('express');
const router = express.Router();
const vnpayController = require('../controllers/vnpayController');

/**
 * @route   GET /api/v2/payment/booking-info/:orderId
 * @desc    Lấy thông tin booking sau khi thanh toán thành công (dùng chung cho tất cả payment methods)
 * @access  Public
 */
router.get('/booking-info/:orderId', vnpayController.getBookingInfoByOrderId);

module.exports = router;

