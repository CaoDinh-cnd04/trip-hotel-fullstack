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
      target_audience, // Frontend sends this
      send_email, // Frontend sends this instead of gui_email
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

    // Map target_audience from frontend format to backend format
    const targetAudienceMapping = {
      'all': 'all',
      'users': 'user',
      'user': 'user',
      'hotel_managers': 'hotel_manager',
      'hotel_manager': 'hotel_manager',
      'admins': 'admin',
      'admin': 'admin'
    };
    const mappedTargetAudience = targetAudienceMapping[target_audience] || targetAudienceMapping[doi_tuong_nhan] || 'all';
    
    // Map send_email to gui_email
    const shouldSendEmail = send_email === true || send_email === 'true' || gui_email === true || gui_email === 'true';
    
    // Create notification
    const notificationData = {
      tieu_de: finalTitle,
      noi_dung: finalContent,
      loai_thong_bao: mappedType,
      url_hinh_anh: finalImageUrl || null,
      url_hanh_dong: finalActionUrl || null,
      van_ban_nut: finalActionText || null,
      khach_san_id: finalHotelId || null,
      ngay_het_han: finalExpiresAt || null,
      doi_tuong_nhan: mappedTargetAudience, // 'all', 'user', 'hotel_manager', 'admin', 'specific_user'
      nguoi_dung_id: nguoi_dung_id || null,
      gui_email: shouldSendEmail, // Ensure boolean
      nguoi_tao_id: req.user.id, // From auth middleware
      hien_thi: true
    };

    console.log('📝 Creating notification with data:', {
      title: finalTitle,
      type: mappedType,
      targetAudience: mappedTargetAudience,
      sendEmail: notificationData.gui_email,
      originalTargetAudience: target_audience || doi_tuong_nhan
    });

    console.log('📝 Creating notification with notificationData:', JSON.stringify(notificationData, null, 2));
    
    const notification = await ThongBao.create(notificationData);
    const notificationId = notification?.id || notification?.ma_thong_bao;
    console.log('✅ Notification created with ID:', notificationId);
    console.log('📋 Created notification data:', {
      id: notificationId,
      tieu_de: notification?.tieu_de,
      doi_tuong_nhan: notification?.doi_tuong_nhan,
      hien_thi: notification?.hien_thi,
      gui_email: notification?.gui_email
    });

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
    // shouldSendEmail already declared above at line 89, reuse it
    // Check if we should send email based on notificationData.gui_email
    const shouldSendEmailNow = notificationData.gui_email === true;
    
    console.log('📧 Email sending check:', {
      shouldSendEmail: shouldSendEmailNow,
      gui_email: notificationData.gui_email,
      notificationId: notification?.id || notification?.ma_thong_bao,
      hasNotification: !!notification
    });
    
    if (shouldSendEmailNow && notification) {
      console.log('📧 Attempting to send email notifications...');
      const notificationId = notification.id || notification.ma_thong_bao;
      
      try {
        console.log(`🔍 Getting users for notification ID: ${notificationId}`);
        console.log(`📋 Notification target audience: ${notification.doi_tuong_nhan || notificationData.doi_tuong_nhan}`);
        
        const users = await ThongBao.getUsersForEmailNotification(notificationId);
        console.log(`📬 Found ${users.length} users to send emails to`);
        
        if (users.length > 0) {
          console.log(`📧 Sending emails to ${users.length} users...`);
          console.log(`📧 First user sample:`, {
            id: users[0]?.id,
            email: users[0]?.email,
            ho_ten: users[0]?.ho_ten,
            nhan_thong_bao_email: users[0]?.nhan_thong_bao_email
          });
          
          emailResults = await emailService.sendBulkNotificationEmails(users, notification);
          console.log('✅ Email sending completed:', emailResults);
        } else {
          console.log('⚠️  No users found to send emails to');
          console.log('💡 Possible reasons:');
          console.log('   - Users have nhan_thong_bao_email = 0 (disabled)');
          console.log('   - Users have trang_thai = 0 (inactive)');
          console.log('   - Target audience filter does not match any users');
          console.log(`   - Notification doi_tuong_nhan: ${notification.doi_tuong_nhan || notificationData.doi_tuong_nhan}`);
          
          // Debug: Check total users
          try {
            const { getPool } = require('../config/db');
            const sql = require('mssql');
            const pool = await getPool();
            const totalUsersResult = await pool.request().query(`
              SELECT COUNT(*) as total FROM nguoi_dung WHERE trang_thai = CAST(1 AS BIT)
            `);
            const totalActiveUsers = totalUsersResult.recordset[0]?.total || 0;
            
            const emailEnabledUsersResult = await pool.request().query(`
              SELECT COUNT(*) as total FROM nguoi_dung 
              WHERE trang_thai = CAST(1 AS BIT) AND nhan_thong_bao_email = CAST(1 AS BIT)
            `);
            const emailEnabledUsers = emailEnabledUsersResult.recordset[0]?.total || 0;
            
            console.log(`📊 Debug stats: ${totalActiveUsers} active users, ${emailEnabledUsers} with email notifications enabled`);
          } catch (debugError) {
            console.error('Error getting debug stats:', debugError);
          }
        }
      } catch (emailError) {
        console.error('❌ Error sending emails:', emailError);
        console.error('❌ Error stack:', emailError.stack);
        // Don't fail the notification creation if email fails
        emailResults = { 
          error: emailError.message,
          stack: process.env.NODE_ENV === 'development' ? emailError.stack : undefined
        };
      }
    } else {
      console.log('📭 Email sending skipped:', {
        shouldSendEmail: shouldSendEmailNow,
        gui_email: notificationData.gui_email,
        hasNotification: !!notification
      });
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

// Public: Get public notifications (no auth required) - FOR GUEST USERS
exports.getPublicNotifications = async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;

    console.log(`📬 Getting public notifications, page=${page}, limit=${limit}`);

    // Lấy thông báo public (doi_tuong_nhan = 'all')
    const { getPool } = require('../config/db');
    const pool = await getPool();
    
    const offset = (parseInt(page) - 1) * parseInt(limit);
    
    const result = await pool.request()
      .input('limit', parseInt(limit))
      .input('offset', offset)
      .query(`
        SELECT 
          id,
          tieu_de,
          noi_dung,
          loai_thong_bao,
          url_hinh_anh,
          url_hanh_dong,
          van_ban_nut,
          ngay_tao,
          0 as is_read
        FROM thong_bao
        WHERE hien_thi = CAST(1 AS BIT)
          AND doi_tuong_nhan = 'all'
          AND (ngay_het_han IS NULL OR ngay_het_han > GETDATE())
        ORDER BY ngay_tao DESC
        OFFSET @offset ROWS
        FETCH NEXT @limit ROWS ONLY
      `);

    const countResult = await pool.request()
      .query(`
        SELECT COUNT(*) as total
        FROM thong_bao
        WHERE hien_thi = CAST(1 AS BIT)
          AND doi_tuong_nhan = 'all'
          AND (ngay_het_han IS NULL OR ngay_het_han > GETDATE())
      `);

    const total = countResult.recordset[0]?.total || 0;
    const totalPages = Math.ceil(total / parseInt(limit));

    console.log(`✅ Found ${result.recordset.length} public notifications`);

    res.json({
      success: true,
      data: result.recordset || [],
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: total,
        totalPages: totalPages
      }
    });
  } catch (error) {
    console.error('❌ Get public notifications error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy thông báo',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// User: Get notifications (with auto fallback to public for guests)
exports.getNotifications = async (req, res) => {
  try {
    // Check if user is authenticated
    if (!req.user || !req.user.id) {
      // User not authenticated -> return public notifications instead
      console.log('⚠️ No authenticated user, returning public notifications');
      return exports.getPublicNotifications(req, res);
    }

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
    // Guest users have 0 unread
    if (!req.user || !req.user.id) {
      console.log('ℹ️ Guest user requesting unread count, returning 0');
      return res.json({
        success: true,
        data: { unread_count: 0 }
      });
    }

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

