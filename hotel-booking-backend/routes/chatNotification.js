const express = require('express');
const router = express.Router();
const chatNotificationController = require('../controllers/chatNotificationController');
const { verifyToken } = require('../middleware/auth');

// Send email notification to hotel manager when user sends message
router.post('/notify-manager', verifyToken, chatNotificationController.notifyHotelManager);

// Send email notification to user when manager replies
router.post('/notify-user', verifyToken, chatNotificationController.notifyUser);

module.exports = router;

