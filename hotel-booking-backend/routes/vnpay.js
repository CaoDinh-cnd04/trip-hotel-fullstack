/**
 * VNPay Routes
 */

const express = require('express');
const router = express.Router();
const vnpayController = require('../controllers/vnpayController');

/**
 * @route   POST /api/v2/vnpay/create-payment
 * @desc    Tạo URL thanh toán VNPay
 * @access  Public
 */
router.post('/create-payment', vnpayController.createPayment);

/**
 * @route   GET /api/v2/vnpay/config
 * @desc    Lấy cấu hình VNPay (Return URL, IPN URL)
 * @access  Public
 */
router.get('/config', vnpayController.getConfig);

/**
 * @route   GET /api/v2/vnpay/payment-status/:orderId
 * @desc    Lấy trạng thái thanh toán theo order ID
 * @access  Public
 */
router.get('/payment-status/:orderId', vnpayController.getPaymentStatus);

/**
 * @route   POST /api/v2/vnpay/query-transaction
 * @desc    Query trạng thái giao dịch
 * @access  Public
 */
router.post('/query-transaction', vnpayController.queryTransaction);

module.exports = router;

