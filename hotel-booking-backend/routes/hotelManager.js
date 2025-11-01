const express = require('express');
const router = express.Router();
const hotelManagerController = require('../controllers/hotelManagerController');
const { verifyHotelManager, verifyToken } = require('../middleware/auth');
const upload = require('../middleware/upload');

// Get hotel manager's assigned hotel
router.get('/hotel', verifyHotelManager, hotelManagerController.getAssignedHotel);

// Get hotel manager's hotel statistics
router.get('/hotel/stats', verifyHotelManager, hotelManagerController.getHotelStats);

// Update hotel information
router.put('/hotel', verifyHotelManager, hotelManagerController.updateHotel);

// Get hotel rooms
router.get('/hotel/rooms', verifyHotelManager, hotelManagerController.getHotelRooms);

// Add new room
router.post('/hotel/rooms', verifyHotelManager, hotelManagerController.addRoom);

// Update room
router.put('/hotel/rooms/:id', verifyHotelManager, hotelManagerController.updateRoom);

// Upload room images
router.post('/hotel/rooms/:id/images', verifyHotelManager, upload.array('images', 5), hotelManagerController.uploadRoomImages);

// Delete room
router.delete('/hotel/rooms/:id', verifyHotelManager, hotelManagerController.deleteRoom);

// Get hotel bookings
router.get('/hotel/bookings', verifyHotelManager, hotelManagerController.getHotelBookings);

// Update booking status
router.put('/hotel/bookings/:id', verifyHotelManager, hotelManagerController.updateBookingStatus);

// Get hotel reviews
router.get('/hotel/reviews', verifyHotelManager, hotelManagerController.getHotelReviews);

// Respond to review
router.post('/hotel/reviews/:id/respond', verifyHotelManager, hotelManagerController.respondToReview);

// Dashboard KPI for hotel manager
router.get('/dashboard', verifyHotelManager, hotelManagerController.getDashboardKpi);

module.exports = router;
