const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const vitriController = require('../controllers/vitriController');
const authMiddleware = require('../middleware/auth');

// Validation rules
const createViTriValidation = [
    body('ten_vi_tri')
        .notEmpty()
        .withMessage('Tên vị trí là bắt buộc')
        .isLength({ min: 2, max: 100 })
        .withMessage('Tên vị trí phải từ 2-100 ký tự'),
    body('ma_tinh_thanh')
        .notEmpty()
        .withMessage('Mã tỉnh thành là bắt buộc'),
    body('mo_ta')
        .optional()
        .isLength({ max: 500 })
        .withMessage('Mô tả không được quá 500 ký tự')
];

const updateViTriValidation = [
    body('ten_vi_tri')
        .optional()
        .isLength({ min: 2, max: 100 })
        .withMessage('Tên vị trí phải từ 2-100 ký tự'),
    body('mo_ta')
        .optional()
        .isLength({ max: 500 })
        .withMessage('Mô tả không được quá 500 ký tự')
];

// Routes
router.get('/', vitriController.getAllViTri);
router.get('/search', vitriController.searchViTri);
router.get('/:id', vitriController.getViTriById);

// Protected routes (Admin only)
router.post('/', 
    authMiddleware.verifyAdmin, 
    createViTriValidation, 
    vitriController.createViTri
);

router.put('/:id', 
    authMiddleware.verifyAdmin, 
    updateViTriValidation, 
    vitriController.updateViTri
);

router.delete('/:id', 
    authMiddleware.verifyAdmin, 
    vitriController.deleteViTri
);

module.exports = router;