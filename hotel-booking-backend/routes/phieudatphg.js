const express = require('express');
const router = express.Router();
const { body, param, query } = require('express-validator');
const phieudatphgController = require('../controllers/phieudatphgController');
const authMiddleware = require('../middleware/auth');

// Validation rules
const validateBooking = [
    body('ma_phong')
        .isInt({ min: 1 })
        .withMessage('Mã phòng phải là số nguyên dương'),
    body('ngay_checkin')
        .isISO8601()
        .withMessage('Ngày checkin phải là định dạng ngày hợp lệ'),
    body('ngay_checkout')
        .isISO8601()
        .withMessage('Ngày checkout phải là định dạng ngày hợp lệ'),
    body('so_khach')
        .isInt({ min: 1 })
        .withMessage('Số khách phải là số nguyên dương'),
    body('tong_tien')
        .isFloat({ min: 0 })
        .withMessage('Tổng tiền phải là số dương'),
    body('ghi_chu')
        .optional()
        .isLength({ max: 500 })
        .withMessage('Ghi chú không được quá 500 ký tự')
];

const validateId = [
    param('id')
        .notEmpty()
        .withMessage('ID phiếu đặt phòng không được để trống')
];

const validateStatus = [
    body('trang_thai')
        .isIn(['pending', 'confirmed', 'checked_in', 'checked_out', 'cancelled'])
        .withMessage('Trạng thái không hợp lệ'),
    body('ghi_chu')
        .optional()
        .isLength({ max: 500 })
        .withMessage('Ghi chú không được quá 500 ký tự')
];

// Routes
// GET /api/phieudatphg/my - Lấy đặt phòng của user hiện tại (đặt trước /:id)
router.get('/my', authMiddleware.verifyToken, phieudatphgController.getMyBookings);

// GET /api/phieudatphg/stats - Lấy thống kê đặt phòng (Admin only)
router.get('/stats', authMiddleware.verifyAdmin, [
    query('tu_ngay')
        .isISO8601()
        .withMessage('Từ ngày phải là định dạng ngày hợp lệ'),
    query('den_ngay')
        .isISO8601()
        .withMessage('Đến ngày phải là định dạng ngày hợp lệ')
], phieudatphgController.getBookingStats);

// GET /api/phieudatphg - Lấy tất cả phiếu đặt phòng (Admin only)
router.get('/', authMiddleware.verifyAdmin, phieudatphgController.getAllPhieuDatPhg);

// GET /api/phieudatphg/:id - Lấy phiếu đặt phòng theo ID
router.get('/:id', authMiddleware.verifyToken, validateId, phieudatphgController.getPhieuDatPhgById);

// POST /api/phieudatphg - Tạo phiếu đặt phòng mới
router.post('/', authMiddleware.verifyToken, validateBooking, phieudatphgController.createPhieuDatPhg);

// PUT /api/phieudatphg/:id/status - Cập nhật trạng thái phiếu đặt phòng
router.put('/:id/status', authMiddleware.verifyToken, [...validateId, ...validateStatus], phieudatphgController.updateBookingStatus);

// PUT /api/phieudatphg/:id/cancel - Hủy phiếu đặt phòng
router.put('/:id/cancel', authMiddleware.verifyToken, [
    ...validateId,
    body('ly_do_huy')
        .optional()
        .isLength({ max: 500 })
        .withMessage('Lý do hủy không được quá 500 ký tự')
], phieudatphgController.cancelBooking);

// PUT /api/phieudatphg/:id - Cập nhật phiếu đặt phòng
router.put('/:id', authMiddleware.verifyToken, [...validateId, ...validateBooking], phieudatphgController.updatePhieuDatPhg);

module.exports = router;