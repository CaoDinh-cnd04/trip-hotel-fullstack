const BaseModel = require('./baseModel');

class TienNghi extends BaseModel {
    constructor() {
        super('tien_nghi');
    }

    /**
     * Lấy tiện nghi theo loại
     */
    async getTienNghiByType(loai_tien_nghi) {
        try {
            const query = `
                SELECT * FROM tien_nghi 
                WHERE loai_tien_nghi = @loai_tien_nghi AND trang_thai = 1
                ORDER BY ten_tien_nghi ASC
            `;
            return await this.executeQuery(query, { loai_tien_nghi });
        } catch (error) {
            throw error;
        }
    }

    /**
     * Tìm kiếm tiện nghi
     */
    async searchTienNghi(keyword) {
        try {
            const query = `
                SELECT * FROM tien_nghi 
                WHERE trang_thai = 1 
                  AND (ten_tien_nghi LIKE @keyword OR mo_ta LIKE @keyword)
                ORDER BY ten_tien_nghi ASC
            `;
            return await this.executeQuery(query, { keyword: `%${keyword}%` });
        } catch (error) {
            throw error;
        }
    }

    /**
     * Lấy tiện nghi của khách sạn
     */
    async getTienNghiByKhachSan(ma_khach_san) {
        try {
            const query = `
                SELECT tn.*, kstn.gia_tri
                FROM tien_nghi tn
                INNER JOIN khach_san_tien_nghi kstn ON tn.ma_tien_nghi = kstn.ma_tien_nghi
                WHERE kstn.ma_khach_san = @ma_khach_san AND tn.trang_thai = 1
                ORDER BY tn.loai_tien_nghi ASC, tn.ten_tien_nghi ASC
            `;
            return await this.executeQuery(query, { ma_khach_san });
        } catch (error) {
            throw error;
        }
    }

    /**
     * Lấy tiện nghi của loại phòng
     */
    async getTienNghiByLoaiPhong(ma_loai_phong) {
        try {
            const query = `
                SELECT tn.*, lptn.gia_tri
                FROM tien_nghi tn
                INNER JOIN loai_phong_tien_nghi lptn ON tn.ma_tien_nghi = lptn.ma_tien_nghi
                WHERE lptn.ma_loai_phong = @ma_loai_phong AND tn.trang_thai = 1
                ORDER BY tn.loai_tien_nghi ASC, tn.ten_tien_nghi ASC
            `;
            return await this.executeQuery(query, { ma_loai_phong });
        } catch (error) {
            throw error;
        }
    }

    /**
     * Override phương thức create để validate
     */
    async create(data) {
        // Validate required fields
        if (!data.ten_tien_nghi || !data.loai_tien_nghi) {
            throw new Error('Tên tiện nghi và loại tiện nghi là bắt buộc');
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

module.exports = TienNghi;