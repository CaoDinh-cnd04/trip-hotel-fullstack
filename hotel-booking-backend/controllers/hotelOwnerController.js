const { getPool } = require('../config/db');
const sql = require('mssql');
const path = require('path');
const fs = require('fs');

const hotelOwnerController = {
  // Register new hotel
  async registerHotel(req, res) {
    try {
      const userId = req.user.ma_nguoi_dung;
      const {
        hotel_name,
        address,
        province,
        district,
        phone,
        email,
        description,
        website,
        star_rating
      } = req.body;

      const images = req.files || [];
      const pool = await getPool();

      // Start transaction
      const transaction = new sql.Transaction(pool);
      await transaction.begin();

      try {
        // Insert hotel
        const insertHotelQuery = `
          INSERT INTO khach_san (
            ten, dia_chi, sdt_lien_he, 
            email_lien_he, mo_ta, website, so_sao, chu_khach_san_id, 
            trang_thai, created_at, updated_at
          )
          OUTPUT INSERTED.id
          VALUES (
            @hotelName, @address, @phone,
            @email, @description, @website, @starRating, @ownerId,
            'pending', GETDATE(), GETDATE()
          )
        `;

        const hotelResult = await transaction.request()
          .input('hotelName', sql.NVarChar, hotel_name)
          .input('address', sql.NVarChar, address)
          .input('phone', sql.NVarChar, phone)
          .input('email', sql.NVarChar, email)
          .input('description', sql.NVarChar, description)
          .input('website', sql.NVarChar, website)
          .input('starRating', sql.Int, parseInt(star_rating))
          .input('ownerId', sql.Int, userId)
          .query(insertHotelQuery);

        const hotelId = hotelResult.recordset[0].id;

        // Save images
        if (images.length > 0) {
          const imageUrls = [];
          for (let i = 0; i < images.length; i++) {
            const image = images[i];
            const imageName = `hotel_${hotelId}_${Date.now()}_${i}${path.extname(image.originalname)}`;
            const imagePath = path.join('uploads', 'hotels', imageName);
            
            // Create directory if it doesn't exist
            const uploadDir = path.dirname(imagePath);
            if (!fs.existsSync(uploadDir)) {
              fs.mkdirSync(uploadDir, { recursive: true });
            }
            
            // Move file
            fs.renameSync(image.path, imagePath);
            imageUrls.push(`/uploads/hotels/${imageName}`);
          }

          // Update hotel with main image
          if (imageUrls.length > 0) {
            await transaction.request()
              .input('hotelId', sql.Int, hotelId)
              .input('mainImage', sql.NVarChar, imageUrls[0])
              .query(`
                UPDATE khach_san 
                SET hinh_anh = @mainImage 
                WHERE id = @hotelId
              `);
          }
        }

        // Create notification for admin
        await transaction.request()
          .input('userId', sql.Int, userId)
          .input('hotelId', sql.Int, hotelId)
          .input('hotelName', sql.NVarChar, hotel_name)
          .query(`
            INSERT INTO thong_bao (
              tieu_de, noi_dung, loai, nguoi_nhan_id, 
              trang_thai, ngay_tao
            )
            VALUES (
              'Đăng ký khách sạn mới',
              'Khách sạn "${hotel_name}" đã được đăng ký và đang chờ duyệt',
              'hotel_registration',
              @userId,
              'unread',
              GETDATE()
            )
          `);

        await transaction.commit();

        res.status(201).json({
          success: true,
          message: 'Đăng ký khách sạn thành công. Chúng tôi sẽ xem xét và liên hệ với bạn sớm nhất.',
          data: {
            hotel_id: hotelId,
            status: 'pending'
          }
        });

      } catch (error) {
        await transaction.rollback();
        throw error;
      }

    } catch (error) {
      console.error('Register hotel error:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi đăng ký khách sạn'
      });
    }
  },

  // Get owner's hotels
  async getMyHotels(req, res) {
    try {
      const userId = req.user.ma_nguoi_dung;
      const pool = await getPool();
      
      const query = `
        SELECT 
          id,
          ten as hotelName,
          dia_chi as address,
          sdt_lien_he as phone,
          email_lien_he as email,
          mo_ta as description,
          website,
          so_sao as starRating,
          hinh_anh as mainImage,
          trang_thai as status,
          created_at as createdAt,
          updated_at as updatedAt
        FROM khach_san 
        WHERE chu_khach_san_id = @userId
        ORDER BY created_at DESC
      `;
      
      const result = await pool.request()
        .input('userId', sql.Int, userId)
        .query(query);
      
      res.json({
        success: true,
        message: 'Lấy danh sách khách sạn thành công',
        data: result.recordset
      });
    } catch (error) {
      console.error('Get my hotels error:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi lấy danh sách khách sạn'
      });
    }
  },

  // Get hotel statistics
  async getHotelStats(req, res) {
    try {
      const userId = req.user.ma_nguoi_dung;
      const pool = await getPool();
      
      const query = `
        SELECT 
          COUNT(*) as totalHotels,
          SUM(CASE WHEN trang_thai = 'active' THEN 1 ELSE 0 END) as activeHotels,
          SUM(CASE WHEN trang_thai = 'pending' THEN 1 ELSE 0 END) as pendingHotels,
          (SELECT COUNT(*) FROM phieu_dat_phong pdp 
           INNER JOIN khach_san ks ON pdp.khach_san_id = ks.id 
           WHERE ks.chu_khach_san_id = @userId) as totalBookings,
          (SELECT COUNT(*) FROM danh_gia dg 
           INNER JOIN phieu_dat_phong pdp ON dg.phieu_dat_phong_id = pdp.id
           INNER JOIN khach_san ks ON pdp.khach_san_id = ks.id 
           WHERE ks.chu_khach_san_id = @userId) as totalReviews
        FROM khach_san 
        WHERE chu_khach_san_id = @userId
      `;
      
      const result = await pool.request()
        .input('userId', sql.Int, userId)
        .query(query);
      
      res.json({
        success: true,
        message: 'Lấy thống kê thành công',
        data: result.recordset[0]
      });
    } catch (error) {
      console.error('Get hotel stats error:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi lấy thống kê'
      });
    }
  },

  // Get hotel details
  async getHotelDetails(req, res) {
    try {
      const userId = req.user.ma_nguoi_dung;
      const hotelId = req.params.id;
      const pool = await getPool();
      
      const query = `
        SELECT 
          id,
          ten as hotelName,
          dia_chi as address,
          sdt_lien_he as phone,
          email_lien_he as email,
          mo_ta as description,
          website,
          so_sao as starRating,
          hinh_anh as mainImage,
          trang_thai as status,
          created_at as createdAt,
          updated_at as updatedAt
        FROM khach_san 
        WHERE id = @hotelId AND chu_khach_san_id = @userId
      `;
      
      const result = await pool.request()
        .input('hotelId', sql.Int, hotelId)
        .input('userId', sql.Int, userId)
        .query(query);
      
      if (result.recordset.length > 0) {
        res.json({
          success: true,
          message: 'Lấy thông tin khách sạn thành công',
          data: result.recordset[0]
        });
      } else {
        res.status(404).json({
          success: false,
          message: 'Không tìm thấy khách sạn'
        });
      }
    } catch (error) {
      console.error('Get hotel details error:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi lấy thông tin khách sạn'
      });
    }
  },

  // Update hotel
  async updateHotel(req, res) {
    try {
      const userId = req.user.ma_nguoi_dung;
      const hotelId = req.params.id;
      const {
        hotel_name,
        address,
        province,
        district,
        phone,
        email,
        description,
        website,
        star_rating
      } = req.body;

      const images = req.files || [];
      const pool = await getPool();

      // Check if hotel belongs to user
      const checkQuery = `
        SELECT id FROM khach_san 
        WHERE id = @hotelId AND chu_khach_san_id = @userId
      `;
      
      const checkResult = await pool.request()
        .input('hotelId', sql.Int, hotelId)
        .input('userId', sql.Int, userId)
        .query(checkQuery);
      
      if (checkResult.recordset.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Không tìm thấy khách sạn'
        });
      }

      // Update hotel
      const updateQuery = `
        UPDATE khach_san 
        SET 
          ten = @hotelName,
          dia_chi = @address,
          sdt_lien_he = @phone,
          email_lien_he = @email,
          mo_ta = @description,
          website = @website,
          so_sao = @starRating,
          updated_at = GETDATE()
        WHERE id = @hotelId
      `;
      
      await pool.request()
        .input('hotelId', sql.Int, hotelId)
        .input('hotelName', sql.NVarChar, hotel_name)
        .input('address', sql.NVarChar, address)
        .input('phone', sql.NVarChar, phone)
        .input('email', sql.NVarChar, email)
        .input('description', sql.NVarChar, description)
        .input('website', sql.NVarChar, website)
        .input('starRating', sql.Int, parseInt(star_rating))
        .query(updateQuery);

      // Handle new images if any
      if (images.length > 0) {
        const imageUrls = [];
        for (let i = 0; i < images.length; i++) {
          const image = images[i];
          const imageName = `hotel_${hotelId}_${Date.now()}_${i}${path.extname(image.originalname)}`;
          const imagePath = path.join('uploads', 'hotels', imageName);
          
          // Create directory if it doesn't exist
          const uploadDir = path.dirname(imagePath);
          if (!fs.existsSync(uploadDir)) {
            fs.mkdirSync(uploadDir, { recursive: true });
          }
          
          // Move file
          fs.renameSync(image.path, imagePath);
          imageUrls.push(`/uploads/hotels/${imageName}`);
        }

        // Update main image if new images were uploaded
        if (imageUrls.length > 0) {
          await pool.request()
            .input('hotelId', sql.Int, hotelId)
            .input('mainImage', sql.NVarChar, imageUrls[0])
            .query(`
              UPDATE khach_san 
              SET hinh_anh = @mainImage 
              WHERE id = @hotelId
            `);
        }
      }

      res.json({
        success: true,
        message: 'Cập nhật khách sạn thành công'
      });

    } catch (error) {
      console.error('Update hotel error:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi cập nhật khách sạn'
      });
    }
  },

  // Delete hotel
  async deleteHotel(req, res) {
    try {
      const userId = req.user.ma_nguoi_dung;
      const hotelId = req.params.id;
      const pool = await getPool();

      // Check if hotel belongs to user
      const checkQuery = `
        SELECT id FROM khach_san 
        WHERE id = @hotelId AND chu_khach_san_id = @userId
      `;
      
      const checkResult = await pool.request()
        .input('hotelId', sql.Int, hotelId)
        .input('userId', sql.Int, userId)
        .query(checkQuery);
      
      if (checkResult.recordset.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Không tìm thấy khách sạn'
        });
      }

      // Delete hotel (cascade will handle related records)
      const deleteQuery = `
        DELETE FROM khach_san 
        WHERE id = @hotelId
      `;
      
      const result = await pool.request()
        .input('hotelId', sql.Int, hotelId)
        .query(deleteQuery);

      if (result.rowsAffected[0] > 0) {
        res.json({
          success: true,
          message: 'Xóa khách sạn thành công'
        });
      } else {
        res.status(404).json({
          success: false,
          message: 'Không tìm thấy khách sạn'
        });
      }

    } catch (error) {
      console.error('Delete hotel error:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi xóa khách sạn'
      });
    }
  },

  // Get hotel bookings
  async getHotelBookings(req, res) {
    try {
      const userId = req.user.ma_nguoi_dung;
      const pool = await getPool();
      
      const query = `
        SELECT 
          pdp.id,
          pdp.ngay_den as checkInDate,
          pdp.ngay_di as checkOutDate,
          pdp.so_phong as roomCount,
          pdp.so_khach as guestCount,
          pdp.tong_tien as totalAmount,
          pdp.trang_thai as status,
          pdp.ngay_tao as createdAt,
          ks.ten as hotelName,
          nd.ho_ten as customerName,
          nd.email as customerEmail,
          nd.so_dien_thoai as customerPhone
        FROM phieu_dat_phong pdp
        INNER JOIN khach_san ks ON pdp.khach_san_id = ks.id
        INNER JOIN nguoi_dung nd ON pdp.nguoi_dung_id = nd.id
        WHERE ks.chu_khach_san_id = @userId
        ORDER BY pdp.ngay_tao DESC
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
      console.error('Get hotel bookings error:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi lấy danh sách đặt phòng'
      });
    }
  },

  // Update booking status
  async updateBookingStatus(req, res) {
    try {
      const userId = req.user.ma_nguoi_dung;
      const bookingId = req.params.id;
      const { status } = req.body;
      const pool = await getPool();

      // Check if booking belongs to user's hotel
      const checkQuery = `
        SELECT pdp.id FROM phieu_dat_phong pdp
        INNER JOIN khach_san ks ON pdp.khach_san_id = ks.id
        WHERE pdp.id = @bookingId AND ks.chu_khach_san_id = @userId
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

      // Update booking status
      const updateQuery = `
        UPDATE phieu_dat_phong 
        SET trang_thai = @status, ngay_cap_nhat = GETDATE()
        WHERE id = @bookingId
      `;
      
      await pool.request()
        .input('bookingId', sql.Int, bookingId)
        .input('status', sql.NVarChar, status)
        .query(updateQuery);

      res.json({
        success: true,
        message: 'Cập nhật trạng thái đặt phòng thành công'
      });

    } catch (error) {
      console.error('Update booking status error:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi cập nhật trạng thái đặt phòng'
      });
    }
  },

  // Get hotel reviews
  async getHotelReviews(req, res) {
    try {
      const userId = req.user.ma_nguoi_dung;
      const pool = await getPool();
      
      const query = `
        SELECT 
          dg.id,
          dg.diem as rating,
          dg.noi_dung as content,
          dg.phan_hoi as reply,
          dg.ngay_tao as createdAt,
          dg.ngay_cap_nhat as updatedAt,
          ks.ten as hotelName,
          nd.ho_ten as customerName,
          nd.anh_dai_dien as customerAvatar
        FROM danh_gia dg
        INNER JOIN phieu_dat_phong pdp ON dg.phieu_dat_phong_id = pdp.id
        INNER JOIN khach_san ks ON pdp.khach_san_id = ks.id
        INNER JOIN nguoi_dung nd ON dg.nguoi_dung_id = nd.id
        WHERE ks.chu_khach_san_id = @userId
        ORDER BY dg.ngay_tao DESC
      `;
      
      const result = await pool.request()
        .input('userId', sql.Int, userId)
        .query(query);
      
      res.json({
        success: true,
        message: 'Lấy danh sách nhận xét thành công',
        data: result.recordset
      });
    } catch (error) {
      console.error('Get hotel reviews error:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi lấy danh sách nhận xét'
      });
    }
  },

  // Reply to review
  async replyToReview(req, res) {
    try {
      const userId = req.user.ma_nguoi_dung;
      const reviewId = req.params.id;
      const { reply } = req.body;
      const pool = await getPool();

      // Check if review belongs to user's hotel
      const checkQuery = `
        SELECT dg.id FROM danh_gia dg
        INNER JOIN phieu_dat_phong pdp ON dg.phieu_dat_phong_id = pdp.id
        INNER JOIN khach_san ks ON pdp.khach_san_id = ks.id
        WHERE dg.id = @reviewId AND ks.chu_khach_san_id = @userId
      `;
      
      const checkResult = await pool.request()
        .input('reviewId', sql.Int, reviewId)
        .input('userId', sql.Int, userId)
        .query(checkQuery);
      
      if (checkResult.recordset.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Không tìm thấy nhận xét'
        });
      }

      // Update review with reply
      const updateQuery = `
        UPDATE danh_gia 
        SET phan_hoi = @reply, ngay_cap_nhat = GETDATE()
        WHERE id = @reviewId
      `;
      
      await pool.request()
        .input('reviewId', sql.Int, reviewId)
        .input('reply', sql.NVarChar, reply)
        .query(updateQuery);

      res.json({
        success: true,
        message: 'Phản hồi nhận xét thành công'
      });

    } catch (error) {
      console.error('Reply to review error:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi phản hồi nhận xét'
      });
    }
  }
};

module.exports = hotelOwnerController;
