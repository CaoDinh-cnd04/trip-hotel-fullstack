const express = require('express');
const router = express.Router();
const { body, param, query } = require('express-validator');
const magiamgiaController = require('../controllers/magiamgiaController_v2');
const { authenticateToken: authenticateUser, authorizeRoles: requireRole } = require('../middleware/auth');

// Validation middleware
const validateMaGiamGia = [
    body('ma_giam_gia').notEmpty().withMessage('Mã giảm giá không được để trống')
        .isLength({ min: 3, max: 20 }).withMessage('Mã giảm giá phải từ 3-20 ký tự'),
    body('ten_ma_giam_gia').notEmpty().withMessage('Tên mã giảm giá không được để trống')
        .isLength({ max: 200 }).withMessage('Tên mã giảm giá không được quá 200 ký tự'),
    body('mo_ta').optional().isLength({ max: 1000 }).withMessage('Mô tả không được quá 1000 ký tự'),
    body('loai_giam_gia').isIn(['percentage', 'fixed_amount']).withMessage('Loại giảm giá không hợp lệ'),
    body('gia_tri_giam').isFloat({ min: 0 }).withMessage('Giá trị giảm phải lớn hơn 0'),
    body('gia_tri_don_hang_toi_thieu').optional().isFloat({ min: 0 }).withMessage('Giá trị đơn hàng tối thiểu không hợp lệ'),
    body('gia_tri_giam_toi_da').optional().isFloat({ min: 0 }).withMessage('Giá trị giảm tối đa không hợp lệ'),
    body('ngay_bat_dau').isDate().withMessage('Ngày bắt đầu không hợp lệ'),
    body('ngay_ket_thuc').isDate().withMessage('Ngày kết thúc không hợp lệ'),
    body('so_luong_gioi_han').optional().isInt({ min: 1 }).withMessage('Số lượng giới hạn phải lớn hơn 0'),
    body('gioi_han_su_dung_moi_nguoi').optional().isInt({ min: 1 }).withMessage('Giới hạn sử dụng mỗi người phải lớn hơn 0')
];

const validateId = [
    param('id').notEmpty().withMessage('ID không được để trống')
        .isLength({ min: 1, max: 50 }).withMessage('ID không hợp lệ')
];

const validateVoucherCode = [
    param('code').isLength({ min: 3, max: 20 }).withMessage('Mã giảm giá không hợp lệ')
];

const validateVoucherValidation = [
    body('ma_giam_gia').notEmpty().withMessage('Mã giảm giá không được để trống'),
    body('gia_tri_don_hang').isFloat({ min: 0 }).withMessage('Giá trị đơn hàng không hợp lệ'),
    body('ma_nguoi_dung').optional().isInt({ min: 1 }).withMessage('Mã người dùng không hợp lệ')
];

// Routes
// GET /api/magiamgia - Lấy tất cả mã giảm giá
router.get('/', 
    magiamgiaController.getAllMaGiamGia
);

// GET /api/magiamgia/active - Lấy mã giảm giá đang hoạt động
router.get('/active', 
    magiamgiaController.getActiveMaGiamGia
);

// GET /api/magiamgia/my - Lấy mã giảm giá của người dùng
router.get('/my', 
    authenticateUser,
    magiamgiaController.getMyMaGiamGia
);

// POST /api/magiamgia/validate - Validate mã giảm giá
router.post('/validate', 
    validateVoucherValidation,
    magiamgiaController.validateVoucher
);

// GET /api/magiamgia/:code/details - Lấy chi tiết mã giảm giá theo code
router.get('/:code/details', 
    validateVoucherCode,
    magiamgiaController.getMaGiamGiaByCode
);

// GET /api/magiamgia/:id - Lấy mã giảm giá theo ID
router.get('/:id', 
    validateId,
    magiamgiaController.getMaGiamGiaById
);

// POST /api/magiamgia - Tạo mã giảm giá mới (Admin only)
router.post('/', 
    authenticateUser,
    requireRole('Admin'),
    validateMaGiamGia,
    magiamgiaController.createMaGiamGia
);

// PUT /api/magiamgia/:id - Cập nhật mã giảm giá (Admin only)
router.put('/:id', 
    authenticateUser,
    requireRole('Admin'),
    validateId,
    validateMaGiamGia,
    magiamgiaController.updateMaGiamGia
);

// DELETE /api/magiamgia/:id - Xóa mã giảm giá (Admin only)
router.delete('/:id', 
    authenticateUser,
    requireRole('Admin'),
    validateId,
    magiamgiaController.deleteMaGiamGia
);

// PUT /api/magiamgia/:id/toggle - Bật/tắt mã giảm giá (Admin only)
router.put('/:id/toggle', 
    authenticateUser,
    requireRole('Admin'),
    validateId,
    magiamgiaController.toggleMaGiamGia
);

// POST /api/magiamgia/:id/use - Sử dụng mã giảm giá
router.post('/:id/use', 
    authenticateUser,
    validateId,
    magiamgiaController.useMaGiamGia
);

module.exports = router;
