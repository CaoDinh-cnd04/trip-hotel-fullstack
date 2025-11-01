/**
 * Admin Role Management Routes
 * Route quản lý phân quyền admin
 */

const express = require('express');
const router = express.Router();
const adminRoleController = require('../controllers/adminRoleController');
const { verifyToken, requireAdmin } = require('../middleware/auth');

// Tất cả các route này yêu cầu đăng nhập và là Admin
router.use(verifyToken);
router.use(requireAdmin);

// Lấy danh sách tất cả users
router.get('/users', adminRoleController.getAllUsers);

// Lấy chi tiết một user
router.get('/users/:userId', adminRoleController.getUserDetail);

// Cấp quyền Admin cho user
router.post('/users/:userId/grant-admin', adminRoleController.grantAdminRole);

// Thu hồi quyền Admin
router.post('/users/:userId/revoke-admin', adminRoleController.revokeAdminRole);

// Cập nhật role (Admin, HotelManager, User)
router.put('/users/:userId/role', adminRoleController.updateUserRole);

// Kích hoạt/Vô hiệu hóa tài khoản
router.post('/users/:userId/toggle-status', adminRoleController.toggleUserStatus);

module.exports = router;

