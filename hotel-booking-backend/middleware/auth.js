// middleware/auth_new.js - Authentication middleware for new API
const jwt = require('jsonwebtoken');
const NguoiDung = require('../models/nguoidung');

// Authenticate JWT Token
const authenticateToken = async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Token không được cung cấp'
      });
    }

    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Get user from database
    const nguoiDung = new NguoiDung();
    const user = await nguoiDung.findById(decoded.ma_nguoi_dung);
    
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Token không hợp lệ - người dùng không tồn tại'
      });
    }

    if (!user.trang_thai) {
      return res.status(401).json({
        success: false,
        message: 'Tài khoản đã bị khóa'
      });
    }

    // Add user info to request
    req.user = {
      ma_nguoi_dung: user.ma_nguoi_dung,
      email: user.email,
      vai_tro: user.vai_tro,
      ho_ten: user.ho_ten
    };

    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        success: false,
        message: 'Token không hợp lệ'
      });
    }
    
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        message: 'Token đã hết hạn'
      });
    }

    console.error('Auth middleware error:', error);
    return res.status(500).json({
      success: false,
      message: 'Lỗi server khi xác thực'
    });
  }
};

// Authorize roles
const authorizeRoles = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Chưa đăng nhập'
      });
    }

    if (!roles.includes(req.user.vai_tro)) {
      return res.status(403).json({
        success: false,
        message: 'Không có quyền truy cập'
      });
    }

    next();
  };
};

// Admin only
const verifyAdmin = [authenticateToken, authorizeRoles('Admin')];

// Hotel Manager or Admin
const verifyHotelManager = [authenticateToken, authorizeRoles('HotelManager', 'Admin')];

// Any authenticated user
const verifyToken = authenticateToken;

module.exports = {
  authenticateToken,
  authorizeRoles,
  verifyAdmin,
  verifyHotelManager,
  verifyToken
};