const express = require('express');
const router = express.Router();
const { verifyToken, verifyAdmin } = require('../middleware/auth');
const feedbackController = require('../controllers/feedbackController');

// =============================================
// FEEDBACK ROUTES - Full CRUD Implementation
// =============================================

// GET /api/v2/feedback - Lấy tất cả feedback (Admin only)
router.get('/', verifyToken, feedbackController.getAllFeedbacks);

// GET /api/v2/feedback/statistics - Thống kê feedback (Admin only)
router.get('/statistics', verifyAdmin, feedbackController.getFeedbackStatistics);

// GET /api/v2/feedback/user/:userId - Lấy feedback của user
router.get('/user/:userId', verifyToken, feedbackController.getUserFeedbacks);

// GET /api/v2/feedback/:id - Lấy chi tiết 1 feedback
router.get('/:id', verifyToken, feedbackController.getFeedbackById);

// POST /api/v2/feedback - Tạo feedback mới
router.post('/', verifyToken, feedbackController.createFeedback);

// PUT /api/v2/feedback/:id/respond - Admin phản hồi (Admin only)
router.put('/:id/respond', verifyAdmin, feedbackController.respondToFeedback);

// PUT /api/v2/feedback/:id/status - Cập nhật trạng thái (Admin only)
router.put('/:id/status', verifyAdmin, feedbackController.updateFeedbackStatus);

// DELETE /api/v2/feedback/:id - Xóa feedback (Admin only)
router.delete('/:id', verifyAdmin, feedbackController.deleteFeedback);

module.exports = router;

