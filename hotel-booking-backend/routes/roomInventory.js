const express = require('express');
const router = express.Router();
const roomInventoryController = require('../controllers/roomInventoryController');
const auth = require('../middleware/auth');

// Public routes - Check availability
router.get(
    '/khachsan/:ma_khach_san/availability',
    roomInventoryController.getHotelAvailability
);

router.get(
    '/khachsan/:ma_khach_san/loaiphong/:ma_loai_phong/availability',
    roomInventoryController.getRoomTypeAvailability
);

// Protected routes - Booking
router.post(
    '/khachsan/book-room-safe',
    auth.authenticateToken,
    roomInventoryController.bookRoomSafe
);

// System routes - Auto tasks (should be protected by admin auth or API key)
router.post(
    '/system/auto-checkout',
    ...auth.verifyAdmin,
    roomInventoryController.autoCheckout
);

router.post(
    '/system/auto-cancel-pending',
    ...auth.verifyAdmin,
    roomInventoryController.autoCancelPending
);

module.exports = router;

