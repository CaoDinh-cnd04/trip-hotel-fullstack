const express = require('express');
const router = express.Router();
const { body, param, query } = require('express-validator');
const tinnhanController = require('../controllers/tinnhanController_v2');
const { authenticateToken: authenticateUser, authorizeRoles: requireRole } = require('../middleware/auth');

// Validation middleware
const validateMessage = [
    body('ma_nguoi_nhan').isInt({ min: 1 }).withMessage('Mã người nhận không hợp lệ'),
    body('noi_dung').notEmpty().withMessage('Nội dung tin nhắn không được để trống')
        .isLength({ max: 1000 }).withMessage('Nội dung không được quá 1000 ký tự'),
    body('loai_tin_nhan').optional().isIn(['text', 'image', 'file']).withMessage('Loại tin nhắn không hợp lệ')
];

const validateId = [
    param('id').isInt({ min: 1 }).withMessage('ID không hợp lệ')
];

const validateUserId = [
    param('user_id').isInt({ min: 1 }).withMessage('ID người dùng không hợp lệ')
];

const validateMessageId = [
    param('message_id').isInt({ min: 1 }).withMessage('ID tin nhắn không hợp lệ')
];

// Routes
// GET /api/tinnhan/conversations - Lấy danh sách cuộc trò chuyện
router.get('/conversations', 
    authenticateUser, 
    tinnhanController.getConversations
);

// GET /api/tinnhan/unread-count - Lấy số tin nhắn chưa đọc
router.get('/unread-count', 
    authenticateUser, 
    tinnhanController.getUnreadCount
);

// GET /api/tinnhan/search - Tìm kiếm tin nhắn
router.get('/search', 
    authenticateUser, 
    tinnhanController.searchMessages
);

// GET /api/tinnhan/:user_id - Lấy tin nhắn với một người dùng
router.get('/:user_id', 
    authenticateUser,
    validateUserId,
    tinnhanController.getMessages
);

// POST /api/tinnhan - Gửi tin nhắn mới
router.post('/', 
    authenticateUser,
    validateMessage,
    tinnhanController.sendMessage
);

// PUT /api/tinnhan/:message_id/read - Đánh dấu đã đọc tin nhắn
router.put('/:message_id/read', 
    authenticateUser,
    validateMessageId,
    tinnhanController.markAsRead
);

// PUT /api/tinnhan/:user_id/read-all - Đánh dấu đã đọc tất cả tin nhắn từ một người
router.put('/:user_id/read-all', 
    authenticateUser,
    validateUserId,
    tinnhanController.markAllAsRead
);

// DELETE /api/tinnhan/:message_id - Xóa tin nhắn
router.delete('/:message_id', 
    authenticateUser,
    validateMessageId,
    tinnhanController.deleteMessage
);

module.exports = router;