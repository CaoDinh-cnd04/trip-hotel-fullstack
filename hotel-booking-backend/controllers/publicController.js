const KhachSan = require('../models/khachsan');
const KhuyenMai = require('../models/khuyenmai');
const MaGiamGia = require('../models/magiamgia');
const TinhThanh = require('../models/tinhthanh');
const { getPool, sql } = require('../config/db');

// Helper to get BASE_URL
const getBaseUrl = () => process.env.BASE_URL || 'http://localhost:5000';

// Helper to transform hotel image URL
const transformHotelImageUrl = (imagePath) => {
  if (!imagePath) return null;
  const baseUrl = getBaseUrl();
  if (imagePath.startsWith('http')) return imagePath;
  if (imagePath.startsWith('/')) return `${baseUrl}${imagePath}`;
  return `${baseUrl}/images/hotels/${imagePath}`;
};

// Helper to transform province image URL
const transformProvinceImageUrl = (imagePath) => {
  if (!imagePath) return null;
  const baseUrl = getBaseUrl();
  if (imagePath.startsWith('http')) return imagePath;
  if (imagePath.startsWith('/')) return `${baseUrl}${imagePath}`;
  return `${baseUrl}/images/provinces/${imagePath}`;
};

const publicController = {
  // Lấy khách sạn nổi bật từ SQL Server
  async getFeaturedHotels(req, res) {
    try {
      const { limit = 6 } = req.query;
      
      // KhachSan đã là instance rồi, không cần new
      const result = await KhachSan.getActiveHotels({
        page: 1,
        limit: parseInt(limit),
        orderBy: 'ks.so_sao DESC, ks.danh_gia_trung_binh DESC'
      });

      // Transform data - Flutter expect snake_case field names
      const featuredHotels = result.data.map(hotel => ({
        id: hotel.id,
        ten: hotel.ten,
        dia_chi: hotel.dia_chi,
        so_sao: hotel.so_sao || 0,  // Flutter expects so_sao
        gia_tb: hotel.gia_tb || 1000000, // Giá trung bình hoặc mặc định
        diem_danh_gia_trung_binh: hotel.diem_danh_gia_trung_binh || 0,  // Flutter expects full name
        so_luot_danh_gia: hotel.so_luot_danh_gia || 0,
        mo_ta: hotel.mo_ta,
        hinh_anh: hotel.hinh_anh,  // Just filename, Flutter will add prefix
        tinh_thanh: hotel.ten_tinh_thanh || hotel.tinh_thanh,
        quoc_gia: hotel.ten_quoc_gia || 'Việt Nam'
      }));

      res.json({
        success: true,
        message: 'Lấy danh sách khách sạn nổi bật thành công',
        data: featuredHotels
      });
    } catch (error) {
      console.error('Error in getFeaturedHotels:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi lấy khách sạn nổi bật',
        error: error.message
      });
    }
  },

  // Lấy ưu đãi nổi bật
  async getFeaturedPromotions(req, res) {
    try {
      const { limit = 4 } = req.query;
      
      // Lấy khuyến mãi đang hoạt động
      KhuyenMai.getAll((error, results) => {
        if (error) {
          console.error('Error in getFeaturedPromotions:', error);
          return res.status(500).json({
            success: false,
            message: 'Lỗi server khi lấy ưu đãi nổi bật',
            error: error.message
          });
        }

        // Filter active promotions
        const now = new Date();
        let activePromotions = results.filter(km => 
          km.trang_thai === 1 && 
          new Date(km.ngay_bat_dau) <= now && 
          new Date(km.ngay_ket_thuc) >= now
        );

        // Sort by discount percentage and limit
        activePromotions.sort((a, b) => (b.phan_tram || 0) - (a.phan_tram || 0));
        activePromotions = activePromotions.slice(0, parseInt(limit));

        // Format response
        const featuredPromotions = activePromotions.map(promo => ({
          id: promo.id,
          ten: promo.ten,
          mo_ta: promo.mo_ta,
          phan_tram: promo.phan_tram,
          giam_toi_da: promo.giam_toi_da,
          ngay_bat_dau: promo.ngay_bat_dau,
          ngay_ket_thuc: promo.ngay_ket_thuc,
          khach_san_id: promo.khach_san_id,
          hinh_anh: `/images/hotels/promotion_${promo.id}.jpg`
        }));

        res.json({
          success: true,
          message: 'Lấy danh sách ưu đãi nổi bật Triphotel thành công',
          data: featuredPromotions
        });
      });
    } catch (error) {
      console.error('Error in getFeaturedPromotions:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi lấy ưu đãi nổi bật',
        error: error.message
      });
    }
  },

  // Lấy địa điểm hot từ SQL Server (tỉnh thành có nhiều khách sạn)
  async getHotDestinations(req, res) {
    try {
      const { limit = 8 } = req.query;
      
      // Query để lấy tỉnh thành có nhiều khách sạn nhất
      const query = `
        SELECT TOP (@limit)
          tt.id,
          tt.ten,
          tt.hinh_anh,
          tt.mo_ta,
          qg.ten AS ten_quoc_gia,
          COUNT(DISTINCT ks.id) AS so_khach_san
        FROM dbo.tinh_thanh tt
        LEFT JOIN dbo.vi_tri vt ON vt.tinh_thanh_id = tt.id
        LEFT JOIN dbo.khach_san ks ON ks.vi_tri_id = vt.id
        LEFT JOIN dbo.quoc_gia qg ON tt.quoc_gia_id = qg.id
        WHERE tt.trang_thai = 1
        GROUP BY tt.id, tt.ten, tt.hinh_anh, tt.mo_ta, qg.ten
        HAVING COUNT(DISTINCT ks.id) > 0
        ORDER BY COUNT(DISTINCT ks.id) DESC, tt.ten ASC
      `;

      const pool = getPool();
      const result = await pool.request()
        .input('limit', sql.Int, parseInt(limit))
        .query(query);

      // Transform data với BASE_URL cho hình ảnh
      const hotDestinations = result.recordset.map(dest => ({
        id: dest.id,
        ten: dest.ten,
        quoc_gia: dest.ten_quoc_gia || 'Việt Nam',
        mo_ta: dest.mo_ta || `Khám phá ${dest.ten}`,
        hinh_anh: transformProvinceImageUrl(dest.hinh_anh),
        so_khach_san: dest.so_khach_san || 0
      }));

      res.json({
        success: true,
        message: 'Lấy danh sách địa điểm hot thành công',
        data: hotDestinations
      });
    } catch (error) {
      console.error('Error in getHotDestinations:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi lấy địa điểm hot',
        error: error.message
      });
    }
  },

  // Lấy các quốc gia phổ biến
  async getPopularCountries(req, res) {
    try {
      const { limit = 6 } = req.query;
      const baseUrl = getBaseUrl();
      
      // Danh sách quốc gia phổ biến với hình ảnh
      const popularCountries = [
        {
          id: 'vietnam',
          ten: 'Việt Nam',
          mo_ta: 'Đất nước hình chữ S với văn hóa đa dạng',
          hinh_anh: `${baseUrl}/images/countries/vietnam.jpg`,
          so_khach_san: 234,
          so_tinh_thanh: 63
        },
        {
          id: 'japan',
          ten: 'Nhật Bản',
          mo_ta: 'Đất nước mặt trời mọc với văn hóa độc đáo',
          hinh_anh: `${baseUrl}/images/countries/Japan.jpg`,
          so_khach_san: 156,
          so_tinh_thanh: 47
        },
        {
          id: 'korea',
          ten: 'Hàn Quốc',
          mo_ta: 'Xứ sở kim chi với công nghệ hiện đại',
          hinh_anh: `${baseUrl}/images/countries/korea.jpg`,
          so_khach_san: 89,
          so_tinh_thanh: 17
        },
        {
          id: 'thailand',
          ten: 'Thái Lan',
          mo_ta: 'Đất nước của những ngôi chùa vàng',
          hinh_anh: `${baseUrl}/images/countries/thailand.jpg`,
          so_khach_san: 198,
          so_tinh_thanh: 77
        },
        {
          id: 'singapore',
          ten: 'Singapore',
          mo_ta: 'Quốc đảo sư tử với kiến trúc hiện đại',
          hinh_anh: `${baseUrl}/images/countries/singapore.jpg`,
          so_khach_san: 45,
          so_tinh_thanh: 1
        }
      ];

      // Limit results
      const limitedCountries = popularCountries.slice(0, parseInt(limit));

      res.json({
        success: true,
        message: 'Lấy danh sách quốc gia phổ biến thành công',
        data: limitedCountries
      });
    } catch (error) {
      console.error('Error in getPopularCountries:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi lấy quốc gia phổ biến',
        error: error.message
      });
    }
  },

  // Lấy dữ liệu tổng hợp cho trang chủ
  async getHomePageData(req, res) {
    try {
      // Lấy tất cả dữ liệu cần thiết cho trang chủ
      const [featuredHotels, featuredPromotions, hotDestinations, popularCountries] = await Promise.all([
        publicController.getFeaturedHotelsData(6),
        publicController.getFeaturedPromotionsData(4),
        publicController.getHotDestinationsData(8),
        publicController.getPopularCountriesData(6)
      ]);

      res.json({
        success: true,
        message: 'Lấy dữ liệu trang chủ Triphotel thành công',
        data: {
          featuredHotels,
          featuredPromotions,
          hotDestinations,
          popularCountries,
          heroBanner: {
            hinh_anh: `${getBaseUrl()}/images/hero-banner.jpg`,
            tieu_de: 'Khám phá thế giới cùng chúng tôi',
            mo_ta: 'Đặt phòng khách sạn tốt nhất với giá ưu đãi'
          }
        }
      });
    } catch (error) {
      console.error('Error in getHomePageData:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi lấy dữ liệu trang chủ',
        error: error.message
      });
    }
  },

  // Helper methods
  async getFeaturedHotelsData(limit) {
    try {
      // KhachSan đã là instance
      const result = await KhachSan.getActiveHotels({
        page: 1,
        limit: limit,
        orderBy: 'ks.so_sao DESC, ks.danh_gia_trung_binh DESC'
      });
      
      return (result.data || []).map(hotel => ({
        id: hotel.id,
        ten: hotel.ten,
        dia_chi: hotel.dia_chi,
        so_sao: hotel.so_sao || 0,  // Flutter expects so_sao
        gia_tb: hotel.gia_tb || 1000000, // Giá trung bình hoặc mặc định
        diem_danh_gia_trung_binh: hotel.diem_danh_gia_trung_binh || 0,
        so_luot_danh_gia: hotel.so_luot_danh_gia || 0,
        hinh_anh: hotel.hinh_anh  // Just filename, Flutter will add prefix
      }));
    } catch (error) {
      console.error('Error in getFeaturedHotelsData:', error);
      return [];
    }
  },

  async getFeaturedPromotionsData(limit) {
    return new Promise((resolve) => {
      KhuyenMai.getAll((error, results) => {
        if (error) {
          resolve([]);
          return;
        }

        const now = new Date();
        let activePromotions = results.filter(km => 
          km.trang_thai === 1 && 
          new Date(km.ngay_bat_dau) <= now && 
          new Date(km.ngay_ket_thuc) >= now
        );

        activePromotions.sort((a, b) => (b.phan_tram || 0) - (a.phan_tram || 0));
        activePromotions = activePromotions.slice(0, limit);

        resolve(activePromotions.map(promo => ({
          id: promo.id,
          ten: promo.ten,
          phan_tram: promo.phan_tram,
          ngay_ket_thuc: promo.ngay_ket_thuc
        })));
      });
    });
  },

  async getHotDestinationsData(limit) {
    try {
      const query = `
        SELECT TOP (@limit)
          tt.id,
          tt.ten,
          tt.hinh_anh,
          qg.ten AS ten_quoc_gia,
          COUNT(DISTINCT ks.id) AS so_khach_san
        FROM dbo.tinh_thanh tt
        LEFT JOIN dbo.vi_tri vt ON vt.tinh_thanh_id = tt.id
        LEFT JOIN dbo.khach_san ks ON ks.vi_tri_id = vt.id
        LEFT JOIN dbo.quoc_gia qg ON tt.quoc_gia_id = qg.id
        WHERE tt.trang_thai = 1
        GROUP BY tt.id, tt.ten, tt.hinh_anh, qg.ten
        HAVING COUNT(DISTINCT ks.id) > 0
        ORDER BY COUNT(DISTINCT ks.id) DESC
      `;

      const pool = getPool();
      const result = await pool.request()
        .input('limit', sql.Int, limit)
        .query(query);

      return result.recordset.map(dest => ({
        id: dest.id,
        ten: dest.ten,
        quoc_gia: dest.ten_quoc_gia || 'Việt Nam',
        hinh_anh: transformProvinceImageUrl(dest.hinh_anh)
      }));
    } catch (error) {
      console.error('Error in getHotDestinationsData:', error);
      return [];
    }
  },

  getPopularCountriesData(limit) {
    const baseUrl = getBaseUrl();
    const countries = [
      { id: 'vietnam', ten: 'Việt Nam', hinh_anh: `${baseUrl}/images/countries/vietnam.jpg` },
      { id: 'japan', ten: 'Nhật Bản', hinh_anh: `${baseUrl}/images/countries/Japan.jpg` },
      { id: 'korea', ten: 'Hàn Quốc', hinh_anh: `${baseUrl}/images/countries/korea.jpg` },
      { id: 'thailand', ten: 'Thái Lan', hinh_anh: `${baseUrl}/images/countries/thailand.jpg` },
      { id: 'singapore', ten: 'Singapore', hinh_anh: `${baseUrl}/images/countries/singapore.jpg` }
    ];
    return countries.slice(0, limit);
  }
};

module.exports = publicController;
