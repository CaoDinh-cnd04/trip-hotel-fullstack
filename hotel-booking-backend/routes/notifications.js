// routes/notifications.js - Notification routes
const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const auth = require('../middleware/auth');

// User routes (require authentication)
router.get('/', auth.verifyToken, notificationController.getNotifications);
router.get('/unread-count', auth.verifyToken, notificationController.getUnreadCount);
router.post('/:id/read', auth.verifyToken, notificationController.markAsRead);

// Admin routes (require admin role)
router.post('/', auth.verifyAdmin, notificationController.createNotification);
router.get('/all', auth.verifyAdmin, notificationController.getAllNotifications);
router.put('/:id', auth.verifyAdmin, notificationController.updateNotification);
router.delete('/:id', auth.verifyAdmin, notificationController.deleteNotification);

module.exports = router;

