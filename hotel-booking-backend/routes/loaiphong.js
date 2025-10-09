const express = require('express');
const router = express.Router();
const { body, param, query } = require('express-validator');
const loaiphongController = require('../controllers/loaiphongController');
const authMiddleware = require('../middleware/auth');

// Validation rules
const validateLoaiPhong = [
    body('ten_loai_phong')
        .notEmpty()
        .withMessage('Tên loại phòng không được để trống')
        .isLength({ min: 1, max: 100 })
        .withMessage('Tên loại phòng phải từ 1-100 ký tự'),
    body('ma_khach_san')
        .isInt({ min: 1 })
        .withMessage('Mã khách sạn phải là số nguyên dương'),
    body('gia_co_ban')
        .isFloat({ min: 0 })
        .withMessage('Giá cơ bản phải là số dương'),
    body('so_khach_toi_da')
        .optional()
        .isInt({ min: 1 })
        .withMessage('Số khách tối đa phải là số nguyên dương'),
    body('dien_tich')
        .optional()
        .isFloat({ min: 0 })
        .withMessage('Diện tích phải là số dương'),
    body('mo_ta')
        .optional()
        .isLength({ max: 500 })
        .withMessage('Mô tả không được quá 500 ký tự'),
    body('hinh_anh')
        .optional()
        .isLength({ max: 255 })
        .withMessage('Đường dẫn hình ảnh không được quá 255 ký tự'),
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
// GET /api/loaiphong - Lấy danh sách loại phòng
router.get('/', loaiphongController.getAllLoaiPhong);

// GET /api/loaiphong/khachsan/:ma_khach_san - Lấy loại phòng của khách sạn
router.get('/khachsan/:ma_khach_san', [
    param('ma_khach_san')
        .isInt({ min: 1 })
        .withMessage('Mã khách sạn phải là số nguyên dương')
], loaiphongController.getLoaiPhongByKhachSan);

// GET /api/loaiphong/:id - Lấy loại phòng theo ID
router.get('/:id', validateId, loaiphongController.getLoaiPhongById);

// POST /api/loaiphong - Tạo loại phòng mới (Admin only)
router.post('/', authMiddleware.verifyAdmin, validateLoaiPhong, loaiphongController.createLoaiPhong);

// PUT /api/loaiphong/:id - Cập nhật loại phòng (Admin only)
router.put('/:id', authMiddleware.verifyAdmin, [...validateId, ...validateLoaiPhong], loaiphongController.updateLoaiPhong);

// DELETE /api/loaiphong/:id - Xóa loại phòng (Admin only)
router.delete('/:id', authMiddleware.verifyAdmin, validateId, loaiphongController.deleteLoaiPhong);

module.exports = router;