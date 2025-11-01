const BaseModel = require('./baseModel');

class PhanHoi extends BaseModel {
  constructor() {
    super('PHAN_HOI', 'MA_PHAN_HOI');
  }

  /**
   * Lấy tất cả phản hồi với filters và pagination
   */
  async getAllFeedbacks(options = {}) {
    const {
      page = 1,
      limit = 20,
      status = null,
      type = null,
      priority = null,
      userId = null,
      search = null
    } = options;

    const offset = (page - 1) * limit;
    let conditions = [];
    let params = {};

    // Build WHERE conditions
    if (status) {
      conditions.push('TRANG_THAI = @status');
      params.status = status;
    }

    if (type) {
      conditions.push('LOAI_PHAN_HOI = @type');
      params.type = type;
    }

    if (priority) {
      conditions.push('UU_TIEN = @priority');
      params.priority = priority;
    }

    if (userId) {
      conditions.push('MA_NGUOI_DUNG = @userId');
      params.userId = userId;
    }

    if (search) {
      conditions.push('(TIEU_DE LIKE @search OR NOI_DUNG LIKE @search)');
      params.search = `%${search}%`;
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    try {
      // Get total count
      const countQuery = `SELECT COUNT(*) as total FROM PHAN_HOI ${whereClause}`;
      const countResult = await this.executeQuery(countQuery, params);
      const total = countResult.recordset[0].total;

      // Get paginated data with user info
      const dataQuery = `
        SELECT 
          ph.*,
          nd.ho_ten as HO_TEN,
          nd.email as EMAIL_NGUOI_DUNG
        FROM PHAN_HOI ph
        LEFT JOIN dbo.nguoi_dung nd ON ph.MA_NGUOI_DUNG = nd.id
        ${whereClause}
        ORDER BY ph.NGAY_TAO DESC
        OFFSET @offset ROWS
        FETCH NEXT @limit ROWS ONLY
      `;

      params.offset = offset;
      params.limit = limit;

      const dataResult = await this.executeQuery(dataQuery, params);

      return {
        data: dataResult.recordset,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: total,
          pages: Math.ceil(total / limit)
        }
      };
    } catch (error) {
      console.error('Error getting feedbacks:', error);
      throw error;
    }
  }

  /**
   * Lấy phản hồi theo ID với thông tin người dùng
   */
  async getFeedbackById(id) {
    const query = `
      SELECT 
        ph.*,
        nd.ho_ten as HO_TEN,
        nd.email as EMAIL_NGUOI_DUNG,
        nd.anh_dai_dien as ANH_DAI_DIEN
      FROM PHAN_HOI ph
      LEFT JOIN dbo.nguoi_dung nd ON ph.MA_NGUOI_DUNG = nd.id
      WHERE ph.MA_PHAN_HOI = @id
    `;

    try {
      const result = await this.executeQuery(query, { id });
      return result.recordset[0];
    } catch (error) {
      console.error('Error getting feedback by ID:', error);
      throw error;
    }
  }

  /**
   * Tạo phản hồi mới
   */
  async createFeedback(feedbackData) {
    const {
      ma_nguoi_dung,
      tieu_de,
      noi_dung,
      loai_phan_hoi,
      uu_tien = 2,
      hinh_anh = null
    } = feedbackData;

    const query = `
      INSERT INTO PHAN_HOI (
        MA_NGUOI_DUNG,
        TIEU_DE,
        NOI_DUNG,
        LOAI_PHAN_HOI,
        TRANG_THAI,
        UU_TIEN,
        HINH_ANH,
        NGAY_TAO,
        NGAY_CAP_NHAT
      ) VALUES (
        @ma_nguoi_dung,
        @tieu_de,
        @noi_dung,
        @loai_phan_hoi,
        'pending',
        @uu_tien,
        @hinh_anh,
        GETDATE(),
        GETDATE()
      );
      SELECT SCOPE_IDENTITY() as MA_PHAN_HOI;
    `;

    try {
      const result = await this.executeQuery(query, {
        ma_nguoi_dung,
        tieu_de,
        noi_dung,
        loai_phan_hoi,
        uu_tien,
        hinh_anh
      });

      const newId = result.recordset[0].MA_PHAN_HOI;
      return await this.getFeedbackById(newId);
    } catch (error) {
      console.error('Error creating feedback:', error);
      throw error;
    }
  }

  /**
   * Cập nhật phản hồi
   */
  async updateFeedback(id, updateData) {
    const {
      trang_thai,
      phan_hoi_admin,
      uu_tien,
      ngay_phan_hoi
    } = updateData;

    const query = `
      UPDATE PHAN_HOI
      SET 
        TRANG_THAI = COALESCE(@trang_thai, TRANG_THAI),
        PHAN_HOI_ADMIN = COALESCE(@phan_hoi_admin, PHAN_HOI_ADMIN),
        UU_TIEN = COALESCE(@uu_tien, UU_TIEN),
        NGAY_PHAN_HOI = COALESCE(@ngay_phan_hoi, NGAY_PHAN_HOI),
        NGAY_CAP_NHAT = GETDATE()
      WHERE MA_PHAN_HOI = @id
    `;

    try {
      await this.executeQuery(query, {
        id,
        trang_thai: trang_thai || null,
        phan_hoi_admin: phan_hoi_admin || null,
        uu_tien: uu_tien || null,
        ngay_phan_hoi: ngay_phan_hoi || null
      });

      return await this.getFeedbackById(id);
    } catch (error) {
      console.error('Error updating feedback:', error);
      throw error;
    }
  }

