/**
 * Admin Role Management Controller
 * Quản lý phân quyền admin
 */

const NguoiDung = require('../models/nguoidung');

// Lấy danh sách tất cả users (chỉ admin mới được xem)
exports.getAllUsers = async (req, res) => {
  try {
    const { page = 1, limit = 20, search = '', role = '' } = req.query;
    
    let whereClause = '';
    const conditions = [];
    
    if (search) {
      conditions.push(`(ho_ten LIKE N'%${search}%' OR email LIKE '%${search}%')`);
    }
    
    if (role) {
      conditions.push(`chuc_vu = N'${role}'`);
    }
    
    if (conditions.length > 0) {
      whereClause = conditions.join(' AND ');
    }
    
    const result = await NguoiDung.findAll({
      page: parseInt(page),
      limit: parseInt(limit),
      where: whereClause,
      orderBy: 'created_at DESC'
    });
    
    // Remove passwords from response
    result.data = result.data.map(user => {
      const { mat_khau, ...userWithoutPassword } = user;
      return userWithoutPassword;
    });
    
    res.json({
      success: true,
      ...result
    });
  } catch (error) {
    console.error('Get all users error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi lấy danh sách người dùng',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Cấp quyền admin cho user
exports.grantAdminRole = async (req, res) => {
  try {
    const { userId } = req.params;
    const currentAdminId = req.user.id;
    
    // Không thể tự cấp quyền cho chính mình (phải có admin khác cấp)
    if (parseInt(userId) === currentAdminId) {
      return res.status(400).json({
        success: false,
        message: 'Không thể tự cấp quyền admin cho chính mình'
      });
    }
    
    // Kiểm tra user tồn tại
    const user = await NguoiDung.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Người dùng không tồn tại'
      });
    }
    
    // Kiểm tra user đã là admin chưa
    if (user.chuc_vu === 'Admin') {
      return res.status(400).json({
        success: false,
        message: 'Người dùng này đã là Admin'
      });
    }
    
    // Cập nhật role
    const updatedUser = await NguoiDung.update(userId, {
      chuc_vu: 'Admin'
    });
    
    // Remove password from response
    const { mat_khau, ...userResponse } = updatedUser;
    
    console.log(`✅ Admin ${req.user.email} granted Admin role to user ${user.email}`);
    
    res.json({
      success: true,
      message: `Đã cấp quyền Admin cho ${user.ho_ten}`,
      user: userResponse
    });
  } catch (error) {
    console.error('Grant admin role error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi cấp quyền admin',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Thu hồi quyền admin
exports.revokeAdminRole = async (req, res) => {
  try {
    const { userId } = req.params;
    const currentAdminId = req.user.id;
    
    // Không thể tự thu hồi quyền của chính mình
    if (parseInt(userId) === currentAdminId) {
      return res.status(400).json({
        success: false,
        message: 'Không thể tự thu hồi quyền admin của chính mình'
      });
    }
    
    // Kiểm tra user tồn tại
    const user = await NguoiDung.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Người dùng không tồn tại'
      });
    }
    
    // Kiểm tra user có phải admin không
    if (user.chuc_vu !== 'Admin') {
      return res.status(400).json({
        success: false,
        message: 'Người dùng này không phải là Admin'
      });
    }
    
    // Cập nhật role về User
    const updatedUser = await NguoiDung.update(userId, {
      chuc_vu: 'User'
    });
    
    // Remove password from response
    const { mat_khau, ...userResponse } = updatedUser;
    
    console.log(`✅ Admin ${req.user.email} revoked Admin role from user ${user.email}`);
    
    res.json({
      success: true,
      message: `Đã thu hồi quyền Admin của ${user.ho_ten}`,
      user: userResponse
    });
  } catch (error) {
    console.error('Revoke admin role error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi thu hồi quyền admin',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Cập nhật role bất kỳ (Admin, HotelManager, User)
exports.updateUserRole = async (req, res) => {
  try {
    const { userId } = req.params;
    const { chuc_vu } = req.body;
    const currentAdminId = req.user.id;
    
    // Validate role
    const validRoles = ['Admin', 'HotelManager', 'User'];
    if (!validRoles.includes(chuc_vu)) {
      return res.status(400).json({
        success: false,
        message: 'Chức vụ không hợp lệ. Chỉ chấp nhận: Admin, HotelManager, User'
      });
    }
    
    // Không thể tự thay đổi role của chính mình
    if (parseInt(userId) === currentAdminId) {
      return res.status(400).json({
        success: false,
        message: 'Không thể tự thay đổi quyền của chính mình'
      });
    }
    
    // Kiểm tra user tồn tại
    const user = await NguoiDung.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Người dùng không tồn tại'
      });
    }
    
    // Cập nhật role
    const updatedUser = await NguoiDung.update(userId, {
      chuc_vu: chuc_vu
    });
    
    // Remove password from response
    const { mat_khau, ...userResponse } = updatedUser;
    
    console.log(`✅ Admin ${req.user.email} changed role of ${user.email} from ${user.chuc_vu} to ${chuc_vu}`);
    
    res.json({
      success: true,
      message: `Đã cập nhật quyền của ${user.ho_ten} thành ${chuc_vu}`,
      user: userResponse
    });
  } catch (error) {
    console.error('Update user role error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi cập nhật quyền',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Lấy thông tin chi tiết user
exports.getUserDetail = async (req, res) => {
  try {
    const { userId } = req.params;
    
    const user = await NguoiDung.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Người dùng không tồn tại'
      });
    }
    
    // Remove password
    const { mat_khau, ...userResponse } = user;
    
    res.json({
      success: true,
      user: userResponse
    });
  } catch (error) {
    console.error('Get user detail error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi lấy thông tin người dùng',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Kích hoạt/Vô hiệu hóa tài khoản
exports.toggleUserStatus = async (req, res) => {
  try {
    const { userId } = req.params;
    const currentAdminId = req.user.id;
    
    // Không thể tự vô hiệu hóa tài khoản của chính mình
    if (parseInt(userId) === currentAdminId) {
      return res.status(400).json({
        success: false,
        message: 'Không thể tự vô hiệu hóa tài khoản của chính mình'
      });
    }
    
    const user = await NguoiDung.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Người dùng không tồn tại'
      });
    }
    
    // Toggle status
    const newStatus = user.trang_thai === 1 ? 0 : 1;
    const updatedUser = await NguoiDung.update(userId, {
      trang_thai: newStatus
    });
    
    // Remove password from response
    const { mat_khau, ...userResponse } = updatedUser;
    
    console.log(`✅ Admin ${req.user.email} ${newStatus === 1 ? 'activated' : 'deactivated'} user ${user.email}`);
    
    res.json({
      success: true,
      message: newStatus === 1 
        ? `Đã kích hoạt tài khoản ${user.ho_ten}` 
        : `Đã vô hiệu hóa tài khoản ${user.ho_ten}`,
      user: userResponse
    });
  } catch (error) {
    console.error('Toggle user status error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi thay đổi trạng thái tài khoản',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

