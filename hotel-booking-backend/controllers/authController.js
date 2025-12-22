// controllers/authController.js - Authentication controller for new database schema
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { check, validationResult } = require('express-validator');
const NguoiDung = require('../models/nguoidung');
const crypto = require('crypto');
const axios = require('axios');

// Generate JWT Token
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
  
  // Map various role formats to standard format
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

// Đăng ký
exports.register = [
  // Validation rules
  check('ho_ten')
    .notEmpty()
    .withMessage('Họ tên không được để trống')
    .isLength({ min: 2, max: 100 })
    .withMessage('Họ tên phải từ 2-100 ký tự'),
  
  check('email')
    .isEmail()
    .withMessage('Email không hợp lệ')
    .normalizeEmail(),
  
  check('mat_khau')
    .isLength({ min: 6 })
    .withMessage('Mật khẩu phải có ít nhất 6 ký tự')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage('Mật khẩu phải chứa ít nhất 1 chữ hoa, 1 chữ thường và 1 số'),
  
  check('sdt')
    .optional()
    .matches(/^[0-9]{10,11}$/)
    .withMessage('Số điện thoại phải có 10-11 chữ số'),
  
  check('gioi_tinh')
    .optional()
    .isIn(['Nam', 'Nữ', 'Khác'])
    .withMessage('Giới tính phải là Nam, Nữ hoặc Khác'),

  async (req, res) => {
    try {
      // Check validation errors
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Dữ liệu không hợp lệ',
          errors: errors.array()
        });
      }

      const { ho_ten, email, mat_khau, sdt, ngay_sinh, gioi_tinh, anh_dai_dien } = req.body;

      // Create user
      const nguoiDung = new NguoiDung();
      const newUser = await nguoiDung.createUser({
        ho_ten,
        email: email.toLowerCase(),
        mat_khau,
        sdt,
        ngay_sinh,
        gioi_tinh: gioi_tinh || 'Khác',
        anh_dai_dien: anh_dai_dien || '/images/users/default.jpg'
      });

      // Generate token
      const token = generateToken(newUser);

      // Remove password from response
      const { mat_khau: _, ...userResponse } = newUser;

      // Prepare role data
      const roleData = {
        role: normalizeRole(newUser.chuc_vu),
        is_active: newUser.trang_thai === 1,
        permissions: getRolePermissions(newUser.chuc_vu),
        hotel_id: newUser.khach_san_id || null
      };

      // Tạo Firebase custom token cho user mới đăng ký
      let firebaseCustomToken = null;
      try {
        const { createCustomToken } = require('../services/firebaseAdmin');
        firebaseCustomToken = await createCustomToken(newUser.id, newUser.email, {
          role: roleData.role,
          hotel_id: roleData.hotel_id
        });
        console.log('✅ Firebase custom token created for new registered user');
      } catch (firebaseError) {
        console.warn('⚠️ Failed to create Firebase custom token (non-critical):', firebaseError.message);
        // Continue without custom token - frontend can use email/password auth
      }

      res.status(201).json({
        success: true,
        message: 'Đăng ký thành công',
        user: userResponse,
        token: token,
        role: roleData,
        firebase_custom_token: firebaseCustomToken // Firebase custom token for Firestore access
      });

    } catch (error) {
      console.error('Register error:', error);
      
      if (error.message === 'Email đã tồn tại trong hệ thống') {
        return res.status(400).json({
          success: false,
          message: error.message
        });
      }

      res.status(500).json({
        success: false,
        message: 'Lỗi server khi đăng ký',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }
];

// Đăng nhập
exports.login = [
  // Validation rules
  check('email')
    .isEmail()
    .withMessage('Email không hợp lệ')
    .normalizeEmail(),
  
  check('mat_khau')
    .notEmpty()
    .withMessage('Mật khẩu không được để trống'),

  async (req, res) => {
    try {
      // Check validation errors
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        console.log('Validation errors:', errors.array());
        return res.status(400).json({
          success: false,
          message: 'Dữ liệu không hợp lệ',
          errors: errors.array()
        });
      }

      const { email, mat_khau } = req.body;
      console.log('Login attempt for:', email);

      // Verify credentials
      const nguoiDung = new NguoiDung();
      const result = await nguoiDung.verifyPassword(email.toLowerCase(), mat_khau);
      console.log('Verify password result:', result);
      
      if (!result.success) {
        console.log('Login failed:', result.message);
        return res.status(401).json({
          success: false,
          message: result.message
        });
      }

      // Generate token
      const token = generateToken(result.user);

      // Prepare role data
      const roleData = {
        role: normalizeRole(result.user.chuc_vu),
        is_active: result.user.trang_thai === 1,
        permissions: getRolePermissions(result.user.chuc_vu),
        hotel_id: result.user.khach_san_id || null
      };

      console.log('🔍 ===== BACKEND LOGIN DEBUG =====');
      console.log('📧 Email:', email);
      console.log('👤 User chuc_vu (raw):', result.user.chuc_vu);
      console.log('🎭 Normalized role:', roleData.role);
      console.log('✅ Is Admin:', roleData.role === 'admin');
      console.log('🔐 Permissions:', roleData.permissions);
      console.log('🔍 ================================');

      // Tạo Firebase custom token cho email/password users (optional, for Firestore access)
      let firebaseCustomToken = null;
      try {
        const { createCustomToken } = require('../services/firebaseAdmin');
        firebaseCustomToken = await createCustomToken(result.user.id, result.user.email, {
          role: roleData.role,
          hotel_id: roleData.hotel_id
        });
        console.log('✅ Firebase custom token created for email/password user');
      } catch (firebaseError) {
        console.warn('⚠️ Failed to create Firebase custom token (non-critical):', firebaseError.message);
        // Continue without custom token - frontend can use email/password auth
      }

      res.json({
        success: true,
        message: 'Đăng nhập thành công',
        user: result.user,
        token: token,
        role: roleData,
        firebase_custom_token: firebaseCustomToken // Firebase custom token for Firestore access
      });

    } catch (error) {
      console.error('Login error:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi đăng nhập',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }
];

// Verify token
exports.verify = async (req, res) => {
  try {
    // Token already verified by middleware
    const nguoiDung = new NguoiDung();
    const user = await nguoiDung.findById(req.user.id);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Người dùng không tồn tại'
      });
    }

    if (!user.trang_thai) {
      return res.status(401).json({
        success: false,
        message: 'Tài khoản đã bị khóa'
      });
    }

    // Remove password from response
    const { mat_khau, ...userResponse } = user;

    res.json({
      success: true,
      valid: true,
      data: {
        user: userResponse
      }
    });

  } catch (error) {
    console.error('Verify token error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi xác thực token'
    });
  }
};

