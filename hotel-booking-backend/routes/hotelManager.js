const express = require('express');
const router = express.Router();
const hotelManagerController = require('../controllers/hotelManagerController');
const { verifyHotelManager, verifyToken } = require('../middleware/auth');
const upload = require('../middleware/upload');
const uploadRoomImages = require('../middleware/uploadRoomImages');
const uploadHotelImage = require('../middleware/uploadHotelImage');
const uploadAmenityImage = require('../middleware/uploadAmenityImage');

// Get hotel manager's assigned hotel
router.get('/hotel', verifyHotelManager, hotelManagerController.getAssignedHotel);

// Get hotel manager's hotel statistics
router.get('/hotel/stats', verifyHotelManager, hotelManagerController.getHotelStats);

// Update hotel information
router.put('/hotel', verifyHotelManager, hotelManagerController.updateHotel);

// Upload hotel image (add to gallery)
router.post('/hotel/image', verifyHotelManager, uploadHotelImage.single('image'), hotelManagerController.uploadHotelImage);

// Delete hotel image
router.delete('/hotel/images/:imageId', verifyHotelManager, hotelManagerController.deleteHotelImage);

// Set hotel main image
router.put('/hotel/images/:imageId/set-main', verifyHotelManager, hotelManagerController.setMainHotelImage);

// Get all available amenities
router.get('/amenities', verifyHotelManager, hotelManagerController.getAllAmenities);

// Create new amenity for hotel (Hotel Manager only)
router.post('/amenities', verifyHotelManager, hotelManagerController.createHotelAmenity);

// Get hotel amenities with pricing (for management)
router.get('/hotel/amenities', verifyHotelManager, hotelManagerController.getHotelAmenitiesWithPricing);

// Update amenity pricing
router.put('/amenities/:amenityId/pricing', verifyHotelManager, (req, res, next) => {
  console.log('✅ Route matched: PUT /amenities/:amenityId/pricing');
  console.log('📋 Params:', req.params);
  console.log('📋 amenityId:', req.params.amenityId);
  next();
}, hotelManagerController.updateAmenityPricing);

// Upload amenity image
router.post('/amenities/:amenityId/image', verifyHotelManager, uploadAmenityImage.single('image'), hotelManagerController.uploadAmenityImage);

// Update hotel amenities
router.put('/hotel/amenities', verifyHotelManager, hotelManagerController.updateHotelAmenities);

// Get all room types
router.get('/room-types', verifyHotelManager, hotelManagerController.getRoomTypes);

// Get hotel rooms
router.get('/hotel/rooms', verifyHotelManager, hotelManagerController.getHotelRooms);

// Add new room
router.post('/hotel/rooms', verifyHotelManager, hotelManagerController.addRoom);

// IMPORTANT: Specific routes must come BEFORE generic :id routes
// Update room status (for maintenance) - must be before /:id
router.patch('/hotel/rooms/:id/status', verifyHotelManager, (req, res, next) => {
  console.log('✅ Route matched: PATCH /hotel/rooms/:id/status', req.params.id);
  next();
}, hotelManagerController.updateRoomStatus);

// Upload room images - must be before /:id
router.post('/hotel/rooms/:id/images', verifyHotelManager, uploadRoomImages.array('images', 5), (req, res, next) => {
  console.log('✅ Route matched: POST /hotel/rooms/:id/images', req.params.id);
  next();
}, hotelManagerController.uploadRoomImages);

// Update room - generic route comes after specific routes
router.put('/hotel/rooms/:id', verifyHotelManager, (req, res, next) => {
  console.log('✅ Route matched: PUT /hotel/rooms/:id', req.params.id, 'Body:', req.body);
  next();
}, hotelManagerController.updateRoom);

// Delete room
router.delete('/hotel/rooms/:id', verifyHotelManager, hotelManagerController.deleteRoom);

// Get hotel bookings
router.get('/hotel/bookings', verifyHotelManager, hotelManagerController.getHotelBookings);

// IMPORTANT: Specific routes must come BEFORE generic :id routes
// Send notification to customer for a booking - must be before /:id
router.post('/hotel/bookings/:id/notify', verifyHotelManager, (req, res, next) => {
  console.log('🔔 ===== NOTIFY ROUTE MATCHED =====');
  console.log('📋 Full URL:', req.originalUrl);
  console.log('📋 Method:', req.method);
  console.log('📋 Params:', req.params);
  console.log('📋 Body:', req.body);
  next();
}, hotelManagerController.sendBookingNotification);

// Update booking (status and other fields)
router.put('/hotel/bookings/:id', verifyHotelManager, hotelManagerController.updateBookingStatus);

// Delete booking
router.delete('/hotel/bookings/:id', verifyHotelManager, hotelManagerController.deleteBooking);

// Get hotel reviews
router.get('/hotel/reviews', verifyHotelManager, hotelManagerController.getHotelReviews);

// Respond to review
router.post('/hotel/reviews/:id/respond', verifyHotelManager, hotelManagerController.respondToReview);

// Report review violation
router.post('/hotel/reviews/:id/report', verifyHotelManager, hotelManagerController.reportReview);

// Dashboard KPI for hotel manager
router.get('/dashboard', verifyHotelManager, hotelManagerController.getDashboardKpi);

// Get customers for messages (who have booked)
router.get('/customers', verifyHotelManager, (req, res, next) => {
  console.log('✅ Route matched: GET /customers');
  next();
}, hotelManagerController.getCustomersForMessages);

module.exports = router;
