// controllers/notificationController.js - Notification management
const ThongBao = require('../models/thongbao');
const emailService = require('../services/emailService');

// Admin: Create notification (and send emails)
exports.createNotification = async (req, res) => {
  try {
    // Support both Vietnamese and English field names
    const {
      // Vietnamese field names
      tieu_de,
      noi_dung,
      loai_thong_bao,
      url_hinh_anh,
      url_hanh_dong,
      van_ban_nut,
      khach_san_id,
      ngay_het_han,
      doi_tuong_nhan,
      nguoi_dung_id,
      gui_email,
      // English field names (from frontend)
      title,
      content,
      type,
      image_url,
      action_url,
      action_text,
      hotel_id,
      expires_at,
      metadata
    } = req.body;

    // Map English fields to Vietnamese if provided
    const finalTitle = title || tieu_de;
    const finalContent = content || noi_dung;
    const finalType = type || loai_thong_bao;
    const finalImageUrl = image_url || url_hinh_anh;
    const finalActionUrl = action_url || url_hanh_dong;
    const finalActionText = action_text || van_ban_nut;
    const finalHotelId = hotel_id || khach_san_id;
    
    // Parse expires_at if it's an ISO string
    let finalExpiresAt = expires_at || ngay_het_han;
    if (finalExpiresAt && typeof finalExpiresAt === 'string') {
      try {
        // Try parsing ISO 8601 format
        const parsedDate = new Date(finalExpiresAt);
        if (!isNaN(parsedDate.getTime())) {
          finalExpiresAt = parsedDate;
        }
      } catch (e) {
        console.warn('⚠️ Could not parse expires_at date:', finalExpiresAt);
      }
    }

    // Validate required fields
    if (!finalTitle || !finalContent || !finalType) {
      return res.status(400).json({
        success: false,
        message: 'Thiếu thông tin bắt buộc (title/tieu_de, content/noi_dung, type/loai_thong_bao)'
      });
    }

    // Map notification type from English to Vietnamese if needed
    const typeMapping = {
      'promotion': 'Ưu đãi',
      'new_room': 'Phòng mới',
      'app_program': 'Chương trình app',
      'booking_success': 'Đặt phòng thành công'
    };
    const mappedType = typeMapping[finalType] || finalType;

    // Create notification
    // Always set doi_tuong_nhan to 'all' for public notifications unless specifically set
    const targetAudience = doi_tuong_nhan || 'all';
    
    const notificationData = {
      tieu_de: finalTitle,
      noi_dung: finalContent,
      loai_thong_bao: mappedType,
      url_hinh_anh: finalImageUrl || null,
      url_hanh_dong: finalActionUrl || null,
      van_ban_nut: finalActionText || null,
      khach_san_id: finalHotelId || null,
      ngay_het_han: finalExpiresAt || null,
      doi_tuong_nhan: targetAudience, // 'all', 'user', 'hotel_manager', 'specific_user'
      nguoi_dung_id: nguoi_dung_id || null,
      gui_email: gui_email === true || gui_email === 'true', // Ensure boolean
      nguoi_tao_id: req.user.id, // From auth middleware
      hien_thi: true
    };

    console.log('📝 Creating notification with data:', {
      title: finalTitle,
      type: mappedType,
      targetAudience: targetAudience,
      sendEmail: notificationData.gui_email
    });

    const notification = await ThongBao.create(notificationData);
    const notificationId = notification?.id || notification?.ma_thong_bao;
    console.log('✅ Notification created with ID:', notificationId);

    // Format response for frontend (map Vietnamese fields to English)
    const formattedNotification = {
      id: notification?.id || notification?.ma_thong_bao || null,
      title: notification?.tieu_de || finalTitle,
      content: notification?.noi_dung || finalContent,
      type: notification?.loai_thong_bao || mappedType,
      image_url: notification?.url_hinh_anh || finalImageUrl || null,
      action_url: notification?.url_hanh_dong || finalActionUrl || null,
      action_text: notification?.van_ban_nut || finalActionText || null,
      hotel_id: notification?.khach_san_id || finalHotelId || null,
      expires_at: notification?.ngay_het_han || finalExpiresAt || null,
      created_at: notification?.ngay_tao || new Date().toISOString(),
      is_read: false,
      sender_name: null,
      sender_type: 'admin',
      metadata: null
    };

    // Send emails if requested
    let emailResults = null;
    const shouldSendEmail = notificationData.gui_email === true;
    
    if (shouldSendEmail && notification) {
      console.log('📧 Attempting to send email notifications...');
      const notificationId = notification.id || notification.ma_thong_bao;
      
      try {
        const users = await ThongBao.getUsersForEmailNotification(notificationId);
        console.log(`📬 Found ${users.length} users to send emails to`);
        
        if (users.length > 0) {
          emailResults = await emailService.sendBulkNotificationEmails(users, notification);
          console.log('✅ Email sending completed:', emailResults);
        } else {
          console.log('⚠️  No users found to send emails to (check nhan_thong_bao_email setting)');
        }
      } catch (emailError) {
        console.error('❌ Error sending emails:', emailError);
        // Don't fail the notification creation if email fails
        emailResults = { error: emailError.message };
      }
    } else {
      console.log('📭 Email sending skipped (gui_email = false)');
    }

    res.status(201).json({
      success: true,
      message: 'Tạo thông báo thành công',
      data: formattedNotification,
      emailResults
    });
  } catch (error) {
    console.error('Create notification error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi tạo thông báo',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// User: Get notifications
exports.getNotifications = async (req, res) => {
  try {
    const userId = req.user.id;
    const { page = 1, limit = 20, unreadOnly = false } = req.query;

    console.log(`📬 Getting notifications for user ${userId}, page=${page}, limit=${limit}, unreadOnly=${unreadOnly}`);

    const result = await ThongBao.getForUser(userId, {
      page: parseInt(page),
      limit: parseInt(limit),
      unreadOnly: unreadOnly === 'true'
    });

    console.log(`✅ Found ${result.data?.length || 0} notifications for user ${userId}`);
    if (result.data && result.data.length > 0) {
      console.log('📋 Sample notification:', {
        id: result.data[0].id || result.data[0].ma_thong_bao,
        title: result.data[0].tieu_de,
        type: result.data[0].loai_thong_bao,
        target: result.data[0].doi_tuong_nhan,
        visible: result.data[0].hien_thi
      });
    }

    res.json({
      success: true,
      data: result.data || [],
      pagination: result.pagination || {
        page: parseInt(page),
        limit: parseInt(limit),
        total: 0,
        totalPages: 0
      }
    });
  } catch (error) {
    console.error('❌ Get notifications error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy thông báo',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// User: Mark notification as read
exports.markAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    await ThongBao.markAsRead(id, userId);

    res.json({
      success: true,
      message: 'Đánh dấu đã đọc thành công'
    });
  } catch (error) {
    console.error('Mark as read error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi đánh dấu đã đọc'
    });
  }
};

// User: Get unread count
exports.getUnreadCount = async (req, res) => {
  try {
    const userId = req.user.id;
    console.log(`🔔 Getting unread count for user ${userId}`);
    
    const count = await ThongBao.getUnreadCount(userId);
    console.log(`✅ User ${userId} has ${count} unread notifications`);

    res.json({
      success: true,
      data: { unread_count: count }
    });
  } catch (error) {
    console.error('❌ Get unread count error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy số thông báo chưa đọc',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Admin: Get all notifications
exports.getAllNotifications = async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;

    const result = await ThongBao.findAll({
      page: parseInt(page),
      limit: parseInt(limit),
      orderBy: 'ngay_tao DESC'
    });

    res.json({
      success: true,
      data: result.data || result,
      pagination: result.pagination
    });
  } catch (error) {
    console.error('Get all notifications error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy danh sách thông báo'
    });
  }
};

// Admin: Update notification
exports.updateNotification = async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = { ...req.body, ngay_cap_nhat: new Date() };

    const notification = await ThongBao.update(id, updateData);

    res.json({
      success: true,
      message: 'Cập nhật thông báo thành công',
      data: notification
    });
  } catch (error) {
    console.error('Update notification error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi cập nhật thông báo'
    });
  }
};

// Admin: Delete notification
exports.deleteNotification = async (req, res) => {
  try {
    const { id } = req.params;

    // Soft delete by hiding
    await ThongBao.update(id, { hien_thi: false });

    res.json({
      success: true,
      message: 'Xóa thông báo thành công'
    });
  } catch (error) {
    console.error('Delete notification error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi xóa thông báo'
    });
  }
};

