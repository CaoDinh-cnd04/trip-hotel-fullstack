const phanHoiModel = require('../models/phanHoi');
const emailService = require('../services/emailService');

/**
 * Lấy tất cả phản hồi (Admin only) với filters
 */
exports.getAllFeedbacks = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 20,
      status,
      type,
      priority,
      user_id,
      search
    } = req.query;

    console.log('📊 Getting feedbacks with filters:', {
      page, limit, status, type, priority, user_id, search
    });

    const result = await phanHoiModel.getAllFeedbacks({
      page: parseInt(page),
      limit: parseInt(limit),
      status: status && status !== 'all' ? status : null,
      type: type && type !== 'all' ? type : null,
      priority: priority ? parseInt(priority) : null,
      userId: user_id ? parseInt(user_id) : null,
      search
    });

    // Map to frontend expected format
    const mappedData = result.data.map(item => ({
      id: item.MA_PHAN_HOI,
      nguoiDungId: item.MA_NGUOI_DUNG,
      tieuDe: item.TIEU_DE,
      noiDung: item.NOI_DUNG,
      loaiPhanHoi: item.LOAI_PHAN_HOI,
      trangThai: item.TRANG_THAI,
      uuTien: item.UU_TIEN,
      hinhAnh: item.HINH_ANH,
      phanHoiAdmin: item.PHAN_HOI_ADMIN,
      ngayTao: item.NGAY_TAO,
      ngayCapNhat: item.NGAY_CAP_NHAT,
      ngayPhanHoi: item.NGAY_PHAN_HOI,
      hoTen: item.HO_TEN,
      email: item.EMAIL_NGUOI_DUNG
    }));

    res.json({
      success: true,
      data: mappedData,
      pagination: result.pagination
    });
  } catch (error) {
    console.error('Error getting feedbacks:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi lấy danh sách phản hồi',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

/**
 * Lấy chi tiết 1 phản hồi
 */
exports.getFeedbackById = async (req, res) => {
  try {
    const { id } = req.params;
    const feedback = await phanHoiModel.getFeedbackById(parseInt(id));

    if (!feedback) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy phản hồi'
      });
    }

    // Map to frontend format
    const mappedData = {
      id: feedback.MA_PHAN_HOI,
      nguoiDungId: feedback.MA_NGUOI_DUNG,
      tieuDe: feedback.TIEU_DE,
      noiDung: feedback.NOI_DUNG,
      loaiPhanHoi: feedback.LOAI_PHAN_HOI,
      trangThai: feedback.TRANG_THAI,
      uuTien: feedback.UU_TIEN,
      hinhAnh: feedback.HINH_ANH,
      phanHoiAdmin: feedback.PHAN_HOI_ADMIN,
      ngayTao: feedback.NGAY_TAO,
      ngayCapNhat: feedback.NGAY_CAP_NHAT,
      ngayPhanHoi: feedback.NGAY_PHAN_HOI,
      hoTen: feedback.HO_TEN,
      email: feedback.EMAIL_NGUOI_DUNG,
      anhDaiDien: feedback.ANH_DAI_DIEN
    };

    res.json({
      success: true,
      data: mappedData
    });
  } catch (error) {
    console.error('Error getting feedback by ID:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi lấy thông tin phản hồi',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

/**
 * Tạo phản hồi mới
 */
exports.createFeedback = async (req, res) => {
  try {
    console.log('📥 Received feedback request body:', JSON.stringify(req.body, null, 2));
    
    // Support both Vietnamese and English field names
    const {
      subject,
      message,
      category,
      tieuDe,
      noiDung,
      loaiPhanHoi,
      uuTien,
      priority,
      hinhAnh,
      images
    } = req.body;
    
    const userId = req.user.id;
    
    // Use Vietnamese fields if available, otherwise use English
    const feedbackSubject = tieuDe || subject || 'Không có tiêu đề';
    const feedbackMessage = noiDung || message;
    const feedbackCategory = loaiPhanHoi || category || 'general';
    const feedbackPriority = uuTien || priority || 2;
    const feedbackImages = hinhAnh || images || null;
    
    console.log('✅ Mapped values:', {
      ma_nguoi_dung: userId,
      tieu_de: feedbackSubject,
      noi_dung: feedbackMessage,
      loai_phan_hoi: feedbackCategory,
      uu_tien: feedbackPriority
    });
    
    // Validate
    if (!feedbackMessage || feedbackMessage.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Nội dung phản hồi không được để trống'
      });
    }

    // Create feedback in database
    const newFeedback = await phanHoiModel.createFeedback({
      ma_nguoi_dung: userId,
      tieu_de: feedbackSubject,
      noi_dung: feedbackMessage,
      loai_phan_hoi: feedbackCategory,
      uu_tien: feedbackPriority,
      hinh_anh: feedbackImages ? JSON.stringify(feedbackImages) : null
    });

    console.log('✅ Feedback created successfully:', newFeedback.MA_PHAN_HOI);

    // Map response
    const mappedData = {
      id: newFeedback.MA_PHAN_HOI,
      nguoiDungId: newFeedback.MA_NGUOI_DUNG,
      tieuDe: newFeedback.TIEU_DE,
      noiDung: newFeedback.NOI_DUNG,
      loaiPhanHoi: newFeedback.LOAI_PHAN_HOI,
      trangThai: newFeedback.TRANG_THAI,
      uuTien: newFeedback.UU_TIEN,
      ngayTao: newFeedback.NGAY_TAO,
      ngayCapNhat: newFeedback.NGAY_CAP_NHAT
    };

    res.status(201).json({
      success: true,
      message: 'Cảm ơn bạn đã gửi phản hồi! Chúng tôi sẽ xem xét và phản hồi sớm.',
      data: mappedData
    });
  } catch (error) {
    console.error('❌ Error creating feedback:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi gửi phản hồi',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

/**
 * Admin phản hồi feedback
 */
exports.respondToFeedback = async (req, res) => {
  try {
    const { id } = req.params;
    const { admin_response, status, priority } = req.body;

    if (!admin_response || admin_response.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Nội dung phản hồi không được để trống'
      });
    }

    const updateData = {
      phan_hoi_admin: admin_response,
      trang_thai: status || 'in_progress',
      ngay_phan_hoi: new Date().toISOString()
    };

    if (priority) {
      updateData.uu_tien = parseInt(priority);
    }

    const updatedFeedback = await phanHoiModel.respondToFeedback(
      parseInt(id),
      admin_response,
      status || 'in_progress'
    );

    if (!updatedFeedback) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy phản hồi'
      });
    }

    // ✅ GỬI EMAIL THÔNG BÁO ĐẾN USER
    try {
      const userEmail = updatedFeedback.EMAIL_NGUOI_DUNG;
      const userName = updatedFeedback.HO_TEN || 'Quý khách';
      
      if (userEmail) {
        const emailSubject = `Phản hồi từ Admin - ${updatedFeedback.TIEU_DE}`;
        const emailHtml = `
          <!DOCTYPE html>
          <html>
          <head>
            <meta charset="UTF-8">
            <style>
              body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
              .container { max-width: 600px; margin: 0 auto; padding: 20px; }
              .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
              .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
              .feedback-box { background: white; padding: 20px; margin: 20px 0; border-left: 4px solid #667eea; border-radius: 5px; }
              .response-box { background: #e8f4fd; padding: 20px; margin: 20px 0; border-left: 4px solid #2196F3; border-radius: 5px; }
              .label { font-weight: bold; color: #667eea; margin-bottom: 10px; }
              .footer { text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; color: #666; font-size: 12px; }
              .btn { display: inline-block; padding: 12px 30px; background: #667eea; color: white; text-decoration: none; border-radius: 5px; margin-top: 20px; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>📬 Phản Hồi Từ Admin</h1>
                <p>Chúng tôi đã trả lời phản hồi của bạn</p>
              </div>
              
              <div class="content">
                <p>Xin chào <strong>${userName}</strong>,</p>
                <p>Cảm ơn bạn đã gửi phản hồi cho chúng tôi. Đội ngũ admin đã xem xét và phản hồi như sau:</p>
                
                <div class="feedback-box">
                  <div class="label">📝 Phản hồi của bạn:</div>
                  <p><strong>Tiêu đề:</strong> ${updatedFeedback.TIEU_DE}</p>
                  <p><strong>Nội dung:</strong> ${updatedFeedback.NOI_DUNG}</p>
                  <p><strong>Loại:</strong> ${updatedFeedback.LOAI_PHAN_HOI}</p>
                </div>
                
                <div class="response-box">
                  <div class="label">💬 Phản hồi từ Admin:</div>
                  <p>${admin_response}</p>
                  <p style="margin-top: 15px; color: #666; font-size: 14px;">
                    <strong>Trạng thái:</strong> ${status === 'resolved' ? 'Đã giải quyết' : status === 'in_progress' ? 'Đang xử lý' : 'Đang xem xét'}
                  </p>
                </div>
                
                <p>Nếu bạn có thắc mắc thêm, vui lòng trả lời email này hoặc liên hệ với chúng tôi.</p>
                
                <div style="text-align: center;">
                  <a href="mailto:support@hotel.com" class="btn">Liên Hệ Support</a>
                </div>
              </div>
              
              <div class="footer">
                <p>Email này được gửi tự động từ hệ thống Hotel Booking</p>
                <p>© ${new Date().getFullYear()} Hotel Booking System. All rights reserved.</p>
              </div>
            </div>
          </body>
          </html>
        `;
        
        await emailService.sendEmail(userEmail, emailSubject, emailHtml);
        console.log(`✅ Email notification sent to ${userEmail}`);
      }
    } catch (emailError) {
      console.error('⚠️ Failed to send email notification:', emailError);
      // Không throw error - vẫn trả về success cho response
    }

    // Map response
    const mappedData = {
      id: updatedFeedback.MA_PHAN_HOI,
      nguoiDungId: updatedFeedback.MA_NGUOI_DUNG,
      tieuDe: updatedFeedback.TIEU_DE,
      noiDung: updatedFeedback.NOI_DUNG,
      loaiPhanHoi: updatedFeedback.LOAI_PHAN_HOI,
      trangThai: updatedFeedback.TRANG_THAI,
      uuTien: updatedFeedback.UU_TIEN,
      phanHoiAdmin: updatedFeedback.PHAN_HOI_ADMIN,
      ngayTao: updatedFeedback.NGAY_TAO,
      ngayCapNhat: updatedFeedback.NGAY_CAP_NHAT,
      ngayPhanHoi: updatedFeedback.NGAY_PHAN_HOI,
      hoTen: updatedFeedback.HO_TEN,
      email: updatedFeedback.EMAIL_NGUOI_DUNG
    };

    res.json({
      success: true,
      message: 'Đã gửi phản hồi thành công và thông báo email đến người dùng',
      data: mappedData
    });
  } catch (error) {
    console.error('Error responding to feedback:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi phản hồi',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

/**
 * Cập nhật trạng thái feedback
 */
exports.updateFeedbackStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!status) {
      return res.status(400).json({
        success: false,
        message: 'Trạng thái không được để trống'
      });
    }

    const updatedFeedback = await phanHoiModel.updateStatus(parseInt(id), status);

    if (!updatedFeedback) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy phản hồi'
      });
    }

    // Map response
    const mappedData = {
      id: updatedFeedback.MA_PHAN_HOI,
      nguoiDungId: updatedFeedback.MA_NGUOI_DUNG,
      tieuDe: updatedFeedback.TIEU_DE,
      noiDung: updatedFeedback.NOI_DUNG,
      loaiPhanHoi: updatedFeedback.LOAI_PHAN_HOI,
      trangThai: updatedFeedback.TRANG_THAI,
      uuTien: updatedFeedback.UU_TIEN,
      ngayTao: updatedFeedback.NGAY_TAO,
      ngayCapNhat: updatedFeedback.NGAY_CAP_NHAT
    };

    res.json({
      success: true,
      message: 'Cập nhật trạng thái thành công',
      data: mappedData
    });
  } catch (error) {
    console.error('Error updating status:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi cập nhật trạng thái',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

/**
 * Xóa feedback
 */
exports.deleteFeedback = async (req, res) => {
  try {
    const { id } = req.params;
    
    await phanHoiModel.deleteFeedback(parseInt(id));

    res.json({
      success: true,
      message: 'Đã xóa phản hồi thành công'
    });
  } catch (error) {
    console.error('Error deleting feedback:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi xóa phản hồi',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

/**
 * Lấy thống kê phản hồi
 */
exports.getFeedbackStatistics = async (req, res) => {
  try {
    const { from_date, to_date } = req.query;

    const stats = await phanHoiModel.getStatistics(
      from_date || null,
      to_date || null
    );

    res.json({
      success: true,
      data: stats
    });
  } catch (error) {
    console.error('Error getting statistics:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi lấy thống kê',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

/**
 * Lấy feedback của user hiện tại
 */
exports.getUserFeedbacks = async (req, res) => {
  try {
    const userId = req.params.userId || req.user.id;
    const { page = 1, limit = 20, status } = req.query;

    const result = await phanHoiModel.getUserFeedbacks(parseInt(userId), {
      page: parseInt(page),
      limit: parseInt(limit),
      status: status && status !== 'all' ? status : null
    });

    // Map to frontend format
    const mappedData = result.data.map(item => ({
      id: item.MA_PHAN_HOI,
      nguoiDungId: item.MA_NGUOI_DUNG,
      tieuDe: item.TIEU_DE,
      noiDung: item.NOI_DUNG,
      loaiPhanHoi: item.LOAI_PHAN_HOI,
      trangThai: item.TRANG_THAI,
      uuTien: item.UU_TIEN,
      hinhAnh: item.HINH_ANH,
      phanHoiAdmin: item.PHAN_HOI_ADMIN,
      ngayTao: item.NGAY_TAO,
      ngayCapNhat: item.NGAY_CAP_NHAT,
      ngayPhanHoi: item.NGAY_PHAN_HOI
    }));

    res.json({
      success: true,
      data: mappedData,
      pagination: result.pagination
    });
  } catch (error) {
    console.error('Error getting user feedbacks:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi lấy danh sách phản hồi',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

