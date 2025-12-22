// routes/notifications.js - Notification routes
const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const auth = require('../middleware/auth');

// Optional auth middleware - allows requests without token
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
      req.user = null;
      return next();
    }

    const jwt = require('jsonwebtoken');
    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const NguoiDung = require('../models/nguoidung');
      const userId = decoded.id || decoded.ma_nguoi_dung;
      const nguoiDung = new NguoiDung();
      const user = await nguoiDung.findById(userId);
      
      if (user && user.trang_thai) {
        req.user = {
          id: user.id || user.ma_nguoi_dung,
          email: user.email,
          vai_tro: user.vai_tro,
          chuc_vu: user.chuc_vu,
          ho_ten: user.ho_ten
        };
      } else {
        req.user = null;
      }
    } catch (err) {
      req.user = null;
    }
    next();
  } catch (error) {
    req.user = null;
    next();
  }
};

// Public routes (no authentication required) - FOR GUEST USERS
router.get('/public', notificationController.getPublicNotifications);

// User routes - now with OPTIONAL auth (auto fallback to public if no token)
router.get('/', optionalAuth, notificationController.getNotifications);
router.get('/unread-count', optionalAuth, (req, res) => {
  // If no user, return 0
  if (!req.user) {
    return res.json({ success: true, data: { unread_count: 0 } });
  }
  // Otherwise, get unread count
  notificationController.getUnreadCount(req, res);
});
router.post('/:id/read', optionalAuth, (req, res) => {
  // Only authenticated users can mark as read
  if (!req.user) {
    return res.json({ success: true, message: 'Guest users cannot mark notifications as read' });
  }
  notificationController.markAsRead(req, res);
});

// Admin routes (require admin role)
router.post('/', auth.verifyAdmin, notificationController.createNotification);
router.get('/all', auth.verifyAdmin, notificationController.getAllNotifications);
router.put('/:id', auth.verifyAdmin, notificationController.updateNotification);
router.delete('/:id', auth.verifyAdmin, notificationController.deleteNotification);

module.exports = router;

