const express = require('express');
const router = express.Router();
const roomStatusController = require('../controllers/roomStatusController');
const { verifyToken } = require('../middleware/auth');

// Auto-update room status (can be called by cron job or manually)
router.post('/auto-update', roomStatusController.autoUpdateRoomStatus);

// Get rooms availability statistics
router.get('/availability', roomStatusController.getRoomAvailability);

module.exports = router;

