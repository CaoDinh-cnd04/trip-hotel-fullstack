const express = require('express');
const router = express.Router();
const hotelRegistrationController = require('../controllers/hotelRegistrationController');
const { verifyToken } = require('../middleware/auth');
const upload = require('../middleware/uploadImages');

/**
 * @route   POST /api/v2/hotel-registration/with-images
 * @desc    Tạo đơn đăng ký khách sạn mới với upload ảnh
 * @access  Public
 */
router.post('/with-images', upload.fields([
  { name: 'hotel_images', maxCount: 10 },
  { name: 'room_images', maxCount: 50 }
]), hotelRegistrationController.createRegistrationWithImages);

/**
 * @route   POST /api/v2/hotel-registration
 * @desc    Tạo đơn đăng ký khách sạn mới (không có ảnh)
 * @access  Public
 */
router.post('/', hotelRegistrationController.createRegistration);

/**
 * @route   GET /api/v2/hotel-registration/my-registrations
 * @desc    Lấy đơn đăng ký của user hiện tại
 * @access  Private
 */
router.get('/my-registrations', verifyToken, hotelRegistrationController.getMyRegistrations);

/**
 * @route   GET /api/v2/hotel-registration/admin/all
 * @desc    Lấy tất cả đơn đăng ký (Admin)
 * @access  Private (Admin only)
 */
router.get('/admin/all', verifyToken, hotelRegistrationController.getAllRegistrations);

/**
 * @route   GET /api/v2/hotel-registration/:id
 * @desc    Lấy đơn đăng ký theo ID
 * @access  Private
 */
router.get('/:id', verifyToken, hotelRegistrationController.getRegistrationById);

/**
 * @route   PUT /api/v2/hotel-registration/:id
 * @desc    Cập nhật thông tin đơn đăng ký
 * @access  Private
 */
router.put('/:id', verifyToken, hotelRegistrationController.updateRegistration);

/**
 * @route   PUT /api/v2/hotel-registration/:id/status
 * @desc    Cập nhật trạng thái đơn đăng ký (Admin)
 * @access  Private (Admin only)
 */
router.put('/:id/status', verifyToken, hotelRegistrationController.updateRegistrationStatus);

/**
 * @route   DELETE /api/v2/hotel-registration/:id
 * @desc    Xóa đơn đăng ký (Admin)
 * @access  Private (Admin only)
 */
router.delete('/:id', verifyToken, hotelRegistrationController.deleteRegistration);

module.exports = router;

