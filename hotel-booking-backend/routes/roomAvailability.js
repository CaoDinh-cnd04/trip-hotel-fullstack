const express = require('express');
const router = express.Router();
const roomAvailabilityController = require('../controllers/roomAvailabilityController');

// GET /api/hotels/:hotel_id/room-availability
// Get all rooms with real-time availability status
router.get('/:hotel_id/room-availability', roomAvailabilityController.getRoomAvailability);

// GET /api/hotels/:hotel_id/availability-summary
// Get summary of available/occupied rooms
router.get('/:hotel_id/availability-summary', roomAvailabilityController.getHotelAvailabilitySummary);

module.exports = router;

