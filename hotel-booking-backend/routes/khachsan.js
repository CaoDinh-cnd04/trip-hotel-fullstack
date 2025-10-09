const express = require('express');
const router = express.Router();
const khachsanController = require('../controllers/khachsanController');
const authMiddleware = require('../middleware/auth');

router.get('/', khachsanController.getAllHotels); // Mọi người có thể xem danh sách khách sạn
router.get('/:id', khachsanController.getHotelById); // Mọi người có thể xem chi tiết khách sạn
router.post('/', authMiddleware.verifyAdmin, khachsanController.createHotel); // Chỉ Admin được thêm
router.put('/:id', authMiddleware.verifyAdmin, khachsanController.updateHotel); // Chỉ Admin được sửa
router.delete('/:id', authMiddleware.verifyAdmin, khachsanController.deleteHotel); // Chỉ Admin được xóa

module.exports = router;