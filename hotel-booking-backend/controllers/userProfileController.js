const { getPool } = require('../config/db');
const sql = require('mssql');

const userProfileController = {
  // Lấy thông tin VIP status của user
  async getVipStatus(req, res) {
    try {
      const userId = req.user?.ma_nguoi_dung;
      if (!userId) {
        return res.status(401).json({
          success: false,
          message: 'Chưa đăng nhập'
        });
      }

      const pool = await getPool();
      const request = pool.request();
      
      // Lấy thông tin VIP từ bảng nguoi_dung
      const result = await request
        .input('userId', sql.Int, userId)
        .query(`
          SELECT 
            id,
            ho_ten,
            email,
            vip_status,
            vip_level,
            vip_points,
            created_at
          FROM nguoi_dung 
          WHERE id = @userId
        `);

      if (result.recordset.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Không tìm thấy thông tin user'
        });
      }

      const user = result.recordset[0];
      
      // Sử dụng VipService để xác định VIP level
      const VipService = require('../services/vipService');
      const totalPoints = user.vip_points || 0;
      const { level, status, nextLevelPoints } = VipService.determineVipLevel(totalPoints);
      
      // Tính progress đến level tiếp theo
      let progressToNextLevel = 0;
      if (nextLevelPoints) {
        const currentLevelMinPoints = VipService.getLevelMinPoints(level);
        const range = nextLevelPoints - currentLevelMinPoints;
        const progress = totalPoints - currentLevelMinPoints;
        progressToNextLevel = Math.min(100, Math.max(0, (progress / range) * 100));
      }

      res.json({
        success: true,
        message: 'Lấy thông tin VIP Triphotel thành công',
        data: {
          id: user.id,
          name: user.ho_ten || user.ten || '',
          email: user.email,
          vipStatus: status,
          vipLevel: level,
          vipPoints: totalPoints,
          nextLevelPoints: nextLevelPoints,
          progressToNextLevel: Math.round(progressToNextLevel),
          memberSince: user.created_at,
          benefits: VipService.getLevelBenefits(level)
        }
      });
    } catch (error) {
      console.error('Lỗi lấy VIP status:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server: ' + error.message
      });
    }
  },

  // Cập nhật thông tin user
  async updateProfile(req, res) {
    try {
      const userId = req.user?.ma_nguoi_dung;
      if (!userId) {
        return res.status(401).json({
          success: false,
          message: 'Chưa đăng nhập'
        });
      }

      const { name, phone, address } = req.body;

      // Validation: name là bắt buộc
      if (!name || name.trim().length === 0) {
        return res.status(400).json({
          success: false,
          message: 'Họ và tên không được để trống'
        });
      }

      const pool = await getPool();
      const request = pool.request();
      
      // Cập nhật thông tin user (chỉ update các field có giá trị)
      // ⚠️ SỬA: Sử dụng đúng tên cột `sdt` thay vì `so_dien_thoai`
      // ⚠️ LƯU Ý: Bảng nguoi_dung không có cột `dia_chi`, bỏ qua address
      const result = await request
        .input('userId', sql.Int, userId)
        .input('name', sql.NVarChar(255), name.trim())
        .input('phone', sql.NVarChar(50), phone && phone.trim().length > 0 ? phone.trim() : null)
        .query(`
          UPDATE nguoi_dung 
          SET 
            ho_ten = @name,
            sdt = ISNULL(@phone, sdt),
            updated_at = GETDATE()
          WHERE id = @userId
          
          SELECT 
            id,
            ho_ten,
            email,
            sdt,
            updated_at
          FROM nguoi_dung 
          WHERE id = @userId
        `);

      if (result.recordset.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Không tìm thấy user'
        });
      }

      const updatedUser = result.recordset[0];

      res.json({
        success: true,
        message: 'Cập nhật thông tin thành công',
        data: {
          id: updatedUser.id,
          name: updatedUser.ho_ten || updatedUser.ten || '',
          email: updatedUser.email,
          phone: updatedUser.sdt,
          updatedAt: updatedUser.updated_at
        }
      });
    } catch (error) {
      console.error('Lỗi cập nhật profile:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server: ' + error.message
      });
    }
  },

  // Xóa tài khoản
  async deleteAccount(req, res) {
    try {
      const userId = req.user?.ma_nguoi_dung;
      if (!userId) {
        return res.status(401).json({
          success: false,
          message: 'Chưa đăng nhập'
        });
      }

      const pool = await getPool();
      const request = pool.request();
      
      // Xóa tài khoản (soft delete - đánh dấu là đã xóa)
      await request
        .input('userId', sql.Int, userId)
        .query(`
          UPDATE nguoi_dung 
          SET 
            trang_thai = 'Đã xóa',
            deleted_at = GETDATE(),
            updated_at = GETDATE()
          WHERE id = @userId
        `);

      res.json({
        success: true,
        message: 'Xóa tài khoản Triphotel thành công'
      });
    } catch (error) {
      console.error('Lỗi xóa tài khoản:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server: ' + error.message
      });
    }
  },

  // Lấy cài đặt user
  async getUserSettings(req, res) {
    try {
      const userId = req.user?.ma_nguoi_dung;
      if (!userId) {
        return res.status(401).json({
          success: false,
          message: 'Chưa đăng nhập'
        });
      }

      const pool = await getPool();
      const request = pool.request();
      
      // Lấy cài đặt từ bảng user_settings (nếu có) hoặc trả về mặc định
      const result = await request
        .input('userId', sql.Int, userId)
        .query(`
          SELECT 
            language,
            currency,
            distance_unit,
            price_display,
            notifications_enabled
          FROM user_settings 
          WHERE user_id = @userId
        `);

      let settings = {
        language: 'Tiếng Việt',
        currency: '₫ | VND',
        distanceUnit: 'km',
        priceDisplay: 'Theo mỗi đêm',
        notificationsEnabled: true
      };

      if (result.recordset.length > 0) {
        const userSettings = result.recordset[0];
        settings = {
          language: userSettings.language || 'Tiếng Việt',
          currency: userSettings.currency || '₫ | VND',
          distanceUnit: userSettings.distance_unit || 'km',
          priceDisplay: userSettings.price_display || 'Theo mỗi đêm',
          notificationsEnabled: userSettings.notifications_enabled !== false
        };
      }

      res.json({
        success: true,
        message: 'Lấy cài đặt Triphotel thành công',
        data: settings
      });
    } catch (error) {
      console.error('Lỗi lấy cài đặt:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server: ' + error.message
      });
    }
  },

  // Cập nhật cài đặt user
  async updateUserSettings(req, res) {
    try {
      const userId = req.user?.ma_nguoi_dung;
      if (!userId) {
        return res.status(401).json({
          success: false,
          message: 'Chưa đăng nhập'
        });
      }

      const { language, currency, distanceUnit, priceDisplay, notificationsEnabled } = req.body;

      const pool = await getPool();
      const request = pool.request();
      
      // Cập nhật hoặc tạo mới cài đặt
      await request
        .input('userId', sql.Int, userId)
        .input('language', sql.NVarChar, language || null)
        .input('currency', sql.NVarChar, currency || null)
        .input('distanceUnit', sql.NVarChar, distanceUnit || null)
        .input('priceDisplay', sql.NVarChar, priceDisplay || null)
        .input('notificationsEnabled', sql.Bit, notificationsEnabled !== null ? notificationsEnabled : null)
        .query(`
          MERGE user_settings AS target
          USING (SELECT @userId AS user_id) AS source
          ON target.user_id = source.user_id
          WHEN MATCHED THEN
            UPDATE SET
              language = ISNULL(@language, language),
              currency = ISNULL(@currency, currency),
              distance_unit = ISNULL(@distanceUnit, distance_unit),
              price_display = ISNULL(@priceDisplay, price_display),
              notifications_enabled = ISNULL(@notificationsEnabled, notifications_enabled),
              updated_at = GETDATE()
          WHEN NOT MATCHED THEN
            INSERT (user_id, language, currency, distance_unit, price_display, notifications_enabled, created_at, updated_at)
            VALUES (@userId, @language, @currency, @distanceUnit, @priceDisplay, @notificationsEnabled, GETDATE(), GETDATE());
        `);

      res.json({
        success: true,
        message: 'Cập nhật cài đặt Triphotel thành công'
      });
    } catch (error) {
      console.error('Lỗi cập nhật cài đặt:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server: ' + error.message
      });
    }
  },

  // Tích điểm thủ công cho các booking đã thanh toán nhưng chưa tích điểm
  async addPointsForPaidBookings(req, res) {
    try {
      const userId = req.user?.ma_nguoi_dung;
      if (!userId) {
        return res.status(401).json({
          success: false,
          message: 'Chưa đăng nhập'
        });
      }

      const pool = await getPool();
      const request = pool.request();
      
      // Lấy tất cả booking đã thanh toán của user trong 30 ngày gần đây
      const bookingsResult = await request
        .input('userId', sql.Int, userId)
        .query(`
          SELECT 
            id,
            booking_code,
            user_id,
            final_price,
            total_price,
            payment_status,
            payment_method,
            created_at
          FROM bookings
          WHERE user_id = @userId
            AND payment_status = 'paid'
            AND created_at >= DATEADD(day, -30, GETDATE())
          ORDER BY created_at DESC
        `);

      if (bookingsResult.recordset.length === 0) {
        return res.json({
          success: true,
          message: 'Không có booking nào cần tích điểm',
          data: {
            processed: 0,
            total: 0,
            totalPointsAdded: 0
          }
        });
      }

      const VipService = require('../services/vipService');
      let totalPointsAdded = 0;
      let processedCount = 0;
      const errors = [];

      // Xử lý từng booking
      for (const booking of bookingsResult.recordset) {
        try {
          const finalPrice = booking.final_price || booking.total_price || 0;
          
          if (finalPrice > 0) {
            console.log(`💰 Processing booking ${booking.booking_code}: userId=${booking.user_id}, finalPrice=${finalPrice}`);
            
            const vipResult = await VipService.addPointsAfterBooking(
              booking.user_id,
              finalPrice
            );
            
            if (vipResult) {
              totalPointsAdded += vipResult.pointsAdded;
              processedCount++;
              console.log(`✅ Added ${vipResult.pointsAdded} points for booking ${booking.booking_code}`);
            } else {
              errors.push(`Booking ${booking.booking_code}: Không thể tích điểm (finalPrice=${finalPrice})`);
            }
          } else {
            errors.push(`Booking ${booking.booking_code}: finalPrice = 0`);
          }
        } catch (error) {
          console.error(`❌ Error processing booking ${booking.booking_code}:`, error);
          errors.push(`Booking ${booking.booking_code}: ${error.message}`);
        }
      }

      res.json({
        success: true,
        message: `Đã xử lý ${processedCount}/${bookingsResult.recordset.length} booking`,
        data: {
          processed: processedCount,
          total: bookingsResult.recordset.length,
          totalPointsAdded: totalPointsAdded,
          errors: errors.length > 0 ? errors : undefined
        }
      });
    } catch (error) {
      console.error('Lỗi tích điểm thủ công:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server: ' + error.message
      });
    }
  }
};

module.exports = userProfileController;
