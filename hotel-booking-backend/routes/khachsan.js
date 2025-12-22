const express = require('express');
const router = express.Router();
const khachsanController = require('../controllers/khachsanController');
const authMiddleware = require('../middleware/auth');

router.get('/', khachsanController.getAllHotels); // Mọi người có thể xem danh sách khách sạn
router.get('/:id', khachsanController.getHotelById); // Mọi người có thể xem chi tiết khách sạn
router.get('/:id/phong', khachsanController.getHotelRooms); // Lấy danh sách phòng của khách sạn
router.get('/:id/reviews', khachsanController.getHotelReviews); // Lấy danh sách đánh giá của khách sạn (Public)
router.get('/:id/tien-nghi', khachsanController.getHotelAmenities); // Lấy danh sách tiện nghi của khách sạn
router.get('/:id/tien-nghi/co-phi', khachsanController.getHotelPaidAmenities); // Lấy danh sách dịch vụ có phí
router.get('/:id/tien-nghi/mien-phi', khachsanController.getHotelFreeAmenities); // Lấy danh sách dịch vụ miễn phí
router.post('/', authMiddleware.verifyAdmin, khachsanController.createHotel); // Chỉ Admin được thêm
router.put('/:id', authMiddleware.verifyAdmin, khachsanController.updateHotel); // Chỉ Admin được sửa
router.put('/:id/toggle-status', authMiddleware.verifyAdmin, khachsanController.toggleHotelStatus); // Chỉ Admin được khoá/mở khoá
router.delete('/:id', authMiddleware.verifyAdmin, khachsanController.deleteHotel); // Chỉ Admin được xóa

module.exports = router;