const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const promotionOfferController = require('../controllers/promotionOfferController');

// Public routes (không cần authentication)
router.get('/hotel/:hotelId/active', promotionOfferController.getActiveOffersForHotel);
router.get('/hotel/:hotelId/room/:roomTypeId', promotionOfferController.getOfferForRoom);

// User routes (cần authentication)
router.post('/book', authenticateToken, promotionOfferController.bookWithOffer);

// Hotel owner routes (cần authentication)
router.post('/', authenticateToken, promotionOfferController.createOffer);
router.put('/:offerId/rooms', authenticateToken, promotionOfferController.updateAvailableRooms);
router.delete('/:offerId', authenticateToken, promotionOfferController.cancelOffer);
router.get('/my-offers', authenticateToken, promotionOfferController.getOffersByHotelOwner);

// Admin routes (có thể thêm middleware admin sau)
router.post('/create-end-of-day', promotionOfferController.createEndOfDayOffers);

module.exports = router;
