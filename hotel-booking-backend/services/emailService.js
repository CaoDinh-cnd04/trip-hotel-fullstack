const nodemailer = require('nodemailer');
const emailConfig = require('../config/email');

class EmailService {
  constructor() {
    this.config = emailConfig;
    this.transporter = null;
    
    if (this.config.enabled) {
      this.initializeTransporter();
    } else {
      console.log('⚠️  Email service is DISABLED');
      console.log('💡 To enable: Set EMAIL_ENABLED=true in environment variables');
      console.log('📝 Note: Notification system works without email delivery');
    }
  }

  initializeTransporter() {
    try {
      this.transporter = nodemailer.createTransport(this.config.smtp);
      
      // Verify connection
      this.transporter.verify((error, success) => {
        if (error) {
          console.error('❌ Email service error:', error.message);
          console.log('📧 Email sending will be disabled');
          this.transporter = null;
        } else {
          console.log('✅ Email service ready');
          console.log(`📧 Sending emails from: ${this.config.from.email}`);
          if (this.config.testMode) {
            console.log('⚠️  TEST MODE: Emails will be logged but not sent');
          }
        }
      });
    } catch (error) {
      console.error('❌ Failed to initialize email service:', error.message);
      this.transporter = null;
    }
  }

  async sendEmail(to, subject, html) {
    if (!this.config.enabled || !this.transporter) {
      console.log(`📧 [OFFLINE] Would send email to: ${to}`);
      return false;
    }

    try {
      const mailOptions = {
        from: `"${this.config.from.name}" <${this.config.from.email}>`,
        to: to,
        subject: subject,
        html: html
      };

      if (this.config.testMode) {
        console.log(`📧 [TEST MODE] Email to: ${to}`);
        console.log(`   Subject: ${subject}`);
        return true;
      }

      const info = await this.transporter.sendMail(mailOptions);
      console.log(`✅ Email sent to ${to}: ${info.messageId}`);
      return true;
    } catch (error) {
      console.error(`❌ Failed to send email to ${to}:`, error.message);
      return false;
    }
  }

  async sendNotificationEmail(to, notification) {
    if (!this.config.enabled || !this.transporter) {
      console.log(`📧 [OFFLINE] Would send email to: ${to}`);
      return false;
    }

    try {
      const mailOptions = {
        from: `"${this.config.from.name}" <${this.config.from.email}>`,
        to: to,
        subject: notification.tieu_de || 'Thông báo từ Hotel Management',
        html: this.buildNotificationHTML(notification),
        text: notification.noi_dung
      };

      if (this.config.testMode) {
        console.log(`📧 [TEST MODE] Email to: ${to}`);
        console.log(`   Subject: ${mailOptions.subject}`);
        return true;
      }

      const info = await this.transporter.sendMail(mailOptions);
      console.log(`✅ Email sent to ${to}: ${info.messageId}`);
      return true;
    } catch (error) {
      console.error(`❌ Failed to send email to ${to}:`, error.message);
      return false;
    }
  }

  async sendBulkNotificationEmails(users, notification) {
    console.log(`📧 sendBulkNotificationEmails called with ${users.length} users`);
    console.log(`📧 Email service enabled: ${this.config.enabled}`);
    console.log(`📧 Transporter available: ${!!this.transporter}`);
    
    if (!this.config.enabled || !this.transporter) {
      console.log(`📧 [OFFLINE] Would send email to ${users.length} users`);
      console.log(`💡 Email service status: enabled=${this.config.enabled}, transporter=${!!this.transporter}`);
      return {
        total: users.length,
        success: 0,
        failed: 0,
        offline: true,
        message: 'Email service is disabled or not configured'
      };
    }

    const results = {
      total: users.length,
      success: 0,
      failed: 0,
      errors: []
    };

    console.log(`📧 Starting to send ${users.length} emails...`);
    
    for (let i = 0; i < users.length; i++) {
      const user = users[i];
      console.log(`📧 [${i + 1}/${users.length}] Sending to: ${user.email}`);
      
      try {
        const sent = await this.sendNotificationEmail(user.email, notification);
        if (sent) {
          results.success++;
          console.log(`✅ [${i + 1}/${users.length}] Email sent successfully to ${user.email}`);
        } else {
          results.failed++;
          results.errors.push({ email: user.email, error: 'Send returned false' });
          console.log(`❌ [${i + 1}/${users.length}] Failed to send to ${user.email}`);
        }
      } catch (error) {
        results.failed++;
        results.errors.push({ email: user.email, error: error.message });
        console.error(`❌ [${i + 1}/${users.length}] Error sending to ${user.email}:`, error.message);
      }
      
      // Delay to avoid rate limiting
      if (i < users.length - 1) {
        await this.delay(100);
      }
    }

    console.log(`📧 Bulk email results: ${results.success}/${results.total} sent successfully`);
    if (results.failed > 0) {
      console.log(`⚠️  Failed emails: ${results.failed}`);
      console.log(`📋 Errors:`, results.errors);
    }
    
    return {
      ...results,
      success: results.success > 0
    };
  }

