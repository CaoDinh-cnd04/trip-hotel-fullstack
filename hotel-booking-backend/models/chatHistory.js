// models/chatHistory.js - Chat history model for SQL Server
const BaseModel = require('./baseModel');

class ChatHistory extends BaseModel {
  constructor() {
    super('cuoc_tro_chuyen', 'id');
  }

  /**
   * Sync conversation from Firestore to SQL Server
   */
  async syncConversation(conversationData) {
    try {
      const {
        firestoreId,
        user1Id,
        user2Id,
        lastMessage,
        lastSenderId,
        lastMessageTime
      } = conversationData;

      // Check if conversation exists
      const existingQuery = `
        SELECT * FROM ${this.tableName} 
        WHERE firestore_conversation_id = @firestoreId
      `;
      const existing = await this.executeQuery(existingQuery, { firestoreId });

      if (existing.recordset.length > 0) {
        // Update existing
        const updateQuery = `
          UPDATE ${this.tableName} SET
            tin_nhan_cuoi = @lastMessage,
            nguoi_gui_cuoi = @lastSenderId,
            thoi_gian_cuoi = @lastMessageTime,
            ngay_cap_nhat = GETDATE()
          WHERE firestore_conversation_id = @firestoreId
        `;
        await this.executeQuery(updateQuery, {
          firestoreId,
          lastMessage,
          lastSenderId,
          lastMessageTime
        });
        
        return existing.recordset[0];
      } else {
        // Insert new
        const insertQuery = `
          INSERT INTO ${this.tableName} (
            firestore_conversation_id,
            nguoi_dung_1_id,
            nguoi_dung_2_id,
            tin_nhan_cuoi,
            nguoi_gui_cuoi,
            thoi_gian_cuoi,
            ngay_tao
          ) VALUES (
            @firestoreId,
            @user1Id,
            @user2Id,
            @lastMessage,
            @lastSenderId,
            @lastMessageTime,
            GETDATE()
          );
          SELECT SCOPE_IDENTITY() as id;
        `;
        
        const result = await this.executeQuery(insertQuery, {
          firestoreId,
          user1Id,
          user2Id,
          lastMessage,
          lastSenderId,
          lastMessageTime
        });
        
        return { id: result.recordset[0].id };
      }
    } catch (error) {
      console.error('Error syncing conversation:', error);
      throw error;
    }
  }

  /**
   * Get conversation by Firestore ID
   */
  async getByFirestoreId(firestoreId) {
    try {
      const query = `
        SELECT * FROM ${this.tableName}
        WHERE firestore_conversation_id = @firestoreId
      `;
      const result = await this.executeQuery(query, { firestoreId });
      return result.recordset[0] || null;
    } catch (error) {
      throw error;
    }
  }

  /**
   * Get conversation history for a user
   */
  async getConversationsForUser(userId, options = {}) {
    const { page = 1, limit = 20 } = options;
    const offset = (page - 1) * limit;

    try {
      const query = `
        SELECT 
          c.*,
          u1.ho_ten as nguoi_dung_1_ten,
          u1.email as nguoi_dung_1_email,
          u1.chuc_vu as nguoi_dung_1_role,
          u2.ho_ten as nguoi_dung_2_ten,
          u2.email as nguoi_dung_2_email,
          u2.chuc_vu as nguoi_dung_2_role,
          (SELECT COUNT(*) FROM tin_nhan WHERE cuoc_tro_chuyen_id = c.id) as tong_tin_nhan
        FROM ${this.tableName} c
        LEFT JOIN nguoi_dung u1 ON c.nguoi_dung_1_id = u1.id
        LEFT JOIN nguoi_dung u2 ON c.nguoi_dung_2_id = u2.id
        WHERE (c.nguoi_dung_1_id = @userId OR c.nguoi_dung_2_id = @userId)
          AND c.trang_thai = 'active'
        ORDER BY c.thoi_gian_cuoi DESC
        OFFSET @offset ROWS
        FETCH NEXT @limit ROWS ONLY
      `;

      const result = await this.executeQuery(query, { userId, offset, limit });
      return result.recordset;
    } catch (error) {
      throw error;
    }
  }
}

class MessageHistory extends BaseModel {
  constructor() {
    super('tin_nhan', 'id');
  }

