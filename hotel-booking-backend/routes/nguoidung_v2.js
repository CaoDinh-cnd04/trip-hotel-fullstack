const express = require('express');
const router = express.Router();
const { body, param, query } = require('express-validator');
const nguoidungController = require('../controllers/nguoidungController_v2');
const { authenticateToken: authenticateUser, authorizeRoles: requireRole } = require('../middleware/auth');
const upload = require('../middleware/upload');

// Validation middleware
const validateUserRegistration = [
    body('ho_ten').notEmpty().withMessage('Họ tên không được để trống')
        .isLength({ min: 2, max: 100 }).withMessage('Họ tên phải từ 2-100 ký tự'),
    body('email').isEmail().withMessage('Email không hợp lệ'),
    body('mat_khau').isLength({ min: 6 }).withMessage('Mật khẩu phải ít nhất 6 ký tự'),
    body('so_dien_thoai').optional().matches(/^[0-9+\-\s()]{10,15}$/).withMessage('Số điện thoại không hợp lệ'),
    body('vai_tro').optional().isIn(['Admin', 'Customer']).withMessage('Vai trò không hợp lệ')
];

const validateUserUpdate = [
    body('ho_ten').optional().isLength({ min: 2, max: 100 }).withMessage('Họ tên phải từ 2-100 ký tự'),
    body('email').optional().isEmail().withMessage('Email không hợp lệ'),
    body('mat_khau').optional().isLength({ min: 6 }).withMessage('Mật khẩu phải ít nhất 6 ký tự'),
    body('so_dien_thoai').optional().matches(/^[0-9+\-\s()]{10,15}$/).withMessage('Số điện thoại không hợp lệ'),
    body('vai_tro').optional().isIn(['Admin', 'Customer']).withMessage('Vai trò không hợp lệ')
];

const validatePasswordChange = [
    body('mat_khau_cu').notEmpty().withMessage('Mật khẩu cũ không được để trống'),
    body('mat_khau_moi').isLength({ min: 6 }).withMessage('Mật khẩu mới phải ít nhất 6 ký tự')
];

const validateId = [
    param('id').isInt({ min: 1 }).withMessage('ID không hợp lệ')
];

// Routes
// GET /api/nguoidung - Lấy tất cả người dùng (Admin only)
router.get('/', 
    authenticateUser, 
    requireRole('Admin'), 
    nguoidungController.getAllUsers
);

// GET /api/nguoidung/stats - Thống kê người dùng (Admin only)
router.get('/stats', 
    authenticateUser, 
    requireRole('Admin'), 
    nguoidungController.getUserStats
);

// GET /api/nguoidung/search - Tìm kiếm người dùng (Admin only)
router.get('/search', 
    authenticateUser, 
    requireRole('Admin'), 
    nguoidungController.searchUsers
);

// GET /api/nguoidung/profile - Lấy profile của người dùng hiện tại
router.get('/profile', 
    authenticateUser, 
    nguoidungController.getMyProfile
);

// PUT /api/nguoidung/profile - Cập nhật profile của người dùng hiện tại
router.put('/profile', 
    authenticateUser,
    upload.single('anh_dai_dien'),
    validateUserUpdate,
    nguoidungController.updateMyProfile
);

// PUT /api/nguoidung/change-password - Đổi mật khẩu
router.put('/change-password', 
    authenticateUser,
    validatePasswordChange,
    nguoidungController.changePassword
);

// GET /api/nguoidung/:id - Lấy người dùng theo ID
router.get('/:id', 
    authenticateUser,
    validateId,
    nguoidungController.getUserById
);

// POST /api/nguoidung/register - Đăng ký người dùng mới
router.post('/register', 
    upload.single('anh_dai_dien'),
    validateUserRegistration,
    nguoidungController.register
);

// PUT /api/nguoidung/:id - Cập nhật người dùng (Admin only)
router.put('/:id', 
    authenticateUser,
    requireRole('Admin'),
    upload.single('anh_dai_dien'),
    validateId,
    validateUserUpdate,
    nguoidungController.updateUser
);

// DELETE /api/nguoidung/:id - Xóa người dùng (Admin only)
router.delete('/:id', 
    authenticateUser,
    requireRole('Admin'),
    validateId,
    nguoidungController.deleteUser
);

module.exports = router;