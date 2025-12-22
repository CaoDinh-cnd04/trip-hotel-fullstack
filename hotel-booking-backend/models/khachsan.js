// models/khachsan.js - Hotel model
const BaseModel = require('./baseModel');

class KhachSan extends BaseModel {
  constructor() {
    super('khach_san', 'id');
  }

  // Get hotels with full information (using view)
  async getHotelsWithFullInfo(options = {}) {
    const { 
      page = 1, 
      limit = 10, 
      where = '', 
      orderBy = 'id DESC',
      params = {} // Accept additional params for WHERE clause
    } = options;
    
    // Ensure page and limit are integers
    const pageInt = parseInt(page);
    const limitInt = parseInt(limit);
    const offset = (pageInt - 1) * limitInt;
    
    let query = `
      SELECT 
        ks.*,
        vt.ten AS ten_vi_tri,
        tt.ten AS ten_tinh_thanh,
        qg.ten AS ten_quoc_gia,
        nd.ho_ten AS ten_nguoi_quan_ly,
        nd.email AS email_nguoi_quan_ly,
        nd.id AS nguoi_quan_ly_id,
        owner.ho_ten AS ten_chu_khach_san,
        owner.email AS email_chu_khach_san,
        COUNT(DISTINCT p.id) AS tong_so_phong_thuc_te,
        (SELECT AVG(CAST(p2.gia_tien AS DECIMAL(18,2))) 
         FROM phong p2 
         WHERE p2.khach_san_id = ks.id) AS gia_tb,
        COALESCE(ks.diem_danh_gia_trung_binh, 0) AS diem_danh_gia_trung_binh,
        COALESCE(ks.so_luot_danh_gia, 0) AS so_luot_danh_gia
      FROM khach_san ks
      LEFT JOIN vi_tri vt ON ks.vi_tri_id = vt.id
      LEFT JOIN tinh_thanh tt ON vt.tinh_thanh_id = tt.id
      LEFT JOIN quoc_gia qg ON tt.quoc_gia_id = qg.id
      LEFT JOIN nguoi_dung nd ON ks.nguoi_quan_ly_id = nd.id
      LEFT JOIN nguoi_dung owner ON ks.chu_khach_san_id = owner.id
      LEFT JOIN phong p ON ks.id = p.khach_san_id
      ${where ? `WHERE ${where}` : ''}
      GROUP BY 
        ks.id, ks.ten, ks.mo_ta, ks.hinh_anh, ks.so_sao, ks.trang_thai, 
        ks.dia_chi, ks.vi_tri_id, ks.yeu_cau_coc, ks.ti_le_coc, ks.ho_so_id,
        ks.nguoi_quan_ly_id, ks.chu_khach_san_id, ks.email_lien_he, ks.sdt_lien_he, ks.website,
        ks.gio_nhan_phong, ks.gio_tra_phong, ks.chinh_sach_huy, ks.tong_so_phong,
        ks.diem_danh_gia_trung_binh, ks.so_luot_danh_gia, ks.created_at, ks.updated_at,
        vt.ten, tt.ten, qg.ten, nd.ho_ten, nd.email, nd.id,
        owner.ho_ten, owner.email, owner.id
      ORDER BY ${orderBy}
      OFFSET @offset ROWS
      FETCH NEXT @limit ROWS ONLY
    `;
    
    const countQuery = `
      SELECT COUNT(DISTINCT ks.id) as total 
      FROM khach_san ks
      LEFT JOIN vi_tri vt ON ks.vi_tri_id = vt.id
      LEFT JOIN tinh_thanh tt ON vt.tinh_thanh_id = tt.id
      LEFT JOIN quoc_gia qg ON tt.quoc_gia_id = qg.id
      ${where ? `WHERE ${where}` : ''}
    `;
    
    // Merge params with offset and limit
    const queryParams = { ...params, offset, limit: limitInt };
    
    try {
      const [data, count] = await Promise.all([
        this.executeQuery(query, queryParams),
        this.executeQuery(countQuery, params) // Count query doesn't need offset/limit
      ]);
      
      return {
        data: data.recordset,
        pagination: {
          page: pageInt,
          limit: limitInt,
          total: count.recordset[0].total,
          totalPages: Math.ceil(count.recordset[0].total / limitInt)
        }
      };
    } catch (error) {
      throw error;
    }
  }

