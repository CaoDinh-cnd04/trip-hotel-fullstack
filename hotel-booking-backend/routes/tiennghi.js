const express = require('express');
const router = express.Router();
const { body, param, query } = require('express-validator');
const tiennghiController = require('../controllers/tiennghiController');
const authMiddleware = require('../middleware/auth');

// Validation rules
const validateTienNghi = [
    body('ten_tien_nghi')
        .notEmpty()
        .withMessage('Tên tiện nghi không được để trống')
        .isLength({ min: 1, max: 100 })
        .withMessage('Tên tiện nghi phải từ 1-100 ký tự'),
    body('mo_ta')
        .optional()
        .isLength({ max: 500 })
        .withMessage('Mô tả không được quá 500 ký tự'),
    body('loai_tien_nghi')
        .optional()
        .isIn(['khach_san', 'phong'])
        .withMessage('Loại tiện nghi phải là "khach_san" hoặc "phong"'),
    body('icon')
        .optional()
        .isLength({ max: 100 })
        .withMessage('Icon không được quá 100 ký tự'),
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

// Routes
// GET /api/tiennghi - Lấy danh sách tiện nghi
router.get('/', tiennghiController.getAllTienNghi);

// GET /api/tiennghi/search - Tìm kiếm tiện nghi
router.get('/search', [
    query('keyword')
        .notEmpty()
        .withMessage('Từ khóa tìm kiếm không được để trống')
        .isLength({ min: 1, max: 100 })
        .withMessage('Từ khóa phải từ 1-100 ký tự')
], tiennghiController.searchTienNghi);

// GET /api/tiennghi/khachsan/:ma_khach_san - Lấy tiện nghi của khách sạn
router.get('/khachsan/:ma_khach_san', [
    param('ma_khach_san')
        .isInt({ min: 1 })
        .withMessage('Mã khách sạn phải là số nguyên dương')
], tiennghiController.getTienNghiByKhachSan);

// GET /api/tiennghi/:id - Lấy tiện nghi theo ID
router.get('/:id', validateId, tiennghiController.getTienNghiById);

// POST /api/tiennghi - Tạo tiện nghi mới (Admin only)
router.post('/', authMiddleware.verifyAdmin, validateTienNghi, tiennghiController.createTienNghi);

// PUT /api/tiennghi/:id - Cập nhật tiện nghi (Admin only)
router.put('/:id', authMiddleware.verifyAdmin, [...validateId, ...validateTienNghi], tiennghiController.updateTienNghi);

// DELETE /api/tiennghi/:id - Xóa tiện nghi (Admin only)
router.delete('/:id', authMiddleware.verifyAdmin, validateId, tiennghiController.deleteTienNghi);

module.exports = router;