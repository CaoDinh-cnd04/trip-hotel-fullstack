const express = require('express');
const router = express.Router();
const { body, param, query } = require('express-validator');
const hosoController = require('../controllers/hosoController_v2');
const { authenticateToken: authenticateUser, authorizeRoles: requireRole } = require('../middleware/auth');

// Validation middleware
const validateHoSo = [
    body('ho_ten').optional().isLength({ min: 2, max: 100 }).withMessage('Họ tên phải từ 2-100 ký tự'),
    body('ngay_sinh').optional().isDate().withMessage('Ngày sinh không hợp lệ'),
    body('gioi_tinh').optional().isIn(['Nam', 'Nữ', 'Khác']).withMessage('Giới tính không hợp lệ'),
    body('cmnd_cccd').optional().isLength({ min: 9, max: 12 }).withMessage('CMND/CCCD phải từ 9-12 ký tự'),
    body('dia_chi').optional().isLength({ max: 200 }).withMessage('Địa chỉ không được quá 200 ký tự'),
    body('so_dien_thoai').optional().matches(/^[0-9+\-\s()]{10,15}$/).withMessage('Số điện thoại không hợp lệ'),
    body('quoc_tich').optional().isLength({ max: 50 }).withMessage('Quốc tịch không được quá 50 ký tự'),
    body('nghe_nghiep').optional().isLength({ max: 100 }).withMessage('Nghề nghiệp không được quá 100 ký tự')
];

const validateId = [
    param('id').isInt({ min: 1 }).withMessage('ID không hợp lệ')
];

// Routes
// GET /api/hoso - Lấy tất cả hồ sơ (Admin only)
router.get('/', 
    authenticateUser, 
    requireRole('Admin'), 
    hosoController.getAllHoSo
);

// GET /api/hoso/stats - Lấy thống kê hồ sơ (Admin only)
router.get('/stats', 
    authenticateUser, 
    requireRole('Admin'), 
    hosoController.getHoSoStats
);

// GET /api/hoso/search - Tìm kiếm hồ sơ (Admin only)
router.get('/search', 
    authenticateUser, 
    requireRole('Admin'), 
    hosoController.searchHoSo
);

// GET /api/hoso/my - Lấy hồ sơ của người dùng hiện tại
router.get('/my', 
    authenticateUser, 
    hosoController.getMyHoSo
);

// PUT /api/hoso/my - Cập nhật hồ sơ của người dùng hiện tại
router.put('/my', 
    authenticateUser,
    validateHoSo,
    hosoController.updateMyHoSo
);

// GET /api/hoso/:id - Lấy hồ sơ theo ID
router.get('/:id', 
    authenticateUser,
    validateId,
    hosoController.getHoSoById
);

// POST /api/hoso - Tạo hồ sơ mới
router.post('/', 
    authenticateUser,
    validateHoSo,
    hosoController.createHoSo
);

// PUT /api/hoso/:id - Cập nhật hồ sơ (Admin only)
router.put('/:id', 
    authenticateUser,
    requireRole('Admin'),
    validateId,
    validateHoSo,
    hosoController.updateHoSo
);

// DELETE /api/hoso/:id - Xóa hồ sơ (Admin only)
router.delete('/:id', 
    authenticateUser,
    requireRole('Admin'),
    validateId,
    hosoController.deleteHoSo
);

module.exports = router;