  /**
   * Phản hồi từ admin
   */
  async respondToFeedback(id, response, status) {
    const query = `
      UPDATE PHAN_HOI
      SET 
        PHAN_HOI_ADMIN = @response,
        TRANG_THAI = @status,
        NGAY_PHAN_HOI = GETDATE(),
        NGAY_CAP_NHAT = GETDATE()
      WHERE MA_PHAN_HOI = @id
    `;

    try {
      await this.executeQuery(query, { id, response, status });
      return await this.getFeedbackById(id);
    } catch (error) {
      console.error('Error responding to feedback:', error);
      throw error;
    }
  }

  /**
   * Cập nhật trạng thái
   */
  async updateStatus(id, status) {
    const query = `
      UPDATE PHAN_HOI
      SET 
        TRANG_THAI = @status,
        NGAY_CAP_NHAT = GETDATE()
      WHERE MA_PHAN_HOI = @id
    `;

    try {
      await this.executeQuery(query, { id, status });
      return await this.getFeedbackById(id);
    } catch (error) {
      console.error('Error updating status:', error);
      throw error;
    }
  }

  /**
   * Xóa phản hồi
   */
  async deleteFeedback(id) {
    const query = `DELETE FROM PHAN_HOI WHERE MA_PHAN_HOI = @id`;
    
    try {
      await this.executeQuery(query, { id });
      return true;
    } catch (error) {
      console.error('Error deleting feedback:', error);
      throw error;
    }
  }

  /**
   * Lấy thống kê phản hồi
   */
  async getStatistics(fromDate = null, toDate = null) {
    let dateCondition = '';
    const params = {};

    if (fromDate && toDate) {
      dateCondition = 'WHERE NGAY_TAO BETWEEN @fromDate AND @toDate';
      params.fromDate = fromDate;
      params.toDate = toDate;
    }

    const query = `
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN TRANG_THAI = 'pending' THEN 1 ELSE 0 END) as pending,
        SUM(CASE WHEN TRANG_THAI = 'in_progress' THEN 1 ELSE 0 END) as in_progress,
        SUM(CASE WHEN TRANG_THAI = 'resolved' THEN 1 ELSE 0 END) as resolved,
        SUM(CASE WHEN TRANG_THAI = 'closed' THEN 1 ELSE 0 END) as closed,
        SUM(CASE WHEN LOAI_PHAN_HOI = 'complaint' THEN 1 ELSE 0 END) as complaints,
        SUM(CASE WHEN LOAI_PHAN_HOI = 'suggestion' THEN 1 ELSE 0 END) as suggestions,
        SUM(CASE WHEN LOAI_PHAN_HOI = 'compliment' THEN 1 ELSE 0 END) as compliments,
        SUM(CASE WHEN LOAI_PHAN_HOI = 'question' THEN 1 ELSE 0 END) as questions,
        SUM(CASE WHEN UU_TIEN >= 4 THEN 1 ELSE 0 END) as high_priority
      FROM PHAN_HOI
      ${dateCondition}
    `;

    try {
      const result = await this.executeQuery(query, params);
      return result.recordset[0];
    } catch (error) {
      console.error('Error getting statistics:', error);
      throw error;
    }
  }

  /**
   * Lấy feedback của user
   */
  async getUserFeedbacks(userId, options = {}) {
    const { page = 1, limit = 20, status = null } = options;
    const offset = (page - 1) * limit;

    let conditions = ['MA_NGUOI_DUNG = @userId'];
    const params = { userId };

    if (status) {
      conditions.push('TRANG_THAI = @status');
      params.status = status;
    }

    const whereClause = `WHERE ${conditions.join(' AND ')}`;

    try {
      // Get total count
      const countQuery = `SELECT COUNT(*) as total FROM PHAN_HOI ${whereClause}`;
      const countResult = await this.executeQuery(countQuery, params);
      const total = countResult.recordset[0].total;

      // Get paginated data
      const dataQuery = `
        SELECT *
        FROM PHAN_HOI
        ${whereClause}
        ORDER BY NGAY_TAO DESC
        OFFSET @offset ROWS
        FETCH NEXT @limit ROWS ONLY
      `;

      params.offset = offset;
      params.limit = limit;

      const dataResult = await this.executeQuery(dataQuery, params);

      return {
        data: dataResult.recordset,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: total,
          pages: Math.ceil(total / limit)
        }
      };
    } catch (error) {
      console.error('Error getting user feedbacks:', error);
      throw error;
    }
  }
}

module.exports = new PhanHoi();

