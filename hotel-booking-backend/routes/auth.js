const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { authenticateToken, adminOnly } = require('../middleware/auth');

// Đăng ký
router.post('/register', authController.register);

// Đăng nhập
router.post('/login', authController.login);

// Facebook Login
router.post('/facebook-login', authController.facebookLogin);

// Firebase Social Login (Google/Facebook) - Đồng bộ từ Firebase
router.post('/firebase-social-login', authController.firebaseSocialLogin);

// Social Login (Google/Facebook) - Legacy (DEPRECATED - use firebase-social-login instead)
// router.post('/social-login', authController.socialLogin);

// Verify token
router.get('/verify', authenticateToken, authController.verify);

module.exports = router;