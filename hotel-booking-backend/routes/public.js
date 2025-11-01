const express = require('express');
const router = express.Router();
const publicController = require('../controllers/publicController');

// Public routes - không cần authentication

// GET /api/public/featured-hotels - Lấy khách sạn nổi bật
router.get('/featured-hotels', publicController.getFeaturedHotels);

// GET /api/public/featured-promotions - Lấy ưu đãi nổi bật
router.get('/featured-promotions', publicController.getFeaturedPromotions);

// GET /api/public/hot-destinations - Lấy địa điểm hot
router.get('/hot-destinations', publicController.getHotDestinations);

// GET /api/public/popular-countries - Lấy quốc gia phổ biến
router.get('/popular-countries', publicController.getPopularCountries);

// GET /api/public/homepage - Lấy tất cả dữ liệu trang chủ
router.get('/homepage', publicController.getHomePageData);

module.exports = router;
