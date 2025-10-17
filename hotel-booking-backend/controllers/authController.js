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

// Get role permissions
const getRolePermissions = (role) => {
  const roleMap = {
    'admin': [
      'user:read', 'user:write', 'user:delete',
      'hotel:read', 'hotel:write', 'hotel:delete',
      'booking:read', 'booking:write', 'booking:delete',
      'system:admin'
    ],
    'hotelmanager': [
      'hotel:read', 'hotel:write',
      'booking:read', 'booking:write',
      'room:read', 'room:write',
      'promotion:read', 'promotion:write'
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

  const normalizedRole = (role || 'user').toLowerCase();
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
      const newUser = await NguoiDung.createUser({
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
        role: newUser.chuc_vu || 'user',
        is_active: newUser.trang_thai === 1,
        permissions: getRolePermissions(newUser.chuc_vu || 'user'),
        hotel_id: newUser.khach_san_id || null
      };

      res.status(201).json({
        success: true,
        message: 'Đăng ký thành công',
        user: userResponse,
        token: token,
        role: roleData
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
      const result = await NguoiDung.verifyPassword(email.toLowerCase(), mat_khau);
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
        role: result.user.chuc_vu || 'user',
        is_active: result.user.trang_thai === 1,
        permissions: getRolePermissions(result.user.chuc_vu || 'user'),
        hotel_id: result.user.khach_san_id || null
      };

      res.json({
        success: true,
        message: 'Đăng nhập thành công',
        user: result.user,
        token: token,
        role: roleData
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
    const user = await NguoiDung.findById(req.user.id);
    
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
    const user = await NguoiDung.findById(req.user.id);
    
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

      await NguoiDung.changePassword(userId, mat_khau_cu, mat_khau_moi);

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

// Social Login (Google/Facebook)
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
    let user = await NguoiDung.findByEmail(email);

    if (user) {
      // User đã tồn tại, cập nhật thông tin social
      const updateData = {
        anh_dai_dien: anh_dai_dien || user.anh_dai_dien,
        provider: provider
      };

      await NguoiDung.update(user.id, updateData);
      user = await NguoiDung.findById(user.id);
    } else {
      // Tạo user mới
      const newUserData = {
        ho_ten: ho_ten || 'User',
        email: email,
        mat_khau: await bcrypt.hash(crypto.randomBytes(20).toString('hex'), 10), // Random password
        sdt: '',
        ngay_sinh: null,
        gioi_tinh: 'Khác',
        anh_dai_dien: anh_dai_dien || '/images/users/default.jpg',
        chuc_vu: 'User',
        trang_thai: 1,
        provider: provider
      };

      const userId = await NguoiDung.create(newUserData);
      user = await NguoiDung.findById(userId);
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
    let existingUser = null;
    
    if (facebookUser.email) {
      existingUser = await NguoiDung.findByEmail(facebookUser.email.toLowerCase());
    }
    
    // Nếu chưa có user với email này, tìm theo facebook_id
    if (!existingUser) {
      existingUser = await NguoiDung.findByFacebookId(facebookUser.id);
    }

    let user;
    
    if (existingUser) {
      // Cập nhật facebook_id nếu chưa có
      if (!existingUser.facebook_id) {
        await NguoiDung.updateFacebookId(existingUser.id, facebookUser.id);
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
      const newUser = await NguoiDung.createWithFacebook(userData);
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