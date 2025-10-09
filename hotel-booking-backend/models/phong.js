const BaseModel = require('./baseModel');

class Phong extends BaseModel {
    constructor() {
        super('phong');
    }

    /**
     * Lấy tất cả phòng theo khách sạn
     */
    async getPhongByKhachSan(ma_khach_san) {
        try {
            const query = `
                SELECT p.*, lp.ten_loai_phong, lp.mo_ta as mo_ta_loai_phong, 
                       ks.ten_khach_san
                FROM phong p
                INNER JOIN loai_phong lp ON p.ma_loai_phong = lp.ma_loai_phong
                INNER JOIN khach_san ks ON p.ma_khach_san = ks.ma_khach_san
                WHERE p.ma_khach_san = @ma_khach_san AND p.trang_thai = 1
                ORDER BY lp.ten_loai_phong ASC, p.so_phong ASC
            `;
            return await this.executeQuery(query, { ma_khach_san });
        } catch (error) {
            throw error;
        }
    }

    /**
     * Lấy phòng available theo ngày
     */
    async getAvailableRooms(ma_khach_san, ngay_checkin, ngay_checkout, ma_loai_phong = null) {
        try {
            let query = `
                SELECT p.*, lp.ten_loai_phong, lp.mo_ta as mo_ta_loai_phong,
                       lp.gia_co_ban, lp.so_khach_toi_da
                FROM phong p
                INNER JOIN loai_phong lp ON p.ma_loai_phong = lp.ma_loai_phong
                WHERE p.ma_khach_san = @ma_khach_san 
                  AND p.trang_thai = 1
                  AND p.ma_phong NOT IN (
                      SELECT DISTINCT pdp.ma_phong 
                      FROM phieu_dat_phong pdp 
                      WHERE pdp.trang_thai IN ('confirmed', 'checked_in')
                        AND NOT (
                            @ngay_checkout <= pdp.ngay_checkin 
                            OR @ngay_checkin >= pdp.ngay_checkout
                        )
                  )
            `;
            
            const params = { 
                ma_khach_san, 
                ngay_checkin, 
                ngay_checkout 
            };

            if (ma_loai_phong) {
                query += ` AND p.ma_loai_phong = @ma_loai_phong`;
                params.ma_loai_phong = ma_loai_phong;
            }

            query += ` ORDER BY lp.gia_co_ban ASC, p.so_phong ASC`;

            return await this.executeQuery(query, params);
        } catch (error) {
            throw error;
        }
    }

    /**
     * Lấy thông tin chi tiết phòng
     */
    async getPhongWithDetails(ma_phong) {
        try {
            const query = `
                SELECT p.*, lp.ten_loai_phong, lp.mo_ta as mo_ta_loai_phong,
                       lp.gia_co_ban, lp.so_khach_toi_da, lp.dien_tich,
                       ks.ten_khach_san, ks.ma_vi_tri
                FROM phong p
                INNER JOIN loai_phong lp ON p.ma_loai_phong = lp.ma_loai_phong
                INNER JOIN khach_san ks ON p.ma_khach_san = ks.ma_khach_san
                WHERE p.ma_phong = @ma_phong AND p.trang_thai = 1
            `;
            const result = await this.executeQuery(query, { ma_phong });
            return result.length > 0 ? result[0] : null;
        } catch (error) {
            throw error;
        }
    }

    /**
     * Kiểm tra phòng có available không
     */
    async isRoomAvailable(ma_phong, ngay_checkin, ngay_checkout) {
        try {
            const query = `
                SELECT COUNT(*) as count
                FROM phieu_dat_phong pdp 
                WHERE pdp.ma_phong = @ma_phong
                  AND pdp.trang_thai IN ('confirmed', 'checked_in')
                  AND NOT (
                      @ngay_checkout <= pdp.ngay_checkin 
                      OR @ngay_checkin >= pdp.ngay_checkout
                  )
            `;
            const result = await this.executeQuery(query, { 
                ma_phong, 
                ngay_checkin, 
                ngay_checkout 
            });
            return result[0].count === 0;
        } catch (error) {
            throw error;
        }
    }

    /**
     * Lấy lịch đặt phòng
     */
    async getRoomBookingSchedule(ma_phong, tu_ngay, den_ngay) {
        try {
            const query = `
                SELECT pdp.*, nd.ho_ten as ten_khach_hang
                FROM phieu_dat_phong pdp
                INNER JOIN nguoi_dung nd ON pdp.ma_nguoi_dung = nd.ma_nguoi_dung
                WHERE pdp.ma_phong = @ma_phong
                  AND pdp.trang_thai IN ('confirmed', 'checked_in', 'checked_out')
                  AND pdp.ngay_checkin <= @den_ngay
                  AND pdp.ngay_checkout >= @tu_ngay
                ORDER BY pdp.ngay_checkin ASC
            `;
            return await this.executeQuery(query, { 
                ma_phong, 
                tu_ngay, 
                den_ngay 
            });
        } catch (error) {
            throw error;
        }
    }

    /**
     * Tìm kiếm phòng
     */
    async searchPhong(keyword, ma_khach_san = null, ma_loai_phong = null) {
        try {
            let query = `
                SELECT p.*, lp.ten_loai_phong, ks.ten_khach_san
                FROM phong p
                INNER JOIN loai_phong lp ON p.ma_loai_phong = lp.ma_loai_phong
                INNER JOIN khach_san ks ON p.ma_khach_san = ks.ma_khach_san
                WHERE p.trang_thai = 1
            `;
            const params = {};

            if (keyword) {
                query += ` AND (p.so_phong LIKE @keyword OR p.ma_phong LIKE @keyword)`;
                params.keyword = `%${keyword}%`;
            }

            if (ma_khach_san) {
                query += ` AND p.ma_khach_san = @ma_khach_san`;
                params.ma_khach_san = ma_khach_san;
            }

            if (ma_loai_phong) {
                query += ` AND p.ma_loai_phong = @ma_loai_phong`;
                params.ma_loai_phong = ma_loai_phong;
            }

            query += ` ORDER BY ks.ten_khach_san ASC, lp.ten_loai_phong ASC, p.so_phong ASC`;

            return await this.executeQuery(query, params);
        } catch (error) {
            throw error;
        }
    }

    /**
     * Override phương thức create để validate
     */
    async create(data) {
        // Validate required fields
        if (!data.so_phong || !data.ma_khach_san || !data.ma_loai_phong) {
            throw new Error('Số phòng, mã khách sạn và mã loại phòng là bắt buộc');
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

module.exports = Phong;