// Refresh token
exports.refreshToken = async (req, res) => {
  try {
    const nguoiDung = new NguoiDung();
    const user = await nguoiDung.findById(req.user.id);
    
    if (!user || !user.trang_thai) {
      return res.status(401).json({
        success: false,
        message: 'Token không hợp lệ'
      });
    }

    // Generate new token
    const newToken = generateToken(user);

    res.json({
      success: true,
      message: 'Làm mới token thành công',
      data: {
        token: newToken
      }
    });

  } catch (error) {
    console.error('Refresh token error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi làm mới token'
    });
  }
};

// Change password
exports.changePassword = [
  check('mat_khau_cu')
    .notEmpty()
    .withMessage('Mật khẩu cũ không được để trống'),
  
  check('mat_khau_moi')
    .isLength({ min: 6 })
    .withMessage('Mật khẩu mới phải có ít nhất 6 ký tự')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage('Mật khẩu mới phải chứa ít nhất 1 chữ hoa, 1 chữ thường và 1 số'),

  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Dữ liệu không hợp lệ',
          errors: errors.array()
        });
      }

      const { mat_khau_cu, mat_khau_moi } = req.body;
      const userId = req.user.id;

      const nguoiDung = new NguoiDung();
      await nguoiDung.changePassword(userId, mat_khau_cu, mat_khau_moi);

      res.json({
        success: true,
        message: 'Đổi mật khẩu thành công'
      });

    } catch (error) {
      console.error('Change password error:', error);
      
      if (error.message === 'Mật khẩu cũ không chính xác') {
        return res.status(400).json({
          success: false,
          message: error.message
        });
      }

      res.status(500).json({
        success: false,
        message: 'Lỗi server khi đổi mật khẩu'
      });
    }
  }
];

