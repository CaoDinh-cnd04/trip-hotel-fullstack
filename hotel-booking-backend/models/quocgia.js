// models/quocgia.js - Country model
const BaseModel = require('./baseModel');

class QuocGia extends BaseModel {
  constructor() {
    super('quoc_gia', 'id');
  }

  // Get active countries
  async getActiveCountries(options = {}) {
    return await this.findAll({
      ...options,
      where: 'trang_thai = 1',
      orderBy: 'ten ASC'
    });
  }

  // Search countries by name
  async searchByName(searchTerm, options = {}) {
    return await this.search(searchTerm, ['ten'], {
      ...options,
      additionalWhere: 'trang_thai = 1'
    });
  }

  // Get country with provinces
  async getCountryWithProvinces(id) {
    const query = `
      SELECT 
        qg.*,
        tt.id as tinh_thanh_id,
        tt.ten as tinh_thanh_ten,
        tt.hinh_anh as tinh_thanh_hinh_anh,
        tt.mo_ta as tinh_thanh_mo_ta
      FROM quoc_gia qg
      LEFT JOIN tinh_thanh tt ON qg.id = tt.quoc_gia_id AND tt.trang_thai = 1
      WHERE qg.id = @id AND qg.trang_thai = 1
      ORDER BY tt.ten ASC
    `;
    
    try {
      const result = await this.executeQuery(query, { id });
      const rows = result.recordset;
      
      if (rows.length === 0) {
        return null;
      }

      // Group provinces under country
      const country = {
        id: rows[0].id,
        ten: rows[0].ten,
        hinh_anh: rows[0].hinh_anh,
        mo_ta: rows[0].mo_ta,
        trang_thai: rows[0].trang_thai,
        created_at: rows[0].created_at,
        updated_at: rows[0].updated_at,
        tinh_thanh: []
      };

      rows.forEach(row => {
        if (row.tinh_thanh_id) {
          country.tinh_thanh.push({
            id: row.tinh_thanh_id,
            ten: row.tinh_thanh_ten,
            hinh_anh: row.tinh_thanh_hinh_anh,
            mo_ta: row.tinh_thanh_mo_ta
          });
        }
      });

      return country;
    } catch (error) {
      throw error;
    }
  }

  // Get countries with statistics
  async getCountriesWithStats() {
    const query = `
      SELECT 
        qg.*,
        COUNT(DISTINCT tt.id) as so_tinh_thanh,
        COUNT(DISTINCT ks.id) as so_khach_san
      FROM quoc_gia qg
      LEFT JOIN tinh_thanh tt ON qg.id = tt.quoc_gia_id AND tt.trang_thai = 1
      LEFT JOIN vi_tri vt ON tt.id = vt.tinh_thanh_id AND vt.trang_thai = 1
      LEFT JOIN khach_san ks ON vt.id = ks.vi_tri_id AND ks.trang_thai = N'Hoạt động'
      WHERE qg.trang_thai = 1
      GROUP BY qg.id, qg.ten, qg.hinh_anh, qg.mo_ta, qg.trang_thai, qg.created_at, qg.updated_at
      ORDER BY qg.ten ASC
    `;
    
    try {
      const result = await this.executeQuery(query);
      return result.recordset;
    } catch (error) {
      throw error;
    }
  }

  // Create country
  async createCountry(data) {
    try {
      const countryData = {
        ten: data.ten,
        hinh_anh: data.hinh_anh,
        mo_ta: data.mo_ta || '',
        trang_thai: data.trang_thai !== undefined ? data.trang_thai : 1
      };

      return await this.create(countryData);
    } catch (error) {
      throw error;
    }
  }

  // Update country
  async updateCountry(id, data) {
    try {
      const updateData = {
        ten: data.ten,
        hinh_anh: data.hinh_anh,
        mo_ta: data.mo_ta,
        trang_thai: data.trang_thai
      };

      // Remove undefined fields
      Object.keys(updateData).forEach(key => {
        if (updateData[key] === undefined) {
          delete updateData[key];
        }
      });

      return await this.update(id, updateData);
    } catch (error) {
      throw error;
    }
  }

  // Toggle country status
  async toggleStatus(id) {
    try {
      const country = await this.findById(id);
      if (!country) {
        throw new Error('Quốc gia không tồn tại');
      }

      const newStatus = country.trang_thai ? 0 : 1;
      return await this.update(id, { trang_thai: newStatus });
    } catch (error) {
      throw error;
    }
  }
}

module.exports = new QuocGia();