  async sendOTPEmail(to, otpCode, expiresIn = 5) {
    if (!this.config.enabled || !this.transporter) {
      console.log(`📧 [OFFLINE] Would send OTP ${otpCode} to: ${to}`);
      return false;
    }

    try {
      const mailOptions = {
        from: `"${this.config.from.name}" <${this.config.from.email}>`,
        to: to,
        subject: 'Mã OTP đăng nhập - Hotel Management',
        html: this.buildOTPHTML(otpCode, expiresIn),
        text: `Mã OTP của bạn là: ${otpCode}. Mã có hiệu lực trong ${expiresIn} phút.`
      };

      if (this.config.testMode) {
        console.log(`📧 [TEST MODE] OTP ${otpCode} to: ${to}`);
        return true;
      }

      const info = await this.transporter.sendMail(mailOptions);
      console.log(`✅ OTP email sent to ${to}: ${info.messageId}`);
      return true;
    } catch (error) {
      console.error(`❌ Failed to send OTP email to ${to}:`, error.message);
      return false;
    }
  }

  async sendBookingConfirmation(to, bookingDetails) {
    if (!this.config.enabled || !this.transporter) {
      console.log(`📧 [OFFLINE] Would send booking confirmation to: ${to}`);
      return false;
    }

    try {
      const mailOptions = {
        from: `"${this.config.from.name}" <${this.config.from.email}>`,
        to: to,
        subject: `Xác nhận đặt phòng #${bookingDetails.bookingCode} - ${bookingDetails.hotelName}`,
        html: this.buildBookingConfirmationHTML(bookingDetails),
        text: `Đặt phòng #${bookingDetails.bookingCode} tại ${bookingDetails.hotelName} đã được xác nhận.`
      };

      if (this.config.testMode) {
        console.log(`📧 [TEST MODE] Booking confirmation to: ${to}`);
        return true;
      }

      const info = await this.transporter.sendMail(mailOptions);
      console.log(`✅ Booking confirmation sent to ${to}: ${info.messageId}`);
      return true;
    } catch (error) {
      console.error(`❌ Failed to send booking confirmation to ${to}:`, error.message);
      return false;
    }
  }

  async sendMessageNotification(to, messageDetails) {
    if (!this.config.enabled || !this.transporter) {
      console.log(`📧 [OFFLINE] Would send message notification to: ${to}`);
      return false;
    }

    try {
      const mailOptions = {
        from: `"${this.config.from.name}" <${this.config.from.email}>`,
        to: to,
        subject: `💬 Tin nhắn mới từ ${messageDetails.senderName}`,
        html: this.buildMessageNotificationHTML(messageDetails),
        text: `Bạn có tin nhắn mới từ ${messageDetails.senderName}: ${messageDetails.content}`
      };

      if (this.config.testMode) {
        console.log(`📧 [TEST MODE] Message notification to: ${to}`);
        return true;
      }

      const info = await this.transporter.sendMail(mailOptions);
      console.log(`✅ Message notification sent to ${to}: ${info.messageId}`);
      return true;
    } catch (error) {
      console.error(`❌ Failed to send message notification to ${to}:`, error.message);
      return false;
    }
  }

