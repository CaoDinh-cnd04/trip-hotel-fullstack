// controllers/khachsanController.js - Hotel controller
const { check, validationResult } = require('express-validator');
const KhachSan = require('../models/khachsan');
const { getPool } = require('../config/db');
const sql = require('mssql');

// Helper function to transform hotel image URLs (auto-detect host from request)
const transformHotelImageUrl = (imagePath, req) => {
  if (!imagePath) return null;
  
  // If already a full URL, return as is
  if (imagePath.startsWith('http')) return imagePath;
  
  // Auto-detect host for emulator/device compatibility
  const host = req.get('host') || 'localhost:5000';
  const protocol = req.protocol || 'http';
  const baseUrl = `${protocol}://${host}`;
  
  // If starts with /, it's a relative path
  if (imagePath.startsWith('/')) return `${baseUrl}${imagePath}`;
  
  // Otherwise, prepend /images/hotels/
  return `${baseUrl}/images/hotels/${imagePath}`;
};

// Helper function to transform location image URLs
const transformLocationImageUrl = (imagePath) => {
  if (!imagePath) return null;
  const baseUrl = process.env.BASE_URL || 'http://localhost:5000';
  
  if (imagePath.startsWith('http')) return imagePath;
  if (imagePath.startsWith('/')) return `${baseUrl}${imagePath}`;
  
  return `${baseUrl}/images/provinces/${imagePath}`;
};

// Get all hotels
exports.getAllHotels = async (req, res) => {
  try {
    const { 
      page = 1, 
      limit = 10, 
      search,
      vi_tri_id,
      so_sao_min,
      so_sao_max,
      gia_min,
      gia_max,
      available_from,
      available_to,
      trang_thai, // Admin can filter by status
      admin_view // If true, show all hotels (including inactive)
    } = req.query;

    // Ensure page and limit are integers
    const pageInt = parseInt(page) || 1;
    const limitInt = parseInt(limit) || 10;

    let result;

    // If admin_view is true or user is admin, show all hotels
    const isAdmin = req.user?.chuc_vu === 'Admin' || admin_view === 'true';
    
    if (search || vi_tri_id || so_sao_min || so_sao_max || gia_min || gia_max || trang_thai) {
      // Search with filters
      result = await KhachSan.searchHotels(search, {
        page: pageInt,
        limit: limitInt,
        vi_tri_id,
        so_sao_min,
        so_sao_max,
        gia_min,
        gia_max,
        trang_thai: trang_thai || (isAdmin ? null : 'Hoạt động')
      });
    } else if (isAdmin) {
      // Admin: Get all hotels (including inactive)
      const whereClause = trang_thai ? `ks.trang_thai = N'${trang_thai}'` : '';
      result = await KhachSan.getHotelsWithFullInfo({ 
        page: pageInt, 
        limit: limitInt,
        where: whereClause,
        orderBy: 'ks.created_at DESC'
      });
    } else {
      // Regular user: Get only active hotels
      result = await KhachSan.getActiveHotels({ page: pageInt, limit: limitInt });
    }

    // Keep image as filename only, Flutter will add prefix
    const transformedData = result.data.map(hotel => ({
      ...hotel,
      hinh_anh: hotel.hinh_anh // Keep as filename: "bangkok_central.jpg"
    }));

    res.json({
      success: true,
      message: 'Lấy danh sách khách sạn thành công',
      data: transformedData,
      pagination: result.pagination
    });

  } catch (error) {
    console.error('Get hotels error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy danh sách khách sạn',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get hotel by ID
exports.getHotelById = async (req, res) => {
  try {
    const { id } = req.params;
    const { with_amenities, with_rooms, available_from, available_to } = req.query;

    const hotel = await KhachSan.getHotelWithDetails(id);

    if (!hotel) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn'
      });
    }

    // Transform hotel image URL
    hotel.hinh_anh = transformHotelImageUrl(hotel.hinh_anh, req);

    // Get all hotel images (gallery)
    try {
      const hotelImages = await KhachSan.getHotelImages(id);
      // Transform image URLs
      hotel.danh_sach_anh = hotelImages.map(img => ({
        id: img.id,
        duong_dan_anh: transformHotelImageUrl(img.duong_dan_anh, req),
        thu_tu: img.thu_tu,
        la_anh_dai_dien: img.la_anh_dai_dien === 1 || img.la_anh_dai_dien === true
      }));
    } catch (error) {
      console.log('⚠️ Could not fetch hotel images:', error.message);
      hotel.danh_sach_anh = [];
    }

    // Get amenities if requested
    if (with_amenities === 'true') {
      hotel.tien_nghi = await KhachSan.getHotelAmenities(id);
    }

    // Get rooms if requested
    if (with_rooms === 'true') {
      const rooms = await KhachSan.getHotelRooms(id, {
        available_from,
        available_to
      });
      
      // Keep room images as JSON string, Flutter will parse and add prefix
      hotel.phong = rooms.map(room => {
        return {
          ...room,
          hinh_anh: room.hinh_anh, // Keep as JSON string: ["img1.jpg","img2.jpg"]
          hinh_anh_phong: room.hinh_anh, // Alternative field name
          gia_tien: room.gia_tien,
          gia_phong: room.gia_tien,
          ma_phong: room.ma_phong,
          so_phong: room.ma_phong,
        };
      });
    }

    res.json({
      success: true,
      message: 'Lấy thông tin khách sạn thành công',
      data: hotel
    });

  } catch (error) {
    console.error('Get hotel by ID error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy thông tin khách sạn'
    });
  }
};

