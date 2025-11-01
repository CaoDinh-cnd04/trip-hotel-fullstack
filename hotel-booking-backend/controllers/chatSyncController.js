// controllers/chatSyncController.js - Sync chat from Firestore to SQL Server
const { ChatHistory, MessageHistory } = require('../models/chatHistory');
const NguoiDung = require('../models/nguoidung');
const emailService = require('../services/emailService');

// Sync một message từ Firestore sang SQL Server
exports.syncMessage = async (req, res) => {
  try {
    const {
      firestoreMessageId,
      firestoreConversationId,
      senderId,
      receiverId,
      content,
      messageType,
      fileUrl,
      senderName,
      senderEmail,
      senderRole,
      receiverName,
      receiverEmail,
      receiverRole,
      replyToMessageId,
      replyToContent,
      timestamp
    } = req.body;

    console.log('📩 Syncing message:', firestoreMessageId);

    // Get or create conversation in SQL
    let conversation = await ChatHistory.getByFirestoreId(firestoreConversationId);
    
    if (!conversation) {
      // Create new conversation
      conversation = await ChatHistory.syncConversation({
        firestoreId: firestoreConversationId,
        user1Id: senderId,
        user2Id: receiverId,
        lastMessage: content,
        lastSenderId: senderId,
        lastMessageTime: timestamp
      });
    }

    // Sync message
    const message = await MessageHistory.syncMessage({
      firestoreMessageId,
      firestoreConversationId,
      conversationId: conversation.id,
      senderId,
      receiverId,
      content,
      messageType,
      fileUrl,
      senderName,
      senderEmail,
      senderRole,
      receiverName,
      receiverEmail,
      receiverRole,
      replyToMessageId,
      replyToContent,
      timestamp: new Date(timestamp)
    });

    // Update conversation last message
    await ChatHistory.syncConversation({
      firestoreId: firestoreConversationId,
      user1Id: senderId,
      user2Id: receiverId,
      lastMessage: content,
      lastSenderId: senderId,
      lastMessageTime: timestamp
    });

    // Send email notification to receiver (async, không block response)
    if (receiverEmail) {
      emailService.sendMessageNotification(receiverEmail, {
        senderName: senderName || 'Người gửi',
        senderRole: senderRole || 'user',
        content: content,
        timestamp: timestamp,
        hotelName: req.body.hotelName || null,
        bookingCode: req.body.bookingCode || null
      }).catch(err => {
        console.error('📧 Failed to send message notification email:', err.message);
      });
    }

    res.json({
      success: true,
      message: 'Message synced to SQL Server',
      data: message
    });
  } catch (error) {
    console.error('Sync message error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to sync message',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get conversation history from SQL Server
exports.getConversationHistory = async (req, res) => {
  try {
    const userId = req.user.id;
    const { page = 1, limit = 20 } = req.query;

    const conversations = await ChatHistory.getConversationsForUser(userId, {
      page: parseInt(page),
      limit: parseInt(limit)
    });

    res.json({
      success: true,
      data: conversations,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit)
      }
    });
  } catch (error) {
    console.error('Get conversation history error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get conversation history'
    });
  }
};

// Get message history for a conversation
exports.getMessageHistory = async (req, res) => {
  try {
    const { conversationId } = req.params;
    const { page = 1, limit = 50 } = req.query;

    const messages = await MessageHistory.getMessagesForConversation(
      parseInt(conversationId),
      {
        page: parseInt(page),
        limit: parseInt(limit)
      }
    );

    res.json({
      success: true,
      data: messages,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: messages.length
      }
    });
  } catch (error) {
    console.error('Get message history error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get message history'
    });
  }
};

// Search messages
exports.searchMessages = async (req, res) => {
  try {
    const userId = req.user.id;
    const { q, page = 1, limit = 20 } = req.query;

    if (!q || q.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Search term is required'
      });
    }

    const messages = await MessageHistory.searchMessages(userId, q, {
      page: parseInt(page),
      limit: parseInt(limit)
    });

    res.json({
      success: true,
      data: messages,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: messages.length
      }
    });
  } catch (error) {
    console.error('Search messages error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to search messages'
    });
  }
};

// Get chat statistics
exports.getChatStatistics = async (req, res) => {
  try {
    const userId = req.user.id;

    const statsQuery = `
      SELECT 
        COUNT(DISTINCT c.id) as total_conversations,
        COUNT(m.id) as total_messages_sent,
        COUNT(DISTINCT CASE WHEN m.nguoi_nhan_id = @userId THEN m.id END) as total_messages_received,
        MAX(m.thoi_gian_gui) as last_message_time
      FROM nguoi_dung u
      LEFT JOIN cuoc_tro_chuyen c ON (u.id = c.nguoi_dung_1_id OR u.id = c.nguoi_dung_2_id)
      LEFT JOIN tin_nhan m ON (u.id = m.nguoi_gui_id)
      WHERE u.id = @userId
      GROUP BY u.id
    `;

    const result = await ChatHistory.executeQuery(statsQuery, { userId });

    res.json({
      success: true,
      data: result.recordset[0] || {
        total_conversations: 0,
        total_messages_sent: 0,
        total_messages_received: 0,
        last_message_time: null
      }
    });
  } catch (error) {
    console.error('Get chat statistics error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get chat statistics'
    });
  }
};

