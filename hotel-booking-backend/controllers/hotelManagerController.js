const { getPool } = require('../config/db');
const sql = require('mssql');

// Get hotel manager's assigned hotel with full details
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
        ks.gio_nhan_phong,
        ks.gio_tra_phong,
        ks.chinh_sach_huy,
        ks.email_lien_he,
        ks.sdt_lien_he,
        ks.website,
        vt.ten as ten_vi_tri,
        tt.ten as ten_tinh_thanh,
        qg.ten as ten_quoc_gia
      FROM dbo.khach_san ks
      LEFT JOIN dbo.vi_tri vt ON ks.vi_tri_id = vt.id
      LEFT JOIN dbo.tinh_thanh tt ON vt.tinh_thanh_id = tt.id
      LEFT JOIN dbo.quoc_gia qg ON tt.quoc_gia_id = qg.id
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
    const hotelId = hotelData.id;
    
    // Get hotel amenities
    const amenitiesQuery = `
      SELECT 
        tn.id,
        tn.ten,
        tn.nhom,
        tn.icon,
        kstn.mien_phi,
        kstn.gia_phi,
        kstn.ghi_chu
      FROM dbo.khach_san_tien_nghi kstn
      JOIN dbo.tien_nghi tn ON kstn.tien_nghi_id = tn.id
      WHERE kstn.khach_san_id = @hotelId AND tn.trang_thai = 1
      ORDER BY tn.nhom, tn.ten
    `;
    
    const amenitiesResult = await pool.request()
      .input('hotelId', hotelId)
      .query(amenitiesQuery);
    
    hotelData.tien_nghi = amenitiesResult.recordset || [];
    
    // Transform image path to full URL
    if (hotelData.hinh_anh && !hotelData.hinh_anh.startsWith('http')) {
      const host = req.get('host') || 'localhost:5000';
      const protocol = req.protocol || 'http';
      hotelData.hinh_anh = `${protocol}://${host}/images/hotels/${hotelData.hinh_anh}`;
    }
    
    // ✅ Get hotel images gallery from anh_khach_san table
    try {
      const imagesQuery = `
        SELECT 
          id,
          duong_dan_anh,
          thu_tu,
          la_anh_dai_dien,
          created_at
        FROM dbo.anh_khach_san
        WHERE khach_san_id = @hotelId
        ORDER BY thu_tu ASC, created_at ASC
      `;
      const imagesResult = await pool.request()
        .input('hotelId', hotelId)
        .query(imagesQuery);
      
      const host = req.get('host') || 'localhost:5000';
      const protocol = req.protocol || 'http';
      hotelData.danh_sach_anh = (imagesResult.recordset || []).map(img => ({
        id: img.id,
        duong_dan_anh: img.duong_dan_anh.startsWith('http') 
          ? img.duong_dan_anh 
          : `${protocol}://${host}/images/hotels/${img.duong_dan_anh}`,
        thu_tu: img.thu_tu,
        la_anh_dai_dien: img.la_anh_dai_dien === 1 || img.la_anh_dai_dien === true
      }));
      
      console.log(`✅ Loaded ${hotelData.danh_sach_anh.length} images for hotel ${hotelId}`);
    } catch (error) {
      console.log('⚠️ Could not fetch hotel images gallery:', error.message);
      hotelData.danh_sach_anh = [];
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

// Get all available amenities
exports.getAllAmenities = async (req, res) => {
  try {
    const pool = getPool();
    
    const query = `
      SELECT 
        id,
        ten,
        nhom,
        icon,
        mo_ta
      FROM dbo.tien_nghi
      WHERE trang_thai = 1
      ORDER BY nhom, ten
    `;
    
    const result = await pool.request().query(query);
    
    res.json({
      success: true,
      data: result.recordset || []
    });
  } catch (error) {
    console.error('Get all amenities error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy danh sách tiện nghi',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Create new amenity for hotel (Hotel Manager only)
exports.createHotelAmenity = async (req, res) => {
  try {
    const managerId = req.user.id;
    const { ten, mo_ta, nhom } = req.body; // ✅ Removed loai_tien_nghi
    const pool = getPool();
    
    console.log('🔍 Create hotel amenity request:', { managerId, ten, nhom });
    
    // Validate required fields
    if (!ten || !ten.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Tên tiện nghi không được để trống'
      });
    }
    
    // Get hotel ID
    const hotelResult = await pool.request()
      .input('managerId', sql.Int, managerId)
      .query('SELECT id FROM dbo.khach_san WHERE nguoi_quan_ly_id = @managerId');
    
    if (!hotelResult.recordset || hotelResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn được gán'
      });
    }
    
    const hotelId = hotelResult.recordset[0].id;
    
    // Start transaction
    const transaction = pool.transaction();
    
    try {
      await transaction.begin();
      
      // Create new amenity (✅ Removed loai_tien_nghi column)
      const createRequest = transaction.request();
      createRequest.input('ten', sql.NVarChar(255), ten.trim());
      createRequest.input('mo_ta', sql.NVarChar(sql.MAX), mo_ta || null);
      createRequest.input('nhom', sql.NVarChar(100), nhom || 'Khác');
      createRequest.input('trang_thai', sql.Bit, 1);
      
      // ✅ Fixed: Removed loai_tien_nghi from INSERT and OUTPUT
      const createResult = await createRequest.query(`
        INSERT INTO dbo.tien_nghi (ten, mo_ta, nhom, trang_thai, created_at)
        OUTPUT INSERTED.id, INSERTED.ten, INSERTED.mo_ta, INSERTED.nhom
        VALUES (@ten, @mo_ta, @nhom, @trang_thai, GETDATE())
      `);
      
      const newAmenity = createResult.recordset[0];
      const amenityId = newAmenity.id;
      
      console.log('✅ Created new amenity:', newAmenity);
      
      // Automatically assign to hotel
      const assignRequest = transaction.request();
      assignRequest.input('hotelId', sql.Int, hotelId);
      assignRequest.input('amenityId', sql.Int, amenityId);
      
      await assignRequest.query(`
        INSERT INTO dbo.khach_san_tien_nghi (khach_san_id, tien_nghi_id, mien_phi)
        VALUES (@hotelId, @amenityId, 1)
      `);
      
      console.log('✅ Assigned amenity to hotel');
      
      await transaction.commit();
      
      res.json({
        success: true,
        message: 'Tạo tiện nghi mới và gán cho khách sạn thành công',
        data: {
          amenity: newAmenity,
          hotelId,
          assigned: true
        }
      });
    } catch (error) {
      await transaction.rollback();
      console.error('❌ Transaction error, rolled back:', error);
      throw error;
    }
  } catch (error) {
    console.error('❌ Create hotel amenity error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi tạo tiện nghi',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get hotel amenities with pricing (for hotel manager to manage)
exports.getHotelAmenitiesWithPricing = async (req, res) => {
  try {
    const managerId = req.user.id;
    const pool = getPool();
    
    // Get hotel ID
    const hotelResult = await pool.request()
      .input('managerId', sql.Int, managerId)
      .query('SELECT id FROM dbo.khach_san WHERE nguoi_quan_ly_id = @managerId');
    
    if (!hotelResult.recordset || hotelResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn được gán'
      });
    }
    
    const hotelId = hotelResult.recordset[0].id;
    
    const query = `
      SELECT 
        tn.id,
        tn.ten,
        tn.nhom,
        tn.mo_ta,
        tn.icon,
        kstn.mien_phi,
        kstn.gia_phi,
        kstn.ghi_chu
      FROM dbo.khach_san_tien_nghi kstn
      JOIN dbo.tien_nghi tn ON kstn.tien_nghi_id = tn.id
      WHERE kstn.khach_san_id = @hotelId AND tn.trang_thai = 1
      ORDER BY tn.nhom, tn.ten
    `;
    
    const result = await pool.request()
      .input('hotelId', sql.Int, hotelId)
      .query(query);
    
    // Transform icon URLs
    const host = req.get('host') || 'localhost:5000';
    const protocol = req.protocol || 'http';
    const amenities = (result.recordset || []).map(amenity => {
      if (amenity.icon && !amenity.icon.startsWith('http')) {
        amenity.icon = `${protocol}://${host}/images/amenities/${amenity.icon}`;
      }
      return amenity;
    });
    
    res.json({
      success: true,
      data: amenities || []
    });
  } catch (error) {
    console.error('Get hotel amenities with pricing error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy danh sách tiện nghi',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Update amenity pricing (set price or free)
exports.updateAmenityPricing = async (req, res) => {
  try {
    const managerId = req.user.id;
    // ✅ Fix: Lấy trực tiếp từ req.params (không destructure)
    const amenityId = req.params.amenityId;
    const { mienPhi, giaPhi, ghiChu } = req.body;
    const pool = getPool();
    
    console.log('🔍 Update amenity pricing - Full request:', { 
      managerId, 
      amenityId, 
      params: req.params,
      'params.amenityId': req.params.amenityId,
      body: req.body,
      url: req.url,
      path: req.path,
      mienPhi, 
      giaPhi 
    });
    
    // ✅ Fix: Validate amenityId
    if (!amenityId || amenityId === 'undefined' || amenityId === undefined) {
      console.error('❌ Missing amenityId in params:', req.params);
      console.error('❌ Full request object:', {
        params: req.params,
        url: req.url,
        path: req.path,
        originalUrl: req.originalUrl
      });
      return res.status(400).json({
        success: false,
        message: 'Thiếu thông tin amenity ID trong URL. Vui lòng kiểm tra lại route.'
      });
    }
    
    // ✅ Fix: Parse và validate amenityId
    let parsedAmenityId = amenityId;
    if (typeof parsedAmenityId === 'string' && parsedAmenityId.includes(',')) {
      parsedAmenityId = parsedAmenityId.split(',')[0].trim();
    }
    parsedAmenityId = parseInt(parsedAmenityId, 10);
    
    if (isNaN(parsedAmenityId) || parsedAmenityId <= 0) {
      return res.status(400).json({
        success: false,
        message: `ID tiện nghi không hợp lệ: ${amenityId}`
      });
    }
    
    console.log('✅ Parsed amenity ID:', parsedAmenityId);
    
    // Get hotel ID
    const hotelResult = await pool.request()
      .input('managerId', sql.Int, managerId)
      .query('SELECT id FROM dbo.khach_san WHERE nguoi_quan_ly_id = @managerId');
    
    if (!hotelResult.recordset || hotelResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn được gán'
      });
    }
    
    const hotelId = hotelResult.recordset[0].id;
    
    // Check if amenity belongs to this hotel
    const checkResult = await pool.request()
      .input('hotelId', sql.Int, hotelId)
      .input('amenityId', sql.Int, parsedAmenityId)
      .query('SELECT * FROM dbo.khach_san_tien_nghi WHERE khach_san_id = @hotelId AND tien_nghi_id = @amenityId');
    
    if (!checkResult.recordset || checkResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Tiện nghi không thuộc khách sạn này'
      });
    }
    
    // ✅ Fix: Validate mienPhi và giaPhi
    // Nếu mienPhi = true, thì giaPhi phải là null
    // Nếu mienPhi = false, thì giaPhi phải > 0
    const isFree = mienPhi === true || mienPhi === 1 || mienPhi === 'true' || mienPhi === '1' || mienPhi === true;
    let finalGiaPhi = null;
    
    if (!isFree) {
      if (giaPhi === undefined || giaPhi === null || giaPhi === '') {
        return res.status(400).json({
          success: false,
          message: 'Vui lòng nhập giá cho dịch vụ có phí'
        });
      }
      const parsedGiaPhi = parseFloat(giaPhi);
      if (isNaN(parsedGiaPhi) || parsedGiaPhi <= 0) {
        return res.status(400).json({
          success: false,
          message: 'Giá dịch vụ phải là số dương'
        });
      }
      finalGiaPhi = parsedGiaPhi;
    }
    
    // Update pricing (✅ Removed updated_at - column may not exist)
    const updateQuery = `
      UPDATE dbo.khach_san_tien_nghi
      SET 
        mien_phi = @mienPhi,
        gia_phi = @giaPhi,
        ghi_chu = @ghiChu
      WHERE khach_san_id = @hotelId AND tien_nghi_id = @amenityId
      
      SELECT 
        tn.id,
        tn.ten,
        tn.nhom,
        kstn.mien_phi,
        kstn.gia_phi,
        kstn.ghi_chu
      FROM dbo.khach_san_tien_nghi kstn
      JOIN dbo.tien_nghi tn ON kstn.tien_nghi_id = tn.id
      WHERE kstn.khach_san_id = @hotelId AND kstn.tien_nghi_id = @amenityId
    `;
    
    const request = pool.request()
      .input('hotelId', sql.Int, hotelId)
      .input('amenityId', sql.Int, parsedAmenityId)
      .input('mienPhi', sql.Bit, isFree ? 1 : 0)
      .input('giaPhi', sql.Decimal(18, 2), finalGiaPhi)
      .input('ghiChu', sql.NVarChar(500), ghiChu || null);
    
    const result = await request.query(updateQuery);
    
    res.json({
      success: true,
      message: 'Cập nhật giá tiện nghi thành công',
      data: result.recordset[0]
    });
  } catch (error) {
    console.error('❌ Update amenity pricing error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi cập nhật giá tiện nghi',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Update hotel amenities (with pricing support)
exports.updateHotelAmenities = async (req, res) => {
  try {
    const managerId = req.user.id;
    const { amenities } = req.body; // Array of amenity IDs or objects with {id, mien_phi, gia_phi}
    const pool = getPool();
    
    console.log('🔍 Update hotel amenities request:', { managerId, amenities });
    
    // Get hotel ID
    const hotelResult = await pool.request()
      .input('managerId', sql.Int, managerId)
      .query('SELECT id FROM dbo.khach_san WHERE nguoi_quan_ly_id = @managerId');
    
    if (!hotelResult.recordset || hotelResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn được gán'
      });
    }
    
    const hotelId = hotelResult.recordset[0].id;
    console.log('✅ Found hotel ID:', hotelId);
    
    // Start transaction
    const transaction = pool.transaction();
    
    try {
      await transaction.begin();
      
      // Delete existing amenities
      const deleteRequest = transaction.request();
      deleteRequest.input('hotelId', sql.Int, hotelId);
      await deleteRequest.query('DELETE FROM dbo.khach_san_tien_nghi WHERE khach_san_id = @hotelId');
      console.log('✅ Deleted existing amenities');
      
      // Insert new amenities
      if (amenities && Array.isArray(amenities) && amenities.length > 0) {
        for (const amenity of amenities) {
          const insertRequest = transaction.request();
          insertRequest.input('hotelId', sql.Int, hotelId);
          
          // Support both simple ID and object with pricing
          const amenityId = typeof amenity === 'object' ? amenity.id : amenity;
          const mienPhi = typeof amenity === 'object' ? (amenity.mien_phi !== undefined ? amenity.mien_phi : 1) : 1;
          const giaPhi = typeof amenity === 'object' ? (amenity.gia_phi || null) : null;
          const ghiChu = typeof amenity === 'object' ? (amenity.ghi_chu || null) : null;
          
          insertRequest.input('amenityId', sql.Int, amenityId);
          insertRequest.input('mienPhi', sql.Bit, mienPhi ? 1 : 0);
          insertRequest.input('giaPhi', sql.Decimal(18, 2), giaPhi ? parseFloat(giaPhi) : null);
          insertRequest.input('ghiChu', sql.NVarChar(500), ghiChu || null);
          
          await insertRequest.query(`
            INSERT INTO dbo.khach_san_tien_nghi (khach_san_id, tien_nghi_id, mien_phi, gia_phi, ghi_chu)
            VALUES (@hotelId, @amenityId, @mienPhi, @giaPhi, @ghiChu)
          `);
        }
        console.log(`✅ Inserted ${amenities.length} amenities`);
      } else {
        console.log('ℹ️ No amenities to insert');
      }
      
      await transaction.commit();
      console.log('✅ Transaction committed successfully');
      
      res.json({
        success: true,
        message: 'Cập nhật tiện nghi thành công',
        data: {
          hotelId,
          amenitiesCount: amenities?.length || 0
        }
      });
    } catch (error) {
      await transaction.rollback();
      console.error('❌ Transaction error, rolled back:', error);
      throw error;
    }
  } catch (error) {
    console.error('❌ Update hotel amenities error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi cập nhật tiện nghi',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get all room types
exports.getRoomTypes = async (req, res) => {
  try {
    const managerId = req.user.id;
    const pool = getPool();
    const sql = require('mssql');
    
    // Get hotel ID for this manager first
    const hotelResult = await pool.request()
      .input('managerId', sql.Int, managerId)
      .query('SELECT id FROM dbo.khach_san WHERE nguoi_quan_ly_id = @managerId');
    
    if (!hotelResult.recordset || hotelResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn được gán'
      });
    }
    
    const hotelId = hotelResult.recordset[0].id;
    
    // Try to get room types from hotel's rooms first
    try {
      const query = `
        SELECT DISTINCT
          lp.id,
          lp.ten,
          lp.mo_ta,
          lp.so_khach,
          lp.so_giuong_don,
          lp.so_giuong_doi
        FROM dbo.loai_phong lp
        INNER JOIN dbo.phong p ON lp.id = p.loai_phong_id
        WHERE p.khach_san_id = @hotelId
        ORDER BY lp.id
      `;
      
      console.log('🔍 Getting room types for hotel:', hotelId);
      const result = await pool.request()
        .input('hotelId', sql.Int, hotelId)
        .query(query);
      
      console.log(`✅ Found ${result.recordset.length} room types for hotel ${hotelId}`);
      
      if (result.recordset.length > 0) {
        return res.json({
          success: true,
          data: result.recordset || []
        });
      }
    } catch (joinError) {
      console.warn('⚠️ Error getting room types from hotel rooms:', joinError.message);
      // Continue to fallback
    }
    
    // Fallback: Get all room types
    console.log('⚠️ No room types found for hotel, trying to get all room types');
    const fallbackQuery = `
      SELECT 
        id,
        ten,
        mo_ta,
        so_khach,
        so_giuong_don,
        so_giuong_doi
      FROM dbo.loai_phong
      ORDER BY id
    `;
    
    const fallbackResult = await pool.request().query(fallbackQuery);
    console.log(`✅ Found ${fallbackResult.recordset.length} room types from fallback query`);
    
    res.json({
      success: true,
      data: fallbackResult.recordset || []
    });
  } catch (error) {
    console.error('❌ Get room types error:', error);
    console.error('❌ Error details:', {
      message: error.message,
      number: error.number,
      code: error.code,
      originalError: error.originalError?.message
    });
    
    // Return empty array instead of error to allow form to work
    res.json({
      success: true,
      data: [],
      message: 'Không thể tải danh sách loại phòng. Vui lòng thử lại sau.'
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
      .input('managerId', sql.Int, managerId)
      .query('SELECT id FROM dbo.khach_san WHERE nguoi_quan_ly_id = @managerId');
    
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
        p.loai_phong_id,
        lp.ten as ten_loai_phong,
        lp.so_khach,
        lp.so_giuong_don,
        lp.so_giuong_doi
      FROM dbo.phong p
      LEFT JOIN dbo.loai_phong lp ON p.loai_phong_id = lp.id
      WHERE p.khach_san_id = @hotelId
      ORDER BY p.ma_phong
    `;
    
    const result = await pool.request()
      .input('hotelId', sql.Int, hotelId)
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
      
      // Parse images array
      let images = [];
      if (room.hinh_anh) {
        try {
          const parsed = JSON.parse(room.hinh_anh);
          if (Array.isArray(parsed)) {
            images = parsed.map(img => {
              if (img.startsWith('http')) return img;
              const host = req.get('host') || 'localhost:5000';
              const protocol = req.protocol || 'http';
              return `${protocol}://${host}/images/rooms/${img}`;
            });
          }
        } catch (e) {
          if (room.hinh_anh && !room.hinh_anh.startsWith('http')) {
            const host = req.get('host') || 'localhost:5000';
            const protocol = req.protocol || 'http';
            images = [`${protocol}://${host}/images/rooms/${room.hinh_anh}`];
          }
        }
      }
      
      return {
        id: room.id,
        ten: room.ten,
        ma_phong: room.ma_phong,
        so_phong: room.ma_phong,
        mo_ta: room.mo_ta,
        gia_phong: parseFloat(room.gia_tien || 0),
        gia_tien: parseFloat(room.gia_tien || 0),
        hinh_anh: images.length > 0 ? images[0] : imageUrl,
        hinh_anh_list: images,
        dien_tich: room.dien_tich,
        trang_thai: room.trang_thai,
        loai_phong_id: room.loai_phong_id,
        ten_loai_phong: room.ten_loai_phong,
        so_nguoi_max: room.so_khach || 0,
        so_giuong: (room.so_giuong_don || 0) + (room.so_giuong_doi || 0),
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
    const { status, page = 1, limit = 100 } = req.query;
    const pool = getPool();
    
    // Get hotel ID for this manager
    const hotelResult = await pool.request()
      .input('managerId', sql.Int, managerId)
      .query('SELECT id FROM dbo.khach_san WHERE nguoi_quan_ly_id = @managerId');
    
    if (!hotelResult.recordset || hotelResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn được gán'
      });
    }
    
    const hotelId = hotelResult.recordset[0].id;
    
    // Build where clause
    let whereClause = 'b.hotel_id = @hotelId';
    const request = pool.request();
    request.input('hotelId', sql.Int, hotelId);
    
    if (status && status !== 'all') {
      whereClause += ' AND b.booking_status = @status';
      request.input('status', sql.NVarChar, status);
    }
    
    // Filter by date range
    if (req.query.startDate) {
      whereClause += ' AND b.check_in_date >= @startDate';
      request.input('startDate', sql.Date, req.query.startDate);
    }
    if (req.query.endDate) {
      whereClause += ' AND b.check_out_date <= @endDate';
      request.input('endDate', sql.Date, req.query.endDate);
    }
    
    // Get bookings for this hotel with room and user info
    const query = `
      SELECT 
        b.id,
        b.booking_code,
        b.user_id,
        b.room_id,
        b.check_in_date,
        b.check_out_date,
        b.nights,
        b.final_price,
        b.booking_status,
        b.created_at,
        b.room_number,
        b.user_name,
        b.user_email,
        b.user_phone,
        b.guest_count,
        b.payment_method,
        b.payment_status,
        b.special_requests,
        b.updated_at,
        p.ma_phong,
        p.ten as ten_phong,
        lp.ten as ten_loai_phong
      FROM dbo.bookings b
      LEFT JOIN dbo.phong p ON b.room_id = p.id
      LEFT JOIN dbo.loai_phong lp ON p.loai_phong_id = lp.id
      WHERE ${whereClause}
      ORDER BY b.created_at DESC
      OFFSET @offset ROWS
      FETCH NEXT @limit ROWS ONLY
    `;
    
    const offset = (parseInt(page) - 1) * parseInt(limit);
    request.input('offset', sql.Int, offset);
    request.input('limit', sql.Int, parseInt(limit));
    
    const result = await request.query(query);
    
    // Format dates
    const bookings = (result.recordset || []).map(booking => ({
      id: booking.id,
      booking_code: booking.booking_code,
      ma_phieu_dat: booking.booking_code,
      user_id: booking.user_id,
      room_id: booking.room_id,
      check_in_date: booking.check_in_date ? new Date(booking.check_in_date).toISOString().split('T')[0] : null,
      check_out_date: booking.check_out_date ? new Date(booking.check_out_date).toISOString().split('T')[0] : null,
      ngay_nhan_phong: booking.check_in_date ? new Date(booking.check_in_date).toISOString().split('T')[0] : null,
      ngay_tra_phong: booking.check_out_date ? new Date(booking.check_out_date).toISOString().split('T')[0] : null,
      nights: booking.nights,
      so_dem_luu_tru: booking.nights,
      final_price: parseFloat(booking.final_price || 0),
      tong_tien: parseFloat(booking.final_price || 0),
      booking_status: booking.booking_status,
      trang_thai: booking.booking_status,
      status: booking.booking_status,
      created_at: booking.created_at,
      ngay_tao: booking.created_at,
      room_number: booking.room_number,
      so_phong: booking.room_number || booking.ma_phong,
      user_name: booking.user_name,
      ten_khach_hang: booking.user_name,
      customer_name: booking.user_name,
      user_email: booking.user_email,
      email_khach_hang: booking.user_email,
      user_phone: booking.user_phone,
      sdt_khach_hang: booking.user_phone,
      guest_count: booking.guest_count,
      payment_method: booking.payment_method,
      payment_status: booking.payment_status,
      special_requests: booking.special_requests,
      ten_phong: booking.ten_phong,
      ten_loai_phong: booking.ten_loai_phong,
      updated_at: booking.updated_at
    }));
    
    res.json({
      success: true,
      data: bookings,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit)
      }
    });
  } catch (error) {
    console.error('❌ Get hotel bookings error:', error);
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
      .input('managerId', sql.Int, managerId)
      .query('SELECT id FROM dbo.khach_san WHERE nguoi_quan_ly_id = @managerId');
    
    if (!hotelResult.recordset || hotelResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn được gán'
      });
    }
    
    const hotelId = hotelResult.recordset[0].id;
    
    // Get reviews for this hotel with average rating
    const query = `
      SELECT 
        dg.id,
        CAST(COALESCE(dg.so_sao_tong, 0) AS DECIMAL(3,2)) as diem_danh_gia,
        dg.so_sao_tong,
        dg.binh_luan as noi_dung,
        dg.ngay as ngay_danh_gia,
        dg.phan_hoi_khach_san,
        dg.ngay_phan_hoi,
        dg.trang_thai,
        nd.ho_ten as ten_khach_hang,
        nd.anh_dai_dien,
        COALESCE(b.room_number, 'N/A') as so_phong,
        (SELECT AVG(CAST(so_sao_tong AS DECIMAL(3,2))) 
         FROM dbo.danh_gia 
         WHERE khach_san_id = @hotelId AND trang_thai = N'Đã duyệt' AND so_sao_tong IS NOT NULL) as diem_trung_binh,
        (SELECT COUNT(*) 
         FROM dbo.danh_gia 
         WHERE khach_san_id = @hotelId AND trang_thai = N'Đã duyệt') as tong_so_danh_gia
      FROM dbo.danh_gia dg
      LEFT JOIN dbo.nguoi_dung nd ON dg.nguoi_dung_id = nd.id
      LEFT JOIN dbo.bookings b ON dg.phieu_dat_phong_id = b.id
      WHERE dg.khach_san_id = @hotelId
      ORDER BY dg.ngay DESC
    `;
    
    const result = await pool.request()
      .input('hotelId', sql.Int, hotelId)
      .query(query);
    
    // Calculate average rating from all approved reviews
    const avgRatingQuery = `
      SELECT 
        AVG(CAST(so_sao_tong AS DECIMAL(3,2))) as diem_trung_binh,
        COUNT(*) as tong_so_danh_gia
      FROM dbo.danh_gia 
      WHERE khach_san_id = @hotelId 
        AND trang_thai = N'Đã duyệt'
        AND so_sao_tong IS NOT NULL
        AND so_sao_tong > 0
    `;
    
    const avgResult = await pool.request()
      .input('hotelId', sql.Int, hotelId)
      .query(avgRatingQuery);
    
    const averageRating = avgResult.recordset[0]?.diem_trung_binh || 0;
    const totalReviews = avgResult.recordset[0]?.tong_so_danh_gia || 0;
    
    console.log('📊 Reviews statistics:', {
      averageRating,
      totalReviews,
      sampleReview: result.recordset[0] ? {
        id: result.recordset[0].id,
        diem_danh_gia: result.recordset[0].diem_danh_gia,
        so_sao_tong: result.recordset[0].so_sao_tong
      } : null
    });
    
    res.json({
      success: true,
      data: result.recordset || [],
      statistics: {
        averageRating: parseFloat(averageRating).toFixed(1),
        totalReviews: parseInt(totalReviews)
      }
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
    // ⚠️ SỬA LỖI: Tính số phòng trống dựa trên bookings thay vì trang_thai
    // Đảm bảo tính chính xác khi booking được confirm
    const query = `
      WITH RoomStats AS (
        -- Tổng số phòng
        SELECT COUNT(*) as total_rooms
        FROM dbo.phong
        WHERE khach_san_id = @hotelId
      ),
      BookedRooms AS (
        -- Số phòng đã được đặt (confirmed, in_progress, checked_in) và chưa hết hạn
        SELECT COUNT(DISTINCT b.room_id) as booked_rooms
        FROM dbo.bookings b
        INNER JOIN dbo.phong p ON b.room_id = p.id
        WHERE p.khach_san_id = @hotelId
          AND b.booking_status IN ('confirmed', 'in_progress', 'checked_in')
          AND b.check_out_date >= CAST(GETDATE() AS DATE)
      )
      SELECT 
        rs.total_rooms,
        (rs.total_rooms - ISNULL(br.booked_rooms, 0)) as available_rooms,
        ISNULL(br.booked_rooms, 0) as occupied_rooms,
        (SELECT COUNT(*) FROM dbo.bookings WHERE hotel_id = @hotelId) as total_bookings,
        (SELECT COUNT(*) FROM dbo.bookings WHERE hotel_id = @hotelId AND booking_status = 'completed') as completed_bookings,
        (SELECT COUNT(*) FROM dbo.bookings WHERE hotel_id = @hotelId AND booking_status = 'pending') as pending_bookings,
        (SELECT COUNT(*) FROM dbo.bookings WHERE hotel_id = @hotelId AND booking_status = 'cancelled') as cancelled_bookings,
        (SELECT COUNT(*) FROM dbo.bookings 
         WHERE hotel_id = @hotelId 
         AND CAST(created_at AS DATE) = CAST(GETDATE() AS DATE)) as today_bookings,
        (SELECT COUNT(*) FROM dbo.bookings 
         WHERE hotel_id = @hotelId 
         AND booking_status IN ('in_progress', 'confirmed', 'checked_in')
         AND CAST(check_in_date AS DATE) <= CAST(GETDATE() AS DATE)
         AND CAST(check_out_date AS DATE) >= CAST(GETDATE() AS DATE)) as ongoing_bookings,
        -- Total revenue: All bookings except cancelled, with final_price > 0
        (SELECT ISNULL(SUM(final_price), 0) FROM dbo.bookings 
         WHERE hotel_id = @hotelId 
         AND booking_status != 'cancelled'
         AND final_price > 0
         AND (payment_status IS NULL OR payment_status != 'refunded')) as total_revenue,
        -- Today revenue: Bookings created today, except cancelled, with final_price > 0
        (SELECT ISNULL(SUM(final_price), 0) FROM dbo.bookings 
         WHERE hotel_id = @hotelId 
         AND booking_status != 'cancelled'
         AND final_price > 0
         AND (payment_status IS NULL OR payment_status != 'refunded')
         AND CAST(created_at AS DATE) = CAST(GETDATE() AS DATE)) as today_revenue,
        -- Monthly revenue: Bookings this month, except cancelled, with final_price > 0
        (SELECT ISNULL(SUM(final_price), 0) FROM dbo.bookings 
         WHERE hotel_id = @hotelId 
         AND booking_status != 'cancelled'
         AND final_price > 0
         AND (payment_status IS NULL OR payment_status != 'refunded')
         AND MONTH(created_at) = MONTH(GETDATE())
         AND YEAR(created_at) = YEAR(GETDATE())) as monthly_revenue,
        (SELECT ISNULL(AVG(CAST(so_sao_tong AS DECIMAL(3,2))), 0) FROM danh_gia 
         WHERE khach_san_id = @hotelId AND trang_thai = N'Đã duyệt') as average_rating,
        (SELECT COUNT(*) FROM danh_gia 
         WHERE khach_san_id = @hotelId AND trang_thai = N'Đã duyệt') as total_reviews
      FROM RoomStats rs
      CROSS JOIN BookedRooms br
    `;
    
    const result = await pool.request()
      .input('hotelId', hotelId)
      .query(query);
    
    // Log để debug
    console.log('📊 Room Stats Query Result:', {
      total_rooms: result.recordset[0]?.total_rooms,
      available_rooms: result.recordset[0]?.available_rooms,
      occupied_rooms: result.recordset[0]?.occupied_rooms,
    });
    
    const stats = result.recordset[0] || {};
    
    // Debug: Check bookings data
    const debugQuery = `
      SELECT 
        booking_status,
        payment_status,
        COUNT(*) as count,
        SUM(final_price) as total_final_price,
        AVG(final_price) as avg_final_price,
        MIN(final_price) as min_final_price,
        MAX(final_price) as max_final_price
      FROM dbo.bookings
      WHERE hotel_id = @hotelId
      GROUP BY booking_status, payment_status
      ORDER BY booking_status, payment_status
    `;
    
    const debugResult = await pool.request()
      .input('hotelId', hotelId)
      .query(debugQuery);
    
    console.log('🔍 Debug - Bookings by status and payment:', debugResult.recordset);
    
    // Get revenue chart data (last 30 days) from bookings table
    // Include all bookings with final_price > 0, except cancelled
    const revenueChartQuery = `
      SELECT 
        CAST(created_at AS DATE) as date,
        ISNULL(SUM(final_price), 0) as revenue
      FROM dbo.bookings
      WHERE hotel_id = @hotelId
        AND booking_status != 'cancelled'
        AND final_price > 0
        AND (payment_status IS NULL OR payment_status != 'refunded')
        AND created_at >= DATEADD(day, -30, GETDATE())
      GROUP BY CAST(created_at AS DATE)
      ORDER BY date ASC
    `;
    
    const revenueChartResult = await pool.request()
      .input('hotelId', hotelId)
      .query(revenueChartQuery);
    
    const revenueChart = revenueChartResult.recordset.map(row => ({
      date: row.date.toISOString().split('T')[0],
      revenue: parseFloat(row.revenue || 0)
    }));
    
    // Calculate occupancy rate
    const totalRooms = parseInt(stats.total_rooms || 0);
    const occupiedRooms = parseInt(stats.occupied_rooms || 0);
    const occupancyRate = totalRooms > 0 ? ((occupiedRooms / totalRooms) * 100).toFixed(1) : 0;
    
    console.log('📊 Hotel Stats for manager:', managerId, 'hotel:', hotelId);
    console.log('📊 Stats:', stats);
    console.log('📊 Revenue breakdown:', {
      total_revenue: stats.total_revenue,
      today_revenue: stats.today_revenue,
      monthly_revenue: stats.monthly_revenue
    });
    
    // Map to DashboardKpi model (English camelCase)
    res.json({
      success: true,
      data: {
        totalRooms: totalRooms,
        availableRooms: parseInt(stats.available_rooms || 0),
        occupiedRooms: occupiedRooms,
        totalBookings: parseInt(stats.total_bookings || 0),
        todayBookings: parseInt(stats.today_bookings || 0),
        ongoingBookings: parseInt(stats.ongoing_bookings || 0),
        completedBookings: parseInt(stats.completed_bookings || 0),
        pendingBookings: parseInt(stats.pending_bookings || 0),
        cancelledBookings: parseInt(stats.cancelled_bookings || 0),
        totalRevenue: parseFloat(stats.total_revenue || 0),
        todayRevenue: parseFloat(stats.today_revenue || 0),
        monthlyRevenue: parseFloat(stats.monthly_revenue || 0),
        averageRating: parseFloat(stats.average_rating || 0),
        totalReviews: parseInt(stats.total_reviews || 0),
        occupancyRate: parseFloat(occupancyRate),
        revenueChart: revenueChart
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
      .input('managerId', sql.Int, managerId)
      .query('SELECT id FROM dbo.khach_san WHERE nguoi_quan_ly_id = @managerId');
    
    if (!hotelResult.recordset || hotelResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn được gán'
      });
    }
    
    const hotelId = hotelResult.recordset[0].id;
    console.log('✅ Found hotel ID for update:', hotelId);
    
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
    // Map frontend field names to database column names
    const fieldMapping = {
      'ten': 'ten',  // Frontend sends 'ten', DB column is 'ten'
      'mo_ta': 'mo_ta',
      'hinh_anh': 'hinh_anh',
      'dia_chi': 'dia_chi',
      'email_lien_he': 'email_lien_he',
      'sdt_lien_he': 'sdt_lien_he',
      'website': 'website',
      'gio_nhan_phong': 'gio_nhan_phong',
      'gio_tra_phong': 'gio_tra_phong',
      'chinh_sach_huy': 'chinh_sach_huy'
    };
    
    const allowedFields = Object.keys(fieldMapping);
    const updates = [];
    const request = pool.request();
    request.input('hotelId', sql.Int, hotelId);
    
    Object.keys(updateData).forEach(key => {
      if (allowedFields.includes(key)) {
        const dbColumn = fieldMapping[key];
        updates.push(`${dbColumn} = @${key}`);
        // Handle different data types
        const value = updateData[key];
        if (value === null || value === undefined || value === '') {
          request.input(key, sql.NVarChar, null);
        } else {
          request.input(key, sql.NVarChar(sql.MAX), value);
        }
        console.log(`✅ Adding field ${key} (${dbColumn}) = ${value}`);
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
      UPDATE dbo.khach_san 
      SET ${updates.join(', ')}, updated_at = GETDATE()
      WHERE id = @hotelId;
      
      SELECT 
        id,
        ten,
        mo_ta,
        hinh_anh,
        dia_chi,
        gio_nhan_phong,
        gio_tra_phong,
        chinh_sach_huy,
        email_lien_he,
        sdt_lien_he,
        website,
        trang_thai,
        updated_at
      FROM dbo.khach_san 
      WHERE id = @hotelId;
    `;
    
    console.log('🔍 SQL Query:', query);
    console.log('🔍 Fields to update:', updates);
    console.log('🔍 Update data:', updateData);
    
    const result = await request.query(query);
    const updatedHotel = result.recordset[0] || {};
    
    console.log('✅ Hotel updated successfully:', updatedHotel);
    
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
    const { ten, ma_phong, gia_tien, trang_thai, mo_ta, loai_phong_id, dien_tich } = req.body;
    
    console.log('🔍 Add room request:', req.body);
    
    // Validate and clean input
    const cleanMaPhong = (ma_phong || '').toString().trim();
    const cleanGiaTien = gia_tien ? parseFloat(gia_tien) : null;
    
    if (!cleanMaPhong || cleanMaPhong === '') {
      return res.status(400).json({
        success: false,
        message: 'Mã phòng là bắt buộc'
      });
    }
    
    if (!cleanGiaTien || isNaN(cleanGiaTien) || cleanGiaTien <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Giá phòng phải là số dương'
      });
    }
    
    const pool = getPool();
    
    // Get hotel ID for this manager
    const hotelResult = await pool.request()
      .input('managerId', sql.Int, managerId)
      .query('SELECT id FROM dbo.khach_san WHERE nguoi_quan_ly_id = @managerId');
    
    if (!hotelResult.recordset || hotelResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn được gán'
      });
    }
    
    const hotelId = hotelResult.recordset[0].id;
    
    // Check if room code already exists
    const checkRoom = await pool.request()
      .input('ma_phong', sql.NVarChar, cleanMaPhong)
      .input('hotelId', sql.Int, hotelId)
      .query('SELECT id FROM dbo.phong WHERE ma_phong = @ma_phong AND khach_san_id = @hotelId');
    
    if (checkRoom.recordset.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Mã phòng đã tồn tại'
      });
    }
    
    // Prepare values
    const cleanTen = (ten || '').trim() || `Phòng ${cleanMaPhong}`;
    const cleanTrangThai = (trang_thai || '').trim() || 'Trống';
    const cleanMoTa = (mo_ta || '').trim() || '';
    const cleanLoaiPhongId = loai_phong_id && loai_phong_id !== '' ? parseInt(loai_phong_id) : 1;
    const cleanDienTich = dien_tich && dien_tich !== '' ? parseFloat(dien_tich) : null;
    
    // Insert new room
    const insertQuery = `
      INSERT INTO dbo.phong (ten, ma_phong, gia_tien, trang_thai, mo_ta, khach_san_id, loai_phong_id, dien_tich)
      OUTPUT INSERTED.*
      VALUES (@ten, @ma_phong, @gia_tien, @trang_thai, @mo_ta, @khach_san_id, @loai_phong_id, @dien_tich)
    `;
    
    const request = pool.request();
    request.input('ten', sql.NVarChar, cleanTen);
    request.input('ma_phong', sql.NVarChar, cleanMaPhong);
    request.input('gia_tien', sql.Decimal(18, 2), cleanGiaTien);
    request.input('trang_thai', sql.NVarChar, cleanTrangThai);
    request.input('mo_ta', sql.NVarChar, cleanMoTa);
    request.input('khach_san_id', sql.Int, hotelId);
    request.input('loai_phong_id', sql.Int, cleanLoaiPhongId);
    if (cleanDienTich !== null) {
      request.input('dien_tich', sql.Float, cleanDienTich);
    } else {
      request.input('dien_tich', sql.Float, null);
    }
    
    const result = await request.query(insertQuery);
    
    console.log(`✅ Room added: ${cleanMaPhong}`);
    
    res.json({
      success: true,
      message: 'Đã thêm phòng mới',
      data: result.recordset[0] || {}
    });
  } catch (error) {
    console.error('❌ Add room error:', error);
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
    console.log('🔍 Update room - Full request:', {
      method: req.method,
      url: req.url,
      params: req.params,
      body: req.body,
      user: req.user
    });
    
    const managerId = req.user.id;
    const roomId = parseInt(req.params.id); // room id (integer)
    
    if (isNaN(roomId)) {
      return res.status(400).json({
        success: false,
        message: 'ID phòng không hợp lệ'
      });
    }
    
    const { ten, ma_phong, gia_tien, trang_thai, mo_ta, loai_phong_id, dien_tich } = req.body;
    
    console.log('🔍 Update room request:', { roomId, managerId, body: req.body });
    
    const pool = getPool();
    
    // Get hotel ID for this manager
    const hotelResult = await pool.request()
      .input('managerId', sql.Int, managerId)
      .query('SELECT id FROM dbo.khach_san WHERE nguoi_quan_ly_id = @managerId');
    
    if (!hotelResult.recordset || hotelResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn được gán'
      });
    }
    
    const hotelId = hotelResult.recordset[0].id;
    
    // Check if room exists and belongs to this hotel
    const roomCheck = await pool.request()
      .input('roomId', sql.Int, roomId)
      .input('hotelId', sql.Int, hotelId)
      .query('SELECT id FROM dbo.phong WHERE id = @roomId AND khach_san_id = @hotelId');
    
    if (roomCheck.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy phòng'
      });
    }
    
    // Check if new ma_phong already exists (if changed)
    if (ma_phong !== undefined && ma_phong !== null && ma_phong !== '') {
      const cleanMaPhong = ma_phong.toString().trim();
      const checkRoom = await pool.request()
        .input('ma_phong', sql.NVarChar, cleanMaPhong)
        .input('hotelId', sql.Int, hotelId)
        .input('roomId', sql.Int, roomId)
        .query('SELECT id FROM dbo.phong WHERE ma_phong = @ma_phong AND khach_san_id = @hotelId AND id != @roomId');
      
      if (checkRoom.recordset.length > 0) {
        return res.status(400).json({
          success: false,
          message: 'Mã phòng đã tồn tại'
        });
      }
    }
    
    // Build update query dynamically
    const updates = [];
    const request = pool.request();
    request.input('roomId', sql.Int, roomId);
    request.input('hotelId', sql.Int, hotelId);
    
    // Helper to check if value is provided
    const hasValue = (val) => val !== undefined && val !== null && val !== '';
    
    if (hasValue(ten)) {
      updates.push('ten = @ten');
      request.input('ten', sql.NVarChar, ten.toString().trim());
    }
    if (hasValue(ma_phong)) {
      updates.push('ma_phong = @ma_phong');
      request.input('ma_phong', sql.NVarChar, ma_phong.toString().trim());
    }
    if (hasValue(gia_tien)) {
      const cleanGiaTien = parseFloat(gia_tien);
      if (isNaN(cleanGiaTien) || cleanGiaTien <= 0) {
        return res.status(400).json({
          success: false,
          message: 'Giá phòng phải là số dương'
        });
      }
      updates.push('gia_tien = @gia_tien');
      request.input('gia_tien', sql.Decimal(18, 2), cleanGiaTien);
    }
    if (trang_thai !== undefined && trang_thai !== null) {
      updates.push('trang_thai = @trang_thai');
      request.input('trang_thai', sql.NVarChar, trang_thai.toString().trim());
    }
    if (mo_ta !== undefined) {
      // Allow empty string for mo_ta
      updates.push('mo_ta = @mo_ta');
      request.input('mo_ta', sql.NVarChar, mo_ta ? mo_ta.toString().trim() : '');
    }
    if (hasValue(loai_phong_id)) {
      const cleanLoaiPhongId = parseInt(loai_phong_id);
      if (isNaN(cleanLoaiPhongId)) {
        return res.status(400).json({
          success: false,
          message: 'Loại phòng không hợp lệ'
        });
      }
      updates.push('loai_phong_id = @loai_phong_id');
      request.input('loai_phong_id', sql.Int, cleanLoaiPhongId);
    }
    if (dien_tich !== undefined) {
      if (dien_tich === null || dien_tich === '') {
        // Allow setting to null
        updates.push('dien_tich = @dien_tich');
        request.input('dien_tich', sql.Float, null);
      } else {
        const cleanDienTich = parseFloat(dien_tich);
        if (isNaN(cleanDienTich)) {
          return res.status(400).json({
            success: false,
            message: 'Diện tích không hợp lệ'
          });
        }
        updates.push('dien_tich = @dien_tich');
        request.input('dien_tich', sql.Float, cleanDienTich);
      }
    }
    
    if (updates.length === 0) {
      console.log('⚠️ No fields to update for room:', roomId);
      return res.status(400).json({
        success: false,
        message: 'Không có dữ liệu để cập nhật. Vui lòng thay đổi ít nhất một trường.'
      });
    }
    
    console.log('📝 Updating room fields:', updates);
    
    const updateQuery = `
      UPDATE dbo.phong
      SET ${updates.join(', ')}
      WHERE id = @roomId AND khach_san_id = @hotelId;
      
      SELECT * FROM dbo.phong WHERE id = @roomId;
    `;
    
    const result = await request.query(updateQuery);
    
    console.log(`✅ Room updated: ${roomId}`);
    
    res.json({
      success: true,
      message: 'Đã cập nhật phòng',
      data: result.recordset[0] || {}
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

// Update room status (for maintenance)
exports.updateRoomStatus = async (req, res) => {
  try {
    const managerId = req.user.id;
    const roomId = parseInt(req.params.id);
    const { trang_thai } = req.body;
    
    console.log('🔍 Update room status request:', { roomId, trang_thai, body: req.body });
    
    if (isNaN(roomId)) {
      return res.status(400).json({
        success: false,
        message: 'ID phòng không hợp lệ'
      });
    }
    
    if (!trang_thai || trang_thai === '') {
      return res.status(400).json({
        success: false,
        message: 'Thiếu thông tin: trang_thai'
      });
    }
    
    const pool = getPool();
    
    // Get hotel ID for this manager
    const hotelResult = await pool.request()
      .input('managerId', sql.Int, managerId)
      .query('SELECT id FROM dbo.khach_san WHERE nguoi_quan_ly_id = @managerId');
    
    if (!hotelResult.recordset || hotelResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn được gán'
      });
    }
    
    const hotelId = hotelResult.recordset[0].id;
    
    // Update room status
    const result = await pool.request()
      .input('roomId', sql.Int, roomId)
      .input('hotelId', sql.Int, hotelId)
      .input('trang_thai', sql.NVarChar, trang_thai)
      .query(`
        UPDATE dbo.phong
        SET trang_thai = @trang_thai
        WHERE id = @roomId AND khach_san_id = @hotelId;
        
        SELECT * FROM dbo.phong WHERE id = @roomId;
      `);
    
    if (result.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy phòng'
      });
    }
    
    console.log(`✅ Room status updated: ${roomId} → ${trang_thai}`);
    
    res.json({
      success: true,
      message: 'Đã cập nhật trạng thái phòng',
      data: result.recordset[0]
    });
  } catch (error) {
    console.error('❌ Update room status error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi cập nhật trạng thái phòng',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Upload room images
exports.uploadRoomImages = async (req, res) => {
  try {
    const managerId = req.user.id;
    const roomId = parseInt(req.params.id);
    
    if (isNaN(roomId)) {
      return res.status(400).json({
        success: false,
        message: 'ID phòng không hợp lệ'
      });
    }
    
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Không có file nào được upload'
      });
    }
    
    const pool = getPool();
    
    // Verify manager owns this hotel
    const hotelResult = await pool.request()
      .input('managerId', sql.Int, managerId)
      .query('SELECT id FROM dbo.khach_san WHERE nguoi_quan_ly_id = @managerId');
    
    if (!hotelResult.recordset || hotelResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn được gán'
      });
    }
    
    const hotelId = hotelResult.recordset[0].id;
    
    // Get current room images
    const roomResult = await pool.request()
      .input('roomId', sql.Int, roomId)
      .input('hotelId', sql.Int, hotelId)
      .query('SELECT hinh_anh FROM dbo.phong WHERE id = @roomId AND khach_san_id = @hotelId');
    
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
        if (!Array.isArray(existingImages)) {
          existingImages = [existingImages];
        }
      } catch (e) {
        existingImages = [currentImages];
      }
    }
    
    // Move uploaded files to images/rooms and get filenames
    const path = require('path');
    const fs = require('fs');
    const imagesDir = path.join(__dirname, '../../images/rooms');
    
    const newImages = [];
    for (const file of req.files) {
      // File đã được lưu vào images/rooms bởi uploadRoomImages middleware
      // Chỉ cần lấy tên file
      newImages.push(file.filename);
    }
    
    const allImages = [...existingImages, ...newImages];
    
    // Update room with new images
    await pool.request()
      .input('roomId', sql.Int, roomId)
      .input('hotelId', sql.Int, hotelId)
      .input('images', sql.NVarChar(sql.MAX), JSON.stringify(allImages))
      .query('UPDATE dbo.phong SET hinh_anh = @images WHERE id = @roomId AND khach_san_id = @hotelId');
    
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
    const roomId = parseInt(req.params.id);
    const pool = getPool();
    
    // Get hotel ID for this manager
    const hotelResult = await pool.request()
      .input('managerId', sql.Int, managerId)
      .query('SELECT id FROM dbo.khach_san WHERE nguoi_quan_ly_id = @managerId');
    
    if (!hotelResult.recordset || hotelResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn được gán'
      });
    }
    
    const hotelId = hotelResult.recordset[0].id;
    
    // Check if room has active bookings
    const bookingCheck = await pool.request()
      .input('roomId', sql.Int, roomId)
      .query(`
        SELECT COUNT(*) as count
        FROM dbo.bookings
        WHERE room_id = @roomId
        AND booking_status NOT IN ('cancelled', 'completed')
      `);
    
    if (bookingCheck.recordset[0].count > 0) {
      return res.status(400).json({
        success: false,
        message: 'Không thể xóa phòng đang có đặt phòng'
      });
    }
    
    // Delete room
    const deleteResult = await pool.request()
      .input('roomId', sql.Int, roomId)
      .input('hotelId', sql.Int, hotelId)
      .query('DELETE FROM dbo.phong WHERE id = @roomId AND khach_san_id = @hotelId');
    
    if (deleteResult.rowsAffected[0] === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy phòng'
      });
    }
    
    console.log(`✅ Room deleted: ${roomId}`);
    
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
// Update booking (status and other fields)
exports.updateBookingStatus = async (req, res) => {
  try {
    const managerId = req.user.id;
    const bookingId = parseInt(req.params.id); // booking id (integer)
    const { booking_status, check_in_date, check_out_date, guest_count, special_requests, payment_status } = req.body;
    
    console.log('🔍 Update booking request:', { bookingId, ...req.body });
    
    if (isNaN(bookingId)) {
      return res.status(400).json({
        success: false,
        message: 'ID đặt phòng không hợp lệ'
      });
    }
    
    const pool = getPool();
    
    // Get hotel ID for this manager
    const hotelResult = await pool.request()
      .input('managerId', sql.Int, managerId)
      .query('SELECT id FROM dbo.khach_san WHERE nguoi_quan_ly_id = @managerId');
    
    if (!hotelResult.recordset || hotelResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn được gán'
      });
    }
    
    const hotelId = hotelResult.recordset[0].id;
    
    // Check if booking exists and belongs to this hotel - Lấy đầy đủ thông tin
    const bookingCheck = await pool.request()
      .input('bookingId', sql.Int, bookingId)
      .input('hotelId', sql.Int, hotelId)
      .query(`
        SELECT 
          b.*,
          nd.email as user_email,
          nd.ho_ten as user_name,
          ks.ten as hotel_name
        FROM dbo.bookings b
        INNER JOIN dbo.nguoi_dung nd ON b.user_id = nd.id
        INNER JOIN dbo.khach_san ks ON b.hotel_id = ks.id
        WHERE b.id = @bookingId AND b.hotel_id = @hotelId
      `);
    
    if (bookingCheck.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy đặt phòng hoặc không có quyền cập nhật'
      });
    }
    
    const booking = bookingCheck.recordset[0];
    
    // ⚠️ VALIDATION 1: Chỉ cho phép xác nhận "completed" sau check-out
    if (booking_status === 'completed') {
      const checkOutDate = new Date(booking.check_out_date);
      const now = new Date();
      
      if (now < checkOutDate) {
        return res.status(400).json({
          success: false,
          message: `Không thể xác nhận hoàn thành. Chỉ có thể xác nhận sau ngày trả phòng (${checkOutDate.toLocaleDateString('vi-VN')})`
        });
      }
    }
    
    // ⚠️ VALIDATION 2: Không cho hủy trong thời gian đặt phòng (check-in đến check-out)
    if (booking_status === 'cancelled') {
      const checkInDate = new Date(booking.check_in_date);
      const checkOutDate = new Date(booking.check_out_date);
      const now = new Date();
      
      // Kiểm tra nếu đang trong thời gian đặt phòng
      if (now >= checkInDate && now <= checkOutDate) {
        return res.status(400).json({
          success: false,
          message: 'Không thể hủy đặt phòng trong thời gian đặt phòng (từ ngày nhận phòng đến ngày trả phòng)'
        });
      }
    }
    
    // Build update query dynamically
    const updates = [];
    const request = pool.request();
    request.input('bookingId', sql.Int, bookingId);
    request.input('hotelId', sql.Int, hotelId);
    
    if (booking_status !== undefined && booking_status !== null) {
      updates.push('booking_status = @booking_status');
      request.input('booking_status', sql.NVarChar, booking_status);
    }
    if (check_in_date !== undefined && check_in_date !== null && check_in_date !== '') {
      updates.push('check_in_date = @check_in_date');
      request.input('check_in_date', sql.Date, check_in_date);
    }
    if (check_out_date !== undefined && check_out_date !== null && check_out_date !== '') {
      updates.push('check_out_date = @check_out_date');
      request.input('check_out_date', sql.Date, check_out_date);
    }
    if (guest_count !== undefined && guest_count !== null && guest_count !== '') {
      updates.push('guest_count = @guest_count');
      request.input('guest_count', sql.Int, parseInt(guest_count));
    }
    if (special_requests !== undefined) {
      updates.push('special_requests = @special_requests');
      request.input('special_requests', sql.NVarChar(sql.MAX), special_requests || null);
    }
    if (payment_status !== undefined && payment_status !== null) {
      updates.push('payment_status = @payment_status');
      request.input('payment_status', sql.NVarChar, payment_status);
    }
    
    if (updates.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Không có dữ liệu để cập nhật'
      });
    }
    
    // Always update updated_at
    updates.push('updated_at = GETDATE()');
    
    // Recalculate nights if dates changed
    if (check_in_date || check_out_date) {
      updates.push('nights = DATEDIFF(day, check_in_date, check_out_date)');
    }
    
    const updateQuery = `
      UPDATE dbo.bookings
      SET ${updates.join(', ')}
      WHERE id = @bookingId AND hotel_id = @hotelId;
      
      SELECT * FROM dbo.bookings WHERE id = @bookingId;
    `;
    
    const result = await request.query(updateQuery);
    
    if (result.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy đặt phòng sau khi cập nhật'
      });
    }
    
    const updatedBooking = result.recordset[0];
    console.log(`✅ Booking updated: ${bookingId}, status: ${booking_status || 'N/A'}`);
    
    // ✅ CẬP NHẬT TRẠNG THÁI PHÒNG KHI BOOKING ĐƯỢC XÁC NHẬN/HỦY/HOÀN THÀNH
    if (booking_status && booking_status !== booking.booking_status) {
      try {
        const roomId = booking.room_id;
        let newRoomStatus = null;
        
        // Xác định trạng thái phòng mới dựa trên booking status
        if (booking_status === 'confirmed' || booking_status === 'checked_in' || booking_status === 'in_progress') {
          // Phòng đã được đặt → "Đã thuê"
          newRoomStatus = 'Đã thuê';
        } else if (booking_status === 'cancelled' || booking_status === 'completed') {
          // Booking bị hủy hoặc hoàn thành → "Trống"
          // Chỉ cập nhật nếu không có booking nào khác đang active cho phòng này
          const activeBookingCheck = await pool.request()
            .input('roomId', sql.Int, roomId)
            .input('currentBookingId', sql.Int, bookingId)
            .query(`
              SELECT COUNT(*) as active_count
              FROM dbo.bookings
              WHERE room_id = @roomId
                AND id != @currentBookingId
                AND booking_status IN ('confirmed', 'checked_in', 'in_progress')
                AND check_out_date >= GETDATE()
            `);
          
          if (activeBookingCheck.recordset[0].active_count === 0) {
            newRoomStatus = 'Trống';
          }
        }
        
        // Cập nhật trạng thái phòng nếu cần
        if (newRoomStatus) {
          await pool.request()
            .input('roomId', sql.Int, roomId)
            .input('newStatus', sql.NVarChar, newRoomStatus)
            .query(`
              UPDATE dbo.phong
              SET trang_thai = @newStatus
              WHERE id = @roomId
            `);
          console.log(`✅ Room ${roomId} status updated to: ${newRoomStatus}`);
        }
      } catch (roomUpdateError) {
        console.error('⚠️ Error updating room status (non-critical):', roomUpdateError);
        // Không throw error vì booking đã cập nhật thành công
      }
    }
    
    // ✅ Gửi email thông báo cho user khi hotel manager xác nhận/hủy
    if (booking_status && booking_status !== booking.booking_status && ['confirmed', 'cancelled', 'completed'].includes(booking_status)) {
      try {
        const EmailService = require('../services/emailService');
        const emailService = new EmailService();
        
        const userEmail = booking.user_email;
        const userName = booking.user_name || 'Khách hàng';
        const hotelName = booking.hotel_name || 'Khách sạn';
        const bookingCode = updatedBooking.booking_code || booking.booking_code;
        const checkInDate = new Date(booking.check_in_date).toLocaleDateString('vi-VN');
        const checkOutDate = new Date(booking.check_out_date).toLocaleDateString('vi-VN');
        
        let emailSubject = '';
        let emailHTML = '';
        
        if (booking_status === 'confirmed') {
          emailSubject = `✅ Đặt phòng đã được xác nhận - ${hotelName}`;
          emailHTML = `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
              <h2 style="color: #27ae60;">✅ Đặt phòng đã được xác nhận</h2>
              <p>Xin chào <strong>${userName}</strong>,</p>
              <p>Đặt phòng của bạn tại <strong>${hotelName}</strong> đã được xác nhận thành công!</p>
              <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                <p><strong>Mã đặt phòng:</strong> ${bookingCode}</p>
                <p><strong>Ngày nhận phòng:</strong> ${checkInDate}</p>
                <p><strong>Ngày trả phòng:</strong> ${checkOutDate}</p>
                <p><strong>Trạng thái:</strong> <span style="color: #27ae60;">Đã xác nhận</span></p>
              </div>
              <p>Vui lòng đến đúng giờ để nhận phòng. Chúng tôi rất mong được phục vụ bạn!</p>
              <p style="color: #666; font-size: 12px; margin-top: 30px;">Email này được gửi tự động từ hệ thống quản lý khách sạn.</p>
            </div>
          `;
        } else if (booking_status === 'cancelled') {
          emailSubject = `❌ Đặt phòng đã bị hủy - ${hotelName}`;
          emailHTML = `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
              <h2 style="color: #e74c3c;">❌ Đặt phòng đã bị hủy</h2>
              <p>Xin chào <strong>${userName}</strong>,</p>
              <p>Rất tiếc, đặt phòng của bạn tại <strong>${hotelName}</strong> đã bị hủy.</p>
              <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                <p><strong>Mã đặt phòng:</strong> ${bookingCode}</p>
                <p><strong>Ngày nhận phòng:</strong> ${checkInDate}</p>
                <p><strong>Ngày trả phòng:</strong> ${checkOutDate}</p>
                <p><strong>Trạng thái:</strong> <span style="color: #e74c3c;">Đã hủy</span></p>
                ${booking.special_requests ? `<p><strong>Lý do:</strong> ${booking.special_requests}</p>` : ''}
              </div>
              <p>Nếu bạn có thắc mắc, vui lòng liên hệ với khách sạn.</p>
              <p style="color: #666; font-size: 12px; margin-top: 30px;">Email này được gửi tự động từ hệ thống quản lý khách sạn.</p>
            </div>
          `;
        } else if (booking_status === 'completed') {
          emailSubject = `🎉 Đặt phòng đã hoàn thành - ${hotelName}`;
          emailHTML = `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
              <h2 style="color: #3498db;">🎉 Đặt phòng đã hoàn thành</h2>
              <p>Xin chào <strong>${userName}</strong>,</p>
              <p>Cảm ơn bạn đã sử dụng dịch vụ của <strong>${hotelName}</strong>!</p>
              <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                <p><strong>Mã đặt phòng:</strong> ${bookingCode}</p>
                <p><strong>Ngày nhận phòng:</strong> ${checkInDate}</p>
                <p><strong>Ngày trả phòng:</strong> ${checkOutDate}</p>
                <p><strong>Trạng thái:</strong> <span style="color: #3498db;">Đã hoàn thành</span></p>
              </div>
              <p>Chúng tôi rất mong được phục vụ bạn lần sau!</p>
              <p style="color: #666; font-size: 12px; margin-top: 30px;">Email này được gửi tự động từ hệ thống quản lý khách sạn.</p>
            </div>
          `;
        }
        
        if (emailSubject && emailHTML && userEmail) {
          await emailService.sendEmail(userEmail, emailSubject, emailHTML);
          console.log(`✅ Email notification sent to user: ${userEmail} (status: ${booking_status})`);
        }
      } catch (emailError) {
        console.error('⚠️ Error sending email to user (non-critical):', emailError);
        // Không throw error vì booking đã cập nhật thành công
      }
    }
    
    res.json({
      success: true,
      message: 'Đã cập nhật đặt phòng',
      data: updatedBooking
    });
  } catch (error) {
    console.error('❌ Update booking error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi cập nhật đặt phòng',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Delete booking
exports.deleteBooking = async (req, res) => {
  try {
    const managerId = req.user.id;
    const bookingId = parseInt(req.params.id);
    
    if (isNaN(bookingId)) {
      return res.status(400).json({
        success: false,
        message: 'ID đặt phòng không hợp lệ'
      });
    }
    
    const pool = getPool();
    
    // Get hotel ID for this manager
    const hotelResult = await pool.request()
      .input('managerId', sql.Int, managerId)
      .query('SELECT id FROM dbo.khach_san WHERE nguoi_quan_ly_id = @managerId');
    
    if (!hotelResult.recordset || hotelResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn được gán'
      });
    }
    
    const hotelId = hotelResult.recordset[0].id;
    
    // Check if booking exists and belongs to this hotel
    const bookingCheck = await pool.request()
      .input('bookingId', sql.Int, bookingId)
      .input('hotelId', sql.Int, hotelId)
      .query('SELECT id, booking_status FROM dbo.bookings WHERE id = @bookingId AND hotel_id = @hotelId');
    
    if (bookingCheck.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy đặt phòng'
      });
    }
    
    // Only allow delete if booking is cancelled or pending
    const bookingStatus = bookingCheck.recordset[0].booking_status;
    if (bookingStatus !== 'cancelled' && bookingStatus !== 'pending') {
      return res.status(400).json({
        success: false,
        message: 'Chỉ có thể xóa đặt phòng ở trạng thái "Đã hủy" hoặc "Chờ xử lý"'
      });
    }
    
    // Delete booking
    const deleteResult = await pool.request()
      .input('bookingId', sql.Int, bookingId)
      .input('hotelId', sql.Int, hotelId)
      .query('DELETE FROM dbo.bookings WHERE id = @bookingId AND hotel_id = @hotelId');
    
    if (deleteResult.rowsAffected[0] === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy đặt phòng'
      });
    }
    
    console.log(`✅ Booking deleted: ${bookingId}`);
    
    res.json({
      success: true,
      message: 'Đã xóa đặt phòng'
    });
  } catch (error) {
    console.error('❌ Delete booking error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi xóa đặt phòng',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Send notification to customer for a booking
exports.sendBookingNotification = async (req, res) => {
  try {
    console.log('📧 ===== sendBookingNotification CALLED =====');
    console.log('📋 Request method:', req.method);
    console.log('📋 Request path:', req.path);
    console.log('📋 Request params:', req.params);
    console.log('📋 Request body:', req.body);
    console.log('📋 Manager ID:', req.user?.id);
    console.log('📋 ==========================================');
    
    const managerId = req.user.id;
    const bookingId = parseInt(req.params.id);
    const { subject, message } = req.body;
    
    if (!subject || !message) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng điền đầy đủ tiêu đề và nội dung thông báo'
      });
    }
    
    const pool = getPool();
    
    // Get hotel ID for this manager
    const hotelResult = await pool.request()
      .input('managerId', sql.Int, managerId)
      .query('SELECT id FROM dbo.khach_san WHERE nguoi_quan_ly_id = @managerId');
    
    if (!hotelResult.recordset || hotelResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn được gán'
      });
    }
    
    const hotelId = hotelResult.recordset[0].id;
    
    // Get booking info
    const bookingResult = await pool.request()
      .input('bookingId', sql.Int, bookingId)
      .input('hotelId', sql.Int, hotelId)
      .query(`
        SELECT 
          b.id,
          b.booking_code,
          b.user_email,
          b.user_name,
          b.user_phone,
          b.check_in_date,
          b.check_out_date,
          b.room_number,
          ks.ten as hotel_name
        FROM dbo.bookings b
        INNER JOIN dbo.khach_san ks ON b.hotel_id = ks.id
        WHERE b.id = @bookingId AND b.hotel_id = @hotelId
      `);
    
    if (!bookingResult.recordset || bookingResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy đặt phòng hoặc không có quyền gửi thông báo'
      });
    }
    
    const booking = bookingResult.recordset[0];
    
    // Send email notification
    const EmailService = require('../services/emailService');
    const emailSent = await EmailService.sendEmail(
      booking.user_email,
      subject,
      `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #2c5aa0;">Xin chào ${booking.user_name}!</h2>
          <p>Chúng tôi gửi thông báo về đặt phòng của bạn:</p>
          
          <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
            <h3 style="margin-top: 0;">Thông tin đặt phòng:</h3>
            <p><strong>Mã đặt phòng:</strong> ${booking.booking_code}</p>
            <p><strong>Khách sạn:</strong> ${booking.hotel_name}</p>
            <p><strong>Số phòng:</strong> ${booking.room_number || 'N/A'}</p>
            <p><strong>Ngày nhận phòng:</strong> ${booking.check_in_date ? new Date(booking.check_in_date).toLocaleDateString('vi-VN') : 'N/A'}</p>
            <p><strong>Ngày trả phòng:</strong> ${booking.check_out_date ? new Date(booking.check_out_date).toLocaleDateString('vi-VN') : 'N/A'}</p>
          </div>
          
          <div style="background-color: #e3f2fd; padding: 15px; border-radius: 5px; margin: 20px 0;">
            <h3 style="margin-top: 0;">Thông báo:</h3>
            <p style="white-space: pre-wrap;">${message}</p>
          </div>
          
          <p>Nếu có bất kỳ thắc mắc nào, vui lòng liên hệ với chúng tôi.</p>
          
          <p style="margin-top: 30px;">Trân trọng,<br><strong>Đội ngũ ${booking.hotel_name}</strong></p>
        </div>
      `
    );
    
    console.log(`✅ Notification sent to ${booking.user_email} for booking ${bookingId}`);
    
    res.json({
      success: true,
      message: 'Đã gửi thông báo cho khách hàng',
      data: {
        booking_id: bookingId,
        customer_email: booking.user_email,
        email_sent: emailSent
      }
    });
  } catch (error) {
    console.error('❌ Send booking notification error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi gửi thông báo',
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
      body: req.body,
      phan_hoi: phan_hoi,
      phan_hoiLength: phan_hoi?.length 
    });
    
    // Validate input
    if (!phan_hoi || (typeof phan_hoi === 'string' && phan_hoi.trim().length === 0)) {
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

// Report review violation
exports.reportReview = async (req, res) => {
  try {
    const managerId = req.user.id;
    const reviewId = req.params.id;
    const { reason, description } = req.body;
    const pool = getPool();
    
    console.log('🚨 Report review request:', { managerId, reviewId, reason });
    
    // Validate input
    if (!reason || reason.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng chọn lý do báo cáo'
      });
    }
    
    // Get hotel ID for this manager
    const hotelResult = await pool.request()
      .input('managerId', sql.Int, managerId)
      .query('SELECT id FROM dbo.khach_san WHERE nguoi_quan_ly_id = @managerId');
    
    if (!hotelResult.recordset || hotelResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn được gán'
      });
    }
    
    const hotelId = hotelResult.recordset[0].id;
    
    // Check if review belongs to this hotel
    const checkQuery = `
      SELECT id FROM dbo.danh_gia 
      WHERE id = @reviewId AND khach_san_id = @hotelId
    `;
    
    const checkResult = await pool.request()
      .input('reviewId', sql.Int, reviewId)
      .input('hotelId', sql.Int, hotelId)
      .query(checkQuery);
    
    if (checkResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy đánh giá hoặc không có quyền báo cáo'
      });
    }
    
    // Create report (you may need to create a reports table or use existing feedback table)
    // For now, we'll update the review status to 'Chờ duyệt' and add a note
    const updateQuery = `
      UPDATE dbo.danh_gia 
      SET 
        trang_thai = N'Chờ duyệt',
        ghi_chu = @description
      WHERE id = @reviewId
    `;
    
    await pool.request()
      .input('reviewId', sql.Int, reviewId)
      .input('description', sql.NVarChar(sql.MAX), `Báo cáo vi phạm: ${reason}. ${description || ''}`)
      .query(updateQuery);
    
    console.log('✅ Review reported successfully:', reviewId);
    
    res.json({
      success: true,
      message: 'Đã gửi báo cáo thành công. Admin sẽ xem xét đánh giá này.'
    });
    
  } catch (error) {
    console.error('❌ Report review error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi báo cáo đánh giá',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get list of customers who have booked (for messages)
exports.getCustomersForMessages = async (req, res) => {
  try {
    console.log('📥 getCustomersForMessages called');
    const managerId = req.user.id;
    console.log('📥 Manager ID:', managerId);
    const pool = getPool();
    
    // Get hotel ID for this manager
    const hotelResult = await pool.request()
      .input('managerId', sql.Int, managerId)
      .query('SELECT id FROM dbo.khach_san WHERE nguoi_quan_ly_id = @managerId');
    
    if (!hotelResult.recordset || hotelResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn được gán'
      });
    }
    
    const hotelId = hotelResult.recordset[0].id;
    
    // Get distinct customers who have booked this hotel
    // Get latest booking info for each customer
    const query = `
      WITH LatestBookings AS (
        SELECT 
          b.user_id,
          b.id as booking_id,
          p.ten as room_name,
          b.check_in_date as ngay_checkin,
          b.check_out_date as ngay_checkout,
          b.booking_status,
          b.created_at as booking_date,
          ROW_NUMBER() OVER (PARTITION BY b.user_id ORDER BY b.created_at DESC) as rn
        FROM dbo.bookings b
        LEFT JOIN dbo.phong p ON b.room_id = p.id
        WHERE b.hotel_id = @hotelId
      )
      SELECT DISTINCT
        nd.id as customer_id,
        nd.ho_ten as customer_name,
        nd.email as customer_email,
        nd.anh_dai_dien as customer_avatar,
        nd.sdt as customer_phone,
        lb.booking_id,
        lb.room_name,
        lb.ngay_checkin,
        lb.ngay_checkout,
        lb.booking_status,
        lb.booking_date
      FROM dbo.nguoi_dung nd
      INNER JOIN LatestBookings lb ON nd.id = lb.user_id AND lb.rn = 1
      WHERE nd.vai_tro = 'user'
      ORDER BY lb.booking_date DESC
    `;
    
    const result = await pool.request()
      .input('hotelId', sql.Int, hotelId)
      .query(query);
    
    // Format the results
    const customers = result.recordset.map(row => ({
      customer_id: row.customer_id,
      customer_name: row.customer_name || 'Khách hàng',
      customer_email: row.customer_email,
      customer_avatar: row.customer_avatar,
      customer_phone: row.customer_phone,
      latest_booking: {
        booking_id: row.booking_id,
        room_name: row.room_name,
        check_in: row.ngay_checkin,
        check_out: row.ngay_checkout,
        status: row.booking_status,
        booking_date: row.booking_date
      }
    }));
    
    console.log(`✅ Found ${customers.length} customers for hotel ${hotelId}`);
    
    res.json({
      success: true,
      data: customers
    });
  } catch (error) {
    console.error('Get customers for messages error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy danh sách khách hàng',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Upload hotel image (add to gallery)
exports.uploadHotelImage = async (req, res) => {
  try {
    const managerId = req.user.id;
    const pool = getPool();
    
    console.log('📸 Upload hotel image request:', {
      managerId,
      hasFile: !!req.file,
      fileInfo: req.file ? {
        filename: req.file.filename,
        originalname: req.file.originalname,
        mimetype: req.file.mimetype,
        size: req.file.size,
        path: req.file.path
      } : null
    });
    
    if (!req.file) {
      console.error('❌ No file in request');
      return res.status(400).json({
        success: false,
        message: 'Không có file ảnh được upload'
      });
    }
    
    // Get hotel ID
    const hotelResult = await pool.request()
      .input('managerId', sql.Int, managerId)
      .query('SELECT id FROM dbo.khach_san WHERE nguoi_quan_ly_id = @managerId');
    
    if (!hotelResult.recordset || hotelResult.recordset.length === 0) {
      console.error('❌ Hotel not found for manager:', managerId);
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn được gán'
      });
    }
    
    const hotelId = hotelResult.recordset[0].id;
    const imageFilename = req.file.filename;
    
    console.log('✅ Hotel found:', { 
      hotelId, 
      imageFilename,
      'req.file': {
        filename: req.file.filename,
        originalname: req.file.originalname,
        mimetype: req.file.mimetype,
        size: req.file.size,
        destination: req.file.destination,
        path: req.file.path,
        fieldname: req.file.fieldname
      }
    });
    
    // ✅ Create table anh_khach_san if not exists
    try {
      const checkTableQuery = `
        SELECT TABLE_NAME 
        FROM INFORMATION_SCHEMA.TABLES 
        WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'anh_khach_san'
      `;
      const tableExists = await pool.request().query(checkTableQuery);
      
      if (tableExists.recordset.length === 0) {
        await pool.request().query(`
          CREATE TABLE dbo.anh_khach_san (
            id INT IDENTITY(1,1) PRIMARY KEY,
            khach_san_id INT NOT NULL,
            duong_dan_anh NVARCHAR(500) NOT NULL,
            thu_tu INT DEFAULT 0,
            la_anh_dai_dien BIT DEFAULT 0,
            created_at DATETIME DEFAULT GETDATE(),
            FOREIGN KEY (khach_san_id) REFERENCES dbo.khach_san(id) ON DELETE CASCADE
          )
        `);
        console.log('✅ Created table anh_khach_san');
      }
    } catch (tableError) {
      console.log('⚠️ Table check/create error (may already exist):', tableError.message);
    }
    
    // ✅ Get current max order to set thu_tu
    const maxOrderResult = await pool.request()
      .input('hotelId', sql.Int, hotelId)
      .query('SELECT MAX(thu_tu) as max_thu_tu FROM dbo.anh_khach_san WHERE khach_san_id = @hotelId');
    
    const maxOrder = maxOrderResult.recordset[0]?.max_thu_tu || 0;
    const newOrder = maxOrder + 1;
    
    // ✅ Check if this is the first image - set as main image
    const countResult = await pool.request()
      .input('hotelId', sql.Int, hotelId)
      .query('SELECT COUNT(*) as count FROM dbo.anh_khach_san WHERE khach_san_id = @hotelId');
    
    const imageCount = countResult.recordset[0]?.count || 0;
    const isMainImage = imageCount === 0;
    
    // ✅ Verify file exists on disk
    const fs = require('fs');
    const path = require('path');
    
    // ✅ Get file path from multer (req.file.path) hoặc construct từ filename
    const filePath = req.file.path || path.join(__dirname, '../images/hotels', imageFilename);
    
    console.log('📁 Checking file:', {
      'req.file.path': req.file.path,
      'constructed path': path.join(__dirname, '../images/hotels', imageFilename),
      'using path': filePath
    });
    
    if (!fs.existsSync(filePath)) {
      console.error('❌ File not found on disk:', filePath);
      console.error('❌ File info:', {
        filename: imageFilename,
        originalname: req.file.originalname,
        destination: req.file.destination,
        path: req.file.path
      });
      return res.status(500).json({
        success: false,
        message: 'File không được lưu trên server',
        debug: {
          filename: imageFilename,
          expectedPath: filePath
        }
      });
    }
    
    const fileStats = fs.statSync(filePath);
    console.log('✅ File exists on disk:', {
      path: filePath,
      size: fileStats.size,
      created: fileStats.birthtime
    });
    
    // ✅ Insert into anh_khach_san (gallery)
    let insertResult;
    try {
      insertResult = await pool.request()
        .input('hotelId', sql.Int, hotelId)
        .input('duongDanAnh', sql.NVarChar(500), imageFilename)
        .input('thuTu', sql.Int, newOrder)
        .input('laAnhDaiDien', sql.Bit, isMainImage ? 1 : 0)
        .query(`
          INSERT INTO dbo.anh_khach_san (khach_san_id, duong_dan_anh, thu_tu, la_anh_dai_dien)
          OUTPUT INSERTED.id, INSERTED.duong_dan_anh, INSERTED.thu_tu, INSERTED.la_anh_dai_dien
          VALUES (@hotelId, @duongDanAnh, @thuTu, @laAnhDaiDien)
        `);
      
      console.log('✅ Inserted into database:', insertResult.recordset[0]);
    } catch (dbError) {
      console.error('❌ Database insert error:', dbError);
      // Delete file if database insert fails
      try {
        fs.unlinkSync(filePath);
        console.log('🗑️ Deleted file after DB error');
      } catch (deleteError) {
        console.error('❌ Error deleting file:', deleteError);
      }
      throw dbError;
    }
    
    // ✅ If this is the first image, also update hinh_anh in khach_san table
    if (isMainImage) {
      try {
        await pool.request()
          .input('hotelId', sql.Int, hotelId)
          .input('hinhAnh', sql.NVarChar(500), imageFilename)
          .query('UPDATE dbo.khach_san SET hinh_anh = @hinhAnh WHERE id = @hotelId');
        console.log('✅ Updated main image in khach_san table');
      } catch (updateError) {
        console.error('⚠️ Error updating main image (non-critical):', updateError);
      }
    }
    
    const insertedImage = insertResult.recordset[0];
    console.log(`✅ Successfully added hotel image to gallery: ${imageFilename} for hotel ${hotelId}`);
    
    // Transform image URL
    const host = req.get('host') || 'localhost:5000';
    const protocol = req.protocol || 'http';
    const imageUrl = `${protocol}://${host}/images/hotels/${imageFilename}`;
    
    res.json({
      success: true,
      message: 'Thêm ảnh khách sạn thành công',
      data: {
        id: insertedImage.id,
        imageUrl: imageUrl,
        filename: imageFilename,
        thuTu: insertedImage.thu_tu,
        laAnhDaiDien: insertedImage.la_anh_dai_dien === 1 || insertedImage.la_anh_dai_dien === true
      }
    });
  } catch (error) {
    console.error('❌ Upload hotel image error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi upload ảnh khách sạn',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Upload amenity image
exports.uploadAmenityImage = async (req, res) => {
  try {
    const managerId = req.user.id;
    const { amenityId } = req.params;
    const pool = getPool();
    
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'Không có file ảnh được upload'
      });
    }
    
    // Parse amenityId
    let parsedAmenityId = amenityId;
    if (typeof parsedAmenityId === 'string' && parsedAmenityId.includes(',')) {
      parsedAmenityId = parsedAmenityId.split(',')[0].trim();
    }
    parsedAmenityId = parseInt(parsedAmenityId, 10);
    
    if (isNaN(parsedAmenityId) || parsedAmenityId <= 0) {
      return res.status(400).json({
        success: false,
        message: 'ID tiện nghi không hợp lệ'
      });
    }
    
    // Get hotel ID
    const hotelResult = await pool.request()
      .input('managerId', sql.Int, managerId)
      .query('SELECT id FROM dbo.khach_san WHERE nguoi_quan_ly_id = @managerId');
    
    if (!hotelResult.recordset || hotelResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn được gán'
      });
    }
    
    const hotelId = hotelResult.recordset[0].id;
    
    // Check if amenity belongs to this hotel
    const checkResult = await pool.request()
      .input('hotelId', sql.Int, hotelId)
      .input('amenityId', sql.Int, parsedAmenityId)
      .query('SELECT * FROM dbo.khach_san_tien_nghi WHERE khach_san_id = @hotelId AND tien_nghi_id = @amenityId');
    
    if (!checkResult.recordset || checkResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Tiện nghi không thuộc khách sạn này'
      });
    }
    
    const imageFilename = req.file.filename;
    
    // Update amenity icon in database
    await pool.request()
      .input('amenityId', sql.Int, parsedAmenityId)
      .input('icon', sql.NVarChar(500), imageFilename)
      .query('UPDATE dbo.tien_nghi SET icon = @icon WHERE id = @amenityId');
    
    console.log(`✅ Uploaded amenity image: ${imageFilename} for amenity ${parsedAmenityId}`);
    
    // Transform image URL
    const host = req.get('host') || 'localhost:5000';
    const protocol = req.protocol || 'http';
    const imageUrl = `${protocol}://${host}/images/amenities/${imageFilename}`;
    
    res.json({
      success: true,
      message: 'Upload ảnh tiện nghi thành công',
      data: {
        imageUrl: imageUrl,
        filename: imageFilename
      }
    });
  } catch (error) {
    console.error('❌ Upload amenity image error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi upload ảnh tiện nghi',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Delete hotel image
exports.deleteHotelImage = async (req, res) => {
  try {
    const managerId = req.user.id;
    const { imageId } = req.params;
    const pool = getPool();
    
    // Parse imageId
    const parsedImageId = parseInt(imageId, 10);
    if (isNaN(parsedImageId) || parsedImageId <= 0) {
      return res.status(400).json({
        success: false,
        message: 'ID ảnh không hợp lệ'
      });
    }
    
    // Get hotel ID
    const hotelResult = await pool.request()
      .input('managerId', sql.Int, managerId)
      .query('SELECT id FROM dbo.khach_san WHERE nguoi_quan_ly_id = @managerId');
    
    if (!hotelResult.recordset || hotelResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn được gán'
      });
    }
    
    const hotelId = hotelResult.recordset[0].id;
    
    // Check if image belongs to this hotel
    const imageResult = await pool.request()
      .input('imageId', sql.Int, parsedImageId)
      .input('hotelId', sql.Int, hotelId)
      .query('SELECT * FROM dbo.anh_khach_san WHERE id = @imageId AND khach_san_id = @hotelId');
    
    if (!imageResult.recordset || imageResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy ảnh hoặc ảnh không thuộc khách sạn này'
      });
    }
    
    const imageData = imageResult.recordset[0];
    const isMainImage = imageData.la_anh_dai_dien === 1 || imageData.la_anh_dai_dien === true;
    
    // Delete image from database
    await pool.request()
      .input('imageId', sql.Int, parsedImageId)
      .query('DELETE FROM dbo.anh_khach_san WHERE id = @imageId');
    
    // If deleted image was main image, set first remaining image as main
    if (isMainImage) {
      const remainingImages = await pool.request()
        .input('hotelId', sql.Int, hotelId)
        .query(`
          SELECT TOP 1 id, duong_dan_anh 
          FROM dbo.anh_khach_san 
          WHERE khach_san_id = @hotelId 
          ORDER BY thu_tu ASC, created_at ASC
        `);
      
      if (remainingImages.recordset.length > 0) {
        const newMainImage = remainingImages.recordset[0];
        // Set as main image
        await pool.request()
          .input('imageId', sql.Int, newMainImage.id)
          .query('UPDATE dbo.anh_khach_san SET la_anh_dai_dien = 1 WHERE id = @imageId');
        
        // Update hinh_anh in khach_san table
        await pool.request()
          .input('hotelId', sql.Int, hotelId)
          .input('hinhAnh', sql.NVarChar(500), newMainImage.duong_dan_anh)
          .query('UPDATE dbo.khach_san SET hinh_anh = @hinhAnh WHERE id = @hotelId');
      } else {
        // No images left, clear hinh_anh
        await pool.request()
          .input('hotelId', sql.Int, hotelId)
          .query('UPDATE dbo.khach_san SET hinh_anh = NULL WHERE id = @hotelId');
      }
    }
    
    console.log(`✅ Deleted hotel image ${parsedImageId} for hotel ${hotelId}`);
    
    res.json({
      success: true,
      message: 'Xóa ảnh thành công'
    });
  } catch (error) {
    console.error('❌ Delete hotel image error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi xóa ảnh',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Set hotel main image
exports.setMainHotelImage = async (req, res) => {
  try {
    const managerId = req.user.id;
    const { imageId } = req.params;
    const pool = getPool();
    
    // Parse imageId
    const parsedImageId = parseInt(imageId, 10);
    if (isNaN(parsedImageId) || parsedImageId <= 0) {
      return res.status(400).json({
        success: false,
        message: 'ID ảnh không hợp lệ'
      });
    }
    
    // Get hotel ID
    const hotelResult = await pool.request()
      .input('managerId', sql.Int, managerId)
      .query('SELECT id FROM dbo.khach_san WHERE nguoi_quan_ly_id = @managerId');
    
    if (!hotelResult.recordset || hotelResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn được gán'
      });
    }
    
    const hotelId = hotelResult.recordset[0].id;
    
    // Check if image belongs to this hotel
    const imageResult = await pool.request()
      .input('imageId', sql.Int, parsedImageId)
      .input('hotelId', sql.Int, hotelId)
      .query('SELECT * FROM dbo.anh_khach_san WHERE id = @imageId AND khach_san_id = @hotelId');
    
    if (!imageResult.recordset || imageResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy ảnh hoặc ảnh không thuộc khách sạn này'
      });
    }
    
    const imageData = imageResult.recordset[0];
    
    // Unset all other main images
    await pool.request()
      .input('hotelId', sql.Int, hotelId)
      .query('UPDATE dbo.anh_khach_san SET la_anh_dai_dien = 0 WHERE khach_san_id = @hotelId');
    
    // Set this image as main
    await pool.request()
      .input('imageId', sql.Int, parsedImageId)
      .query('UPDATE dbo.anh_khach_san SET la_anh_dai_dien = 1 WHERE id = @imageId');
    
    // Update hinh_anh in khach_san table
    await pool.request()
      .input('hotelId', sql.Int, hotelId)
      .input('hinhAnh', sql.NVarChar(500), imageData.duong_dan_anh)
      .query('UPDATE dbo.khach_san SET hinh_anh = @hinhAnh WHERE id = @hotelId');
    
    console.log(`✅ Set hotel image ${parsedImageId} as main for hotel ${hotelId}`);
    
    res.json({
      success: true,
      message: 'Đặt ảnh đại diện thành công'
    });
  } catch (error) {
    console.error('❌ Set main hotel image error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi đặt ảnh đại diện',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

module.exports = exports;
