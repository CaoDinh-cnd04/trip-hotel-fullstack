const { getPool } = require('../config/db');
const sql = require('mssql');
const emailService = require('../services/emailService');

/**
 * Send email notification when user sends message to hotel manager
 */
exports.notifyHotelManager = async (req, res) => {
  try {
    const { 
      hotel_manager_id, 
      user_name, 
      user_email,
      hotel_name, 
      booking_id, 
      message_content 
    } = req.body;

    console.log('📧 Sending chat notification email to hotel manager:', hotel_manager_id);

    // Get hotel manager email from database
    const pool = await getPool();
    const managerQuery = `
      SELECT email, ho_ten 
      FROM nguoi_dung 
      WHERE id = @manager_id
    `;
    
    const result = await pool.request()
      .input('manager_id', sql.Int, hotel_manager_id)
      .query(managerQuery);

    if (result.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy quản lý khách sạn'
      });
    }

    const manager = result.recordset[0];
    const managerEmail = manager.email;
    const managerName = manager.ho_ten;

    // Send email notification
    const emailSubject = `💬 Tin nhắn mới từ khách hàng - ${hotel_name}`;
    const emailHtml = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #8B4513;">🏨 Tin nhắn mới từ khách hàng</h2>
        
        <div style="background-color: #f5f5f5; padding: 20px; border-radius: 8px; margin: 20px 0;">
          <p><strong>Khách sạn:</strong> ${hotel_name}</p>
          <p><strong>Mã đặt phòng:</strong> ${booking_id}</p>
          <p><strong>Khách hàng:</strong> ${user_name} (${user_email})</p>
        </div>

        <div style="background-color: #fff3cd; padding: 15px; border-left: 4px solid #ffc107; margin: 20px 0;">
          <p><strong>Nội dung tin nhắn:</strong></p>
          <p style="white-space: pre-wrap;">${message_content}</p>
        </div>

        <div style="margin-top: 30px; padding: 20px; background-color: #e7f3ff; border-radius: 8px;">
          <p><strong>💡 Để trả lời:</strong></p>
          <ol>
            <li>Mở ứng dụng Hotel Management</li>
            <li>Vào mục "Tin nhắn" hoặc "Chat"</li>
            <li>Tìm cuộc trò chuyện với ${user_name}</li>
            <li>Nhắn tin trực tiếp qua app</li>
          </ol>
        </div>

        <p style="margin-top: 30px; color: #666; font-size: 12px;">
          Email này được gửi tự động từ hệ thống đặt phòng khách sạn.
        </p>
      </div>
    `;

    await emailService.sendEmail(managerEmail, emailSubject, emailHtml);

    console.log(`✅ Email notification sent to ${managerEmail}`);

    // Log to database for tracking
    const logQuery = `
      INSERT INTO chat_notifications (
        hotel_manager_id,
        user_email,
        booking_id,
        notification_type,
        sent_at
      ) VALUES (
        @manager_id,
        @user_email,
        @booking_id,
        'email',
        GETDATE()
      )
    `;

    await pool.request()
      .input('manager_id', sql.Int, hotel_manager_id)
      .input('user_email', sql.VarChar, user_email)
      .input('booking_id', sql.VarChar, booking_id)
      .query(logQuery)
      .catch(err => {
        // Ignore if table doesn't exist
        console.log('⚠️ Could not log notification (table may not exist):', err.message);
      });

    res.json({
      success: true,
      message: 'Đã gửi thông báo email đến quản lý',
      data: {
        manager_email: managerEmail,
        manager_name: managerName
      }
    });

  } catch (error) {
    console.error('❌ Error sending chat notification:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi gửi thông báo email',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

/**
 * Send email notification to user when manager replies
 */
exports.notifyUser = async (req, res) => {
  try {
    const { 
      user_email, 
      manager_name, 
      hotel_name, 
      booking_id, 
      message_content 
    } = req.body;

    console.log('📧 Sending chat notification email to user:', user_email);

    const emailSubject = `💬 Phản hồi từ ${hotel_name}`;
    const emailHtml = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #8B4513;">🏨 Bạn có tin nhắn mới từ khách sạn</h2>
        
        <div style="background-color: #f5f5f5; padding: 20px; border-radius: 8px; margin: 20px 0;">
          <p><strong>Từ:</strong> ${manager_name} - Quản lý ${hotel_name}</p>
          <p><strong>Mã đặt phòng:</strong> ${booking_id}</p>
        </div>

        <div style="background-color: #d4edda; padding: 15px; border-left: 4px solid #28a745; margin: 20px 0;">
          <p><strong>Nội dung:</strong></p>
          <p style="white-space: pre-wrap;">${message_content}</p>
        </div>

        <div style="margin-top: 30px; text-align: center;">
          <p>Mở ứng dụng để xem và trả lời tin nhắn</p>
        </div>

        <p style="margin-top: 30px; color: #666; font-size: 12px;">
          Email này được gửi tự động từ hệ thống đặt phòng khách sạn.
        </p>
      </div>
    `;

    await emailService.sendEmail(user_email, emailSubject, emailHtml);

    console.log(`✅ Email notification sent to ${user_email}`);

    res.json({
      success: true,
      message: 'Đã gửi thông báo email đến khách hàng'
    });

  } catch (error) {
    console.error('❌ Error sending user notification:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi gửi thông báo email'
    });
  }
};

