/**
 * MoMo Routes
 */

const express = require('express');
const router = express.Router();
const momoController = require('../controllers/momoController');
const { verifyToken } = require('../middleware/auth');

/**
 * @route   POST /api/payment/momo/create-payment-url
 * @desc    Tạo URL thanh toán MoMo (giống VNPay)
 * @access  Public (no authentication required for payment)
 */
router.post('/create-payment-url', momoController.createPaymentUrl);

/**
 * @route   POST /api/payment/momo/create-payment
 * @desc    Tạo payment request đến MoMo (legacy)
 * @access  Public (no authentication required for payment)
 */
router.post('/create-payment', momoController.createPayment);

/**
 * @route   GET /api/payment/momo-return
 * @desc    Return URL từ MoMo sau khi thanh toán
 * @access  Public (MoMo callback)
 */
router.get('/momo-return', momoController.momoReturn);

/**
 * @route   POST /api/payment/momo-ipn
 * @desc    IPN (Instant Payment Notification) từ MoMo
 * @access  Public (MoMo webhook)
 */
router.post('/momo-ipn', momoController.momoIPN);

/**
 * @route   POST /api/payment/momo/query-transaction
 * @desc    Query trạng thái giao dịch
 * @access  Private
 */
router.post('/query-transaction', verifyToken, momoController.queryTransaction);

module.exports = router;