  buildNotificationHTML(notification) {
    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
          .content { background: white; padding: 30px; border: 1px solid #ddd; border-top: none; border-radius: 0 0 8px 8px; }
          .footer { text-align: center; margin-top: 20px; color: #888; font-size: 12px; }
          .button { display: inline-block; padding: 12px 24px; background: #667eea; color: white; text-decoration: none; border-radius: 4px; margin-top: 20px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🏨 ${notification.tieu_de || 'Thông báo'}</h1>
          </div>
          <div class="content">
            <p>${notification.noi_dung || ''}</p>
            ${notification.link ? `<a href="${notification.link}" class="button">Xem chi tiết</a>` : ''}
          </div>
          <div class="footer">
            <p>Email được gửi tự động từ Hotel Management System</p>
            <p>Vui lòng không trả lời email này</p>
          </div>
        </div>
      </body>
      </html>
    `;
  }

  buildOTPHTML(otpCode, expiresIn) {
    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
          .content { background: white; padding: 30px; border: 1px solid #ddd; border-top: none; }
          .otp-box { background: #f8f9fa; border: 2px dashed #667eea; padding: 20px; text-align: center; margin: 20px 0; border-radius: 8px; }
          .otp-code { font-size: 32px; font-weight: bold; color: #667eea; letter-spacing: 8px; }
          .footer { text-align: center; margin-top: 20px; color: #888; font-size: 12px; border-radius: 0 0 8px 8px; background: white; padding: 20px; border: 1px solid #ddd; border-top: none; }
          .warning { color: #dc3545; font-weight: bold; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🔐 Mã OTP Đăng Nhập</h1>
          </div>
          <div class="content">
            <p>Xin chào,</p>
            <p>Bạn đã yêu cầu đăng nhập vào hệ thống Hotel Management. Đây là mã OTP của bạn:</p>
            <div class="otp-box">
              <div class="otp-code">${otpCode}</div>
            </div>
            <p>Mã OTP có hiệu lực trong <strong>${expiresIn} phút</strong>.</p>
            <p class="warning">⚠️ Không chia sẻ mã này với bất kỳ ai!</p>
            <p>Nếu bạn không yêu cầu mã này, vui lòng bỏ qua email này.</p>
          </div>
          <div class="footer">
            <p>Email được gửi tự động từ Hotel Management System</p>
            <p>Vui lòng không trả lời email này</p>
          </div>
        </div>
      </body>
      </html>
    `;
  }

  buildBookingConfirmationHTML(booking) {
    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
          .content { background: white; padding: 30px; border: 1px solid #ddd; border-top: none; }
          .booking-info { background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0; }
          .info-row { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #ddd; }
          .label { font-weight: bold; color: #666; }
          .value { color: #333; }
          .footer { text-align: center; margin-top: 20px; color: #888; font-size: 12px; border-radius: 0 0 8px 8px; background: white; padding: 20px; border: 1px solid #ddd; border-top: none; }
          .success { color: #28a745; font-weight: bold; font-size: 18px; text-align: center; margin: 20px 0; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>✅ Đặt Phòng Thành Công</h1>
          </div>
          <div class="content">
            <div class="success">🎉 Đặt phòng của bạn đã được xác nhận!</div>
            <div class="booking-info">
              <div class="info-row">
                <span class="label">Mã đặt phòng:</span>
                <span class="value">${booking.bookingCode}</span>
              </div>
              <div class="info-row">
                <span class="label">Khách sạn:</span>
                <span class="value">${booking.hotelName}</span>
              </div>
              <div class="info-row">
                <span class="label">Loại phòng:</span>
                <span class="value">${booking.roomType || 'N/A'}</span>
              </div>
              <div class="info-row">
                <span class="label">Check-in:</span>
                <span class="value">${booking.checkInDate}</span>
              </div>
              <div class="info-row">
                <span class="label">Check-out:</span>
                <span class="value">${booking.checkOutDate}</span>
              </div>
              <div class="info-row">
                <span class="label">Số đêm:</span>
                <span class="value">${booking.nights} đêm</span>
              </div>
              <div class="info-row">
                <span class="label">Tổng tiền:</span>
                <span class="value" style="color: #667eea; font-weight: bold;">${booking.totalPrice} VNĐ</span>
              </div>
            </div>
            <p>Cảm ơn bạn đã sử dụng dịch vụ của chúng tôi!</p>
            <p>Chúc bạn có một kỳ nghỉ vui vẻ! 🏖️</p>
          </div>
          <div class="footer">
            <p>Email được gửi tự động từ Hotel Management System</p>
            <p>Nếu có thắc mắc, vui lòng liên hệ: support@hotel.com</p>
          </div>
        </div>
      </body>
      </html>
    `;
  }

  buildMessageNotificationHTML(messageDetails) {
    const { senderName, senderRole, content, timestamp, hotelName, bookingCode } = messageDetails;
    
    const roleLabel = senderRole === 'hotel_manager' ? '🏨 Quản lý khách sạn' : 
                      senderRole === 'admin' ? '👨‍💼 Quản trị viên' : 
                      '👤 Khách hàng';
    
    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; background: #f5f5f5; margin: 0; padding: 0; }
          .container { max-width: 600px; margin: 20px auto; background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
          .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; }
          .header h1 { margin: 0; font-size: 24px; }
          .content { padding: 30px; }
          .message-box { background: #f8f9fa; border-left: 4px solid #667eea; padding: 20px; margin: 20px 0; border-radius: 8px; }
          .sender-info { margin-bottom: 15px; }
          .sender-name { font-weight: bold; color: #667eea; font-size: 16px; }
          .sender-role { color: #666; font-size: 14px; margin-left: 8px; }
          .message-content { font-size: 16px; line-height: 1.8; color: #333; white-space: pre-wrap; }
          .timestamp { color: #888; font-size: 12px; margin-top: 10px; }
          .booking-info { background: #e3f2fd; border-radius: 8px; padding: 15px; margin: 20px 0; }
          .booking-label { color: #1976d2; font-weight: bold; font-size: 14px; }
          .footer { background: #f8f9fa; padding: 20px; text-align: center; color: #666; font-size: 12px; }
          .button { display: inline-block; padding: 12px 30px; background: #667eea; color: white; text-decoration: none; border-radius: 6px; margin-top: 20px; font-weight: bold; }
          .button:hover { background: #5568d3; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>💬 Bạn Có Tin Nhắn Mới!</h1>
          </div>
          <div class="content">
            <p>Xin chào,</p>
            <p>Bạn vừa nhận được một tin nhắn mới trong hệ thống Hotel Management:</p>
            
            <div class="message-box">
              <div class="sender-info">
                <span class="sender-name">${senderName}</span>
                <span class="sender-role">${roleLabel}</span>
              </div>
              <div class="message-content">${content}</div>
              ${timestamp ? `<div class="timestamp">📅 ${new Date(timestamp).toLocaleString('vi-VN')}</div>` : ''}
            </div>
            
            ${hotelName || bookingCode ? `
              <div class="booking-info">
                ${hotelName ? `<div><span class="booking-label">🏨 Khách sạn:</span> ${hotelName}</div>` : ''}
                ${bookingCode ? `<div><span class="booking-label">📋 Mã đặt phòng:</span> ${bookingCode}</div>` : ''}
              </div>
            ` : ''}
            
            <p>Vui lòng đăng nhập vào ứng dụng để xem và trả lời tin nhắn.</p>
            
            <div style="text-align: center;">
              <a href="#" class="button">📱 Mở Ứng Dụng</a>
            </div>
          </div>
          <div class="footer">
            <p><strong>🔔 Mẹo:</strong> Bật thông báo trong ứng dụng để nhận tin nhắn ngay lập tức!</p>
            <p style="margin-top: 15px;">Email được gửi tự động từ Hotel Management System</p>
            <p>Vui lòng không trả lời email này</p>
          </div>
        </div>
      </body>
      </html>
    `;
  }

  delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

module.exports = new EmailService();
