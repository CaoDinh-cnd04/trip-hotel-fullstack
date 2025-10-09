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

// Social Login (Google/Facebook)
router.post('/social-login', authController.socialLogin);

// Verify token
router.get('/verify', authenticateToken, authController.verify);

module.exports = router;