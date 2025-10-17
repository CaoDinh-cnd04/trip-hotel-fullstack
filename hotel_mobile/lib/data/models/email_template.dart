class EmailTemplate {
  static String getBookingConfirmationTemplate(Map<String, dynamic> data) {
    return '''
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Xác nhận đặt phòng</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f4f4f4;
        }
        .container {
            background-color: #ffffff;
            border-radius: 10px;
            padding: 30px;
            box-shadow: 0 0 20px rgba(0,0,0,0.1);
        }
        .header {
            text-align: center;
            border-bottom: 3px solid #4CAF50;
            padding-bottom: 20px;
            margin-bottom: 30px;
        }
        .header h1 {
            color: #4CAF50;
            margin: 0;
            font-size: 28px;
        }
        .header p {
            color: #666;
            margin: 10px 0 0 0;
            font-size: 16px;
        }
        .booking-info {
            background-color: #f8f9fa;
            border-radius: 8px;
            padding: 20px;
            margin: 20px 0;
        }
        .info-row {
            display: flex;
            justify-content: space-between;
            margin: 10px 0;
            padding: 8px 0;
            border-bottom: 1px solid #e9ecef;
        }
        .info-row:last-child {
            border-bottom: none;
        }
        .info-label {
            font-weight: bold;
            color: #495057;
            min-width: 120px;
        }
        .info-value {
            color: #212529;
            text-align: right;
        }
        .highlight {
            background-color: #e8f5e8;
            color: #2e7d32;
            padding: 15px;
            border-radius: 8px;
            text-align: center;
            font-weight: bold;
            margin: 20px 0;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #e9ecef;
            color: #6c757d;
            font-size: 14px;
        }
        .contact-info {
            background-color: #e3f2fd;
            padding: 15px;
            border-radius: 8px;
            margin: 20px 0;
        }
        .contact-info h3 {
            color: #1976d2;
            margin: 0 0 10px 0;
        }
        .contact-info p {
            margin: 5px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>✅ Đặt phòng thành công!</h1>
            <p>Cảm ơn bạn đã chọn dịch vụ của chúng tôi</p>
        </div>

        <div class="highlight">
            🎉 Đặt phòng của bạn đã được xác nhận thành công!
        </div>

        <div class="booking-info">
            <h3 style="color: #4CAF50; margin-top: 0;">📋 Thông tin đặt phòng</h3>
            
            <div class="info-row">
                <span class="info-label">Mã phiếu:</span>
                <span class="info-value"><strong>${data['ma_phieu']}</strong></span>
            </div>
            
            <div class="info-row">
                <span class="info-label">Tên khách hàng:</span>
                <span class="info-value">${data['ten_khach_hang']}</span>
            </div>
            
            <div class="info-row">
                <span class="info-label">Số điện thoại:</span>
                <span class="info-value">${data['so_dien_thoai']}</span>
            </div>
            
            <div class="info-row">
                <span class="info-label">Email:</span>
                <span class="info-value">${data['email']}</span>
            </div>
            
            <div class="info-row">
                <span class="info-label">Tên phòng:</span>
                <span class="info-value"><strong>${data['ten_phong']}</strong></span>
            </div>
            
            <div class="info-row">
                <span class="info-label">Mã phòng:</span>
                <span class="info-value">${data['ma_phong']}</span>
            </div>
            
            <div class="info-row">
                <span class="info-label">Ngày check-in:</span>
                <span class="info-value"><strong>${data['formatted_check_in']}</strong></span>
            </div>
            
            <div class="info-row">
                <span class="info-label">Ngày check-out:</span>
                <span class="info-value"><strong>${data['formatted_check_out']}</strong></span>
            </div>
            
            <div class="info-row">
                <span class="info-label">Số đêm:</span>
                <span class="info-value">${data['so_dem']} đêm</span>
            </div>
            
            <div class="info-row">
                <span class="info-label">Giá phòng:</span>
                <span class="info-value">${data['gia_phong'].toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '\${m[1]},')} VNĐ/đêm</span>
            </div>
            
            <div class="info-row">
                <span class="info-label">Tổng tiền:</span>
                <span class="info-value" style="color: #4CAF50; font-size: 18px; font-weight: bold;">${data['formatted_tong_tien']}</span>
            </div>
            
            <div class="info-row">
                <span class="info-label">Ngày đặt:</span>
                <span class="info-value">${data['formatted_ngay_dat']}</span>
            </div>
            
            ${data['ghi_chu'] != null && data['ghi_chu'].toString().isNotEmpty ? '''
            <div class="info-row">
                <span class="info-label">Ghi chú:</span>
                <span class="info-value">${data['ghi_chu']}</span>
            </div>
            ''' : ''}
        </div>

        <div class="contact-info">
            <h3>📞 Thông tin liên hệ</h3>
            <p><strong>Hotline:</strong> 1900-xxxx</p>
            <p><strong>Email:</strong> support@hotel.com</p>
            <p><strong>Địa chỉ:</strong> [Địa chỉ khách sạn]</p>
        </div>

        <div style="background-color: #fff3cd; padding: 15px; border-radius: 8px; margin: 20px 0;">
            <h4 style="color: #856404; margin: 0 0 10px 0;">⚠️ Lưu ý quan trọng:</h4>
            <ul style="color: #856404; margin: 0; padding-left: 20px;">
                <li>Vui lòng mang theo CMND/CCCD khi check-in</li>
                <li>Thời gian check-in: 14:00 - 22:00</li>
                <li>Thời gian check-out: 06:00 - 12:00</li>
                <li>Liên hệ trước 24h nếu cần thay đổi hoặc hủy phòng</li>
            </ul>
        </div>

        <div class="footer">
            <p>Chúc bạn có một kỳ nghỉ tuyệt vời! 🏨✨</p>
            <p>Trân trọng,<br><strong>Đội ngũ Khách sạn</strong></p>
            <p style="font-size: 12px; color: #999;">
                Email này được gửi tự động, vui lòng không trả lời trực tiếp.
            </p>
        </div>
    </div>
</body>
</html>
    ''';
  }

  static String getBookingCancellationTemplate(Map<String, dynamic> data) {
    return '''
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Thông báo hủy đặt phòng</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f4f4f4;
        }
        .container {
            background-color: #ffffff;
            border-radius: 10px;
            padding: 30px;
            box-shadow: 0 0 20px rgba(0,0,0,0.1);
        }
        .header {
            text-align: center;
            border-bottom: 3px solid #f44336;
            padding-bottom: 20px;
            margin-bottom: 30px;
        }
        .header h1 {
            color: #f44336;
            margin: 0;
            font-size: 28px;
        }
        .header p {
            color: #666;
            margin: 10px 0 0 0;
            font-size: 16px;
        }
        .booking-info {
            background-color: #f8f9fa;
            border-radius: 8px;
            padding: 20px;
            margin: 20px 0;
        }
        .info-row {
            display: flex;
            justify-content: space-between;
            margin: 10px 0;
            padding: 8px 0;
            border-bottom: 1px solid #e9ecef;
        }
        .info-row:last-child {
            border-bottom: none;
        }
        .info-label {
            font-weight: bold;
            color: #495057;
            min-width: 120px;
        }
        .info-value {
            color: #212529;
            text-align: right;
        }
        .highlight {
            background-color: #ffebee;
            color: #c62828;
            padding: 15px;
            border-radius: 8px;
            text-align: center;
            font-weight: bold;
            margin: 20px 0;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #e9ecef;
            color: #6c757d;
            font-size: 14px;
        }
        .contact-info {
            background-color: #e3f2fd;
            padding: 15px;
            border-radius: 8px;
            margin: 20px 0;
        }
        .contact-info h3 {
            color: #1976d2;
            margin: 0 0 10px 0;
        }
        .contact-info p {
            margin: 5px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>❌ Đặt phòng đã bị hủy</h1>
            <p>Thông báo về việc hủy đặt phòng</p>
        </div>

        <div class="highlight">
            🚫 Đặt phòng của bạn đã bị hủy
        </div>

        <div class="booking-info">
            <h3 style="color: #f44336; margin-top: 0;">📋 Thông tin đặt phòng đã hủy</h3>
            
            <div class="info-row">
                <span class="info-label">Mã phiếu:</span>
                <span class="info-value"><strong>${data['ma_phieu']}</strong></span>
            </div>
            
            <div class="info-row">
                <span class="info-label">Tên khách hàng:</span>
                <span class="info-value">${data['ten_khach_hang']}</span>
            </div>
            
            <div class="info-row">
                <span class="info-label">Tên phòng:</span>
                <span class="info-value"><strong>${data['ten_phong']}</strong></span>
            </div>
            
            <div class="info-row">
                <span class="info-label">Ngày check-in:</span>
                <span class="info-value">${data['formatted_check_in']}</span>
            </div>
            
            <div class="info-row">
                <span class="info-label">Ngày check-out:</span>
                <span class="info-value">${data['formatted_check_out']}</span>
            </div>
            
            <div class="info-row">
                <span class="info-label">Tổng tiền:</span>
                <span class="info-value">${data['formatted_tong_tien']}</span>
            </div>
            
            <div class="info-row">
                <span class="info-label">Ngày hủy:</span>
                <span class="info-value">${data['formatted_ngay_huy']}</span>
            </div>
            
            <div class="info-row">
                <span class="info-label">Lý do hủy:</span>
                <span class="info-value">${data['ly_do_huy']}</span>
            </div>
        </div>

        <div class="contact-info">
            <h3>📞 Thông tin liên hệ</h3>
            <p><strong>Hotline:</strong> 1900-xxxx</p>
            <p><strong>Email:</strong> support@hotel.com</p>
            <p><strong>Địa chỉ:</strong> [Địa chỉ khách sạn]</p>
        </div>

        <div style="background-color: #fff3cd; padding: 15px; border-radius: 8px; margin: 20px 0;">
            <h4 style="color: #856404; margin: 0 0 10px 0;">ℹ️ Thông tin hoàn tiền:</h4>
            <ul style="color: #856404; margin: 0; padding-left: 20px;">
                <li>Tiền hoàn sẽ được xử lý trong vòng 3-5 ngày làm việc</li>
                <li>Liên hệ hotline nếu có thắc mắc về việc hoàn tiền</li>
                <li>Chúng tôi rất tiếc vì sự bất tiện này</li>
            </ul>
        </div>

        <div class="footer">
            <p>Hy vọng được phục vụ bạn trong tương lai! 🏨</p>
            <p>Trân trọng,<br><strong>Đội ngũ Khách sạn</strong></p>
            <p style="font-size: 12px; color: #999;">
                Email này được gửi tự động, vui lòng không trả lời trực tiếp.
            </p>
        </div>
    </div>
</body>
</html>
    ''';
  }

  static String getCheckInReminderTemplate(Map<String, dynamic> data) {
    return '''
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Nhắc nhở check-in</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f4f4f4;
        }
        .container {
            background-color: #ffffff;
            border-radius: 10px;
            padding: 30px;
            box-shadow: 0 0 20px rgba(0,0,0,0.1);
        }
        .header {
            text-align: center;
            border-bottom: 3px solid #ff9800;
            padding-bottom: 20px;
            margin-bottom: 30px;
        }
        .header h1 {
            color: #ff9800;
            margin: 0;
            font-size: 28px;
        }
        .header p {
            color: #666;
            margin: 10px 0 0 0;
            font-size: 16px;
        }
        .booking-info {
            background-color: #f8f9fa;
            border-radius: 8px;
            padding: 20px;
            margin: 20px 0;
        }
        .info-row {
            display: flex;
            justify-content: space-between;
            margin: 10px 0;
            padding: 8px 0;
            border-bottom: 1px solid #e9ecef;
        }
        .info-row:last-child {
            border-bottom: none;
        }
        .info-label {
            font-weight: bold;
            color: #495057;
            min-width: 120px;
        }
        .info-value {
            color: #212529;
            text-align: right;
        }
        .highlight {
            background-color: #fff3e0;
            color: #e65100;
            padding: 15px;
            border-radius: 8px;
            text-align: center;
            font-weight: bold;
            margin: 20px 0;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #e9ecef;
            color: #6c757d;
            font-size: 14px;
        }
        .contact-info {
            background-color: #e3f2fd;
            padding: 15px;
            border-radius: 8px;
            margin: 20px 0;
        }
        .contact-info h3 {
            color: #1976d2;
            margin: 0 0 10px 0;
        }
        .contact-info p {
            margin: 5px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>⏰ Nhắc nhở check-in</h1>
            <p>Thời gian check-in của bạn sắp tới</p>
        </div>

        <div class="highlight">
            🏨 Hẹn gặp bạn tại khách sạn vào ngày ${data['formatted_check_in']}!
        </div>

        <div class="booking-info">
            <h3 style="color: #ff9800; margin-top: 0;">📋 Thông tin đặt phòng</h3>
            
            <div class="info-row">
                <span class="info-label">Mã phiếu:</span>
                <span class="info-value"><strong>${data['ma_phieu']}</strong></span>
            </div>
            
            <div class="info-row">
                <span class="info-label">Tên khách hàng:</span>
                <span class="info-value">${data['ten_khach_hang']}</span>
            </div>
            
            <div class="info-row">
                <span class="info-label">Tên phòng:</span>
                <span class="info-value"><strong>${data['ten_phong']}</strong></span>
            </div>
            
            <div class="info-row">
                <span class="info-label">Ngày check-in:</span>
                <span class="info-value"><strong>${data['formatted_check_in']}</strong></span>
            </div>
            
            <div class="info-row">
                <span class="info-label">Ngày check-out:</span>
                <span class="info-value">${data['formatted_check_out']}</span>
            </div>
            
            <div class="info-row">
                <span class="info-label">Số đêm:</span>
                <span class="info-value">${data['so_dem']} đêm</span>
            </div>
        </div>

        <div class="contact-info">
            <h3>📞 Thông tin liên hệ</h3>
            <p><strong>Hotline:</strong> 1900-xxxx</p>
            <p><strong>Email:</strong> support@hotel.com</p>
            <p><strong>Địa chỉ:</strong> [Địa chỉ khách sạn]</p>
        </div>

        <div style="background-color: #e8f5e8; padding: 15px; border-radius: 8px; margin: 20px 0;">
            <h4 style="color: #2e7d32; margin: 0 0 10px 0;">✅ Checklist trước khi đến:</h4>
            <ul style="color: #2e7d32; margin: 0; padding-left: 20px;">
                <li>Mang theo CMND/CCCD</li>
                <li>Thời gian check-in: 14:00 - 22:00</li>
                <li>Liên hệ trước nếu đến muộn hơn 22:00</li>
                <li>Chuẩn bị tinh thần cho một kỳ nghỉ tuyệt vời!</li>
            </ul>
        </div>

        <div class="footer">
            <p>Chúng tôi rất mong được chào đón bạn! 🎉</p>
            <p>Trân trọng,<br><strong>Đội ngũ Khách sạn</strong></p>
            <p style="font-size: 12px; color: #999;">
                Email này được gửi tự động, vui lòng không trả lời trực tiếp.
            </p>
        </div>
    </div>
</body>
</html>
    ''';
  }
}
