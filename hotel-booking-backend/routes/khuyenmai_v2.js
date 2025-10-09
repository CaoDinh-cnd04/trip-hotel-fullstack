const express = require('express');
const router = express.Router();
const { body, param, query } = require('express-validator');
const khuyenmaiController = require('../controllers/khuyenmaiController_v2');
const { authenticateToken: authenticateUser, authorizeRoles: requireRole } = require('../middleware/auth');

// Validation middleware
const validateKhuyenMai = [
    body('ten_khuyen_mai').notEmpty().withMessage('Tên khuyến mãi không được để trống')
        .isLength({ max: 200 }).withMessage('Tên khuyến mãi không được quá 200 ký tự'),
    body('mo_ta').optional().isLength({ max: 1000 }).withMessage('Mô tả không được quá 1000 ký tự'),
    body('loai_khuyen_mai').isIn(['percentage', 'fixed_amount', 'free_night']).withMessage('Loại khuyến mãi không hợp lệ'),
    body('gia_tri_giam').isFloat({ min: 0 }).withMessage('Giá trị giảm phải lớn hơn 0'),
    body('gia_tri_don_hang_toi_thieu').optional().isFloat({ min: 0 }).withMessage('Giá trị đơn hàng tối thiểu không hợp lệ'),
    body('ngay_bat_dau').isDate().withMessage('Ngày bắt đầu không hợp lệ'),
    body('ngay_ket_thuc').isDate().withMessage('Ngày kết thúc không hợp lệ'),
    body('so_luong_gioi_han').optional().isInt({ min: 1 }).withMessage('Số lượng giới hạn phải lớn hơn 0'),
    body('ma_khach_san').optional().isInt({ min: 1 }).withMessage('Mã khách sạn không hợp lệ')
];

const validateId = [
    param('id').isInt({ min: 1 }).withMessage('ID không hợp lệ')
];

const validatePromotionCode = [
    param('code').isLength({ min: 1, max: 50 }).withMessage('Mã khuyến mãi không hợp lệ')
];

// Routes
// GET /api/khuyenmai - Lấy tất cả khuyến mãi
router.get('/', 
    khuyenmaiController.getAllKhuyenMai
);

// GET /api/khuyenmai/active - Lấy khuyến mãi đang hoạt động
router.get('/active', 
    khuyenmaiController.getActivePromotions
);

// GET /api/khuyenmai/validate/:code - Validate mã khuyến mãi
router.get('/validate/:code', 
    validatePromotionCode,
    khuyenmaiController.validatePromotion
);

// GET /api/khuyenmai/:id - Lấy khuyến mãi theo ID
router.get('/:id', 
    validateId,
    khuyenmaiController.getKhuyenMaiById
);

// POST /api/khuyenmai - Tạo khuyến mãi mới (Admin only)
router.post('/', 
    authenticateUser,
    requireRole('Admin'),
    validateKhuyenMai,
    khuyenmaiController.createKhuyenMai
);

// PUT /api/khuyenmai/:id - Cập nhật khuyến mãi (Admin only)
router.put('/:id', 
    authenticateUser,
    requireRole('Admin'),
    validateId,
    validateKhuyenMai,
    khuyenmaiController.updateKhuyenMai
);

// DELETE /api/khuyenmai/:id - Xóa khuyến mãi (Admin only)
router.delete('/:id', 
    authenticateUser,
    requireRole('Admin'),
    validateId,
    khuyenmaiController.deleteKhuyenMai
);

// PUT /api/khuyenmai/:id/toggle - Bật/tắt khuyến mãi (Admin only)
// router.put('/:id/toggle', 
//     authenticateUser,
//     requireRole('Admin'),
//     validateId,
//     khuyenmaiController.toggleKhuyenMai
// );

module.exports = router;
