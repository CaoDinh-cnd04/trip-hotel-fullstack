const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const upload = require('../middleware/upload');
const hotelOwnerController = require('../controllers/hotelOwnerController');

// Apply authentication middleware to all routes
router.use(authenticateToken);

// Hotel Registration Routes
router.post('/register-hotel', upload.array('images', 10), hotelOwnerController.registerHotel);
router.get('/my-hotels', hotelOwnerController.getMyHotels);
router.get('/stats', hotelOwnerController.getHotelStats);
router.get('/hotels/:id', hotelOwnerController.getHotelDetails);
router.put('/hotels/:id', upload.array('images', 10), hotelOwnerController.updateHotel);
router.delete('/hotels/:id', hotelOwnerController.deleteHotel);

// Hotel Management Routes
router.get('/bookings', hotelOwnerController.getHotelBookings);
router.put('/bookings/:id/status', hotelOwnerController.updateBookingStatus);
router.get('/reviews', hotelOwnerController.getHotelReviews);
router.post('/reviews/:id/reply', hotelOwnerController.replyToReview);

module.exports = router;
