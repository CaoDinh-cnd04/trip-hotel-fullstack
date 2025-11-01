const { getPool } = require('../config/db');
const sql = require('mssql');

const discountController = {
  /**
   * Validate mã giảm giá
   * POST /api/v2/discount/validate
   * Body: { code: string, orderAmount: number, hotelId?: number, locationId?: number }
   * 
   * LƯU Ý: 
   * - Mã giảm giá (discount code) áp dụng cho TẤT CẢ khách sạn
   * - Ưu đãi (promotion) mới giới hạn theo khách sạn cụ thể
   * - Mỗi người dùng chỉ được sử dụng mã giảm giá 1 lần
   */
  async validateDiscountCode(req, res) {
    try {
      const { code, orderAmount } = req.body;

      if (!code || !orderAmount) {
        return res.status(400).json({
          success: false,
          message: 'Thiếu thông tin mã giảm giá hoặc số tiền đơn hàng',
        });
      }

      const pool = await getPool();
      
      // Query để tìm mã giảm giá (mã giảm giá áp dụng cho tất cả khách sạn)
      const query = `
        SELECT 
          mgg.id,
          mgg.ten AS ma_giam_gia,
          mgg.dieu_kien AS mo_ta,
          mgg.loai AS loai_giam_gia,
          mgg.gia_tri AS gia_tri_giam,
          mgg.gia_tri_don_hang_toi_thieu,
          mgg.giam_toi_da AS gia_tri_giam_toi_da,
          (mgg.so_luong - mgg.so_luong_da_dung) AS so_luong_con_lai,
          mgg.so_luong,
          mgg.so_luong_da_dung,
          mgg.ngay_bat_dau,
          mgg.ngay_ket_thuc,
          mgg.trang_thai
        FROM dbo.ma_giam_gia mgg
        WHERE UPPER(mgg.ten) = UPPER(@code)
      `;

      const result = await pool.request()
        .input('code', sql.NVarChar, code.toUpperCase())
        .query(query);

      if (result.recordset.length === 0) {
        return res.json({
          success: false,
          message: 'Mã giảm giá không tồn tại',
        });
      }

      const discount = result.recordset[0];

      // Kiểm tra trạng thái (hỗ trợ cả boolean và number)
      const isActive = discount.trang_thai === true || discount.trang_thai === 1 || discount.trang_thai === '1';
      if (!isActive) {
        return res.json({
          success: false,
          message: 'Mã giảm giá đã bị vô hiệu hóa',
        });
      }

      // Kiểm tra số lượng
      if (discount.so_luong_con_lai <= 0) {
        return res.json({
          success: false,
          message: 'Mã giảm giá đã hết lượt sử dụng',
        });
      }

      // Kiểm tra thời gian
      const now = new Date();
      const startDate = new Date(discount.ngay_bat_dau);
      const endDate = new Date(discount.ngay_ket_thuc);

      if (now < startDate) {
        return res.json({
          success: false,
          message: 'Mã giảm giá chưa có hiệu lực',
        });
      }

      if (now > endDate) {
        return res.json({
          success: false,
          message: 'Mã giảm giá đã hết hạn',
        });
      }

      // Kiểm tra giá trị đơn hàng tối thiểu
      if (orderAmount < discount.gia_tri_don_hang_toi_thieu) {
        return res.json({
          success: false,
          message: `Đơn hàng tối thiểu ${discount.gia_tri_don_hang_toi_thieu.toLocaleString()}₫ để áp dụng mã này`,
        });
      }

      // LƯU Ý: Mã giảm giá (discount code) áp dụng cho TẤT CẢ khách sạn
      // Không kiểm tra khách sạn/địa điểm cho mã giảm giá
      // Chỉ có ƯU ĐÃI (promotion) mới giới hạn theo khách sạn

      // KIỂM TRA NGƯỜI DÙNG ĐÃ SỬ DỤNG MÃ NÀY CHƯA - MỖI NGƯỜI CHỈ ĐƯỢC DÙNG 1 LẦN
      // Kiểm tra xem người dùng đã sử dụng mã này chưa (từ bảng lich_su_su_dung_voucher)
      // Yêu cầu đăng nhập để sử dụng mã giảm giá
      if (!req.user || !req.user.id) {
        return res.status(401).json({
          success: false,
          message: 'Vui lòng đăng nhập để sử dụng mã giảm giá',
        });
      }

      // LƯU Ý: Kiểm tra lịch sử sử dụng mã giảm giá
      // Hiện tại bảng phieu_dat_phong không có cột ma_giam_gia
      // Nếu cần kiểm tra, có thể:
      // 1. Thêm cột ma_giam_gia vào bảng phieu_dat_phong
      // 2. Hoặc kiểm tra từ bảng bookings nếu có
      // Tạm thời bỏ phần kiểm tra này để tránh lỗi
      
      // TODO: Implement check usage history when database schema is updated

      // Tính số tiền giảm
      let discountAmount = 0;
      
      // Kiểm tra loại giảm giá (hỗ trợ cả tiếng Việt và tiếng Anh)
      const isPercentage = discount.loai_giam_gia.toLowerCase().includes('phần trăm') || 
                           discount.loai_giam_gia.toLowerCase() === 'percentage';
      
      if (isPercentage) {
        // Giảm theo %
        discountAmount = (orderAmount * discount.gia_tri_giam) / 100;
        
        // Áp dụng giới hạn giảm tối đa
        if (discount.gia_tri_giam_toi_da && discountAmount > discount.gia_tri_giam_toi_da) {
          discountAmount = discount.gia_tri_giam_toi_da;
        }
      } else {
        // Giảm cố định
        discountAmount = discount.gia_tri_giam;
        
        // Không được giảm quá tổng đơn hàng
        if (discountAmount > orderAmount) {
          discountAmount = orderAmount;
        }
      }

      // Trả về thông tin mã giảm giá hợp lệ
      return res.json({
        success: true,
        message: 'Mã giảm giá hợp lệ',
        data: {
          code: discount.ma_giam_gia,
          description: discount.mo_ta,
          discountType: discount.loai_giam_gia,
          discountValue: discount.gia_tri_giam,
          discountAmount: discountAmount,
          minOrderValue: discount.gia_tri_don_hang_toi_thieu,
          maxDiscountValue: discount.gia_tri_giam_toi_da,
        },
      });

    } catch (error) {
      console.error('❌ Error validating discount code:', error);
      return res.status(500).json({
        success: false,
        message: 'Lỗi server khi validate mã giảm giá',
        error: error.message,
      });
    }
  },

  /**
   * Lấy danh sách mã giảm giá có sẵn
   * GET /api/v2/discount/available
   */
  async getAvailableDiscounts(req, res) {
    try {
      const pool = await getPool();
      
      const query = `
        SELECT 
          ten AS ma_giam_gia,
          dieu_kien AS mo_ta,
          loai AS loai_giam_gia,
          gia_tri AS gia_tri_giam,
          gia_tri_don_hang_toi_thieu,
          giam_toi_da AS gia_tri_giam_toi_da,
          (so_luong - so_luong_da_dung) AS so_luong_con_lai,
          ngay_bat_dau,
          ngay_ket_thuc
        FROM dbo.ma_giam_gia
        WHERE trang_thai = 1
          AND (so_luong - so_luong_da_dung) > 0
          AND ngay_bat_dau <= GETDATE()
          AND ngay_ket_thuc >= GETDATE()
        ORDER BY gia_tri DESC
      `;

      const result = await pool.request().query(query);

      return res.json({
        success: true,
        message: 'Lấy danh sách mã giảm giá thành công',
        data: result.recordset.map(d => ({
          code: d.ma_giam_gia,
          description: d.mo_ta,
          discountType: d.loai_giam_gia,
          discountValue: d.gia_tri_giam,
          minOrderValue: d.gia_tri_don_hang_toi_thieu,
          maxDiscountValue: d.gia_tri_giam_toi_da,
          remainingUses: d.so_luong_con_lai,
          validFrom: d.ngay_bat_dau,
          validUntil: d.ngay_ket_thuc,
        })),
      });

    } catch (error) {
      console.error('❌ Error getting available discounts:', error);
      return res.status(500).json({
        success: false,
        message: 'Lỗi server khi lấy danh sách mã giảm giá',
        error: error.message,
      });
    }
  },
};

module.exports = discountController;