// Firebase Social Login (Google/Facebook) - Đồng bộ từ Firebase
exports.firebaseSocialLogin = async (req, res) => {
  try {
    const { 
      firebase_uid, 
      email, 
      ho_ten, 
      anh_dai_dien, 
      provider, 
      google_id, 
      facebook_id, 
      access_token 
    } = req.body;

    if (!firebase_uid || !email) {
      return res.status(400).json({
        success: false,
        message: 'Thiếu thông tin bắt buộc (firebase_uid, email)'
      });
    }

    console.log('🔥 Firebase Social Login:', {
      firebase_uid,
      email,
      provider,
      google_id: google_id ? '***' : null,
      facebook_id: facebook_id ? '***' : null
    });

    // Đồng bộ user từ Firebase về SQL Server
    // Role will be managed via database or Admin API
    const userData = {
      firebase_uid,
      email: email.toLowerCase(),
      ho_ten: ho_ten || email.split('@')[0],
      anh_dai_dien: anh_dai_dien || '/images/users/default.jpg',
      google_id: provider === 'google.com' ? google_id : null,
      facebook_id: provider === 'facebook.com' ? facebook_id : null,
      chuc_vu: 'User', // Default role is User
      trang_thai: 1,
      nhan_thong_bao_email: 1 // Default to enabled for email notifications
    };

    // Sync user data to database
    const nguoiDung = new NguoiDung();
    const user = await nguoiDung.syncFirebaseUser(userData);
    console.log('✅ User synced to database:', user.id);

    // Generate JWT token
    const token = generateToken(user);

    // Prepare role data
    const roleData = {
      role: normalizeRole(user.chuc_vu),
      is_active: user.trang_thai === 1,
      permissions: getRolePermissions(user.chuc_vu),
      hotel_id: user.khach_san_id || null
    };

    console.log('🔍 ===== BACKEND FIREBASE LOGIN DEBUG =====');
    console.log('📧 Email:', user.email);
    console.log('👤 User chuc_vu (raw):', user.chuc_vu);
    console.log('🎭 Normalized role:', roleData.role);
    console.log('✅ Is Admin:', roleData.role === 'admin');
    console.log('🔐 Permissions:', roleData.permissions);
    console.log('🔍 ==========================================');

    res.json({
      success: true,
      message: 'Đăng nhập Firebase thành công',
      user: {
        id: user.id,
        ho_ten: user.ho_ten,
        email: user.email,
        sdt: user.sdt,
        anh_dai_dien: user.anh_dai_dien,
        chuc_vu: user.chuc_vu,
        firebase_uid: user.firebase_uid,
        google_id: user.google_id,
        facebook_id: user.facebook_id,
        trang_thai: user.trang_thai
      },
      token: token,
      role: roleData
    });

  } catch (error) {
    console.error('Firebase Social login error:', error);
    
    if (error.message.includes('đã được liên kết') || error.message.includes('đã tồn tại')) {
      return res.status(409).json({
        success: false,
        message: error.message
      });
    }

    res.status(500).json({
      success: false,
      message: 'Lỗi server khi đồng bộ Firebase',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Legacy Social Login (Google/Facebook) - Giữ lại để tương thích
exports.socialLogin = async (req, res) => {
  try {
    const { email, ho_ten, anh_dai_dien, provider, access_token } = req.body;

    if (!email || !provider) {
      return res.status(400).json({
        success: false,
        message: 'Thiếu thông tin bắt buộc'
      });
    }

    // Kiểm tra xem user đã tồn tại chưa
    const nguoiDung = new NguoiDung();
    let user = await nguoiDung.findByEmail(email);

    if (user) {
      // User đã tồn tại, cập nhật thông tin social
      const updateData = {
        anh_dai_dien: anh_dai_dien || user.anh_dai_dien,
        provider: provider
      };

      await nguoiDung.update(user.id, updateData);
      user = await nguoiDung.findById(user.id);
    } else {
      // Tạo user mới
      // Auto-assign Admin role for specific emails
      const adminEmails = [
        'dcao52862@gmail.com',  // Thêm email admin của bạn ở đây
        'admin@hotel.com'
      ];
      
      const chucVu = adminEmails.includes(email.toLowerCase()) ? 'Admin' : 'User';
      
      const newUserData = {
        ho_ten: ho_ten || 'User',
        email: email,
        mat_khau: await bcrypt.hash(crypto.randomBytes(20).toString('hex'), 10), // Random password
        sdt: '',
        ngay_sinh: null,
        gioi_tinh: 'Khác',
        anh_dai_dien: anh_dai_dien || '/images/users/default.jpg',
        chuc_vu: chucVu,
        trang_thai: 1,
        nhan_thong_bao_email: 1, // Default to enabled for email notifications
        provider: provider
      };

      const userId = await nguoiDung.create(newUserData);
      user = await nguoiDung.findById(userId);
      
      if (chucVu === 'Admin') {
        console.log(`✅ Auto-assigned Admin role to: ${email}`);
      }
    }

    // Tạo JWT token
    const token = generateToken(user);

    res.json({
      success: true,
      message: 'Đăng nhập thành công',
      data: {
        user: {
          id: user.id,
          ho_ten: user.ho_ten,
          email: user.email,
          sdt: user.sdt,
          anh_dai_dien: user.anh_dai_dien,
          chuc_vu: user.chuc_vu,
          provider: user.provider || provider
        },
        role: {
          role: user.chuc_vu,
          is_active: user.trang_thai === 1,
          permissions: []
        },
        token: token
      }
    });

  } catch (error) {
    console.error('Social login error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Facebook Login
exports.facebookLogin = async (req, res) => {
  try {
    const { accessToken } = req.body;
    
    if (!accessToken) {
      return res.status(400).json({
        success: false,
        message: 'Access token là bắt buộc'
      });
    }

    // Verify Facebook access token và lấy thông tin user
    const facebookResponse = await axios.get(
      `https://graph.facebook.com/me?fields=id,name,email,first_name,last_name,picture&access_token=${accessToken}`
    );

    const facebookUser = facebookResponse.data;

    if (!facebookUser.id) {
      return res.status(401).json({
        success: false,
        message: 'Token Facebook không hợp lệ'
      });
    }

    // Kiểm tra xem user đã tồn tại chưa (theo email hoặc facebook_id)
    const nguoiDung = new NguoiDung();
    let existingUser = null;
    
    if (facebookUser.email) {
      existingUser = await nguoiDung.findByEmail(facebookUser.email.toLowerCase());
    }
    
    // Nếu chưa có user với email này, tìm theo facebook_id
    if (!existingUser) {
      existingUser = await nguoiDung.findByFacebookId(facebookUser.id);
    }

    let user;
    
    if (existingUser) {
      // Cập nhật facebook_id nếu chưa có
      if (!existingUser.facebook_id) {
        await nguoiDung.updateFacebookId(existingUser.id, facebookUser.id);
        existingUser.facebook_id = facebookUser.id;
      }
      user = existingUser;
    } else {
      // Tạo user mới
      const userData = {
        ho_ten: facebookUser.name || `${facebookUser.first_name || ''} ${facebookUser.last_name || ''}`.trim(),
        email: facebookUser.email ? facebookUser.email.toLowerCase() : null,
        facebook_id: facebookUser.id,
        hinh_anh: facebookUser.picture?.data?.url || null,
        chuc_vu: 'khach_hang', // Mặc định là khách hàng
        trang_thai: 'active'
      };

      // Tạo user mới với Facebook
      const newUser = await nguoiDung.createWithFacebook(userData);
      user = newUser;
    }

    // Generate JWT token
    const token = generateToken(user);

    res.json({
      success: true,
      message: 'Đăng nhập Facebook thành công',
      user: {
        id: user.id,
        ho_ten: user.ho_ten,
        email: user.email,
        hinh_anh: user.hinh_anh,
        chuc_vu: user.chuc_vu,
        facebook_id: user.facebook_id
      },
      token: token
    });

  } catch (error) {
    console.error('Facebook login error:', error);
    
    if (error.response?.status === 400) {
      return res.status(401).json({
        success: false,
        message: 'Token Facebook không hợp lệ hoặc đã hết hạn'
      });
    }

    res.status(500).json({
      success: false,
      message: 'Lỗi server khi đăng nhập Facebook',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Logout (client-side mainly, but can blacklist token if needed)
exports.logout = (req, res) => {
  res.json({
    success: true,
    message: 'Đăng xuất thành công'
  });
};

module.exports = exports;