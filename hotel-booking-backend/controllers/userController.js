const { getPool } = require('../config/db');
const sql = require('mssql');

const userController = {
  // Get user messages
  async getMessages(req, res) {
    try {
      const userId = req.user.ma_nguoi_dung;
      const pool = await getPool();
      
      const query = `
        SELECT 
          tm.id,
          tm.tieu_de as title,
          tm.noi_dung as content,
          tm.loai as type,
          tm.da_doc as isRead,
          tm.ngay_tao as createdAt,
          tm.ngay_cap_nhat as updatedAt,
          ks.ten as hotelName,
          ks.hinh_anh as hotelImage,
          pdp.check_in_date as checkInDate,
          pdp.check_out_date as checkOutDate,
          CONCAT(FORMAT(pdp.check_in_date, 'dd/MM/yyyy'), ' - ', FORMAT(pdp.check_out_date, 'dd/MM/yyyy')) as bookingDateRange,
          CASE 
            WHEN tm.loai = 'cancel' THEN 'Hủy đặt phòng'
            WHEN tm.loai = 'confirm' THEN 'Xác nhận đặt phòng'
            WHEN tm.loai = 'reminder' THEN 'Nhắc nhở'
            ELSE 'Thông báo'
          END as actionText,
          CASE 
            WHEN tm.loai IN ('cancel', 'confirm', 'reminder') THEN 1
            ELSE 0
          END as hasAction
        FROM tin_nhan tm
        LEFT JOIN bookings pdp ON tm.phieu_dat_phong_id = pdp.id
        LEFT JOIN khach_san ks ON pdp.hotel_id = ks.id
        WHERE tm.nguoi_dung_id = @userId
        ORDER BY tm.ngay_tao DESC
      `;
      
      const result = await pool.request()
        .input('userId', sql.Int, userId)
        .query(query);
      
      res.json({
        success: true,
        message: 'Lấy danh sách tin nhắn thành công',
        data: result.recordset
      });
    } catch (error) {
      console.error('Get messages error:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi lấy danh sách tin nhắn'
      });
    }
  },

  // Mark message as read
  async markMessageAsRead(req, res) {
    try {
      const userId = req.user.ma_nguoi_dung;
      const messageId = req.params.id;
      const pool = await getPool();
      
      const query = `
        UPDATE tin_nhan 
        SET da_doc = 1, ngay_cap_nhat = GETDATE()
        WHERE id = @messageId AND nguoi_dung_id = @userId
      `;
      
      const result = await pool.request()
        .input('messageId', sql.Int, messageId)
        .input('userId', sql.Int, userId)
        .query(query);
      
      if (result.rowsAffected[0] > 0) {
        res.json({
          success: true,
          message: 'Đã đánh dấu đã đọc'
        });
      } else {
        res.status(404).json({
          success: false,
          message: 'Không tìm thấy tin nhắn'
        });
      }
    } catch (error) {
      console.error('Mark message as read error:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi đánh dấu đã đọc'
      });
    }
  },

  // Delete message
  async deleteMessage(req, res) {
    try {
      const userId = req.user.ma_nguoi_dung;
      const messageId = req.params.id;
      const pool = await getPool();
      
      const query = `
        DELETE FROM tin_nhan 
        WHERE id = @messageId AND nguoi_dung_id = @userId
      `;
      
      const result = await pool.request()
        .input('messageId', sql.Int, messageId)
        .input('userId', sql.Int, userId)
        .query(query);
      
      if (result.rowsAffected[0] > 0) {
        res.json({
          success: true,
          message: 'Đã xóa tin nhắn'
        });
      } else {
        res.status(404).json({
          success: false,
          message: 'Không tìm thấy tin nhắn'
        });
      }
    } catch (error) {
      console.error('Delete message error:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi xóa tin nhắn'
      });
    }
  },

  // Get user reviews
  async getMyReviews(req, res) {
    try {
      // ✅ FIX: Get userId from multiple possible sources
      const userId = req.user?.ma_nguoi_dung || req.user?.id || req.user?.userId;
      
      if (!userId) {
        console.error('❌ User ID not found in getMyReviews:', req.user);
        return res.status(401).json({
          success: false,
          message: 'Không tìm thấy thông tin người dùng. Vui lòng đăng nhập lại.'
        });
      }
      
      const pool = await getPool();
      
      const query = `
        SELECT 
          b.id,
          b.hotel_id,
          b.booking_code as booking_id,
          b.hotel_name as hotel_name,
          ks.hinh_anh as hotel_image,
          ks.dia_chi as location,
          b.room_type as room_type,
          b.check_in_date as check_in_date,
          b.check_out_date as check_out_date,
          b.nights as nights,
          CASE WHEN dg.id IS NOT NULL THEN 1 ELSE 0 END as is_reviewed,
          dg.so_sao_tong as rating,
          dg.binh_luan as content,
          dg.ngay as reviewed_at,
          dg.id as review_id
        FROM bookings b
        LEFT JOIN khach_san ks ON b.hotel_id = ks.id
        LEFT JOIN danh_gia dg ON dg.phieu_dat_phong_id = b.id AND dg.nguoi_dung_id = @userId
        WHERE b.user_id = @userId
          AND b.booking_status = 'completed'
        ORDER BY b.check_in_date DESC
      `;
      
      const result = await pool.request()
        .input('userId', sql.Int, userId)
        .query(query);
      
      console.log(`📋 Reviews for user ${userId}: Found ${result.recordset.length} completed bookings`);
      
      // Debug: Check if there are any reviews in danh_gia table
      const debugQuery = `
        SELECT 
          dg.id,
          dg.phieu_dat_phong_id,
          dg.nguoi_dung_id,
          dg.khach_san_id,
          dg.so_sao_tong,
          dg.binh_luan,
          dg.ngay
        FROM danh_gia dg
        WHERE dg.nguoi_dung_id = @userId
        ORDER BY dg.ngay DESC
      `;
      
      const debugResult = await pool.request()
        .input('userId', sql.Int, userId)
        .query(debugQuery);
      
      console.log(`🔍 Debug: Found ${debugResult.recordset.length} reviews in danh_gia table for user ${userId}`);
      if (debugResult.recordset.length > 0) {
        console.log('🔍 Debug review data:', JSON.stringify(debugResult.recordset[0], null, 2));
      }
      
      if (result.recordset.length > 0) {
        console.log('📋 Sample booking data:', JSON.stringify(result.recordset[0], null, 2));
      }
      
      res.json({
        success: true,
        message: 'Lấy danh sách nhận xét thành công',
        data: result.recordset
      });
    } catch (error) {
      console.error('Get reviews error:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi lấy danh sách nhận xét'
      });
    }
  },

  // Create review
  async createReview(req, res) {
    try {
      // ✅ FIX: Get userId from multiple possible sources
      const userId = req.user?.ma_nguoi_dung || req.user?.id || req.user?.userId;
      
      if (!userId) {
        console.error('❌ User ID not found in request:', req.user);
        return res.status(401).json({
          success: false,
          message: 'Không tìm thấy thông tin người dùng. Vui lòng đăng nhập lại.'
        });
      }
      
      const { booking_id, rating, content } = req.body;
      const pool = await getPool();
      
      console.log('📝 Create review request:', { 
        booking_id, 
        booking_id_type: typeof booking_id,
        rating, 
        rating_type: typeof rating,
        content,
        contentLength: content?.length,
        userId,
        user_object: { ma_nguoi_dung: req.user.ma_nguoi_dung, id: req.user.id }
      });
      
      // ✅ Validate required fields
      if (!booking_id) {
        console.log('❌ Missing booking_id');
        return res.status(400).json({
          success: false,
          message: 'Vui lòng cung cấp mã đặt phòng'
        });
      }
      
      if (!rating || rating < 1 || rating > 5) {
        console.log('❌ Invalid rating:', rating);
        return res.status(400).json({
          success: false,
          message: 'Đánh giá phải từ 1 đến 5 sao'
        });
      }
      
      if (!content || content.trim().length === 0) {
        console.log('❌ Missing or empty content');
        return res.status(400).json({
          success: false,
          message: 'Vui lòng nhập nội dung nhận xét'
        });
      }
      
      console.log('✅ Input validation passed');
      
      // ✅ FIX: booking_id từ frontend có thể là string (booking_code) hoặc int (id)
      // Cần tìm booking.id thực tế dựa trên booking_code hoặc id
      let bookingIdInt = null;
      let booking = null;
      
      // ✅ Check if booking_id is booking_code (starts with "BOOK-") or numeric ID
      const isBookingCode = typeof booking_id === 'string' && booking_id.startsWith('BOOK-');
      
      if (isBookingCode) {
        console.log('🔍 Looking for booking by code:', booking_id);
        // It's a booking_code (string like "BOOK-20251030-4350")
        const checkQuery = `
          SELECT id, booking_status, hotel_id, booking_code 
          FROM bookings 
          WHERE booking_code = @bookingCode AND user_id = @userId
        `;
        
        const checkResult = await pool.request()
          .input('bookingCode', sql.NVarChar, booking_id)
          .input('userId', sql.Int, userId)
          .query(checkQuery);
        
        console.log('🔍 Booking query result:', checkResult.recordset.length, 'records found');
        
        if (checkResult.recordset.length === 0) {
          console.log('❌ Booking not found with code:', booking_id, 'for user:', userId);
          return res.status(404).json({
            success: false,
            message: 'Không tìm thấy đặt phòng với mã: ' + booking_id
          });
        }
        booking = checkResult.recordset[0];
        bookingIdInt = booking.id;
        console.log('✅ Found booking:', { id: bookingIdInt, status: booking.booking_status, hotel_id: booking.hotel_id });
      } else {
        // It's an integer ID (number or numeric string)
        bookingIdInt = parseInt(booking_id);
        
        if (isNaN(bookingIdInt)) {
          return res.status(400).json({
            success: false,
            message: 'Mã đặt phòng không hợp lệ: ' + booking_id
          });
        }
        
        const checkQuery = `
          SELECT id, booking_status, hotel_id, booking_code 
          FROM bookings 
          WHERE id = @bookingId AND user_id = @userId
        `;
        
        const checkResult = await pool.request()
          .input('bookingId', sql.Int, bookingIdInt)
          .input('userId', sql.Int, userId)
          .query(checkQuery);
        
        if (checkResult.recordset.length === 0) {
          return res.status(404).json({
            success: false,
            message: 'Không tìm thấy đặt phòng với ID: ' + bookingIdInt
          });
        }
        booking = checkResult.recordset[0];
      }
      
      // Validate booking status
      console.log('📋 Booking status:', booking.booking_status);
      if (booking.booking_status !== 'confirmed' && booking.booking_status !== 'completed') {
        console.log('❌ Invalid booking status:', booking.booking_status);
        return res.status(400).json({
          success: false,
          message: 'Chỉ có thể nhận xét sau khi đặt phòng được xác nhận hoặc hoàn thành'
        });
      }
      
      const hotelId = booking.hotel_id;
      console.log('📋 Hotel ID:', hotelId);
      
      if (!hotelId) {
        console.log('❌ Hotel ID not found for booking:', bookingIdInt);
        return res.status(400).json({
          success: false,
          message: 'Không tìm thấy thông tin khách sạn'
        });
      }
      
      console.log('✅ Booking validation passed. Booking ID:', bookingIdInt, 'Hotel ID:', hotelId);
      
      // ✅ FIX: Since danh_gia.phieu_dat_phong_id FK references phieu_dat_phong table
      // but we're using bookings.id, we need to use bookings.id directly
      // The FK constraint needs to be updated to reference bookings instead
      // For now, try to use bookings.id (might fail if FK doesn't match)
      // OR find/create corresponding phieu_dat_phong record
      
      // ✅ FIX: Check if review already exists for THIS SPECIFIC BOOKING only
      // Don't block if user reviewed the hotel before (different booking)
      const existingQuery = `
        SELECT id FROM danh_gia 
        WHERE phieu_dat_phong_id = @bookingIdInt
      `;
      
      const existingResult = await pool.request()
        .input('bookingIdInt', sql.Int, bookingIdInt)
        .query(existingQuery);
      
      if (existingResult.recordset.length > 0) {
        console.log('⚠️ Review already exists for booking:', bookingIdInt);
        return res.status(400).json({
          success: false,
          message: 'Bạn đã đánh giá cho đặt phòng này rồi'
        });
      }
      
      console.log('✅ No existing review found for booking:', bookingIdInt);
      
      // ✅ FIX: Try to insert with bookings.id directly
      // If FK constraint fails, we'll catch and provide a better error message
      const insertQuery = `
        INSERT INTO danh_gia (
          phieu_dat_phong_id,
          nguoi_dung_id, 
          khach_san_id, 
          so_sao_tong,
          binh_luan, 
          ngay,
          trang_thai
        )
        VALUES (
          @bookingIdInt,
          @userId, 
          @hotelId, 
          @rating,
          @content, 
          GETDATE(),
          N'Đã duyệt'
        )
      `;
      
      await pool.request()
        .input('bookingIdInt', sql.Int, bookingIdInt)
        .input('userId', sql.Int, userId)
        .input('hotelId', sql.Int, hotelId)
        .input('rating', sql.Int, rating)
        .input('content', sql.NVarChar, content || '')
        .query(insertQuery);
      
      console.log('✅ Review created successfully for booking:', bookingIdInt);
      
      res.status(201).json({
        success: true,
        message: 'Đã tạo nhận xét thành công'
      });
    } catch (error) {
      console.error('❌ Create review error:', error);
      console.error('Error details:', {
        message: error.message,
        code: error.code,
        number: error.number,
        stack: error.stack
      });
      
      // Better error messages
      let errorMessage = 'Lỗi server khi tạo nhận xét';
      if (error.number === 547) {
        if (error.message.includes('fk_danh_gia_pdp')) {
          errorMessage = 'Lỗi: Foreign key constraint - Cần cập nhật FOREIGN KEY constraint để reference bảng bookings thay vì phieu_dat_phong. Vui lòng liên hệ admin.';
          console.error('🔧 FIX NEEDED: Foreign key constraint fk_danh_gia_pdp needs to reference bookings table, not phieu_dat_phong');
        } else {
          errorMessage = 'Lỗi ràng buộc dữ liệu. Vui lòng kiểm tra lại thông tin đặt phòng.';
        }
      } else if (error.message.includes('FOREIGN KEY')) {
        errorMessage = 'Không tìm thấy đặt phòng hợp lệ để đánh giá.';
      } else if (error.message.includes('CHECK constraint')) {
        errorMessage = 'Dữ liệu không hợp lệ. Vui lòng thử lại.';
      } else {
        errorMessage = `Lỗi: ${error.message}`;
      }
      
      res.status(500).json({
        success: false,
        message: errorMessage
      });
    }
  },

  // Update review
  async updateReview(req, res) {
    try {
      const userId = req.user.ma_nguoi_dung;
      const reviewId = req.params.id;
      const { rating, content } = req.body;
      const pool = await getPool();
      
      const query = `
        UPDATE danh_gia 
        SET diem = @rating, noi_dung = @content, ngay_cap_nhat = GETDATE()
        WHERE id = @reviewId AND nguoi_dung_id = @userId
      `;
      
      const result = await pool.request()
        .input('reviewId', sql.Int, reviewId)
        .input('userId', sql.Int, userId)
        .input('rating', sql.Int, rating)
        .input('content', sql.NVarChar, content)
        .query(query);
      
      if (result.rowsAffected[0] > 0) {
        res.json({
          success: true,
          message: 'Đã cập nhật nhận xét thành công'
        });
      } else {
        res.status(404).json({
          success: false,
          message: 'Không tìm thấy nhận xét'
        });
      }
    } catch (error) {
      console.error('Update review error:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi cập nhật nhận xét'
      });
    }
  },

  // Delete review
  async deleteReview(req, res) {
    try {
      const userId = req.user.ma_nguoi_dung;
      const reviewId = req.params.id;
      const pool = await getPool();
      
      const query = `
        DELETE FROM danh_gia 
        WHERE id = @reviewId AND nguoi_dung_id = @userId
      `;
      
      const result = await pool.request()
        .input('reviewId', sql.Int, reviewId)
        .input('userId', sql.Int, userId)
        .query(query);
      
      if (result.rowsAffected[0] > 0) {
        res.json({
          success: true,
          message: 'Đã xóa nhận xét thành công'
        });
      } else {
        res.status(404).json({
          success: false,
          message: 'Không tìm thấy nhận xét'
        });
      }
    } catch (error) {
      console.error('Delete review error:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi xóa nhận xét'
      });
    }
  },

  // Get review by ID
  async getReview(req, res) {
    try {
      const userId = req.user.ma_nguoi_dung;
      const reviewId = req.params.id;
      const pool = await getPool();
      
      const query = `
        SELECT 
          dg.id,
          dg.diem as rating,
          dg.noi_dung as content,
          dg.ngay_tao as createdAt,
          dg.ngay_cap_nhat as updatedAt,
          pdp.check_in_date as checkInDate,
          pdp.check_out_date as checkOutDate,
          pdp.nights as nights,
          pdp.hotel_name as hotelName,
          ks.dia_chi as location,
          ks.hinh_anh as hotelImage,
          pdp.room_type as roomType
        FROM danh_gia dg
        INNER JOIN bookings pdp ON dg.phieu_dat_phong_id = pdp.id
        INNER JOIN khach_san ks ON pdp.hotel_id = ks.id
        WHERE dg.id = @reviewId AND dg.nguoi_dung_id = @userId
      `;
      
      const result = await pool.request()
        .input('reviewId', sql.Int, reviewId)
        .input('userId', sql.Int, userId)
        .query(query);
      
      if (result.recordset.length > 0) {
        res.json({
          success: true,
          message: 'Lấy thông tin nhận xét thành công',
          data: result.recordset[0]
        });
      } else {
        res.status(404).json({
          success: false,
          message: 'Không tìm thấy nhận xét'
        });
      }
    } catch (error) {
      console.error('Get review error:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi lấy thông tin nhận xét'
      });
    }
  },

  // Get user profile
  async getProfile(req, res) {
    try {
      const userId = req.user.ma_nguoi_dung;
      const pool = await getPool();
      
      const query = `
        SELECT 
          id,
          ho_ten as hoTen,
          email,
          sdt,
          anh_dai_dien as anhDaiDien,
          ngay_sinh as ngaySinh,
          gioi_tinh as gioiTinh,
          trang_thai as trangThai,
          created_at as createdAt,
          updated_at as updatedAt,
          vip_points as vipPoints,
          vip_status as vipStatus
        FROM nguoi_dung 
        WHERE id = @userId
      `;
      
      const result = await pool.request()
        .input('userId', sql.Int, userId)
        .query(query);
      
      if (result.recordset.length > 0) {
        res.json({
          success: true,
          message: 'Lấy thông tin profile thành công',
          data: result.recordset[0]
        });
      } else {
        res.status(404).json({
          success: false,
          message: 'Không tìm thấy thông tin người dùng'
        });
      }
    } catch (error) {
      console.error('Get profile error:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi lấy thông tin profile'
      });
    }
  },

  // Update user profile
  async updateProfile(req, res) {
    try {
      const userId = req.user.ma_nguoi_dung || req.user.id;
      const { ho_ten, hoTen, sdt, diaChi, ngaySinh, gioiTinh } = req.body;
      
      // Support both ho_ten and hoTen
      const tenToUpdate = ho_ten || hoTen;
      
      if (!userId) {
        return res.status(401).json({
          success: false,
          message: 'Chưa đăng nhập'
        });
      }
      
      const pool = await getPool();
      
      // Build dynamic query based on what fields are provided
      const updates = [];
      const request = pool.request().input('userId', sql.Int, userId);
      
      if (tenToUpdate) {
        updates.push('ho_ten = @hoTen');
        request.input('hoTen', sql.NVarChar, tenToUpdate);
      }
      if (sdt !== undefined) {
        updates.push('sdt = @sdt');
        request.input('sdt', sql.NVarChar, sdt);
      }
      if (ngaySinh !== undefined) {
        updates.push('ngay_sinh = @ngaySinh');
        request.input('ngaySinh', sql.Date, ngaySinh);
      }
      if (gioiTinh !== undefined) {
        updates.push('gioi_tinh = @gioiTinh');
        request.input('gioiTinh', sql.NVarChar, gioiTinh);
      }
      
      if (updates.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'Không có thông tin để cập nhật'
        });
      }
      
      const query = `
        UPDATE nguoi_dung 
        SET ${updates.join(', ')}
        WHERE id = @userId
      `;
      
      const result = await request.query(query);
      
      if (result.rowsAffected[0] > 0) {
        res.json({
          success: true,
          message: 'Đã cập nhật profile thành công'
        });
      } else {
        res.status(404).json({
          success: false,
          message: 'Không tìm thấy thông tin người dùng'
        });
      }
    } catch (error) {
      console.error('Update profile error:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi cập nhật profile'
      });
    }
  },

  // Get user bookings
  async getMyBookings(req, res) {
    try {
      const userId = req.user.ma_nguoi_dung;
      const pool = await getPool();
      
      const query = `
        SELECT 
          pdp.id,
          pdp.hotel_id as hotelId,
          ks.ten as hotelName,
          ks.hinh_anh as hotelImage,
          ks.dia_chi as location,
          pdp.check_in_date as checkInDate,
          pdp.check_out_date as checkOutDate,
          pdp.nights as nights,
          pdp.room_count as rooms,
          pdp.guest_count as adults,
          0 as children,
          pdp.final_price as totalAmount,
          pdp.booking_status as status,
          pdp.created_at as createdAt,
          pdp.updated_at as updatedAt,
          '' as cancellationReason,
          CASE 
            WHEN pdp.booking_status = 'pending' THEN 1
            ELSE 0
          END as canCancel
        FROM bookings pdp
        INNER JOIN khach_san ks ON pdp.hotel_id = ks.id
        WHERE pdp.user_id = @userId
        ORDER BY pdp.created_at DESC
      `;
      
      const result = await pool.request()
        .input('userId', sql.Int, userId)
        .query(query);
      
      res.json({
        success: true,
        message: 'Lấy danh sách đặt phòng thành công',
        data: result.recordset
      });
    } catch (error) {
      console.error('Get bookings error:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi lấy danh sách đặt phòng'
      });
    }
  },

  // Get booking by ID
  async getBooking(req, res) {
    try {
      const userId = req.user.ma_nguoi_dung;
      const bookingId = req.params.id;
      const pool = await getPool();
      
      const query = `
        SELECT 
          pdp.id,
          pdp.check_in_date as checkInDate,
          pdp.check_out_date as checkOutDate,
          pdp.room_count as roomCount,
          pdp.guest_count as guestCount,
          pdp.final_price as totalAmount,
          pdp.booking_status as status,
          pdp.created_at as createdAt,
          pdp.hotel_name as hotelName,
          ks.dia_chi as hotelAddress,
          ks.hinh_anh as hotelImage,
          ks.so_dien_thoai as hotelPhone,
          pdp.room_type as roomType,
          pdp.room_price as roomPrice
        FROM bookings pdp
        INNER JOIN khach_san ks ON pdp.hotel_id = ks.id
        WHERE pdp.id = @bookingId AND pdp.user_id = @userId
      `;
      
      const result = await pool.request()
        .input('bookingId', sql.Int, bookingId)
        .input('userId', sql.Int, userId)
        .query(query);
      
      if (result.recordset.length > 0) {
        res.json({
          success: true,
          message: 'Lấy thông tin đặt phòng thành công',
          data: result.recordset[0]
        });
      } else {
        res.status(404).json({
          success: false,
          message: 'Không tìm thấy đặt phòng'
        });
      }
    } catch (error) {
      console.error('Get booking error:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi lấy thông tin đặt phòng'
      }      );
    }
  },

  // Get saved items
  async getSavedItems(req, res) {
    try {
      const userId = req.user.ma_nguoi_dung;
      const pool = await getPool();
      
      const query = `
        SELECT 
          id,
          item_id as itemId,
          type,
          name,
          location,
          price,
          image_url as imageUrl,
          metadata,
          created_at as savedAt
        FROM saved_items 
        WHERE user_id = @userId
        ORDER BY created_at DESC
      `;
      
      const result = await pool.request()
        .input('userId', sql.Int, userId)
        .query(query);
      
      res.json({
        success: true,
        message: 'Lấy danh sách đã lưu thành công',
        data: result.recordset
      });
    } catch (error) {
      console.error('Get saved items error:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi lấy danh sách đã lưu'
      });
    }
  },

  // Add to saved items
  async addToSaved(req, res) {
    try {
      const userId = req.user.ma_nguoi_dung;
      const { item_id, type, name, location, price, image_url, metadata } = req.body;
      const pool = await getPool();
      
      // Check if already saved
      const checkQuery = `
        SELECT id FROM saved_items 
        WHERE user_id = @userId AND item_id = @itemId AND type = @type
      `;
      
      const checkResult = await pool.request()
        .input('userId', sql.Int, userId)
        .input('itemId', sql.NVarChar, item_id)
        .input('type', sql.NVarChar, type)
        .query(checkQuery);
      
      if (checkResult.recordset.length > 0) {
        return res.status(400).json({
          success: false,
          message: 'Mục này đã được lưu trước đó'
        });
      }
      
      // Add to saved items
      const insertQuery = `
        INSERT INTO saved_items (user_id, item_id, type, name, location, price, image_url, metadata, created_at)
        VALUES (@userId, @itemId, @type, @name, @location, @price, @imageUrl, @metadata, GETDATE())
      `;
      
      await pool.request()
        .input('userId', sql.Int, userId)
        .input('itemId', sql.NVarChar, item_id)
        .input('type', sql.NVarChar, type)
        .input('name', sql.NVarChar, name)
        .input('location', sql.NVarChar, location)
        .input('price', sql.NVarChar, price)
        .input('imageUrl', sql.NVarChar, image_url)
        .input('metadata', sql.NVarChar, metadata ? JSON.stringify(metadata) : null)
        .query(insertQuery);
      
      res.status(201).json({
        success: true,
        message: 'Đã thêm vào danh sách đã lưu'
      });
    } catch (error) {
      console.error('Add to saved error:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi thêm vào danh sách đã lưu'
      });
    }
  },

  // Remove from saved items
  async removeFromSaved(req, res) {
    try {
      const userId = req.user.ma_nguoi_dung;
      const savedItemId = req.params.id;
      const pool = await getPool();
      
      const query = `
        DELETE FROM saved_items 
        WHERE id = @savedItemId AND user_id = @userId
      `;
      
      const result = await pool.request()
        .input('savedItemId', sql.Int, savedItemId)
        .input('userId', sql.Int, userId)
        .query(query);
      
      if (result.rowsAffected[0] > 0) {
        res.json({
          success: true,
          message: 'Đã xóa khỏi danh sách đã lưu'
        });
      } else {
        res.status(404).json({
          success: false,
          message: 'Không tìm thấy mục đã lưu'
        });
      }
    } catch (error) {
      console.error('Remove from saved error:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi xóa khỏi danh sách đã lưu'
      });
    }
  },

  // Check if item is saved
  async checkIsSaved(req, res) {
    try {
      const userId = req.user.ma_nguoi_dung;
      const { item_id, type } = req.query;
      const pool = await getPool();
      
      const query = `
        SELECT id FROM saved_items 
        WHERE user_id = @userId AND item_id = @itemId AND type = @type
      `;
      
      const result = await pool.request()
        .input('userId', sql.Int, userId)
        .input('itemId', sql.NVarChar, item_id)
        .input('type', sql.NVarChar, type)
        .query(query);
      
      res.json({
        success: true,
        data: {
          is_saved: result.recordset.length > 0
        },
        message: 'Kiểm tra trạng thái lưu thành công'
      });
    } catch (error) {
      console.error('Check is saved error:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi kiểm tra trạng thái lưu'
      });
    }
  },

  // Cancel booking
  async cancelBooking(req, res) {
    try {
      const userId = req.user.ma_nguoi_dung;
      const bookingId = req.params.id;
      const { reason } = req.body;
      const pool = await getPool();
      
      // First check if booking exists and belongs to user
      const checkQuery = `
        SELECT id, booking_status 
        FROM bookings 
        WHERE id = @bookingId AND user_id = @userId
      `;
      
      const checkResult = await pool.request()
        .input('bookingId', sql.Int, bookingId)
        .input('userId', sql.Int, userId)
        .query(checkQuery);
      
      if (checkResult.recordset.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Không tìm thấy đặt phòng'
        });
      }
      
      const booking = checkResult.recordset[0];
      
      // Check if booking can be cancelled
      if (booking.booking_status !== 'pending') {
        return res.status(400).json({
          success: false,
          message: 'Chỉ có thể hủy đặt phòng đang chờ xác nhận'
        });
      }
      
      // Update booking status to cancelled
      const updateQuery = `
        UPDATE bookings 
        SET booking_status = 'cancelled',
            refund_reason = @reason,
            updated_at = GETDATE()
        WHERE id = @bookingId
      `;
      
      await pool.request()
        .input('bookingId', sql.Int, bookingId)
        .input('reason', sql.NVarChar, reason || 'Khách hàng hủy')
        .query(updateQuery);
      
      res.json({
        success: true,
        message: 'Hủy đặt phòng thành công'
      });
    } catch (error) {
      console.error('Cancel booking error:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi hủy đặt phòng'
      });
    }
  }
};

module.exports = userController;
