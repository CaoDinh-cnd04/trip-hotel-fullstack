const express = require('express');
const router = express.Router();
const quocgiaController = require('../controllers/quocgiaController');
const authMiddleware = require('../middleware/auth');

router.get('/', quocgiaController.getAllCountries); // Mọi người có thể xem danh sách quốc gia
router.get('/:id', quocgiaController.getCountryById); // Mọi người có thể xem chi tiết quốc gia
router.post('/', authMiddleware.verifyAdmin, quocgiaController.createCountry); // Chỉ Admin được thêm
router.put('/:id', authMiddleware.verifyAdmin, quocgiaController.updateCountry); // Chỉ Admin được sửa
router.delete('/:id', authMiddleware.verifyAdmin, quocgiaController.deleteCountry); // Chỉ Admin được xóa

module.exports = router;