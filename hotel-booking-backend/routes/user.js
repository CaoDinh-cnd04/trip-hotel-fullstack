const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const userController = require('../controllers/userController');

// Apply authentication middleware to all routes
router.use(authenticateToken);

// User Messages Routes
router.get('/messages', userController.getMessages);
router.put('/messages/:id/read', userController.markMessageAsRead);
router.delete('/messages/:id', userController.deleteMessage);

// User Reviews Routes
router.get('/reviews', userController.getMyReviews);
router.post('/reviews', userController.createReview);
router.put('/reviews/:id', userController.updateReview);
router.delete('/reviews/:id', userController.deleteReview);
router.get('/reviews/:id', userController.getReview);

// User Profile Routes
router.get('/profile', userController.getProfile);
router.put('/profile', userController.updateProfile);

// User Bookings Routes
router.get('/bookings', userController.getMyBookings);
router.get('/bookings/:id', userController.getBooking);
router.put('/bookings/:id/cancel', userController.cancelBooking);

// User Saved Items Routes
router.get('/saved-items', userController.getSavedItems);
router.post('/saved-items', userController.addToSaved);
router.delete('/saved-items/:id', userController.removeFromSaved);
router.get('/saved-items/check', userController.checkIsSaved);

module.exports = router;
