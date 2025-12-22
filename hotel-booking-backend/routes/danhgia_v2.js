const express = require('express');
const router = express.Router();
const { body, param, query } = require('express-validator');
const danhgiaController = require('../controllers/danhgiaController_v2');
const { authenticateToken: authenticateUser, authorizeRoles: requireRole } = require('../middleware/auth');

// Validation middleware
const validateDanhGia = [
    body('ma_khach_san').notEmpty().withMessage('Mã khách sạn không được để trống'),
    body('diem_danh_gia').isInt({ min: 1, max: 5 }).withMessage('Điểm đánh giá phải từ 1 đến 5'),
    body('binh_luan').optional().isLength({ max: 1000 }).withMessage('Bình luận không được quá 1000 ký tự'),
    body('uu_diem').optional().isLength({ max: 500 }).withMessage('Ưu điểm không được quá 500 ký tự'),
    body('nhuoc_diem').optional().isLength({ max: 500 }).withMessage('Nhược điểm không được quá 500 ký tự')
];

const validateId = [
    param('id').isInt({ min: 1 }).withMessage('ID không hợp lệ')
];

const validateKhachSanId = [
    param('ma_khach_san').isInt({ min: 1 }).withMessage('Mã khách sạn không hợp lệ')
];

// Routes
// GET /api/danhgia - Lấy tất cả đánh giá (Admin only)
router.get('/', 
    authenticateUser, 
    requireRole('Admin'), 
    danhgiaController.getAllDanhGia
);

// GET /api/danhgia/my - Lấy đánh giá của người dùng hiện tại
router.get('/my', 
    authenticateUser, 
    danhgiaController.getMyDanhGia
);

// GET /api/danhgia/khachsan/:ma_khach_san - Lấy đánh giá theo khách sạn
router.get('/khachsan/:ma_khach_san', 
    validateKhachSanId,
    danhgiaController.getDanhGiaByKhachSan
);

// GET /api/danhgia/:id - Lấy đánh giá theo ID
router.get('/:id', 
    validateId,
    danhgiaController.getDanhGiaById
);

// POST /api/danhgia - Tạo đánh giá mới
router.post('/', 
    authenticateUser,
    validateDanhGia,
    danhgiaController.createDanhGia
);

// PUT /api/danhgia/:id - Cập nhật đánh giá
router.put('/:id', 
    authenticateUser,
    validateId,
    validateDanhGia,
    danhgiaController.updateDanhGia
);

// PUT /api/danhgia/:id/status - Cập nhật trạng thái đánh giá (Admin only - for moderation)
router.put('/:id/status', 
    authenticateUser,
    requireRole('Admin'),
    validateId,
    [
        body('trang_thai').isIn(['Đã duyệt', 'Chờ duyệt', 'Từ chối']).withMessage('Trạng thái không hợp lệ')
    ],
    danhgiaController.updateReviewStatus
);

// DELETE /api/danhgia/:id - Xóa đánh giá (Admin only)
router.delete('/:id', 
    authenticateUser,
    requireRole('Admin'),
    validateId,
    danhgiaController.deleteDanhGia
);

module.exports = router;