  /**
   * Sync message from Firestore to SQL Server
   */
  async syncMessage(messageData) {
    try {
      const {
        firestoreMessageId,
        firestoreConversationId,
        conversationId, // SQL ID
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
      } = messageData;

      // Check if message already synced
      const existingQuery = `
        SELECT id FROM ${this.tableName}
        WHERE firestore_message_id = @firestoreMessageId
      `;
      const existing = await this.executeQuery(existingQuery, { firestoreMessageId });

      if (existing.recordset.length > 0) {
        console.log(`⏭️  Message ${firestoreMessageId} already synced`);
        return existing.recordset[0];
      }

      // Insert new message
      const insertQuery = `
        INSERT INTO ${this.tableName} (
          firestore_message_id,
          cuoc_tro_chuyen_id,
          firestore_conversation_id,
          nguoi_gui_id,
          nguoi_nhan_id,
          noi_dung,
          loai_tin_nhan,
          url_file,
          ten_nguoi_gui,
          email_nguoi_gui,
          chuc_vu_nguoi_gui,
          ten_nguoi_nhan,
          email_nguoi_nhan,
          chuc_vu_nguoi_nhan,
          reply_to_content,
          thoi_gian_gui,
          thoi_gian_dong_bo,
          da_dong_bo
        ) VALUES (
          @firestoreMessageId,
          @conversationId,
          @firestoreConversationId,
          @senderId,
          @receiverId,
          @content,
          @messageType,
          @fileUrl,
          @senderName,
          @senderEmail,
          @senderRole,
          @receiverName,
          @receiverEmail,
          @receiverRole,
          @replyToContent,
          @timestamp,
          GETDATE(),
          1
        );
        SELECT SCOPE_IDENTITY() as id;
      `;

      const result = await this.executeQuery(insertQuery, {
        firestoreMessageId,
        conversationId,
        firestoreConversationId,
        senderId,
        receiverId,
        content,
        messageType: messageType || 'text',
        fileUrl: fileUrl || null,
        senderName: senderName || null,
        senderEmail: senderEmail || null,
        senderRole: senderRole || null,
        receiverName: receiverName || null,
        receiverEmail: receiverEmail || null,
        receiverRole: receiverRole || null,
        replyToContent: replyToContent || null,
        timestamp
      });

      return { id: result.recordset[0].id };
    } catch (error) {
      console.error('Error syncing message:', error);
      throw error;
    }
  }

  /**
   * Get message history for a conversation
   */
  async getMessagesForConversation(conversationId, options = {}) {
    const { page = 1, limit = 50 } = options;
    const offset = (page - 1) * limit;

    try {
      const query = `
        SELECT 
          m.*,
          ug.ho_ten as nguoi_gui_ten,
          ug.anh_dai_dien as nguoi_gui_avatar,
          un.ho_ten as nguoi_nhan_ten,
          un.anh_dai_dien as nguoi_nhan_avatar
        FROM ${this.tableName} m
        LEFT JOIN nguoi_dung ug ON m.nguoi_gui_id = ug.id
        LEFT JOIN nguoi_dung un ON m.nguoi_nhan_id = un.id
        WHERE m.cuoc_tro_chuyen_id = @conversationId
        ORDER BY m.thoi_gian_gui DESC
        OFFSET @offset ROWS
        FETCH NEXT @limit ROWS ONLY
      `;

      const result = await this.executeQuery(query, { conversationId, offset, limit });
      return result.recordset;
    } catch (error) {
      throw error;
    }
  }

  /**
   * Search messages by content
   */
  async searchMessages(userId, searchTerm, options = {}) {
    const { page = 1, limit = 20 } = options;
    const offset = (page - 1) * limit;

    try {
      const query = `
        SELECT 
          m.*,
          c.firestore_conversation_id,
          ug.ho_ten as nguoi_gui_ten,
          un.ho_ten as nguoi_nhan_ten
        FROM ${this.tableName} m
        INNER JOIN cuoc_tro_chuyen c ON m.cuoc_tro_chuyen_id = c.id
        LEFT JOIN nguoi_dung ug ON m.nguoi_gui_id = ug.id
        LEFT JOIN nguoi_dung un ON m.nguoi_nhan_id = un.id
        WHERE (m.nguoi_gui_id = @userId OR m.nguoi_nhan_id = @userId)
          AND m.noi_dung LIKE '%' + @searchTerm + '%'
        ORDER BY m.thoi_gian_gui DESC
        OFFSET @offset ROWS
        FETCH NEXT @limit ROWS ONLY
      `;

      const result = await this.executeQuery(query, { userId, searchTerm, offset, limit });
      return result.recordset;
    } catch (error) {
      throw error;
    }
  }
}

module.exports = {
  ChatHistory: new ChatHistory(),
  MessageHistory: new MessageHistory()
};

