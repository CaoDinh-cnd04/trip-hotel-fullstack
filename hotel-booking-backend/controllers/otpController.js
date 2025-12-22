const OTPCode = require('../models/otpCode');
const PendingUser = require('../models/pendingUser');
const NguoiDung = require('../models/nguoidung');
const EmailService = require('../services/emailService');
const jwt = require('jsonwebtoken');

// Generate JWT token
const generateToken = (user) => {
  const secret = process.env.JWT_SECRET || 'your-secret-key-change-in-production';
  return jwt.sign(
    { 
      id: user.id,
      email: user.email,
      chuc_vu: user.chuc_vu,
      ho_ten: user.ho_ten
    },
    secret,
    { expiresIn: '24h' }
  );
};

// Normalize role to standard format
const normalizeRole = (role) => {
  const roleString = (role || 'user').toLowerCase().trim();
  
  const roleMap = {
    'admin': 'admin',
    'administrator': 'admin',
    'hotelmanager': 'hotel_manager',
    'hotel_manager': 'hotel_manager',
    'manager': 'hotel_manager',
    'user': 'user',
    'customer': 'user',
    'khach_hang': 'user'
  };
  
  return roleMap[roleString] || 'user';
};

// Get role permissions
const getRolePermissions = (role) => {
  const normalizedRole = normalizeRole(role);
  
  const roleMap = {
    'admin': [
      'user:read', 'user:write', 'user:delete',
      'hotel:read', 'hotel:write', 'hotel:delete',
      'booking:read', 'booking:write', 'booking:delete',
      'system:admin'
    ],
    'hotel_manager': [
      'hotel:read', 'hotel:write',
      'booking:read', 'booking:write',
      'room:read', 'room:write',
      'promotion:read', 'promotion:write'
    ],
    'user': [
      'booking:read', 'booking:write',
      'hotel:read',
      'room:read'
    ]
  };

  return roleMap[normalizedRole] || roleMap['user'];
};