  // Get active hotels
  async getActiveHotels(options = {}) {
    return await this.getHotelsWithFullInfo({
      ...options,
      where: "ks.trang_thai = N'Hoạt động'",
      orderBy: 'ks.diem_danh_gia_trung_binh DESC, ks.ten ASC'
    });
  }

  // Search hotels
  async searchHotels(searchTerm, options = {}) {
    const { 
      page = 1, 
      limit = 10, 
      vi_tri_id,
      so_sao_min,
      so_sao_max,
      gia_min,
      gia_max,
      tien_nghi,
      trang_thai
    } = options;

    // Ensure page and limit are integers
    const pageInt = parseInt(page);
    const limitInt = parseInt(limit);

    // Allow filtering by status, default to active for regular users
    let whereConditions = [];
    if (!trang_thai) {
      whereConditions.push("ks.trang_thai = N'Hoạt động'");
    } else if (trang_thai !== 'all') {
      whereConditions.push(`ks.trang_thai = N'${trang_thai}'`);
    }
    let params = { offset: (pageInt - 1) * limitInt, limit: limitInt };

    // Search term
    if (searchTerm) {
      whereConditions.push("(ks.ten LIKE @searchTerm OR ks.dia_chi LIKE @searchTerm OR vt.ten LIKE @searchTerm OR tt.ten LIKE @searchTerm)");
      params.searchTerm = `%${searchTerm}%`;
    }

    // Location filter
    if (vi_tri_id) {
      whereConditions.push("ks.vi_tri_id = @vi_tri_id");
      params.vi_tri_id = vi_tri_id;
    }

    // Star rating filter
    if (so_sao_min) {
      whereConditions.push("ks.so_sao >= @so_sao_min");
      params.so_sao_min = so_sao_min;
    }
    if (so_sao_max) {
      whereConditions.push("ks.so_sao <= @so_sao_max");
      params.so_sao_max = so_sao_max;
    }

    // Price filter (based on room prices)
    if (gia_min || gia_max) {
      let priceSubquery = "EXISTS (SELECT 1 FROM phong p WHERE p.khach_san_id = ks.id";
      if (gia_min) {
        priceSubquery += " AND p.gia_tien >= @gia_min";
        params.gia_min = gia_min;
      }
      if (gia_max) {
        priceSubquery += " AND p.gia_tien <= @gia_max";
        params.gia_max = gia_max;
      }
      priceSubquery += ")";
      whereConditions.push(priceSubquery);
    }

    return await this.getHotelsWithFullInfo({
      page,
      limit,
      where: whereConditions.join(' AND '),
      orderBy: 'ks.diem_danh_gia_trung_binh DESC, ks.ten ASC',
      params // Pass the params to getHotelsWithFullInfo
    });
  }

  // Get hotel by ID with full details
  async getHotelWithDetails(id) {
    const query = `
      SELECT 
        ks.*,
        vt.ten AS ten_vi_tri,
        tt.ten AS ten_tinh_thanh,
        qg.ten AS ten_quoc_gia,
        nd.ho_ten AS ten_nguoi_quan_ly,
        nd.email AS email_nguoi_quan_ly,
        nd.sdt AS sdt_nguoi_quan_ly
      FROM khach_san ks
      LEFT JOIN vi_tri vt ON ks.vi_tri_id = vt.id
      LEFT JOIN tinh_thanh tt ON vt.tinh_thanh_id = tt.id
      LEFT JOIN quoc_gia qg ON tt.quoc_gia_id = qg.id
      LEFT JOIN nguoi_dung nd ON ks.nguoi_quan_ly_id = nd.id
      WHERE ks.id = @id
    `;

    try {
      const result = await this.executeQuery(query, { id });
      return result.recordset[0] || null;
    } catch (error) {
      throw error;
    }
  }

