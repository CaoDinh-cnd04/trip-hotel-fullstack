const { getPool } = require('../config/db');
const sql = require('mssql');

// Get hotel manager's assigned hotel
exports.getAssignedHotel = async (req, res) => {
  try {
    const managerId = req.user.id;
    const pool = getPool();
    
    const query = `
      SELECT 
        ks.id,
        ks.ten as ten_khach_san,
        ks.mo_ta,
        ks.hinh_anh,
        ks.so_sao,
        ks.trang_thai,
        ks.dia_chi,
        ks.vi_tri_id,
        vt.ten as ten_vi_tri,
        tt.ten as ten_tinh_thanh,
        qg.ten as ten_quoc_gia
      FROM khach_san ks
      LEFT JOIN vi_tri vt ON ks.vi_tri_id = vt.id
      LEFT JOIN tinh_thanh tt ON vt.tinh_thanh_id = tt.id
      LEFT JOIN quoc_gia qg ON tt.quoc_gia_id = qg.id
      WHERE ks.nguoi_quan_ly_id = @managerId
    `;
    
    const result = await pool.request()
      .input('managerId', managerId)
      .query(query);
    
    if (!result.recordset || result.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn được gán cho quản lý này'
      });
    }
    
    const hotelData = result.recordset[0];
    
    // Transform image path to full URL (auto-detect host for emulator compatibility)
    if (hotelData.hinh_anh && !hotelData.hinh_anh.startsWith('http')) {
      const host = req.get('host') || 'localhost:5000';
      const protocol = req.protocol || 'http';
      hotelData.hinh_anh = `${protocol}://${host}/images/hotels/${hotelData.hinh_anh}`;
    }
    
    res.json({
      success: true,
      data: hotelData
    });
  } catch (error) {
    console.error('Get assigned hotel error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy thông tin khách sạn',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get hotel rooms
exports.getHotelRooms = async (req, res) => {
  try {
    const managerId = req.user.id;
    const pool = getPool();
    
    // Get hotel ID for this manager
    const hotelResult = await pool.request()
      .input('managerId', managerId)
      .query('SELECT id FROM khach_san WHERE nguoi_quan_ly_id = @managerId');
    
    if (!hotelResult.recordset || hotelResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn được gán'
      });
    }
    
    const hotelId = hotelResult.recordset[0].id;
    
    // Get rooms for this hotel
    const query = `
      SELECT 
        p.id,
        p.ten,
        p.ma_phong,
        p.mo_ta,
        p.gia_tien,
        p.hinh_anh,
        p.dien_tich,
        p.trang_thai,
        lp.ten as ten_loai_phong,
        lp.so_khach,
        lp.so_giuong_don,
        lp.so_giuong_doi
      FROM phong p
      LEFT JOIN loai_phong lp ON p.loai_phong_id = lp.id
      WHERE p.khach_san_id = @hotelId
      ORDER BY p.ma_phong
    `;
    
    const result = await pool.request()
      .input('hotelId', hotelId)
      .query(query);
    
    // Map to Flutter expected format
    const rooms = (result.recordset || []).map(room => {
      // Parse hinh_anh JSON array
      let imageUrl = null;
      if (room.hinh_anh) {
        try {
          const images = JSON.parse(room.hinh_anh);
          if (Array.isArray(images) && images.length > 0) {
            // Get first image and transform to full URL
            // Note: Room images are stored in images/rooms/ folder
            // Auto-detect host from request for emulator/device compatibility
            const host = req.get('host') || 'localhost:5000';
            const protocol = req.protocol || 'http';
            imageUrl = `${protocol}://${host}/images/rooms/${images[0]}`;
          }
        } catch (e) {
          // If not JSON, treat as single image path
          if (!room.hinh_anh.startsWith('http')) {
            const host = req.get('host') || 'localhost:5000';
            const protocol = req.protocol || 'http';
            imageUrl = `${protocol}://${host}/images/rooms/${room.hinh_anh}`;
          } else {
            imageUrl = room.hinh_anh;
          }
        }
      }
      
      return {
        id: room.id,
        ten: room.ten,
        ma_phong: room.ma_phong,
        so_phong: room.ma_phong, // Use ma_phong as so_phong
        mo_ta: room.mo_ta,
        gia_phong: room.gia_tien, // Map gia_tien to gia_phong
        hinh_anh: imageUrl,
        dien_tich: room.dien_tich,
        trang_thai: room.trang_thai,
        ten_loai_phong: room.ten_loai_phong,
        so_nguoi_max: room.so_khach || 0, // Map so_khach to so_nguoi_max
        so_giuong: (room.so_giuong_don || 0) + (room.so_giuong_doi || 0), // Total beds
      };
    });
    
    res.json({
      success: true,
      data: rooms
    });
  } catch (error) {
    console.error('Get hotel rooms error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy danh sách phòng',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get hotel bookings
exports.getHotelBookings = async (req, res) => {
  try {
    const managerId = req.user.id;
    const { status, page = 1, limit = 20 } = req.query;
    const pool = getPool();
    
    // Get hotel ID for this manager
    const hotelResult = await pool.request()
      .input('managerId', managerId)
      .query('SELECT id FROM khach_san WHERE nguoi_quan_ly_id = @managerId');
    
    if (!hotelResult.recordset || hotelResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn được gán'
      });
    }
    
    const hotelId = hotelResult.recordset[0].id;
    
    // Build where clause
    let whereClause = 'hotel_id = @hotelId';
    const params = { hotelId };
    
    if (status && status !== 'all') {
      whereClause += ' AND booking_status = @status';
      params.status = status;
    }
    
    // Get bookings for this hotel
    const query = `
      SELECT 
        id,
        booking_code as ma_phieu_dat,
        CAST(user_id AS NVARCHAR(50)) as ma_nguoi_dung,
        CAST(room_id AS NVARCHAR(50)) as ma_phong,
        check_in_date as ngay_nhan_phong,
        check_out_date as ngay_tra_phong,
        nights as so_dem_luu_tru,
        final_price as tong_tien,
        booking_status as trang_thai,
        created_at as ngay_tao,
        room_number as so_phong,
        user_name as ten_khach_hang,
        user_email as email_khach_hang,
        user_phone as sdt_khach_hang,
        guest_count,
        payment_method,
        payment_status,
        special_requests
      FROM bookings
      WHERE ${whereClause}
      ORDER BY created_at DESC
      OFFSET ${(page - 1) * limit} ROWS
      FETCH NEXT ${limit} ROWS ONLY
    `;
    
    const request = pool.request();
    Object.keys(params).forEach(key => {
      request.input(key, params[key]);
    });
    
    const result = await request.query(query);
    
    res.json({
      success: true,
      data: result.recordset || [],
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit)
      }
    });
  } catch (error) {
    console.error('Get hotel bookings error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy danh sách đặt phòng',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get hotel reviews
exports.getHotelReviews = async (req, res) => {
  try {
    const managerId = req.user.id;
    const pool = getPool();
    
    // Get hotel ID for this manager
    const hotelResult = await pool.request()
      .input('managerId', managerId)
      .query('SELECT id FROM khach_san WHERE nguoi_quan_ly_id = @managerId');
    
    if (!hotelResult.recordset || hotelResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn được gán'
      });
    }
    
    const hotelId = hotelResult.recordset[0].id;
    
    // Get reviews for this hotel
    // ✅ FIX: Get room_number from bookings table only (simplified)
    const query = `
      SELECT 
        dg.id,
        dg.so_sao_tong,
        dg.binh_luan,
        dg.ngay,
        dg.phan_hoi_khach_san,
        dg.ngay_phan_hoi,
        dg.trang_thai,
        nd.ho_ten as ten_khach_hang,
        nd.anh_dai_dien,
        COALESCE(b.room_number, 'N/A') as so_phong
      FROM danh_gia dg
      LEFT JOIN nguoi_dung nd ON dg.nguoi_dung_id = nd.id
      LEFT JOIN bookings b ON dg.phieu_dat_phong_id = b.id
      WHERE dg.khach_san_id = @hotelId
      ORDER BY dg.ngay DESC
    `;
    
    const result = await pool.request()
      .input('hotelId', hotelId)
      .query(query);
    
    res.json({
      success: true,
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

// Get hotel stats
exports.getHotelStats = async (req, res) => {
  try {
    const managerId = req.user.id;
    const pool = getPool();
    
    // Get hotel ID
    const hotelResult = await pool.request()
      .input('managerId', managerId)
      .query('SELECT id FROM khach_san WHERE nguoi_quan_ly_id = @managerId');
    
    if (!hotelResult.recordset || hotelResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn được gán'
      });
    }
    
    const hotelId = hotelResult.recordset[0].id;
    
    // Get stats
    const query = `
      SELECT 
        (SELECT COUNT(*) FROM phong WHERE khach_san_id = @hotelId) as total_rooms,
        (SELECT COUNT(*) FROM phong WHERE khach_san_id = @hotelId AND trang_thai = N'Trống') as available_rooms,
        (SELECT COUNT(*) FROM bookings WHERE hotel_id = @hotelId) as total_bookings,
        (SELECT COUNT(*) FROM bookings WHERE hotel_id = @hotelId AND booking_status = 'completed') as completed_bookings,
        (SELECT COUNT(*) FROM bookings WHERE hotel_id = @hotelId AND booking_status = 'pending') as pending_bookings,
        (SELECT COUNT(*) FROM bookings WHERE hotel_id = @hotelId AND booking_status = 'cancelled') as cancelled_bookings,
        (SELECT ISNULL(SUM(final_price), 0) FROM bookings 
         WHERE hotel_id = @hotelId 
         AND booking_status IN ('completed', 'in_progress', 'confirmed')
         AND payment_status != 'refunded') as total_revenue,
        (SELECT ISNULL(SUM(final_price), 0) FROM bookings 
         WHERE hotel_id = @hotelId 
         AND booking_status IN ('completed', 'in_progress', 'confirmed')
         AND payment_status != 'refunded'
         AND MONTH(created_at) = MONTH(GETDATE())
         AND YEAR(created_at) = YEAR(GETDATE())) as monthly_revenue
    `;
    
    const result = await pool.request()
      .input('hotelId', hotelId)
      .query(query);
    
    const stats = result.recordset[0] || {};
    
    // Map to Flutter DashboardKpi model (English camelCase)
    res.json({
      success: true,
      data: {
        totalRooms: stats.total_rooms || 0,
        availableRooms: stats.available_rooms || 0,
        occupiedRooms: (stats.total_rooms || 0) - (stats.available_rooms || 0),
        totalBookings: stats.total_bookings || 0,
        completedBookings: stats.completed_bookings || 0,
        pendingBookings: stats.pending_bookings || 0,
        cancelledBookings: stats.cancelled_bookings || 0,
        totalRevenue: stats.total_revenue || 0,
        monthlyRevenue: stats.monthly_revenue || 0,
        averageRating: 0, // TODO: Get from hotel reviews
        totalReviews: 0, // TODO: Count total reviews
      }
    });
  } catch (error) {
    console.error('Get hotel stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy thống kê',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get dashboard KPI
exports.getDashboardKpi = async (req, res) => {
  try {
    // Reuse getHotelStats logic
    return await exports.getHotelStats(req, res);
  } catch (error) {
    console.error('Get dashboard KPI error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy KPI dashboard',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Update hotel
exports.updateHotel = async (req, res) => {
  try {
    const managerId = req.user.id;
    const updateData = req.body;
    const pool = getPool();
    
    console.log('🔍 Update hotel request data:', updateData);
    
    // Get hotel ID
    const hotelResult = await pool.request()
      .input('managerId', managerId)
      .query('SELECT id FROM khach_san WHERE nguoi_quan_ly_id = @managerId');
    
    if (!hotelResult.recordset || hotelResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn được gán'
      });
    }
    
    const hotelId = hotelResult.recordset[0].id;
    
    // ✅ FIX: Validate trang_thai if present
    if (updateData.trang_thai !== undefined) {
      const validStatuses = ['Hoạt động', 'Tạm dừng', 'Đang bảo trì'];
      
      // Convert boolean to string if needed (Flutter might send boolean)
      if (typeof updateData.trang_thai === 'boolean') {
        updateData.trang_thai = updateData.trang_thai ? 'Hoạt động' : 'Tạm dừng';
        console.log('🔄 Converted boolean trang_thai to:', updateData.trang_thai);
      }
      
      // Validate against allowed values
      if (!validStatuses.includes(updateData.trang_thai)) {
        return res.status(400).json({
          success: false,
          message: `Trạng thái không hợp lệ. Cho phép: ${validStatuses.join(', ')}`
        });
      }
    }
    
    // Build UPDATE query
    // ⚠️ REMOVED 'trang_thai' - Hotel Manager shouldn't change hotel status
    // Only Admin can change hotel status
    const allowedFields = [
      'ten', 'mo_ta', 'hinh_anh', 'dia_chi', 
      'email_lien_he', 'sdt_lien_he', 'website',
      'gio_nhan_phong', 'gio_tra_phong', 'chinh_sach_huy'
    ];
    const updates = [];
    const request = pool.request().input('hotelId', hotelId);
    
    Object.keys(updateData).forEach(key => {
      if (allowedFields.includes(key)) {
        updates.push(`${key} = @${key}`);
        request.input(key, updateData[key]);
        console.log(`✅ Adding field ${key} = ${updateData[key]}`);
      } else {
        console.log(`⚠️ Skipping field ${key} (not allowed)`);
      }
    });
    
    if (updates.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Không có dữ liệu hợp lệ để cập nhật'
      });
    }
    
    const query = `
      UPDATE khach_san 
      SET ${updates.join(', ')}, updated_at = GETDATE()
      WHERE id = @hotelId;
      
      SELECT * FROM khach_san WHERE id = @hotelId;
    `;
    
    console.log('🔍 SQL Query:', query);
    console.log('🔍 Fields to update:', updates);
    
    const result = await request.query(query);
    const updatedHotel = result.recordset[0] || {};
    
    console.log('✅ Hotel updated successfully');
    
    res.json({
      success: true,
      message: 'Cập nhật thông tin khách sạn thành công',
      data: updatedHotel
    });
  } catch (error) {
    console.error('❌ Update hotel error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi cập nhật khách sạn',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Add room
exports.addRoom = async (req, res) => {
  try {
    const managerId = req.user.id;
    const { so_phong, gia_phong, trang_thai, mo_ta, loai_phong_id } = req.body;
    
    console.log('🔍 Add room request:', { so_phong, gia_phong, trang_thai, mo_ta, loai_phong_id });
    
    // Validate input
    if (!so_phong || !gia_phong || !trang_thai) {
      return res.status(400).json({
        success: false,
        message: 'Thiếu thông tin: so_phong, gia_phong, trang_thai'
      });
    }
    
    const pool = getPool();
    
    // Get hotel ID for this manager
    const hotelResult = await pool.request()
      .input('managerId', managerId)
      .query('SELECT id FROM khach_san WHERE nguoi_quan_ly_id = @managerId');
    
    if (!hotelResult.recordset || hotelResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn được gán'
      });
    }
    
    const hotelId = hotelResult.recordset[0].id;
    
    // Insert new room
    const insertQuery = `
      INSERT INTO phong (ten, ma_phong, gia_tien, trang_thai, mo_ta, khach_san_id, loai_phong_id)
      VALUES (@ten, @ma_phong, @gia_tien, @trang_thai, @mo_ta, @khach_san_id, @loai_phong_id)
    `;
    
    const result = await pool.request()
      .input('ten', `Phòng ${so_phong}`)
      .input('ma_phong', so_phong)
      .input('gia_tien', parseFloat(gia_phong))
      .input('trang_thai', trang_thai)
      .input('mo_ta', mo_ta || '')
      .input('khach_san_id', hotelId)
      .input('loai_phong_id', loai_phong_id || 1)
      .query(insertQuery);
    
    console.log(`✅ Room added: ${so_phong}, rows affected: ${result.rowsAffected[0]}`);
    
    res.json({
      success: true,
      message: 'Đã thêm phòng mới',
      data: {}
    });
  } catch (error) {
    console.error('Add room error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi thêm phòng',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Update room
exports.updateRoom = async (req, res) => {
  try {
    const managerId = req.user.id;
    const roomId = req.params.id; // ma_phong (string like 'SGR-DEL311')
    const { so_phong, gia_phong, trang_thai, mo_ta } = req.body;
    
    console.log('🔍 Update room request:', { roomId, so_phong, gia_phong, trang_thai, mo_ta });
    
    // Validate input
    if (!so_phong || !gia_phong || !trang_thai) {
      return res.status(400).json({
        success: false,
        message: 'Thiếu thông tin: so_phong, gia_phong, trang_thai'
      });
    }
    
    const pool = getPool();
    
    // Get hotel ID for this manager
    const hotelResult = await pool.request()
      .input('managerId', managerId)
      .query('SELECT id FROM khach_san WHERE nguoi_quan_ly_id = @managerId');
    
    if (!hotelResult.recordset || hotelResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn được gán'
      });
    }
    
    const hotelId = hotelResult.recordset[0].id;
    
    // Update room - Note: ma_phong can be updated, so we use the old roomId in WHERE
    const updateQuery = `
      UPDATE phong
      SET ma_phong = @new_ma_phong,
          gia_tien = @gia_tien,
          trang_thai = @trang_thai,
          mo_ta = @mo_ta
      WHERE ma_phong = @old_ma_phong AND khach_san_id = @hotelId
    `;
    
    const result = await pool.request()
      .input('new_ma_phong', so_phong)
      .input('gia_tien', parseFloat(gia_phong))
      .input('trang_thai', trang_thai)
      .input('mo_ta', mo_ta || '')
      .input('old_ma_phong', roomId)
      .input('hotelId', hotelId)
      .query(updateQuery);
    
    console.log(`✅ Room updated: ${roomId} → ${so_phong}, rows affected: ${result.rowsAffected[0]}`);
    
    res.json({
      success: true,
      message: 'Đã cập nhật phòng',
      data: {}
    });
  } catch (error) {
    console.error('❌ Update room error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi cập nhật phòng',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Upload room images
exports.uploadRoomImages = async (req, res) => {
  try {
    const managerId = req.user.id;
    const roomId = req.params.id;
    
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Không có file nào được upload'
      });
    }
    
    const pool = getPool();
    
    // Verify manager owns this hotel
    const hotelResult = await pool.request()
      .input('managerId', managerId)
      .query('SELECT id FROM khach_san WHERE nguoi_quan_ly_id = @managerId');
    
    if (!hotelResult.recordset || hotelResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn được gán'
      });
    }
    
    const hotelId = hotelResult.recordset[0].id;
    
    // Get current room images
    const roomResult = await pool.request()
      .input('roomId', roomId)
      .input('hotelId', hotelId)
      .query('SELECT hinh_anh FROM phong WHERE ma_phong = @roomId AND khach_san_id = @hotelId');
    
    if (!roomResult.recordset || roomResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy phòng'
      });
    }
    
    // Parse existing images
    let existingImages = [];
    const currentImages = roomResult.recordset[0].hinh_anh;
    if (currentImages) {
      try {
        existingImages = JSON.parse(currentImages);
      } catch (e) {
        existingImages = [currentImages];
      }
    }
    
    // Add new images (just filenames, not full paths)
    const newImages = req.files.map(file => file.filename);
    const allImages = [...existingImages, ...newImages];
    
    // Update room with new images
    await pool.request()
      .input('roomId', roomId)
      .input('hotelId', hotelId)
      .input('images', JSON.stringify(allImages))
      .query('UPDATE phong SET hinh_anh = @images WHERE ma_phong = @roomId AND khach_san_id = @hotelId');
    
    console.log(`✅ Uploaded ${newImages.length} images for room ${roomId}`);
    
    res.json({
      success: true,
      message: `Đã upload ${newImages.length} ảnh`,
      data: {
        uploadedImages: newImages,
        allImages: allImages
      }
    });
  } catch (error) {
    console.error('❌ Upload room images error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi upload ảnh',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Delete room
exports.deleteRoom = async (req, res) => {
  try {
    const managerId = req.user.id;
    const roomId = req.params.id;
    const pool = getPool();
    
    // Get hotel ID for this manager
    const hotelResult = await pool.request()
      .input('managerId', managerId)
      .query('SELECT id FROM khach_san WHERE nguoi_quan_ly_id = @managerId');
    
    if (!hotelResult.recordset || hotelResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn được gán'
      });
    }
    
    const hotelId = hotelResult.recordset[0].id;
    
    // Delete room
    const deleteQuery = `
      DELETE FROM phong
      WHERE ma_phong = @roomId AND khach_san_id = @hotelId
    `;
    
    await pool.request()
      .input('roomId', roomId)
      .input('hotelId', hotelId)
      .query(deleteQuery);
    
    res.json({
      success: true,
      message: 'Đã xóa phòng',
      data: {}
    });
  } catch (error) {
    console.error('Delete room error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi xóa phòng',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Update booking status
exports.updateBookingStatus = async (req, res) => {
  try {
    const managerId = req.user.id;
    const bookingId = req.params.id; // booking_code hoặc id
    const { status } = req.body;
    
    if (!status) {
      return res.status(400).json({
        success: false,
        message: 'Thiếu trạng thái mới'
      });
    }
    
    const pool = getPool();
    
    // Get hotel ID for this manager
    const hotelResult = await pool.request()
      .input('managerId', managerId)
      .query('SELECT id FROM khach_san WHERE nguoi_quan_ly_id = @managerId');
    
    if (!hotelResult.recordset || hotelResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn được gán'
      });
    }
    
    const hotelId = hotelResult.recordset[0].id;
    
    // Check if booking belongs to this hotel and update status
    const updateResult = await pool.request()
      .input('bookingId', sql.NVarChar, bookingId)
      .input('hotelId', sql.Int, hotelId)
      .input('newStatus', sql.NVarChar, status)
      .query(`
        UPDATE bookings
        SET booking_status = @newStatus, updated_at = GETDATE()
        WHERE booking_code = @bookingId AND hotel_id = @hotelId;
        
        SELECT * FROM bookings 
        WHERE booking_code = @bookingId AND hotel_id = @hotelId;
      `);
    
    if (!updateResult.recordset || updateResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy đặt phòng hoặc không có quyền cập nhật'
      });
    }
    
    res.json({
      success: true,
      message: 'Đã cập nhật trạng thái',
      data: updateResult.recordset[0]
    });
  } catch (error) {
    console.error('Update booking status error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi cập nhật trạng thái',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Respond to review
exports.respondToReview = async (req, res) => {
  try {
    const managerId = req.user.id;
    const reviewId = req.params.id;
    const { phan_hoi } = req.body;
    const pool = getPool();
    
    console.log('📝 Respond to review request:', { 
      managerId, 
      reviewId, 
      phan_hoiLength: phan_hoi?.length 
    });
    
    // Validate input
    if (!phan_hoi || phan_hoi.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Nội dung phản hồi không được để trống'
      });
    }
    
    // Get hotel ID for this manager
    const hotelResult = await pool.request()
      .input('managerId', managerId)
      .query('SELECT id FROM khach_san WHERE nguoi_quan_ly_id = @managerId');
    
    if (!hotelResult.recordset || hotelResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn được gán'
      });
    }
    
    const hotelId = hotelResult.recordset[0].id;
    
    // Check if review belongs to this hotel
    const checkQuery = `
      SELECT id FROM danh_gia 
      WHERE id = @reviewId AND khach_san_id = @hotelId
    `;
    
    const checkResult = await pool.request()
      .input('reviewId', sql.Int, reviewId)
      .input('hotelId', sql.Int, hotelId)
      .query(checkQuery);
    
    if (checkResult.recordset.length === 0) {
      console.log('❌ Review not found or not authorized:', { reviewId, hotelId });
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy đánh giá hoặc không có quyền phản hồi'
      });
    }
    
    // Update review with hotel response
    const updateQuery = `
      UPDATE danh_gia 
      SET 
        phan_hoi_khach_san = @phan_hoi,
        ngay_phan_hoi = GETDATE()
      WHERE id = @reviewId
    `;
    
    await pool.request()
      .input('reviewId', sql.Int, reviewId)
      .input('phan_hoi', sql.NVarChar(sql.MAX), phan_hoi.trim())
      .query(updateQuery);
    
    console.log('✅ Review response updated successfully:', reviewId);
    
    res.json({
      success: true,
      message: 'Đã gửi phản hồi thành công'
    });
    
  } catch (error) {
    console.error('❌ Respond to review error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi phản hồi đánh giá',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

module.exports = exports;