// Gửi mã OTP
exports.sendOTP = async (req, res) => {
  try {
    const { email, user_data } = req.body;

    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email là bắt buộc'
      });
    }

    // PASSWORDLESS LOGIN: Cho phép cả user mới và user cũ nhận OTP
    // Không cần kiểm tra email đã tồn tại

    // Kiểm tra xem email có OTP chưa hết hạn không
    // TEMP: Disable để dễ test - Enable lại khi production
    // const hasActiveOTP = await OTPCode.hasActiveOTP(email);
    // if (hasActiveOTP) {
    //   return res.status(429).json({
    //     success: false,
    //     message: 'Mã OTP đã được gửi. Vui lòng đợi 5 phút trước khi gửi lại.'
    //   });
    // }

    // Tạo mã OTP 6 số
    const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Thời gian hết hạn: 5 phút (300 giây)
    const expiresAt = new Date(Date.now() + 300 * 1000);

    // Lưu OTP vào database
    try {
      await OTPCode.createOTP(email, otpCode, expiresAt);
      console.log('✅ OTP saved to database');
    } catch (dbError) {
      console.error('❌ Database error:', dbError);
      return res.status(500).json({
        success: false,
        message: 'Lỗi lưu mã OTP vào database',
        error: process.env.NODE_ENV === 'development' ? dbError.message : undefined
      });
    }

    // Lưu thông tin user tạm thời nếu có
    if (user_data) {
      try {
        await PendingUser.createPendingUser(email, user_data);
      } catch (dbError) {
        console.error('❌ Error saving pending user:', dbError);
        // Continue anyway
      }
    }

    // Gửi email OTP
    try {
      await EmailService.sendOTPEmail(email, otpCode);
      console.log('✅ Email sent successfully');
    } catch (emailError) {
      console.error('❌ Error sending email:', emailError);
      // Vẫn trả về success vì OTP đã được tạo
      // Trong production, có thể gửi qua SMS backup
    }

    console.log('🔥 OTP sent:', {
      email,
      otp_code: otpCode,
      expires_at: expiresAt
    });

    res.json({
      success: true,
      message: 'Mã OTP đã được gửi đến email của bạn',
      expires_in: 300 // giây (5 phút)
    });

  } catch (error) {
    console.error('❌ Send OTP error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi gửi mã OTP',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Xác thực mã OTP
exports.verifyOTP = async (req, res) => {
  try {
    const { email, otp_code } = req.body;

    console.log('🔍 Verify OTP Request:', {
      email,
      otp_code,
      otp_code_length: otp_code?.length,
      otp_code_type: typeof otp_code
    });

    if (!email || !otp_code) {
      return res.status(400).json({
        success: false,
        message: 'Email và mã OTP là bắt buộc'
      });
    }

    // Trim và convert OTP code về string
    const cleanOtpCode = String(otp_code).trim();
    
    console.log('🔍 Looking for OTP:', {
      email: email.toLowerCase(),
      clean_otp_code: cleanOtpCode
    });

    // Tìm OTP
    const otp = await OTPCode.findByEmailAndCode(email, cleanOtpCode);
    
    console.log('🔍 OTP found:', otp ? 'YES' : 'NO', otp);
    if (!otp) {
      // Tăng số lần thử nếu có OTP nhưng sai mã
      const existingOTP = await OTPCode.findByEmail(email);
      if (existingOTP) {
        await OTPCode.incrementAttempts(existingOTP.id);
        const attempts = await OTPCode.getAttempts(existingOTP.id);
        
        if (attempts >= 3) {
          await OTPCode.deleteByEmail(email);
          return res.status(400).json({
            success: false,
            message: 'Bạn đã nhập sai quá 3 lần. Vui lòng yêu cầu mã OTP mới.'
          });
        }
      }

      return res.status(400).json({
        success: false,
        message: 'Mã OTP không hợp lệ hoặc đã hết hạn'
      });
    }

    // Kiểm tra số lần thử
    if (otp.attempts >= 3) {
      await OTPCode.deleteByEmail(email);
      return res.status(400).json({
        success: false,
        message: 'Bạn đã nhập sai quá 3 lần. Vui lòng yêu cầu mã OTP mới.'
      });
    }

    // Kiểm tra user đã tồn tại chưa (bất kể trạng thái)
    const nguoiDung = new NguoiDung();
    let user;
    try {
      user = await nguoiDung.findByEmailAny(email);
    } catch (dbError) {
      console.error('❌ Error finding user:', dbError);
      return res.status(500).json({
        success: false,
        message: 'Lỗi truy vấn database',
        error: process.env.NODE_ENV === 'development' ? dbError.message : undefined
      });
    }
    
    if (user) {
      // User đã tồn tại
      if (user.trang_thai === 0 || user.trang_thai === false) {
        // User bị vô hiệu hóa → Kích hoạt lại
        try {
          await nguoiDung.update(user.id, { trang_thai: 1 });
          user.trang_thai = 1;
          console.log('✅ Inactive user reactivated via OTP:', user.id);
        } catch (updateError) {
          console.error('❌ Error reactivating user:', updateError);
          return res.status(500).json({
            success: false,
            message: 'Lỗi kích hoạt lại tài khoản',
            error: process.env.NODE_ENV === 'development' ? updateError.message : undefined
          });
        }
      } else {
        console.log('✅ Existing user login via OTP:', user.id);
      }
    } else {
      // User mới → Tạo tài khoản tự động
      try {
        const pendingUser = await PendingUser.findByEmail(email);
        let userData = pendingUser?.user_data || {};

        const newUser = {
          ho_ten: userData.ho_ten || email.split('@')[0],
          email: email.toLowerCase(),
          mat_khau: 'otp_user_no_password', // OTP users don't have passwords
          sdt: userData.sdt || '0000000000',
          gioi_tinh: userData.gioi_tinh || 'Khác', // Max 10 chars for DB column
          ngay_sinh: userData.ngay_sinh ? new Date(userData.ngay_sinh) : null,
          chuc_vu: 'User',
          trang_thai: 1,
          nhan_thong_bao_email: 1, // Default to enabled for email notifications
          ngay_dang_ky: new Date(),
          anh_dai_dien: '/images/users/default.jpg'
        };

        const userId = await nguoiDung.create(newUser);
        user = await nguoiDung.findById(userId);
        console.log('✅ New user created via OTP:', user.id);
      } catch (createError) {
        console.error('❌ Error creating user:', createError);
        return res.status(500).json({
          success: false,
          message: 'Lỗi tạo tài khoản người dùng',
          error: process.env.NODE_ENV === 'development' ? createError.message : undefined
        });
      }
    }

    // Đánh dấu OTP đã sử dụng
    try {
      await OTPCode.markAsUsed(otp.id);
    } catch (err) {
      console.error('❌ Error marking OTP as used:', err);
      // Continue anyway
    }

    // Xóa pending user
    try {
      await PendingUser.deleteByEmail(email);
    } catch (err) {
      console.error('❌ Error deleting pending user:', err);
      // Continue anyway
    }

    // Tạo JWT token
    const token = generateToken(user);

    // Prepare role data
    console.log('🔍 OTP Login - User role from DB:', user.chuc_vu);
    console.log('🔍 OTP Login - User trang_thai from DB:', user.trang_thai, typeof user.trang_thai);
    console.log('🔍 OTP Login - Normalized role:', normalizeRole(user.chuc_vu));
    
    const roleData = {
      role: normalizeRole(user.chuc_vu),
      is_active: user.trang_thai === 1 || user.trang_thai === true, // Handle both boolean and int
      permissions: getRolePermissions(user.chuc_vu),
      hotel_id: user.khach_san_id || null
    };
    
    console.log('🔍 OTP Login - Final roleData:', JSON.stringify(roleData, null, 2));

    // Tạo Firebase custom token cho OTP users
    let firebaseCustomToken = null;
    try {
      const { createCustomToken } = require('../services/firebaseAdmin');
      firebaseCustomToken = await createCustomToken(user.id, user.email, {
        role: roleData.role,
        hotel_id: roleData.hotel_id
      });
      console.log('✅ Firebase custom token created for OTP user');
    } catch (firebaseError) {
      console.warn('⚠️ Failed to create Firebase custom token (non-critical):', firebaseError.message);
      // Continue without custom token - frontend will handle it
    }

    // Gửi email chào mừng cho user mới (async, không cần đợi)
    const isNewUser = user.ngay_dang_ky && (new Date() - user.ngay_dang_ky < 60000);
    if (isNewUser) {
      EmailService.sendWelcomeEmail(email, user.ho_ten).catch(err => 
        console.error('❌ Error sending welcome email:', err)
      );
    }

    res.json({
      success: true,
      message: user.ngay_dang_ky && (new Date() - user.ngay_dang_ky < 60000) 
        ? 'Đăng ký và đăng nhập thành công' 
        : 'Đăng nhập thành công',
      user: {
        id: user.id,
        ho_ten: user.ho_ten,
        email: user.email,
        sdt: user.sdt,
        anh_dai_dien: user.anh_dai_dien,
        chuc_vu: user.chuc_vu,
        trang_thai: user.trang_thai,
        ngay_dang_ky: user.ngay_dang_ky
      },
      token: token,
      role: roleData,
      firebase_custom_token: firebaseCustomToken // Firebase custom token for Firestore access
    });

  } catch (error) {
    console.error('❌ Verify OTP error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi xác thực mã OTP',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Gửi lại mã OTP
exports.resendOTP = async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email là bắt buộc'
      });
    }

    // PASSWORDLESS LOGIN: Cho phép cả user mới và user cũ resend OTP
    
    // Xóa OTP cũ
    await OTPCode.deleteByEmail(email);

    // Tạo mã OTP mới
    const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 300 * 1000); // 5 phút

    // Lưu OTP mới
    await OTPCode.createOTP(email, otpCode, expiresAt);

    // Gửi email OTP
    try {
      await EmailService.sendOTPEmail(email, otpCode);
    } catch (emailError) {
      console.error('❌ Error sending email:', emailError);
    }

    console.log('🔄 OTP resent:', {
      email,
      otp_code: otpCode,
      expires_at: expiresAt
    });

    res.json({
      success: true,
      message: 'Mã OTP mới đã được gửi đến email của bạn',
      expires_in: 300 // 5 phút
    });

  } catch (error) {
    console.error('❌ Resend OTP error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi gửi lại mã OTP',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Clean expired OTPs (có thể gọi định kỳ)
exports.cleanExpiredOTPs = async (req, res) => {
  try {
    const deletedOTPs = await OTPCode.cleanExpired();
    const deletedPendingUsers = await PendingUser.cleanExpired();
    
    res.json({
      success: true,
      message: 'Đã dọn dẹp dữ liệu hết hạn',
      deleted_otps: deletedOTPs,
      deleted_pending_users: deletedPendingUsers
    });
  } catch (error) {
    console.error('❌ Clean expired OTPs error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi dọn dẹp dữ liệu hết hạn'
    });
  }
};