  // Get hotel amenities
  async getHotelAmenities(hotelId) {
    const query = `
      SELECT 
        tn.*,
        kstn.mien_phi,
        kstn.gia_phi,
        kstn.ghi_chu
      FROM khach_san_tien_nghi kstn
      JOIN tien_nghi tn ON kstn.tien_nghi_id = tn.id
      WHERE kstn.khach_san_id = @hotelId AND tn.trang_thai = 1
      ORDER BY tn.nhom, tn.ten
    `;

    try {
      const result = await this.executeQuery(query, { hotelId });
      return result.recordset;
    } catch (error) {
      throw error;
    }
  }

  // Get hotel rooms with types
  async getHotelRooms(hotelId, options = {}) {
    const { available_from, available_to, page = 1, limit = 20 } = options;
    const offset = (page - 1) * limit;

    // WHERE condition đơn giản
    let whereConditions = ["p.khach_san_id = @hotelId"];
    let params = { hotelId, offset, limit };

    // Check availability if dates provided
    if (available_from && available_to) {
      whereConditions.push(`
        NOT EXISTS (
          SELECT 1 FROM phieu_dat_phong pdp 
          WHERE pdp.phong_id = p.id 
          AND pdp.trang_thai NOT IN (N'Đã hủy', N'Đã checkout')
          AND (
            (pdp.ngay_den <= @available_to AND pdp.ngay_di > @available_from)
          )
        )
      `);
      params.available_from = available_from;
      params.available_to = available_to;
    }

    // Query với columns chính xác từ database - Lấy đầy đủ thông tin từ loai_phong
    const query = `
      SELECT 
        p.id,
        p.ten,
        p.ma_phong,
        p.mo_ta,
        p.gia_tien,
        p.hinh_anh,
        p.dien_tich,
        p.khach_san_id,
        p.loai_phong_id,
        p.trang_thai,
        lp.ten AS ten_loai_phong,
        lp.mo_ta AS mo_ta_loai_phong,
        lp.so_khach AS suc_chua,
        lp.so_giuong_don,
        lp.so_giuong_doi,
        ks.ten AS ten_khach_san,
        ks.hinh_anh AS hinh_anh_khach_san
      FROM dbo.phong p
      LEFT JOIN dbo.loai_phong lp ON p.loai_phong_id = lp.id
      LEFT JOIN dbo.khach_san ks ON p.khach_san_id = ks.id
      WHERE ${whereConditions.join(' AND ')}
      ORDER BY p.gia_tien ASC
      OFFSET @offset ROWS
      FETCH NEXT @limit ROWS ONLY
    `;

    try {
      const result = await this.executeQuery(query, params);
      return result.recordset;
    } catch (error) {
      console.error('❌ Lỗi getHotelRooms:', error.message);
      // Return empty array thay vì throw error để không crash app
      return [];
    }
  }

  // Create hotel
  async createHotel(data) {
    try {
      const hotelData = {
        ten: data.ten,
        mo_ta: data.mo_ta,
        hinh_anh: data.hinh_anh,
        so_sao: data.so_sao,
        trang_thai: data.trang_thai || 'Hoạt động',
        dia_chi: data.dia_chi,
        vi_tri_id: data.vi_tri_id,
        yeu_cau_coc: data.yeu_cau_coc || 0,
        ti_le_coc: data.ti_le_coc || 0,
        ho_so_id: data.ho_so_id || null,
        nguoi_quan_ly_id: data.nguoi_quan_ly_id || null,
        email_lien_he: data.email_lien_he || null,
        sdt_lien_he: data.sdt_lien_he || null,
        website: data.website || null,
        gio_nhan_phong: data.gio_nhan_phong || '14:00:00',
        gio_tra_phong: data.gio_tra_phong || '12:00:00',
        chinh_sach_huy: data.chinh_sach_huy || null
      };

      return await this.create(hotelData);
    } catch (error) {
      throw error;
    }
  }