// Get hotel rooms
exports.getHotelRooms = async (req, res) => {
  try {
    const { id } = req.params;
    const { 
      page = 1, 
      limit = 20, 
      available_from, 
      available_to 
    } = req.query;

    // Check if hotel exists
    const hotel = await KhachSan.findById(id);
    if (!hotel) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn'
      });
    }

    const rooms = await KhachSan.getHotelRooms(id, {
      page,
      limit,
      available_from,
      available_to
    });

    // Transform room data - keep images as JSON string, Flutter will parse
    const transformedRooms = rooms.map(room => {
      // Keep hinh_anh as is (JSON string from DB), Flutter will parse it
      // Don't transform to full URLs - let Flutter add the prefix
      
      return {
        ...room,
        hinh_anh: room.hinh_anh, // Keep as JSON string: ["img1.jpg","img2.jpg"]
        hinh_anh_phong: room.hinh_anh, // Alternative field name
        // Also include price with both field names (gia_tien from SQL Server)
        gia_tien: room.gia_tien || 0,
        gia_phong: room.gia_tien || 0, // Map gia_tien to gia_phong for Flutter
        // Include room code/number
        ma_phong: room.ma_phong,
        so_phong: room.ma_phong, // Alternative field name (use ma_phong as so_phong)
        // Ensure capacity and bed fields are included (from loai_phong table)
        suc_chua: room.suc_chua || null,
        so_khach: room.suc_chua || null, // Alternative field name
        so_giuong_don: room.so_giuong_don || 0,
        so_giuong_doi: room.so_giuong_doi || 0,
      };
    });

    res.json({
      success: true,
      message: 'Lấy danh sách phòng thành công',
      data: transformedRooms
    });

  } catch (error) {
    console.error('Get hotel rooms error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy danh sách phòng'
    });
  }
};

// Get hotel amenities
exports.getHotelAmenities = async (req, res) => {
  try {
    const { id } = req.params;

    // Check if hotel exists
    const hotel = await KhachSan.findById(id);
    if (!hotel) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn'
      });
    }

    const amenities = await KhachSan.getHotelAmenities(id);

    res.json({
      success: true,
      message: 'Lấy danh sách tiện nghi thành công',
      data: amenities
    });

  } catch (error) {
    console.error('Get hotel amenities error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy danh sách tiện nghi'
    });
  }
};

