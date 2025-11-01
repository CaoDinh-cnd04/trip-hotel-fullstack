const BaseModel = require('./baseModel');

class LoaiPhong extends BaseModel {
    constructor() {
        super('loai_phong');
    }

    /**
     * Lấy tất cả loại phòng theo khách sạn
     */
    async getLoaiPhongByKhachSan(ma_khach_san) {
        try {
            const query = `
                SELECT lp.*, 
                       COUNT(p.ma_phong) as so_phong_available,
                       ks.ten_khach_san
                FROM loai_phong lp
                INNER JOIN khach_san ks ON lp.ma_khach_san = ks.ma_khach_san
                LEFT JOIN phong p ON lp.ma_loai_phong = p.ma_loai_phong AND p.trang_thai = 1
                WHERE lp.ma_khach_san = @ma_khach_san AND lp.trang_thai = 1
                GROUP BY lp.ma_loai_phong, lp.ten_loai_phong, lp.mo_ta, 
                         lp.gia_co_ban, lp.dien_tich,
                         lp.hinh_anh, lp.trang_thai, lp.ngay_tao, 
                         lp.ngay_cap_nhat, ks.ten_khach_san
                ORDER BY lp.gia_co_ban ASC
            `;
            return await this.executeQuery(query, { ma_khach_san });
        } catch (error) {
            throw error;
        }
    }

    /**
     * Lấy thông tin chi tiết loại phòng kèm tiện nghi
     */
    async getLoaiPhongWithDetails(ma_loai_phong) {
        try {
            const query = `
                SELECT lp.*, ks.ten_khach_san,
                       COUNT(p.ma_phong) as tong_so_phong
                FROM loai_phong lp
                INNER JOIN khach_san ks ON lp.ma_khach_san = ks.ma_khach_san
                LEFT JOIN phong p ON lp.ma_loai_phong = p.ma_loai_phong AND p.trang_thai = 1
                WHERE lp.ma_loai_phong = @ma_loai_phong AND lp.trang_thai = 1
                GROUP BY lp.ma_loai_phong, lp.ten_loai_phong, lp.mo_ta, 
                         lp.gia_co_ban, lp.dien_tich,
                         lp.hinh_anh, lp.trang_thai, lp.ngay_tao, 
                         lp.ngay_cap_nhat, ks.ten_khach_san
            `;
            const result = await this.executeQuery(query, { ma_loai_phong });
            
            if (result.length === 0) return null;
            
            // Lấy tiện nghi của loại phòng
            const tienNghiQuery = `
                SELECT tn.*
                FROM tien_nghi tn
                INNER JOIN loai_phong_tien_nghi lptn ON tn.ma_tien_nghi = lptn.ma_tien_nghi
                WHERE lptn.ma_loai_phong = @ma_loai_phong AND tn.trang_thai = 1
                ORDER BY tn.ten_tien_nghi ASC
            `;
            const tienNghi = await this.executeQuery(tienNghiQuery, { ma_loai_phong });
            
            return {
                ...result[0],
                tien_nghi: tienNghi
            };
        } catch (error) {
            throw error;
        }
    }

    /**
     * Override phương thức create để validate
     */
    async create(data) {
        // Validate required fields
        if (!data.ten_loai_phong || !data.ma_khach_san || !data.gia_co_ban) {
            throw new Error('Tên loại phòng, mã khách sạn và giá cơ bản là bắt buộc');
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

module.exports = LoaiPhong;