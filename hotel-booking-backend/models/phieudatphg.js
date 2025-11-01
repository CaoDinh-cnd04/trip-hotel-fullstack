const BaseModel = require('./baseModel');

class PhieuDatPhong extends BaseModel {
    constructor() {
        super('phieu_dat_phong');
    }

    /**
     * Lấy tất cả phiếu đặt phòng của người dùng
     */
    async getBookingsByUser(ma_nguoi_dung, trang_thai = null) {
        try {
            let query = `
                SELECT pdp.*, 
                       p.so_phong, 
                       lp.ten_loai_phong,
                       ks.ten_khach_san, ks.dia_chi,
                       vt.ten_vi_tri, tt.ten_tinh_thanh, qg.ten_quoc_gia
                FROM phieu_dat_phong pdp
                INNER JOIN phong p ON pdp.ma_phong = p.ma_phong
                INNER JOIN loai_phong lp ON p.ma_loai_phong = lp.ma_loai_phong
                INNER JOIN khach_san ks ON p.ma_khach_san = ks.ma_khach_san
                INNER JOIN vi_tri vt ON ks.ma_vi_tri = vt.ma_vi_tri
                INNER JOIN tinh_thanh tt ON vt.ma_tinh_thanh = tt.ma_tinh_thanh
                INNER JOIN quoc_gia qg ON tt.ma_quoc_gia = qg.ma_quoc_gia
                WHERE pdp.ma_nguoi_dung = @ma_nguoi_dung
            `;
            const params = { ma_nguoi_dung };

            if (trang_thai) {
                query += ` AND pdp.trang_thai = @trang_thai`;
                params.trang_thai = trang_thai;
            }

            query += ` ORDER BY pdp.ngay_dat DESC`;

            return await this.executeQuery(query, params);
        } catch (error) {
            throw error;
        }
    }

    /**
     * Lấy chi tiết phiếu đặt phòng
     */
    async getBookingDetails(ma_phieu_dat_phong) {
        try {
            const query = `
                SELECT pdp.*, 
                       nd.ho_ten, nd.email, nd.so_dien_thoai,
                       p.so_phong, 
                       lp.ten_loai_phong, lp.gia_co_ban, lp.dien_tich,
                       ks.ten_khach_san, ks.dia_chi, ks.so_dien_thoai as sdt_khach_san,
                       vt.ten_vi_tri, tt.ten_tinh_thanh, qg.ten_quoc_gia
                FROM phieu_dat_phong pdp
                INNER JOIN nguoi_dung nd ON pdp.ma_nguoi_dung = nd.ma_nguoi_dung
                INNER JOIN phong p ON pdp.ma_phong = p.ma_phong
                INNER JOIN loai_phong lp ON p.ma_loai_phong = lp.ma_loai_phong
                INNER JOIN khach_san ks ON p.ma_khach_san = ks.ma_khach_san
                INNER JOIN vi_tri vt ON ks.ma_vi_tri = vt.ma_vi_tri
                INNER JOIN tinh_thanh tt ON vt.ma_tinh_thanh = tt.ma_tinh_thanh
                INNER JOIN quoc_gia qg ON tt.ma_quoc_gia = qg.ma_quoc_gia
                WHERE pdp.ma_phieu_dat_phong = @ma_phieu_dat_phong
            `;
            const result = await this.executeQuery(query, { ma_phieu_dat_phong });
            return result.length > 0 ? result[0] : null;
        } catch (error) {
            throw error;
        }
    }

    /**
     * Lấy tất cả đặt phòng của khách sạn
     */
    async getBookingsByHotel(ma_khach_san, trang_thai = null, tu_ngay = null, den_ngay = null) {
        try {
            let query = `
                SELECT pdp.*, 
                       nd.ho_ten, nd.email, nd.so_dien_thoai,
                       p.so_phong, 
                       lp.ten_loai_phong
                FROM phieu_dat_phong pdp
                INNER JOIN nguoi_dung nd ON pdp.ma_nguoi_dung = nd.ma_nguoi_dung
                INNER JOIN phong p ON pdp.ma_phong = p.ma_phong
                INNER JOIN loai_phong lp ON p.ma_loai_phong = lp.ma_loai_phong
                WHERE p.ma_khach_san = @ma_khach_san
            `;
            const params = { ma_khach_san };

            if (trang_thai) {
                query += ` AND pdp.trang_thai = @trang_thai`;
                params.trang_thai = trang_thai;
            }

            if (tu_ngay) {
                query += ` AND pdp.ngay_checkin >= @tu_ngay`;
                params.tu_ngay = tu_ngay;
            }

            if (den_ngay) {
                query += ` AND pdp.ngay_checkout <= @den_ngay`;
                params.den_ngay = den_ngay;
            }

            query += ` ORDER BY pdp.ngay_dat DESC`;

            return await this.executeQuery(query, params);
        } catch (error) {
            throw error;
        }
    }

