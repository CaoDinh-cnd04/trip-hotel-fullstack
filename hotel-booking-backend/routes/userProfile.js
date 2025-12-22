const express = require('express');
const router = express.Router();
const userProfileController = require('../controllers/userProfileController');
const { verifyToken } = require('../middleware/auth');

// Tất cả routes đều cần authentication
router.use(verifyToken);

// Lấy thông tin VIP status
router.get('/vip-status', userProfileController.getVipStatus);

// Tích điểm thủ công cho các booking đã thanh toán
router.post('/vip-status/add-points-for-bookings', userProfileController.addPointsForPaidBookings);

// Cập nhật thông tin user
router.put('/profile', userProfileController.updateProfile);

// Xóa tài khoản
router.delete('/account', userProfileController.deleteAccount);

// Lấy cài đặt user
router.get('/settings', userProfileController.getUserSettings);

// Cập nhật cài đặt user
router.put('/settings', userProfileController.updateUserSettings);

module.exports = router;
