const express = require('express');
const router = express.Router();
const discountController = require('../controllers/discountController');
const { authenticateToken } = require('../middleware/auth');

/**
 * @route POST /api/v2/discount/validate
 * @desc Validate mã giảm giá (cần đăng nhập để kiểm tra mỗi người chỉ dùng 1 lần)
 * @access Private - Yêu cầu đăng nhập
 */
router.post('/validate', authenticateToken, discountController.validateDiscountCode);

/**
 * @route GET /api/v2/discount/available
 * @desc Lấy danh sách mã giảm giá có sẵn
 * @access Public
 */
router.get('/available', discountController.getAvailableDiscounts);

module.exports = router;