  // Update hotel
  async updateHotel(id, data) {
    try {
      // Remove undefined fields
      const updateData = {};
      Object.keys(data).forEach(key => {
        if (data[key] !== undefined) {
          updateData[key] = data[key];
        }
      });

      return await this.update(id, updateData);
    } catch (error) {
      throw error;
    }
  }

  // Get hotels by manager
  async getHotelsByManager(managerId, options = {}) {
    return await this.getHotelsWithFullInfo({
      ...options,
      where: `ks.nguoi_quan_ly_id = ${managerId}`
    });
  }

  // Get hotel statistics
  async getHotelStats(hotelId) {
    const query = `
      SELECT 
        COUNT(DISTINCT p.id) as tong_so_phong,
        COUNT(DISTINCT CASE WHEN p.trang_thai = N'Trống' THEN p.id END) as phong_trong,
        COUNT(DISTINCT pdp.id) as tong_booking,
        COUNT(DISTINCT CASE WHEN pdp.trang_thai = N'Đã checkout' THEN pdp.id END) as booking_hoan_thanh,
        AVG(CAST(dg.so_sao_tong AS DECIMAL(3,2))) as diem_trung_binh,
        COUNT(DISTINCT dg.id) as so_danh_gia
      FROM khach_san ks
      LEFT JOIN phong p ON ks.id = p.khach_san_id
      LEFT JOIN phieu_dat_phong pdp ON p.id = pdp.phong_id
      LEFT JOIN danh_gia dg ON ks.id = dg.khach_san_id AND dg.trang_thai = N'Đã duyệt'
      WHERE ks.id = @hotelId
      GROUP BY ks.id
    `;

    try {
      const result = await this.executeQuery(query, { hotelId });
      return result.recordset[0] || null;
    } catch (error) {
      throw error;
    }
  }

  // Get all images for a hotel
  async getHotelImages(hotelId) {
    const query = `
      SELECT 
        id,
        khach_san_id,
        duong_dan_anh,
        thu_tu,
        la_anh_dai_dien,
        created_at
      FROM dbo.anh_khach_san
      WHERE khach_san_id = @hotelId
      ORDER BY thu_tu ASC, created_at ASC
    `;

    try {
      const result = await this.executeQuery(query, { hotelId });
      return result.recordset || [];
    } catch (error) {
      // Nếu bảng chưa tồn tại, trả về mảng rỗng
      if (error.message && error.message.includes("Invalid object name")) {
        console.log('⚠️ Table anh_khach_san does not exist yet');
        return [];
      }
      throw error;
    }
  }

  // Get hotel statistics for admin dashboard
  async getStats() {
    try {
      const query = `
        SELECT 
          COUNT(*) as totalHotels,
          SUM(CASE WHEN trang_thai = N'Hoạt động' THEN 1 ELSE 0 END) as activeHotels,
          SUM(CASE WHEN created_at >= DATEADD(month, -1, GETDATE()) THEN 1 ELSE 0 END) as newHotelsThisMonth
        FROM ${this.tableName}
      `;
      
      const result = await this.executeQuery(query);
      const stats = result.recordset[0] || {};
      
      // Convert SQL Server types to JavaScript numbers
      return {
        totalHotels: parseInt(stats.totalHotels) || 0,
        activeHotels: parseInt(stats.activeHotels) || 0,
        newHotelsThisMonth: parseInt(stats.newHotelsThisMonth) || 0
      };
    } catch (error) {
      console.error('Get hotel stats error:', error);
      throw error;
    }
  }
}

module.exports = new KhachSan();