// Get hotel paid amenities (for payment screen suggestions)
exports.getHotelPaidAmenities = async (req, res) => {
  try {
    const { id } = req.params;

    // Check if hotel exists
    const hotel = await KhachSan.findById(id);
    if (!hotel) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn'
      });
    }

    const pool = getPool();
    const query = `
      SELECT 
        tn.id,
        tn.ten,
        tn.nhom,
        tn.mo_ta,
        kstn.mien_phi,
        kstn.gia_phi,
        kstn.ghi_chu
      FROM dbo.khach_san_tien_nghi kstn
      JOIN dbo.tien_nghi tn ON kstn.tien_nghi_id = tn.id
      WHERE kstn.khach_san_id = @hotelId 
        AND tn.trang_thai = 1
        AND kstn.mien_phi = 0
        AND kstn.gia_phi > 0
      ORDER BY kstn.gia_phi ASC, tn.nhom, tn.ten
    `;

    const result = await pool.request()
      .input('hotelId', sql.Int, id)
      .query(query);

    res.json({
      success: true,
      message: 'Lấy danh sách dịch vụ có phí thành công',
      data: result.recordset || []
    });

  } catch (error) {
    console.error('Get hotel paid amenities error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy danh sách dịch vụ có phí'
    });
  }
};

// Get hotel free amenities (for high price bookings)
exports.getHotelFreeAmenities = async (req, res) => {
  try {
    const { id } = req.params;

    // Check if hotel exists
    const hotel = await KhachSan.findById(id);
    if (!hotel) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn'
      });
    }

    const pool = getPool();
    const query = `
      SELECT 
        tn.id,
        tn.ten,
        tn.nhom,
        tn.mo_ta,
        kstn.mien_phi,
        kstn.gia_phi,
        kstn.ghi_chu
      FROM dbo.khach_san_tien_nghi kstn
      JOIN dbo.tien_nghi tn ON kstn.tien_nghi_id = tn.id
      WHERE kstn.khach_san_id = @hotelId 
        AND tn.trang_thai = 1
        AND kstn.mien_phi = 1
      ORDER BY tn.nhom, tn.ten
    `;

    const result = await pool.request()
      .input('hotelId', sql.Int, id)
      .query(query);

    res.json({
      success: true,
      message: 'Lấy danh sách dịch vụ miễn phí thành công',
      data: result.recordset || []
    });

  } catch (error) {
    console.error('Get hotel free amenities error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy danh sách dịch vụ miễn phí'
    });
  }
};

// Get hotel statistics
exports.getHotelStats = async (req, res) => {
  try {
    const { id } = req.params;

    // Check if hotel exists
    const hotel = await KhachSan.findById(id);
    if (!hotel) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn'
      });
    }

    const stats = await KhachSan.getHotelStats(id);

    res.json({
      success: true,
      message: 'Lấy thống kê khách sạn thành công',
      data: stats
    });

  } catch (error) {
    console.error('Get hotel stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy thống kê khách sạn'
    });
  }
};

// Create new hotel
exports.createHotel = [
  // Validation rules
  check('ten')
    .notEmpty()
    .withMessage('Tên khách sạn không được để trống')
    .isLength({ min: 2, max: 100 })
    .withMessage('Tên khách sạn phải từ 2-100 ký tự'),
  
  check('mo_ta')
    .notEmpty()
    .withMessage('Mô tả không được để trống'),
  
  check('hinh_anh')
    .notEmpty()
    .withMessage('Hình ảnh không được để trống'),
  
  check('so_sao')
    .isInt({ min: 1, max: 5 })
    .withMessage('Số sao phải từ 1-5'),
  
  check('dia_chi')
    .notEmpty()
    .withMessage('Địa chỉ không được để trống'),
  
  check('vi_tri_id')
    .isInt({ min: 1 })
    .withMessage('Vị trí không hợp lệ'),
  
  check('ti_le_coc')
    .optional()
    .isFloat({ min: 0, max: 100 })
    .withMessage('Tỷ lệ cọc phải từ 0-100%'),

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

      const hotel = await KhachSan.createHotel(req.body);

      res.status(201).json({
        success: true,
        message: 'Tạo khách sạn thành công',
        data: hotel
      });

    } catch (error) {
      console.error('Create hotel error:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi tạo khách sạn'
      });
    }
  }
];

