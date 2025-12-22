const NguoiDung = require('../models/nguoidung');
const KhachSan = require('../models/khachsan');
const PhieuDatPhg = require('../models/phieudatphg');
const HotelRegistration = require('../models/hotelRegistration');

// Dashboard KPI
exports.getDashboardKpi = async (req, res) => {
  try {
    console.log('📊 Getting dashboard KPI...');
    
    // Get user statistics - NguoiDung is exported as class, so use new
    const nguoiDung = new NguoiDung();
    const userStats = await nguoiDung.getStats();
    console.log('✅ User stats:', userStats);
    
    // Get hotel statistics - KhachSan is exported as instance, use directly
    let hotelStats = {
      totalHotels: 0,
      activeHotels: 0,
      newHotelsThisMonth: 0
    };
    try {
      // KhachSan is already an instance, call method directly
      hotelStats = await KhachSan.getStats();
      console.log('✅ Hotel stats:', hotelStats);
    } catch (hotelError) {
      console.error('⚠️ Error getting hotel stats:', hotelError);
      console.error('⚠️ Error message:', hotelError.message);
      console.error('⚠️ Error stack:', hotelError.stack);
      // Use default values
    }
    
    // Get booking statistics - PhieuDatPhg is exported as instance, use directly
    let bookingStats = {
      totalBookings: 0,
      completedBookings: 0,
      pendingBookings: 0,
      totalRevenue: 0,
      monthlyRevenue: 0,
      statusDistribution: []
    };
    try {
      bookingStats = await PhieuDatPhg.getStats();
      console.log('✅ Booking stats:', bookingStats);
    } catch (bookingError) {
      console.error('⚠️ Error getting booking stats:', bookingError);
      console.error('⚠️ Error message:', bookingError.message);
      // Use default values if booking stats fail
    }
    
    // Get hotel registration pending count
    let hoSoChoDuyet = 0;
    try {
      const pendingRegistrations = await HotelRegistration.getAll({ status: 'pending' });
      hoSoChoDuyet = Array.isArray(pendingRegistrations) ? pendingRegistrations.length : 0;
      console.log(`✅ Hotel registrations pending: ${hoSoChoDuyet}`);
    } catch (regError) {
      console.error('⚠️ Error getting pending registrations:', regError);
      hoSoChoDuyet = 0;
    }
    
    // Calculate KPI data - ensure all values are properly extracted from SQL Server results
    const kpiData = {
      tongSoNguoiDung: parseInt(userStats?.activeUsers) || parseInt(userStats?.dang_hoat_dong) || 0,
      activeUsers: parseInt(userStats?.activeUsers) || parseInt(userStats?.dang_hoat_dong) || 0,
      newUsersThisMonth: parseInt(userStats?.newUsersThisMonth) || 0,
      tongSoKhachSan: parseInt(hotelStats?.activeHotels) || 0,
      activeHotels: parseInt(hotelStats?.activeHotels) || 0,
      totalBookings: parseInt(bookingStats?.totalBookings) || 0,
      completedBookings: parseInt(bookingStats?.completedBookings) || 0,
      pendingBookings: parseInt(bookingStats?.pendingBookings) || 0,
      totalRevenue: parseFloat(bookingStats?.totalRevenue) || 0,
      monthlyRevenue: parseFloat(bookingStats?.monthlyRevenue) || 0,
      hoSoChoDuyet: hoSoChoDuyet,
      userRoleDistribution: userStats?.roleDistribution || [],
      bookingStatusDistribution: bookingStats?.statusDistribution || [],
      monthlyGrowth: {
        users: parseFloat(userStats?.monthlyGrowth) || 0,
        bookings: parseFloat(bookingStats?.monthlyGrowth) || 0,
        revenue: parseFloat(bookingStats?.revenueGrowth) || 0
      }
    };

    console.log('📊 Final KPI data:', kpiData);

    res.json({
      success: true,
      data: kpiData
    });
  } catch (error) {
    console.error('❌ Get dashboard KPI error:', error);
    console.error('❌ Error stack:', error.stack);
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
    
    const nguoiDung = new NguoiDung();
    const result = await nguoiDung.findAll({
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
    const nguoiDung = new NguoiDung();
    const user = await nguoiDung.findById(id);
    
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
    
    const nguoiDung = new NguoiDung();
    const updatedUser = await nguoiDung.update(id, updateData);
    
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
    const nguoiDung = new NguoiDung();
    const user = await nguoiDung.findById(id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy người dùng'
      });
    }
    
    // Soft delete by setting status to 0
    await nguoiDung.update(id, { trang_thai: 0 });
    
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
    
    const nguoiDung = new NguoiDung();
    await nguoiDung.update(id, { trang_thai });
    
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
    const nguoiDung = new NguoiDung();
    const stats = await nguoiDung.getStats();
    res.json({
      success: true,
      data: stats
    });
  } catch (error) {
    console.error('Get user stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy thống kê người dùng',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
};

exports.getHotelStats = async (req, res) => {
  try {
    // KhachSan is exported as instance, call method directly
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
    // PhieuDatPhg is exported as instance, so we can call getStats directly
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
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
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

// Get system statistics for reports (with trends)
exports.getSystemStatistics = async (req, res) => {
  try {
    console.log('📊 getSystemStatistics called');
    console.log('📊 Request user:', req.user);
    console.log('📊 Request query:', req.query);
    
    const { from_date, to_date } = req.query;
    
    console.log('📊 Getting system statistics with params:', { from_date, to_date });
    
    // Parse dates or use defaults
    let fromDate, toDate;
    try {
      fromDate = from_date ? new Date(from_date) : new Date(Date.now() - 30 * 24 * 60 * 60 * 1000); // 30 days ago
      toDate = to_date ? new Date(to_date) : new Date();
      
      // Validate dates
      if (isNaN(fromDate.getTime()) || isNaN(toDate.getTime())) {
        throw new Error('Invalid date format');
      }
      
      // Ensure toDate is after fromDate
      if (toDate < fromDate) {
        const temp = fromDate;
        fromDate = toDate;
        toDate = temp;
      }
    } catch (dateError) {
      console.error('Date parsing error:', dateError);
      return res.status(400).json({
        success: false,
        message: 'Định dạng ngày không hợp lệ. Sử dụng ISO 8601 format (YYYY-MM-DDTHH:mm:ss.sssZ)',
        error: process.env.NODE_ENV === 'development' ? dateError.message : undefined
      });
    }
    
    console.log('📊 Getting system statistics from', fromDate.toISOString(), 'to', toDate.toISOString());
    
    const { getPool } = require('../config/db');
    const sql = require('mssql');
    const pool = await getPool();
    
    // Get booking trends (daily)
    let bookingTrend = [];
    try {
      // Get booking trends from bookings table
      const bookingTrendQuery = `
        SELECT 
          CAST(created_at AS DATE) as date,
          COUNT(*) as count
        FROM dbo.bookings
        WHERE created_at >= @fromDate 
          AND created_at <= @toDate
          AND booking_status != 'cancelled'
        GROUP BY CAST(created_at AS DATE)
        ORDER BY date ASC
      `;
      
      console.log('📊 Executing booking trend query...');
      console.log('📊 Date range:', fromDate.toISOString(), 'to', toDate.toISOString());
      const bookingTrendResult = await pool.request()
        .input('fromDate', sql.DateTime, fromDate)
        .input('toDate', sql.DateTime, toDate)
        .query(bookingTrendQuery);
      
      console.log(`✅ Booking trend query returned ${bookingTrendResult.recordset.length} rows`);
      if (bookingTrendResult.recordset.length > 0) {
        console.log('📊 Sample booking trend data:', bookingTrendResult.recordset[0]);
      }
      
      bookingTrend = bookingTrendResult.recordset.map(row => {
        let date;
        if (row.date instanceof Date) {
          date = row.date;
        } else if (row.date) {
          date = new Date(row.date);
        } else {
          return null;
        }
        return {
          date: date.toISOString().split('T')[0],
          count: parseInt(row.count) || 0
        };
      }).filter(item => item !== null);
    } catch (error) {
      console.error('❌ Error fetching booking trend:', error);
      console.error('❌ Error details:', {
        message: error.message,
        code: error.code,
        number: error.number,
        stack: error.stack
      });
      bookingTrend = [];
    }
    
    // Get revenue trends (daily)
    let revenueTrend = [];
    try {
      // Get revenue trends from bookings table - System revenue (15% of final_price)
      const revenueTrendQuery = `
        SELECT 
          CAST(created_at AS DATE) as date,
          SUM(CASE WHEN booking_status IN ('confirmed', 'checked_in', 'in_progress', 'completed', 'checked_out') 
            AND final_price > 0
            AND (payment_status IS NULL OR payment_status != 'refunded')
            THEN final_price * 0.15 
            ELSE 0 END) as amount
        FROM dbo.bookings
        WHERE created_at >= @fromDate 
          AND created_at <= @toDate
          AND booking_status != 'cancelled'
        GROUP BY CAST(created_at AS DATE)
        ORDER BY date ASC
      `;
      
      console.log('📊 Executing revenue trend query...');
      const revenueTrendResult = await pool.request()
        .input('fromDate', sql.DateTime, fromDate)
        .input('toDate', sql.DateTime, toDate)
        .query(revenueTrendQuery);
      
      console.log(`✅ Revenue trend query returned ${revenueTrendResult.recordset.length} rows`);
      if (revenueTrendResult.recordset.length > 0) {
        console.log('📊 Sample revenue trend data:', revenueTrendResult.recordset[0]);
      }
      
      revenueTrend = revenueTrendResult.recordset.map(row => {
        let date;
        if (row.date instanceof Date) {
          date = row.date;
        } else if (row.date) {
          date = new Date(row.date);
        } else {
          return null;
        }
        return {
          date: date.toISOString().split('T')[0],
          amount: parseFloat(row.amount || 0)
        };
      }).filter(item => item !== null);
    } catch (error) {
      console.error('❌ Error fetching revenue trend:', error);
      console.error('❌ Error details:', {
        message: error.message,
        code: error.code,
        number: error.number,
        stack: error.stack
      });
      revenueTrend = [];
    }
    
    // Get summary statistics
    let summary = {
      total_bookings: 0,
      completed_bookings: 0,
      confirmed_bookings: 0,
      pending_bookings: 0,
      total_revenue: 0,
      avg_booking_value: 0
    };
    
    try {
      // Get summary statistics for the date range from bookings table
      // Revenue calculation: System gets 15% of final_price, Hotel gets 75% of final_price
      const summaryQuery = `
        SELECT 
          COUNT(*) as total_bookings,
          SUM(CASE WHEN b.booking_status IN ('completed', 'checked_out') THEN 1 ELSE 0 END) as completed_bookings,
          SUM(CASE WHEN b.booking_status IN ('confirmed', 'checked_in', 'in_progress') THEN 1 ELSE 0 END) as confirmed_bookings,
          SUM(CASE WHEN b.booking_status IN ('pending', 'waiting') THEN 1 ELSE 0 END) as pending_bookings,
          -- System revenue: 15% of final_price for completed/confirmed bookings
          SUM(CASE WHEN b.booking_status IN ('confirmed', 'checked_in', 'in_progress', 'completed', 'checked_out') 
            AND b.final_price > 0
            AND (b.payment_status IS NULL OR b.payment_status != 'refunded')
            THEN b.final_price * 0.15 
            ELSE 0 END) as total_revenue,
          -- Hotel revenue: 75% of final_price for completed/confirmed bookings
          SUM(CASE WHEN b.booking_status IN ('confirmed', 'checked_in', 'in_progress', 'completed', 'checked_out') 
            AND b.final_price > 0
            AND (b.payment_status IS NULL OR b.payment_status != 'refunded')
            THEN b.final_price * 0.75 
            ELSE 0 END) as hotel_revenue,
          -- Average booking value
          AVG(CASE WHEN b.booking_status IN ('confirmed', 'checked_in', 'in_progress', 'completed', 'checked_out') 
            AND b.final_price > 0
            AND (b.payment_status IS NULL OR b.payment_status != 'refunded')
            THEN b.final_price 
            ELSE NULL END) as avg_booking_value
        FROM dbo.bookings b
        WHERE b.created_at >= @fromDate 
          AND b.created_at <= @toDate
          AND b.booking_status != 'cancelled'
      `;
      
      console.log('📊 Executing summary statistics query...');
      console.log('📊 Date range:', fromDate.toISOString(), 'to', toDate.toISOString());
      const summaryResult = await pool.request()
        .input('fromDate', sql.DateTime, fromDate)
        .input('toDate', sql.DateTime, toDate)
        .query(summaryQuery);
      
      console.log('✅ Summary statistics query result:', summaryResult.recordset[0]);
      summary = summaryResult.recordset[0] || summary;
      
      // Convert to numbers
      summary.total_bookings = parseInt(summary.total_bookings) || 0;
      summary.completed_bookings = parseInt(summary.completed_bookings) || 0;
      summary.confirmed_bookings = parseInt(summary.confirmed_bookings) || 0;
      summary.pending_bookings = parseInt(summary.pending_bookings) || 0;
      summary.total_revenue = parseFloat(summary.total_revenue) || 0; // System revenue (15%)
      summary.hotel_revenue = parseFloat(summary.hotel_revenue) || 0; // Hotel revenue (75%)
      summary.avg_booking_value = parseFloat(summary.avg_booking_value) || 0;
      
      console.log('📊 Processed summary:', summary);
      console.log(`💰 System revenue (15%): ${summary.total_revenue.toLocaleString('vi-VN')} VND`);
      console.log(`🏨 Hotel revenue (75%): ${summary.hotel_revenue.toLocaleString('vi-VN')} VND`);
    } catch (error) {
      console.error('❌ Error fetching summary statistics:', error);
      console.error('❌ Error details:', {
        message: error.message,
        code: error.code,
        number: error.number,
        stack: error.stack
      });
      // Use default summary values
    }
    
    const responseData = {
      summary: {
        total_bookings: summary.total_bookings || 0,
        completed_bookings: summary.completed_bookings || 0,
        confirmed_bookings: summary.confirmed_bookings || 0,
        pending_bookings: summary.pending_bookings || 0,
        total_revenue: parseFloat(summary.total_revenue || 0), // System revenue (15% of booking total)
        hotel_revenue: parseFloat(summary.hotel_revenue || 0), // Hotel revenue (75% of booking total)
        avg_booking_value: parseFloat(summary.avg_booking_value || 0)
      },
      booking_trend: bookingTrend,
      revenue_trend: revenueTrend,
      period: {
        from: fromDate.toISOString(),
        to: toDate.toISOString()
      }
    };

    // Get user stats - NguoiDung is exported as class, so use new
    try {
      const nguoiDung = new NguoiDung();
      const userStats = await nguoiDung.getStats();
      // Ensure proper data type conversion
      responseData.user_stats = {
        activeUsers: parseInt(userStats?.activeUsers) || 0,
        newUsersThisMonth: parseInt(userStats?.newUsersThisMonth) || 0,
        roleDistribution: userStats?.roleDistribution || []
      };
    } catch (error) {
      console.error('Error fetching user stats:', error);
      responseData.user_stats = {
        activeUsers: 0,
        newUsersThisMonth: 0,
        roleDistribution: []
      };
    }
    
    // Get hotel stats - KhachSan is exported as instance, use directly
    try {
      const hotelStats = await KhachSan.getStats();
      // Ensure proper data type conversion
      responseData.hotel_stats = {
        totalHotels: parseInt(hotelStats?.totalHotels) || 0,
        activeHotels: parseInt(hotelStats?.activeHotels) || 0,
        newHotelsThisMonth: parseInt(hotelStats?.newHotelsThisMonth) || 0
      };
    } catch (error) {
      console.error('Error fetching hotel stats:', error);
      console.error('Error details:', {
        message: error.message,
        stack: error.stack
      });
      responseData.hotel_stats = {
        totalHotels: 0,
        activeHotels: 0,
        newHotelsThisMonth: 0
      };
    }

    res.json({
      success: true,
      data: responseData
    });
  } catch (error) {
    console.error('Get system statistics error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy thống kê hệ thống',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
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