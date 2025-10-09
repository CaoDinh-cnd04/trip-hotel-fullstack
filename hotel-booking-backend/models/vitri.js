const BaseModel = require('./baseModel');

class ViTri extends BaseModel {
    constructor() {
        super('vi_tri');
    }

    /**
     * Lấy tất cả vị trí theo tỉnh thành
     */
    async getViTriByTinhThanh(ma_tinh_thanh) {
        try {
            const query = `
                SELECT vt.*, tt.ten_tinh_thanh, qg.ten_quoc_gia
                FROM vi_tri vt
                INNER JOIN tinh_thanh tt ON vt.ma_tinh_thanh = tt.ma_tinh_thanh
                INNER JOIN quoc_gia qg ON tt.ma_quoc_gia = qg.ma_quoc_gia
                WHERE vt.ma_tinh_thanh = @ma_tinh_thanh AND vt.trang_thai = 1
                ORDER BY vt.ten_vi_tri ASC
            `;
            return await this.executeQuery(query, { ma_tinh_thanh });
        } catch (error) {
            throw error;
        }
    }

    /**
     * Lấy tất cả vị trí theo quốc gia
     */
    async getViTriByQuocGia(ma_quoc_gia) {
        try {
            const query = `
                SELECT vt.*, tt.ten_tinh_thanh, qg.ten_quoc_gia
                FROM vi_tri vt
                INNER JOIN tinh_thanh tt ON vt.ma_tinh_thanh = tt.ma_tinh_thanh
                INNER JOIN quoc_gia qg ON tt.ma_quoc_gia = qg.ma_quoc_gia
                WHERE qg.ma_quoc_gia = @ma_quoc_gia AND vt.trang_thai = 1
                ORDER BY tt.ten_tinh_thanh ASC, vt.ten_vi_tri ASC
            `;
            return await this.executeQuery(query, { ma_quoc_gia });
        } catch (error) {
            throw error;
        }
    }

    /**
     * Tìm kiếm vị trí
     */
    async searchViTri(keyword, ma_tinh_thanh = null, ma_quoc_gia = null) {
        try {
            let query = `
                SELECT vt.*, tt.ten_tinh_thanh, qg.ten_quoc_gia
                FROM vi_tri vt
                INNER JOIN tinh_thanh tt ON vt.ma_tinh_thanh = tt.ma_tinh_thanh
                INNER JOIN quoc_gia qg ON tt.ma_quoc_gia = qg.ma_quoc_gia
                WHERE vt.trang_thai = 1
            `;
            const params = {};

            if (keyword) {
                query += ` AND (vt.ten_vi_tri LIKE @keyword OR vt.ma_vi_tri LIKE @keyword)`;
                params.keyword = `%${keyword}%`;
            }

            if (ma_tinh_thanh) {
                query += ` AND vt.ma_tinh_thanh = @ma_tinh_thanh`;
                params.ma_tinh_thanh = ma_tinh_thanh;
            }

            if (ma_quoc_gia) {
                query += ` AND qg.ma_quoc_gia = @ma_quoc_gia`;
                params.ma_quoc_gia = ma_quoc_gia;
            }

            query += ` ORDER BY vt.ten_vi_tri ASC`;

            return await this.executeQuery(query, params);
        } catch (error) {
            throw error;
        }
    }

    /**
     * Lấy thông tin chi tiết vị trí kèm số lượng khách sạn
     */
    async getViTriWithStats(ma_vi_tri) {
        try {
            const query = `
                SELECT 
                    vt.*,
                    tt.ten_tinh_thanh,
                    qg.ten_quoc_gia,
                    COUNT(ks.ma_khach_san) as so_luong_khach_san
                FROM vi_tri vt
                INNER JOIN tinh_thanh tt ON vt.ma_tinh_thanh = tt.ma_tinh_thanh
                INNER JOIN quoc_gia qg ON tt.ma_quoc_gia = qg.ma_quoc_gia
                LEFT JOIN khach_san ks ON vt.ma_vi_tri = ks.ma_vi_tri AND ks.trang_thai = 1
                WHERE vt.ma_vi_tri = @ma_vi_tri AND vt.trang_thai = 1
                GROUP BY vt.ma_vi_tri, vt.ten_vi_tri, vt.ma_tinh_thanh, 
                         vt.mo_ta, vt.hinh_anh, vt.trang_thai, 
                         vt.ngay_tao, vt.ngay_cap_nhat, 
                         tt.ten_tinh_thanh, qg.ten_quoc_gia
            `;
            const result = await this.executeQuery(query, { ma_vi_tri });
            return result.length > 0 ? result[0] : null;
        } catch (error) {
            throw error;
        }
    }

    /**
     * Lấy danh sách vị trí phổ biến (có nhiều khách sạn)
     */
    async getPopularViTri(limit = 10) {
        try {
            const query = `
                SELECT 
                    vt.*,
                    tt.ten_tinh_thanh,
                    qg.ten_quoc_gia,
                    COUNT(ks.ma_khach_san) as so_luong_khach_san
                FROM vi_tri vt
                INNER JOIN tinh_thanh tt ON vt.ma_tinh_thanh = tt.ma_tinh_thanh
                INNER JOIN quoc_gia qg ON tt.ma_quoc_gia = qg.ma_quoc_gia
                LEFT JOIN khach_san ks ON vt.ma_vi_tri = ks.ma_vi_tri AND ks.trang_thai = 1
                WHERE vt.trang_thai = 1
                GROUP BY vt.ma_vi_tri, vt.ten_vi_tri, vt.ma_tinh_thanh, 
                         vt.mo_ta, vt.hinh_anh, vt.trang_thai, 
                         vt.ngay_tao, vt.ngay_cap_nhat, 
                         tt.ten_tinh_thanh, qg.ten_quoc_gia
                HAVING COUNT(ks.ma_khach_san) > 0
                ORDER BY COUNT(ks.ma_khach_san) DESC, vt.ten_vi_tri ASC
                OFFSET 0 ROWS FETCH NEXT @limit ROWS ONLY
            `;
            return await this.executeQuery(query, { limit });
        } catch (error) {
            throw error;
        }
    }

    /**
     * Override phương thức create để validate
     */
    async create(data) {
        // Validate required fields
        if (!data.ten_vi_tri || !data.ma_tinh_thanh) {
            throw new Error('Tên vị trí và mã tỉnh thành là bắt buộc');
        }

        // Set default values
        data.trang_thai = data.trang_thai !== undefined ? data.trang_thai : 1;
        data.ngay_tao = new Date();

        return await super.create(data);
    }

    /**
     * Override phương thức update để validate
     */
    async update(id, data) {
        data.ngay_cap_nhat = new Date();
        return await super.update(id, data);
    }
}

module.exports = ViTri;