// Update hotel
exports.updateHotel = [
  // Validation rules
  check('ten')
    .optional()
    .isLength({ min: 2, max: 100 })
    .withMessage('Tên khách sạn phải từ 2-100 ký tự'),
  
  check('so_sao')
    .optional()
    .isInt({ min: 1, max: 5 })
    .withMessage('Số sao phải từ 1-5'),
  
  check('ti_le_coc')
    .optional()
    .isFloat({ min: 0, max: 100 })
    .withMessage('Tỷ lệ cọc phải từ 0-100%'),

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

      const { id } = req.params;
      const khachSan = new KhachSan();
      
      // Check if hotel exists (without status filter for admin)
      const checkQuery = `SELECT * FROM ${khachSan.tableName} WHERE ${khachSan.primaryKey} = @id`;
      const checkResult = await khachSan.executeQuery(checkQuery, { id });
      const existingHotel = checkResult.recordset[0];

      if (!existingHotel) {
        return res.status(404).json({
          success: false,
          message: 'Không tìm thấy khách sạn'
        });
      }

      // Update hotel
      const hotel = await khachSan.updateHotel(id, req.body);

      if (!hotel) {
        return res.status(500).json({
          success: false,
          message: 'Không thể cập nhật khách sạn'
        });
      }

      res.json({
        success: true,
        message: 'Cập nhật khách sạn thành công',
        data: hotel
      });

    } catch (error) {
      console.error('Update hotel error:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi cập nhật khách sạn',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined,
        stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
      });
    }
  }
];

// Toggle hotel status (lock/unlock)
exports.toggleHotelStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { action } = req.body; // 'lock' or 'unlock'
    console.log(`🔒 Toggling hotel status for ID: ${id}, action: ${action}`);
    const khachSan = new KhachSan();

    // Find hotel by ID without status check (to toggle blocked hotels)
    const checkQuery = `SELECT * FROM ${khachSan.tableName} WHERE ${khachSan.primaryKey} = @id`;
    console.log(`🔍 Checking hotel existence: ${checkQuery}`);
    const checkResult = await khachSan.executeQuery(checkQuery, { id });
    const hotel = checkResult.recordset[0];

    if (!hotel) {
      console.log(`❌ Hotel ${id} not found`);
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn'
      });
    }

    console.log(`✅ Hotel found: ${hotel.ten}, current status: ${hotel.trang_thai}`);

    let newStatus;
    if (action === 'lock' || action === 'ban') {
      newStatus = 'Bị chặn';
    } else if (action === 'unlock' || action === 'activate') {
      newStatus = 'Hoạt động';
    } else {
      // Toggle current status
      const currentStatus = hotel.trang_thai?.toString() || '';
      if (currentStatus === 'Hoạt động') {
        newStatus = 'Bị chặn';
      } else {
        newStatus = 'Hoạt động';
      }
    }

    console.log(`🔄 Updating status to: ${newStatus}`);

    // Update status using direct query with NVARCHAR for Vietnamese text
    // Use sql.NVarChar for proper Unicode handling
    const sql = require('mssql');
    const updateQuery = `
      UPDATE ${khachSan.tableName} 
      SET trang_thai = @newStatus, updated_at = GETDATE()
      WHERE ${khachSan.primaryKey} = @id
    `;
    
    try {
      const { getPool } = require('../config/db');
      const pool = await getPool();
      const updateResult = await pool.request()
        .input('id', sql.Int, parseInt(id))
        .input('newStatus', sql.NVarChar(50), newStatus)
        .query(updateQuery);

      console.log(`✅ Update executed, rows affected: ${updateResult.rowsAffected[0]}`);
      
      if (updateResult.rowsAffected[0] === 0) {
        console.log(`⚠️ No rows affected for hotel ${id}`);
        return res.status(500).json({
          success: false,
          message: 'Không thể cập nhật trạng thái khách sạn - không có dòng nào được cập nhật'
        });
      }
    } catch (updateError) {
      console.error('❌ Update query error:', updateError);
      throw updateError;
    }

    res.json({
      success: true,
      message: `Khách sạn đã được ${newStatus === 'Hoạt động' ? 'mở khóa' : 'khóa'}`,
      data: {
        id,
        trang_thai: newStatus
      }
    });

  } catch (error) {
    console.error('❌ Toggle hotel status error:', error);
    console.error('Error details:', {
      message: error.message,
      code: error.code,
      number: error.number,
      stack: error.stack
    });
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi cập nhật trạng thái khách sạn',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
};

