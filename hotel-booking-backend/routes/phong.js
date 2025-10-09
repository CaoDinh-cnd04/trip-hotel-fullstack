const express = require('express');
const router = express.Router();
const { body, param, query } = require('express-validator');
const phongController = require('../controllers/phongController');
const authMiddleware = require('../middleware/auth');

// Validation rules
const validatePhong = [
    body('so_phong')
        .notEmpty()
        .withMessage('Số phòng không được để trống')
        .isLength({ min: 1, max: 20 })
        .withMessage('Số phòng phải từ 1-20 ký tự'),
    body('ma_khach_san')
        .isInt({ min: 1 })
        .withMessage('Mã khách sạn phải là số nguyên dương'),
    body('ma_loai_phong')
        .isInt({ min: 1 })
        .withMessage('Mã loại phòng phải là số nguyên dương'),
    body('tang')
        .optional()
        .isInt({ min: 1 })
        .withMessage('Tầng phải là số nguyên dương'),
    body('hinh_anh')
        .optional()
        .isLength({ max: 255 })
        .withMessage('Đường dẫn hình ảnh không được quá 255 ký tự'),
    body('ghi_chu')
        .optional()
        .isLength({ max: 500 })
        .withMessage('Ghi chú không được quá 500 ký tự'),
    body('trang_thai')
        .optional()
        .isInt({ min: 0, max: 1 })
        .withMessage('Trạng thái phải là 0 hoặc 1')
];

const validateId = [
    param('id')
        .isInt({ min: 1 })
        .withMessage('ID phải là số nguyên dương')
];

const validateAvailability = [
    query('ngay_checkin')
        .isISO8601()
        .withMessage('Ngày checkin phải là định dạng ngày hợp lệ'),
    query('ngay_checkout')
        .isISO8601()
        .withMessage('Ngày checkout phải là định dạng ngày hợp lệ'),
    query('ma_khach_san')
        .isInt({ min: 1 })
        .withMessage('Mã khách sạn phải là số nguyên dương')
];

// Routes
// GET /api/phong - Lấy danh sách phòng
router.get('/', phongController.getAllPhong);

// GET /api/phong/available - Lấy phòng trống
router.get('/available', validateAvailability, phongController.getAvailableRooms);

// GET /api/phong/:id/availability - Kiểm tra phòng có sẵn
router.get('/:id/availability', [
    ...validateId,
    query('ngay_checkin')
        .isISO8601()
        .withMessage('Ngày checkin phải là định dạng ngày hợp lệ'),
    query('ngay_checkout')
        .isISO8601()
        .withMessage('Ngày checkout phải là định dạng ngày hợp lệ')
], phongController.checkRoomAvailability);

// GET /api/phong/:id/schedule - Lấy lịch đặt phòng
router.get('/:id/schedule', [
    ...validateId,
    query('tu_ngay')
        .isISO8601()
        .withMessage('Từ ngày phải là định dạng ngày hợp lệ'),
    query('den_ngay')
        .isISO8601()
        .withMessage('Đến ngày phải là định dạng ngày hợp lệ')
], phongController.getRoomSchedule);

// GET /api/phong/:id - Lấy phòng theo ID
router.get('/:id', validateId, phongController.getPhongById);

// POST /api/phong - Tạo phòng mới (Admin & Hotel Manager only)
router.post('/', authMiddleware.verifyAdmin, validatePhong, phongController.createPhong);

// PUT /api/phong/:id - Cập nhật phòng (Admin & Hotel Manager only)
router.put('/:id', authMiddleware.verifyAdmin, [...validateId, ...validatePhong], phongController.updatePhong);

// DELETE /api/phong/:id - Xóa phòng (Admin & Hotel Manager only)
router.delete('/:id', authMiddleware.verifyAdmin, validateId, phongController.deletePhong);

module.exports = router;