    /**
     * Tạo phiếu đặt phòng mới
     */
    async createBooking(bookingData) {
        try {
            // Validate required fields
            const required = ['ma_nguoi_dung', 'ma_phong', 'ngay_checkin', 'ngay_checkout', 'so_khach', 'tong_tien'];
            for (let field of required) {
                if (!bookingData[field]) {
                    throw new Error(`${field} là bắt buộc`);
                }
            }

            // Set default values
            bookingData.ma_phieu_dat_phong = `PDP${Date.now()}`;
            bookingData.ngay_dat = new Date();
            bookingData.trang_thai = 'pending';
            bookingData.ngay_tao = new Date();

            return await this.create(bookingData);
        } catch (error) {
            throw error;
        }
    }

    /**
     * Cập nhật trạng thái đặt phòng
     */
    async updateBookingStatus(ma_phieu_dat_phong, trang_thai, ghi_chu = null) {
        try {
            const updateData = {
                trang_thai,
                ngay_cap_nhat: new Date()
            };

            if (ghi_chu) {
                updateData.ghi_chu = ghi_chu;
            }

            // Cập nhật thời gian checkin/checkout
            if (trang_thai === 'checked_in') {
                updateData.ngay_checkin_thuc_te = new Date();
            } else if (trang_thai === 'checked_out') {
                updateData.ngay_checkout_thuc_te = new Date();
            }

            return await this.update(ma_phieu_dat_phong, updateData);
        } catch (error) {
            throw error;
        }
    }

    /**
     * Lấy thống kê đặt phòng theo thời gian
     */
    async getBookingStats(tu_ngay, den_ngay, ma_khach_san = null) {
        try {
            let query = `
                SELECT 
                    COUNT(*) as tong_so_dat_phong,
                    COUNT(CASE WHEN pdp.trang_thai = 'confirmed' THEN 1 END) as da_xac_nhan,
                    COUNT(CASE WHEN pdp.trang_thai = 'checked_in' THEN 1 END) as dang_o,
                    COUNT(CASE WHEN pdp.trang_thai = 'checked_out' THEN 1 END) as da_checkout,
                    COUNT(CASE WHEN pdp.trang_thai = 'cancelled' THEN 1 END) as da_huy,
                    SUM(pdp.tong_tien) as tong_doanh_thu
                FROM phieu_dat_phong pdp
                INNER JOIN phong p ON pdp.ma_phong = p.ma_phong
                WHERE pdp.ngay_dat >= @tu_ngay AND pdp.ngay_dat <= @den_ngay
            `;
            const params = { tu_ngay, den_ngay };

            if (ma_khach_san) {
                query += ` AND p.ma_khach_san = @ma_khach_san`;
                params.ma_khach_san = ma_khach_san;
            }

            const result = await this.executeQuery(query, params);
            return result[0];
        } catch (error) {
            throw error;
        }
    }

    /**
     * Kiểm tra conflict đặt phòng
     */
    async checkBookingConflict(ma_phong, ngay_checkin, ngay_checkout, ma_phieu_dat_phong_exclude = null) {
        try {
            let query = `
                SELECT COUNT(*) as count
                FROM phieu_dat_phong 
                WHERE ma_phong = @ma_phong
                  AND trang_thai IN ('confirmed', 'checked_in')
                  AND NOT (
                      @ngay_checkout <= ngay_checkin 
                      OR @ngay_checkin >= ngay_checkout
                  )
            `;
            const params = { ma_phong, ngay_checkin, ngay_checkout };

            if (ma_phieu_dat_phong_exclude) {
                query += ` AND ma_phieu_dat_phong != @ma_phieu_dat_phong_exclude`;
                params.ma_phieu_dat_phong_exclude = ma_phieu_dat_phong_exclude;
            }

            const result = await this.executeQuery(query, params);
            return result[0].count > 0;
        } catch (error) {
            throw error;
        }
    }

    /**
     * Override phương thức update để validate
     */
    async update(id, data) {
        data.ngay_cap_nhat = new Date();
        return await super.update(id, data);
    }

    // Get booking statistics for admin dashboard
    async getStats() {
        try {
            // Return dummy stats (no data yet)
            return {
                totalBookings: 0,
                completedBookings: 0,
                pendingBookings: 0,
                cancelledBookings: 0,
                totalRevenue: 0,
                monthlyRevenue: 0,
                statusDistribution: [],
                monthlyGrowth: 0,
                revenueGrowth: 0
            };
        } catch (error) {
            console.error('Get booking stats error:', error);
            throw error;
        }
    }
}

module.exports = new PhieuDatPhong();