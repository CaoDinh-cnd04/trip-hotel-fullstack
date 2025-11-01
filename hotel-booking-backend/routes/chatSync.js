// routes/chatSync.js - Chat history sync routes
const express = require('express');
const router = express.Router();
const chatSyncController = require('../controllers/chatSyncController');
const { authenticateToken } = require('../middleware/auth');

// POST /api/chat-sync/message - Sync message từ Firestore → SQL Server
// Called from Flutter app after sending message
router.post('/message', authenticateToken, chatSyncController.syncMessage);

// GET /api/chat-sync/conversations - Get conversation history từ SQL Server
router.get('/conversations', authenticateToken, chatSyncController.getConversationHistory);

// GET /api/chat-sync/conversations/:conversationId/messages - Get message history
router.get('/conversations/:conversationId/messages', authenticateToken, chatSyncController.getMessageHistory);

// GET /api/chat-sync/search - Search messages
router.get('/search', authenticateToken, chatSyncController.searchMessages);

// GET /api/chat-sync/statistics - Get chat statistics
router.get('/statistics', authenticateToken, chatSyncController.getChatStatistics);

module.exports = router;

