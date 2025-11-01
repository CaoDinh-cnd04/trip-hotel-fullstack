// models/thongbao.js - Notification model
const BaseModel = require('./baseModel');

class ThongBao extends BaseModel {
  constructor() {
    super('thong_bao');
  }

  /**
   * Get notifications for a specific user
   */
  async getForUser(userId, options = {}) {
    const { page = 1, limit = 20, unreadOnly = false } = options;
    const offset = (page - 1) * limit;

    try {
      // Build WHERE clause
      let whereConditions = [];
      
      // Filter by visibility
      whereConditions.push('tb.hien_thi = CAST(1 AS BIT)');
      
      // Filter by target audience (qualify column with table alias to avoid ambiguity)
      whereConditions.push(`(
        tb.doi_tuong_nhan = 'all' OR 
        tb.doi_tuong_nhan = 'user' OR 
        (tb.doi_tuong_nhan = 'specific_user' AND tb.nguoi_dung_id = ${userId})
      )`);

      // Filter by expiration
      whereConditions.push(`(tb.ngay_het_han IS NULL OR tb.ngay_het_han > GETDATE())`);

      // If unread only, join with thong_bao_da_doc table
      let joinClause = '';
      if (unreadOnly) {
        joinClause = `LEFT JOIN thong_bao_da_doc tdd ON tb.id = tdd.thong_bao_id AND tdd.nguoi_dung_id = ${userId}`;
        whereConditions.push('tdd.id IS NULL');
      }

      const whereClause = whereConditions.join(' AND ');

      // Get total count
      const countQuery = `
        SELECT COUNT(*) as total 
        FROM ${this.tableName} tb
        ${joinClause}
        WHERE ${whereClause}
      `;
      const countResult = await this.executeQuery(countQuery);
      const total = countResult.recordset[0].total;

      // Get notifications with read status
      const query = `
        SELECT 
          tb.*,
          CASE WHEN tdd.id IS NOT NULL THEN 1 ELSE 0 END as da_doc
        FROM ${this.tableName} tb
        LEFT JOIN thong_bao_da_doc tdd ON tb.id = tdd.thong_bao_id AND tdd.nguoi_dung_id = @userId
        WHERE ${whereClause}
        ORDER BY tb.ngay_tao DESC
        OFFSET @offset ROWS
        FETCH NEXT @limit ROWS ONLY
      `;

      const result = await this.executeQuery(query, {
        userId,
        offset,
        limit
      });

      return {
        data: result.recordset,
        pagination: {
          page,
          limit,
          total,
          totalPages: Math.ceil(total / limit)
        }
      };
    } catch (error) {
      console.error('Get notifications for user error:', error);
      throw error;
    }
  }

  /**
   * Get unread count for a user
   */
  async getUnreadCount(userId) {
    try {
      const query = `
        SELECT COUNT(*) as count
        FROM ${this.tableName} tb
        LEFT JOIN thong_bao_da_doc tdd ON tb.id = tdd.thong_bao_id AND tdd.nguoi_dung_id = @userId
        WHERE 
          tb.hien_thi = CAST(1 AS BIT) AND
          (tb.doi_tuong_nhan = 'all' OR tb.doi_tuong_nhan = 'user' OR 
           (tb.doi_tuong_nhan = 'specific_user' AND tb.nguoi_dung_id = @userId)) AND
          (tb.ngay_het_han IS NULL OR tb.ngay_het_han > GETDATE()) AND
          tdd.id IS NULL
      `;

      console.log(`🔍 Executing unread count query for user ${userId}`);
      const result = await this.executeQuery(query, { userId });
      const count = result.recordset[0]?.count || 0;
      console.log(`📊 Unread count query result: ${count} notifications`);
      
      // Debug: Also check total notifications for this user
      const debugQuery = `
        SELECT COUNT(*) as total
        FROM ${this.tableName} tb
        WHERE 
          tb.hien_thi = CAST(1 AS BIT) AND
          (tb.doi_tuong_nhan = 'all' OR tb.doi_tuong_nhan = 'user' OR 
           (tb.doi_tuong_nhan = 'specific_user' AND tb.nguoi_dung_id = @userId)) AND
          (tb.ngay_het_han IS NULL OR tb.ngay_het_han > GETDATE())
      `;
      const debugResult = await this.executeQuery(debugQuery, { userId });
      const total = debugResult.recordset[0]?.total || 0;
      console.log(`📊 Total notifications for user ${userId}: ${total} (unread: ${count})`);
      
      return count;
    } catch (error) {
      console.error('❌ Get unread count error:', error);
      return 0;
    }
  }

  /**
   * Mark notification as read
   */
  async markAsRead(notificationId, userId) {
    try {
      const query = `
        IF NOT EXISTS (
          SELECT 1 FROM thong_bao_da_doc 
          WHERE thong_bao_id = @notificationId AND nguoi_dung_id = @userId
        )
        BEGIN
          INSERT INTO thong_bao_da_doc (thong_bao_id, nguoi_dung_id, ngay_doc)
          VALUES (@notificationId, @userId, GETDATE())
        END
      `;

      await this.executeQuery(query, { notificationId, userId });
      return true;
    } catch (error) {
      console.error('Mark as read error:', error);
      throw error;
    }
  }

  /**
   * Get users who should receive email for this notification
   */
  async getUsersForEmailNotification(notificationId) {
    try {
      const notification = await this.findById(notificationId);
      if (!notification) {
        throw new Error('Notification not found');
      }

      let query = '';
      const NguoiDung = require('./nguoidung');

      // Determine target users based on doi_tuong_nhan
      switch (notification.doi_tuong_nhan) {
        case 'all':
          query = `
            SELECT * FROM nguoi_dung 
            WHERE trang_thai = CAST(1 AS BIT) AND nhan_thong_bao_email = CAST(1 AS BIT)
          `;
          break;
        
        case 'user':
          query = `
            SELECT * FROM nguoi_dung 
            WHERE chuc_vu = 'User' AND trang_thai = CAST(1 AS BIT) AND nhan_thong_bao_email = CAST(1 AS BIT)
          `;
          break;
        
        case 'hotel_manager':
          query = `
            SELECT * FROM nguoi_dung 
            WHERE chuc_vu = 'HotelManager' AND trang_thai = CAST(1 AS BIT) AND nhan_thong_bao_email = CAST(1 AS BIT)
          `;
          break;
        
        case 'admin':
          query = `
            SELECT * FROM nguoi_dung 
            WHERE chuc_vu = 'Admin' AND trang_thai = CAST(1 AS BIT) AND nhan_thong_bao_email = CAST(1 AS BIT)
          `;
          break;
        
        case 'specific_user':
          if (notification.nguoi_dung_id) {
            query = `
              SELECT * FROM nguoi_dung 
              WHERE id = ${notification.nguoi_dung_id} AND trang_thai = CAST(1 AS BIT) AND nhan_thong_bao_email = CAST(1 AS BIT)
            `;
          } else {
            return [];
          }
          break;
        
        default:
          return [];
      }

      const result = await this.executeQuery(query);
      return result.recordset;
    } catch (error) {
      console.error('Get users for email notification error:', error);
      return [];
    }
  }
}

module.exports = new ThongBao();
