const BaseModel = require('./baseModel');

class TinhThanh extends BaseModel {
    constructor() {
        super('tinh_thanh');
    }

    /**
     * Lấy tất cả tỉnh thành theo quốc gia
     */
    async getTinhThanhByQuocGia(ma_quoc_gia) {
        try {
            const query = `
                SELECT tt.*, qg.ten_quoc_gia
                FROM tinh_thanh tt
                INNER JOIN quoc_gia qg ON tt.ma_quoc_gia = qg.ma_quoc_gia
                WHERE tt.ma_quoc_gia = @ma_quoc_gia AND tt.trang_thai = 1
                ORDER BY tt.ten_tinh_thanh ASC
            `;
            return await this.executeQuery(query, { ma_quoc_gia });
        } catch (error) {
            throw error;
        }
    }

    /**
     * Tìm kiếm tỉnh thành
     */
    async searchTinhThanh(keyword, ma_quoc_gia = null) {
        try {
            let query = `
                SELECT tt.*, qg.ten_quoc_gia
                FROM tinh_thanh tt
                INNER JOIN quoc_gia qg ON tt.ma_quoc_gia = qg.ma_quoc_gia
                WHERE tt.trang_thai = 1
            `;
            const params = {};

            if (keyword) {
                query += ` AND (tt.ten_tinh_thanh LIKE @keyword OR tt.ma_tinh_thanh LIKE @keyword)`;
                params.keyword = `%${keyword}%`;
            }

            if (ma_quoc_gia) {
                query += ` AND tt.ma_quoc_gia = @ma_quoc_gia`;
                params.ma_quoc_gia = ma_quoc_gia;
            }

            query += ` ORDER BY tt.ten_tinh_thanh ASC`;

            return await this.executeQuery(query, params);
        } catch (error) {
            throw error;
        }
    }

    /**
     * Lấy thông tin chi tiết tỉnh thành kèm số lượng vị trí
     */
    async getTinhThanhWithStats(ma_tinh_thanh) {
        try {
            const query = `
                SELECT 
                    tt.*,
                    qg.ten_quoc_gia,
                    COUNT(vt.ma_vi_tri) as so_luong_vi_tri
                FROM tinh_thanh tt
                INNER JOIN quoc_gia qg ON tt.ma_quoc_gia = qg.ma_quoc_gia
                LEFT JOIN vi_tri vt ON tt.ma_tinh_thanh = vt.ma_tinh_thanh AND vt.trang_thai = 1
                WHERE tt.ma_tinh_thanh = @ma_tinh_thanh AND tt.trang_thai = 1
                GROUP BY tt.ma_tinh_thanh, tt.ten_tinh_thanh, tt.ma_quoc_gia, 
                         tt.mo_ta, tt.hinh_anh, tt.trang_thai, 
                         tt.ngay_tao, tt.ngay_cap_nhat, qg.ten_quoc_gia
            `;
            const result = await this.executeQuery(query, { ma_tinh_thanh });
            return result.length > 0 ? result[0] : null;
        } catch (error) {
            throw error;
        }
    }

    /**
     * Lấy danh sách tỉnh thành phổ biến (có nhiều vị trí)
     */
    async getPopularTinhThanh(limit = 10) {
        try {
            const query = `
                SELECT 
                    tt.*,
                    qg.ten_quoc_gia,
                    COUNT(vt.ma_vi_tri) as so_luong_vi_tri
                FROM tinh_thanh tt
                INNER JOIN quoc_gia qg ON tt.ma_quoc_gia = qg.ma_quoc_gia
                LEFT JOIN vi_tri vt ON tt.ma_tinh_thanh = vt.ma_tinh_thanh AND vt.trang_thai = 1
                WHERE tt.trang_thai = 1
                GROUP BY tt.ma_tinh_thanh, tt.ten_tinh_thanh, tt.ma_quoc_gia, 
                         tt.mo_ta, tt.hinh_anh, tt.trang_thai, 
                         tt.ngay_tao, tt.ngay_cap_nhat, qg.ten_quoc_gia
                HAVING COUNT(vt.ma_vi_tri) > 0
                ORDER BY COUNT(vt.ma_vi_tri) DESC, tt.ten_tinh_thanh ASC
                OFFSET 0 ROWS FETCH NEXT @limit ROWS ONLY
            `;
            return await this.executeQuery(query, { limit });
        } catch (error) {
            throw error;
        }
    }

    /**
     * Kiểm tra tỉnh thành có tồn tại và thuộc quốc gia không
     */
    async checkTinhThanhExists(ma_tinh_thanh, ma_quoc_gia) {
        try {
            const query = `
                SELECT COUNT(*) as count
                FROM tinh_thanh 
                WHERE ma_tinh_thanh = @ma_tinh_thanh 
                  AND ma_quoc_gia = @ma_quoc_gia 
                  AND trang_thai = 1
            `;
            const result = await this.executeQuery(query, { ma_tinh_thanh, ma_quoc_gia });
            return result[0].count > 0;
        } catch (error) {
            throw error;
        }
    }

    /**
     * Override phương thức create để validate
     */
    async create(data) {
        // Validate required fields
        if (!data.ten_tinh_thanh || !data.ma_quoc_gia) {
            throw new Error('Tên tỉnh thành và mã quốc gia là bắt buộc');
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

module.exports = TinhThanh;