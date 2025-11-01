const NguoiDung = require('../models/nguoidung');
const KhachSan = require('../models/khachsan');
const PhieuDatPhg = require('../models/phieudatphg');
const HotelRegistration = require('../models/hotelRegistration');

// Dashboard KPI
exports.getDashboardKpi = async (req, res) => {
  try {
    console.log('📊 Getting dashboard KPI...');
    
    // Get user statistics
    const userStats = await NguoiDung.getStats();
    console.log('✅ User stats:', userStats);
    
    // Get hotel statistics
    const hotelStats = await KhachSan.getStats();
    console.log('✅ Hotel stats:', hotelStats);
    
    // Get booking statistics
    const bookingStats = await PhieuDatPhg.getStats();
    console.log('✅ Booking stats:', bookingStats);
    
    // ✅ NEW: Get hotel registration pending count
    const pendingRegistrations = await HotelRegistration.getAll({ status: 'pending' });
    const hoSoChoDuyet = pendingRegistrations?.length || 0;
    console.log(`✅ Hotel registrations pending: ${hoSoChoDuyet}`);
    
    // Calculate KPI data
    const kpiData = {
      tongSoNguoiDung: userStats.activeUsers || 0, // Chỉ count active users
      activeUsers: userStats.activeUsers || 0,
      newUsersThisMonth: userStats.newUsersThisMonth || 0,
      tongSoKhachSan: hotelStats.activeHotels || 0, // Chỉ count active hotels
      activeHotels: hotelStats.activeHotels || 0,
      totalBookings: bookingStats.totalBookings || 0,
      completedBookings: bookingStats.completedBookings || 0,
      pendingBookings: bookingStats.pendingBookings || 0,
      totalRevenue: bookingStats.totalRevenue || 0,
      monthlyRevenue: bookingStats.monthlyRevenue || 0,
      hoSoChoDuyet: hoSoChoDuyet, // ✅ NEW: Số lượng đơn đăng ký khách sạn chờ duyệt
      userRoleDistribution: userStats.roleDistribution || [],
      bookingStatusDistribution: bookingStats.statusDistribution || [],
      monthlyGrowth: {
        users: userStats.monthlyGrowth || 0,
        bookings: bookingStats.monthlyGrowth || 0,
        revenue: bookingStats.revenueGrowth || 0
      }
    };

    res.json({
      success: true,
      data: kpiData
    });
  } catch (error) {
    console.error('Get dashboard KPI error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy dữ liệu dashboard',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// User Management
exports.getUsers = async (req, res) => {
  try {
    console.log('👥 Getting users list...');
    const { page = 1, limit = 20, chuc_vu, search } = req.query;
    const offset = (page - 1) * limit;
    
    let whereConditions = [];
    
    // Only show active users (not soft-deleted)
    // trang_thai is a boolean in SQL Server (BIT type)
    whereConditions.push('trang_thai = CAST(1 AS BIT)');
    
    if (chuc_vu && chuc_vu !== 'all') {
      whereConditions.push(`chuc_vu = '${chuc_vu}'`);
    }
    
    if (search) {
      whereConditions.push(`(ho_ten LIKE '%${search}%' OR email LIKE '%${search}%')`);
    }
    
    const whereClause = whereConditions.join(' AND ');
    
    const result = await NguoiDung.findAll({
      page: parseInt(page),
      limit: parseInt(limit),
      where: whereClause,
      orderBy: 'id DESC'
    });
    
    // BaseModel.findAll() returns { data: [...], pagination: {...} }
    const users = result.data || [];
    
    console.log('✅ Found', users.length, 'users');
    if (users.length > 0) {
      console.log('📦 Sample user (first):', JSON.stringify(users[0], null, 2));
    }
    
    res.json({
      success: true,
      data: users,
      pagination: result.pagination || {
        page: parseInt(page),
        limit: parseInt(limit),
        total: 0,
        totalPages: 0
      }
    });
  } catch (error) {
    console.error('❌ Get users error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy danh sách người dùng',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

exports.getUserById = async (req, res) => {
  try {
    const { id } = req.params;
    const user = await NguoiDung.findById(id);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy người dùng'
      });
    }
    
    res.json({
      success: true,
      data: user
    });
  } catch (error) {
    console.error('Get user by ID error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy thông tin người dùng',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

exports.updateUser = async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;
    
    // Remove sensitive fields
    delete updateData.mat_khau;
    delete updateData.id;
    
    const updatedUser = await NguoiDung.update(id, updateData);
    
    res.json({
      success: true,
      message: 'Cập nhật người dùng thành công',
      data: updatedUser
    });
  } catch (error) {
    console.error('Update user error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi cập nhật người dùng',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

exports.deleteUser = async (req, res) => {
  try {
    const { id } = req.params;
    
    // Check if user exists
    const user = await NguoiDung.findById(id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy người dùng'
      });
    }
    
    // Soft delete by setting status to 0
    await NguoiDung.update(id, { trang_thai: 0 });
    
    res.json({
      success: true,
      message: 'Xóa người dùng thành công'
    });
  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi xóa người dùng',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

exports.updateUserStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { trang_thai } = req.body;
    
    await NguoiDung.update(id, { trang_thai });
    
    res.json({
      success: true,
      message: 'Cập nhật trạng thái người dùng thành công'
    });
  } catch (error) {
    console.error('Update user status error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi cập nhật trạng thái người dùng',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Role Management
exports.getRoles = async (req, res) => {
  try {
    const roles = [
      { id: 1, name: 'Admin', displayName: 'Quản trị viên', permissions: ['*'] },
      { id: 2, name: 'HotelManager', displayName: 'Quản lý khách sạn', permissions: ['hotel:read', 'hotel:write', 'room:read', 'room:write', 'booking:read', 'booking:write'] },
      { id: 3, name: 'User', displayName: 'Người dùng', permissions: ['booking:read', 'booking:write', 'hotel:read', 'room:read'] }
    ];
    
    res.json({
      success: true,
      data: roles
    });
  } catch (error) {
    console.error('Get roles error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy danh sách vai trò',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Application Review (placeholder)
exports.getApplications = async (req, res) => {
  try {
    const { page = 1, limit = 20, trang_thai } = req.query;
    
    let whereConditions = [];
    
    if (trang_thai && trang_thai !== 'all') {
      whereConditions.push(`status = '${trang_thai}'`);
    }
    
    const whereClause = whereConditions.length > 0 ? whereConditions.join(' AND ') : '';
    
    const result = await HotelRegistration.findAll({
      page: parseInt(page),
      limit: parseInt(limit),
      where: whereClause,
      orderBy: 'created_at DESC'
    });
    
    const total = await HotelRegistration.count(whereClause ? `WHERE ${whereClause}` : '');
    
    res.json({
      success: true,
      data: result || [],
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Get applications error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy danh sách đơn đăng ký',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

exports.getApplicationById = async (req, res) => {
  try {
    const { id } = req.params;
    
    const application = await HotelRegistration.findById(id);
    
    if (!application) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy đơn đăng ký'
      });
    }
    
    res.json({
      success: true,
      data: application
    });
  } catch (error) {
    console.error('Get application by ID error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy thông tin đơn đăng ký',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

exports.approveApplication = async (req, res) => {
  try {
    const { id } = req.params;
    // Placeholder implementation
    res.json({
      success: true,
      message: 'Duyệt đơn đăng ký thành công'
    });
  } catch (error) {
    console.error('Approve application error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi duyệt đơn đăng ký',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

exports.rejectApplication = async (req, res) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    // Placeholder implementation
    res.json({
      success: true,
      message: 'Từ chối đơn đăng ký thành công'
    });
  } catch (error) {
    console.error('Reject application error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi từ chối đơn đăng ký',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Statistics
exports.getUserStats = async (req, res) => {
  try {
    const stats = await NguoiDung.getStats();
    res.json({
      success: true,
      data: stats
    });
  } catch (error) {
    console.error('Get user stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy thống kê người dùng',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

exports.getHotelStats = async (req, res) => {
  try {
    const stats = await KhachSan.getStats();
    res.json({
      success: true,
      data: stats
    });
  } catch (error) {
    console.error('Get hotel stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy thống kê khách sạn',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

exports.getBookingStats = async (req, res) => {
  try {
    const stats = await PhieuDatPhg.getStats();
    res.json({
      success: true,
      data: stats
    });
  } catch (error) {
    console.error('Get booking stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy thống kê đặt phòng',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

exports.getRevenueStats = async (req, res) => {
  try {
    // Placeholder implementation
    res.json({
      success: true,
      data: {
        totalRevenue: 0,
        monthlyRevenue: 0,
        yearlyRevenue: 0,
        revenueGrowth: 0
      }
    });
  } catch (error) {
    console.error('Get revenue stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy thống kê doanh thu',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// System Management
exports.getSystemHealth = async (req, res) => {
  try {
    res.json({
      success: true,
      data: {
        status: 'healthy',
        uptime: process.uptime(),
        memory: process.memoryUsage(),
        timestamp: new Date().toISOString()
      }
    });
  } catch (error) {
    console.error('Get system health error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi kiểm tra trạng thái hệ thống',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

exports.getSystemLogs = async (req, res) => {
  try {
    // Placeholder implementation
    res.json({
      success: true,
      data: [],
      message: 'Chức năng đang được phát triển'
    });
  } catch (error) {
    console.error('Get system logs error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy log hệ thống',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

exports.createBackup = async (req, res) => {
  try {
    // Placeholder implementation
    res.json({
      success: true,
      message: 'Tạo backup thành công',
      data: {
        backupId: Date.now(),
        timestamp: new Date().toISOString()
      }
    });
  } catch (error) {
    console.error('Create backup error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi tạo backup',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// ✅ NEW: Update hotel status (Admin only)
exports.updateHotelStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { trang_thai } = req.body;
    
    console.log(`🔍 Admin updating hotel ${id} status to: ${trang_thai}`);
    
    // Validate status
    const validStatuses = ['Hoạt động', 'Tạm dừng', 'Đang bảo trì'];
    if (!validStatuses.includes(trang_thai)) {
      return res.status(400).json({
        success: false,
        message: `Trạng thái không hợp lệ. Cho phép: ${validStatuses.join(', ')}`
      });
    }
    
    // Check if hotel exists
    const hotel = await KhachSan.getById(id);
    if (!hotel) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn'
      });
    }
    
    // Update status
    await KhachSan.update(id, { trang_thai });
    
    console.log(`✅ Admin ${req.user.email} updated hotel "${hotel.ten}" status to "${trang_thai}"`);
    
    res.json({
      success: true,
      message: `Đã cập nhật trạng thái khách sạn thành "${trang_thai}"`,
      data: { id, trang_thai }
    });
  } catch (error) {
    console.error('Update hotel status error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi cập nhật trạng thái khách sạn',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};