// Delete hotel (soft delete)
exports.deleteHotel = async (req, res) => {
  try {
    const { id } = req.params;
    console.log(`🗑️ Deleting hotel with ID: ${id}`);
    const khachSan = new KhachSan();

    // Find hotel by ID without status check (to delete blocked hotels)
    const checkQuery = `SELECT * FROM ${khachSan.tableName} WHERE ${khachSan.primaryKey} = @id`;
    console.log(`🔍 Checking hotel existence: ${checkQuery}`);
    const checkResult = await khachSan.executeQuery(checkQuery, { id });
    const hotel = checkResult.recordset[0];

    if (!hotel) {
      console.log(`❌ Hotel ${id} not found`);
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn'
      });
    }

    console.log(`✅ Hotel found: ${hotel.ten}, current status: ${hotel.trang_thai}`);

    // Soft delete - set trang_thai = 'Ngừng hoạt động' using direct query with NVARCHAR
    // Sử dụng transaction để đảm bảo commit
    const sql = require('mssql');
    const { getPool } = require('../config/db');
    const pool = await getPool();
    const transaction = new sql.Transaction(pool);
    
    try {
        await transaction.begin();
        console.log(`🔄 Transaction started for deleting hotel ${id}`);
        
        const deleteStatus = 'Ngừng hoạt động';
        const deleteQuery = `
          UPDATE ${khachSan.tableName} 
          SET trang_thai = @deleteStatus, updated_at = GETDATE()
          WHERE ${khachSan.primaryKey} = @id
        `;
        
        console.log(`🔄 Executing delete query: ${deleteQuery}`);
        const request = new sql.Request(transaction);
        const deleteResult = await request
          .input('id', sql.Int, parseInt(id))
          .input('deleteStatus', sql.NVarChar(50), deleteStatus)
          .query(deleteQuery);

        console.log(`✅ Delete query executed, rows affected: ${deleteResult.rowsAffected[0]}`);
        
        if (deleteResult.rowsAffected[0] === 0) {
            await transaction.rollback();
            console.log(`⚠️ No rows affected for hotel ${id}, rolling back`);
            return res.status(500).json({
                success: false,
                message: 'Không thể xóa khách sạn - không có dòng nào được cập nhật'
            });
        }
        
        // Commit transaction
        await transaction.commit();
        console.log(`✅ Transaction committed for hotel ${id}`);
        
        // Verify deletion sau khi commit
        await new Promise(resolve => setTimeout(resolve, 200));

        // Verify deletion
        const verifyQuery = `SELECT ${khachSan.primaryKey}, trang_thai FROM ${khachSan.tableName} WHERE ${khachSan.primaryKey} = @id`;
        const verifyResult = await pool.request()
          .input('id', sql.Int, parseInt(id))
          .query(verifyQuery);
        const updatedHotel = verifyResult.recordset[0];

        console.log(`🔍 Verification result:`, updatedHotel);

        // Check if trang_thai matches 'Ngừng hoạt động'
        const isDeleted = updatedHotel && 
                         (updatedHotel.trang_thai === 'Ngừng hoạt động' || 
                          updatedHotel.trang_thai?.toString() === 'Ngừng hoạt động');

        if (!isDeleted) {
            console.log(`❌ Hotel status not updated correctly. Current status: ${updatedHotel?.trang_thai}`);
            return res.status(500).json({
                success: false,
                message: 'Không thể xóa khách sạn - trạng thái không được cập nhật'
            });
        }

        console.log(`✅ Hotel ${id} deleted successfully`);
        res.json({
            success: true,
            message: 'Xóa khách sạn thành công'
        });
    } catch (deleteError) {
        // Rollback transaction nếu có lỗi
        if (transaction) {
            try {
                await transaction.rollback();
                console.log(`🔄 Transaction rolled back due to error`);
            } catch (rollbackError) {
                console.error('❌ Error rolling back transaction:', rollbackError);
            }
        }
        
        console.error('❌ Delete query error:', deleteError);
        // Kiểm tra xem có phải lỗi foreign key constraint không
        if (deleteError.number === 547) {
            return res.status(400).json({
                success: false,
                message: 'Không thể xóa khách sạn vì đang được sử dụng trong hệ thống (có dữ liệu liên quan)',
                error: process.env.NODE_ENV === 'development' ? {
                    message: deleteError.message,
                    number: deleteError.number
                } : undefined
            });
        }
        throw deleteError; // Re-throw để catch block xử lý
    }

  } catch (error) {
    console.error('❌ Delete hotel error:', error);
    console.error('Error details:', {
      message: error.message,
      code: error.code,
      number: error.number,
      stack: error.stack
    });
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi xóa khách sạn',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
};

