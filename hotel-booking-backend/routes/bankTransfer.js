/**
 * Bank Transfer Routes (MOCK/TEST)
 * 
 * Routes for mock bank transfer payment testing
 */

const express = require('express');
const router = express.Router();
const bankTransferController = require('../controllers/bankTransferController');

// Create payment URL
router.post('/create-payment-url', bankTransferController.createPaymentUrl);

// Test page (HTML)
router.get('/test-page', bankTransferController.testPage);

// Return from bank (callback)
router.get('/return', bankTransferController.bankTransferReturn);
router.post('/return', bankTransferController.bankTransferReturn); // Support POST for manual confirmation

// Get payment status
router.get('/payment-status/:orderId', bankTransferController.getPaymentStatus);

module.exports = router;

