const express = require('express');
const router = express.Router();
const { authenticateToken, verifyAdmin } = require('../middleware/auth');
const promotionOfferController = require('../controllers/promotionOfferController');

// Public routes (không cần authentication)
router.get('/hotel/:hotelId/active', promotionOfferController.getActiveOffersForHotel);
router.get('/hotel/:hotelId/room/:roomTypeId', promotionOfferController.getOfferForRoom);

// User routes (cần authentication)
router.post('/book', authenticateToken, promotionOfferController.bookWithOffer);

// Hotel owner routes (cần authentication)
router.post('/', authenticateToken, promotionOfferController.createOffer);
router.put('/:offerId/rooms', authenticateToken, promotionOfferController.updateAvailableRooms);
router.patch('/:offerId/toggle', authenticateToken, promotionOfferController.toggleOffer);
router.post('/:offerId/submit-approval', authenticateToken, promotionOfferController.submitForApproval);
router.delete('/:offerId', authenticateToken, promotionOfferController.cancelOffer);
router.get('/my-offers', authenticateToken, promotionOfferController.getOffersByHotelOwner);

// Admin routes
router.get('/admin/all', ...verifyAdmin, promotionOfferController.getAllPromotionOffers);
router.put('/admin/:offerId/approve', ...verifyAdmin, promotionOfferController.approvePromotionOffer);
router.put('/admin/:offerId/reject', ...verifyAdmin, promotionOfferController.rejectPromotionOffer);
router.post('/create-end-of-day', ...verifyAdmin, promotionOfferController.createEndOfDayOffers);

module.exports = router;