// Get hotels by manager (for hotel managers)
exports.getMyHotels = async (req, res) => {
  try {
    const { page = 1, limit = 10 } = req.query;
    const managerId = req.user.id;

    const result = await KhachSan.getHotelsByManager(managerId, { page, limit });

    res.json({
      success: true,
      message: 'Lấy danh sách khách sạn của tôi thành công',
      data: result.data,
      pagination: result.pagination
    });

  } catch (error) {
    console.error('Get my hotels error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy danh sách khách sạn'
    });
  }
};

// Get hotel reviews (Public - no auth required)
exports.getHotelReviews = async (req, res) => {
  try {
    const { id } = req.params;
    const pool = getPool();
    
    console.log('📋 Getting reviews for hotel ID:', id);
    
    // Get reviews for this hotel (only approved reviews)
    const query = `
      SELECT 
        dg.id,
        dg.so_sao_tong as rating,
        dg.binh_luan as content,
        dg.ngay as review_date,
        dg.phan_hoi_khach_san as hotel_response,
        dg.ngay_phan_hoi as response_date,
        nd.ho_ten as customer_name,
        nd.anh_dai_dien as customer_avatar,
        COALESCE(b.room_number, 'N/A') as room_number
      FROM danh_gia dg
      LEFT JOIN nguoi_dung nd ON dg.nguoi_dung_id = nd.id
      LEFT JOIN bookings b ON dg.phieu_dat_phong_id = b.id
      WHERE dg.khach_san_id = @hotelId
        AND dg.trang_thai = N'Đã duyệt'
      ORDER BY dg.ngay DESC
    `;
    
    const result = await pool.request()
      .input('hotelId', sql.Int, id)
      .query(query);
    
    console.log(`✅ Found ${result.recordset.length} reviews for hotel ${id}`);
    
    res.json({
      success: true,
      message: 'Lấy danh sách đánh giá thành công',
      data: result.recordset || []
    });
    
  } catch (error) {
    console.error('Get hotel reviews error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy danh sách đánh giá',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

module.exports = exports;