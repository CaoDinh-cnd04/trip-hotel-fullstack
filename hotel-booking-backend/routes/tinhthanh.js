const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const tinhthanhController = require('../controllers/tinhthanhController');
const authMiddleware = require('../middleware/auth');

// Validation rules
const createTinhThanhValidation = [
    body('ten_tinh_thanh')
        .notEmpty()
        .withMessage('Tên tỉnh thành là bắt buộc')
        .isLength({ min: 2, max: 100 })
        .withMessage('Tên tỉnh thành phải từ 2-100 ký tự'),
    body('ma_quoc_gia')
        .notEmpty()
        .withMessage('Mã quốc gia là bắt buộc'),
    body('mo_ta')
        .optional()
        .isLength({ max: 500 })
        .withMessage('Mô tả không được quá 500 ký tự')
];

const updateTinhThanhValidation = [
    body('ten_tinh_thanh')
        .optional()
        .isLength({ min: 2, max: 100 })
        .withMessage('Tên tỉnh thành phải từ 2-100 ký tự'),
    body('mo_ta')
        .optional()
        .isLength({ max: 500 })
        .withMessage('Mô tả không được quá 500 ký tự')
];

// Routes
router.get('/', tinhthanhController.getAllTinhThanh);
router.get('/search', tinhthanhController.searchTinhThanh);
router.get('/popular', tinhthanhController.getPopularTinhThanh);
router.get('/:id', tinhthanhController.getTinhThanhById);

// Protected routes (Admin only)
router.post('/', 
    authMiddleware.verifyAdmin, 
    createTinhThanhValidation, 
    tinhthanhController.createTinhThanh
);

router.put('/:id', 
    authMiddleware.verifyAdmin, 
    updateTinhThanhValidation,
    tinhthanhController.updateTinhThanh
);

router.delete('/:id', 
    authMiddleware.verifyAdmin, 
    tinhthanhController.deleteTinhThanh
);

module.exports = router;