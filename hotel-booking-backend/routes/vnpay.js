/**
 * VNPay Routes
 */

const express = require('express');
const router = express.Router();
const vnpayController = require('../controllers/vnpayController');
const { verifyToken } = require('../middleware/auth');

/**
 * @route   POST /api/payment/vnpay/create-payment-url
 * @desc    Tạo URL thanh toán VNPay
 * @access  Public (no authentication required for payment)
 */
router.post('/create-payment-url', vnpayController.createPaymentUrl);

/**
 * @route   GET /api/payment/vnpay-return
 * @desc    Callback URL từ VNPay sau khi thanh toán
 * @access  Public (VNPay callback)
 */
router.get('/vnpay-return', vnpayController.vnpayReturn);

/**
 * @route   POST /api/payment/vnpay/query-transaction
 * @desc    Query trạng thái giao dịch
 * @access  Private
 */
router.post('/query-transaction', verifyToken, vnpayController.queryTransaction);

/**
 * @route   GET /api/payment/vnpay/banks
 * @desc    Lấy danh sách ngân hàng hỗ trợ VNPay
 * @access  Public
 */
router.get('/banks', vnpayController.getBankList);

module.exports = router;
