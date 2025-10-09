const KhuyenMai = require('../models/khuyenmai');
const { validationResult } = require('express-validator');

const khuyenmaiController = {
    // Lấy tất cả khuyến mãi
    async getAllKhuyenMai(req, res) {
        try {
            const { page = 1, limit = 10, active_only, ma_khach_san } = req.query;
            
            const khuyenMai = new KhuyenMai();
            let results;

            if (active_only === 'true') {
                results = await khuyenMai.findAll({
                    trang_thai: 1,
                    active: true
                }, parseInt(page), parseInt(limit));
            } else {
                const filters = {};
                if (ma_khach_san) filters.ma_khach_san = ma_khach_san;
                results = await khuyenMai.findAll(filters, parseInt(page), parseInt(limit));
            }

            res.status(200).json({
                success: true,
                message: 'Lấy danh sách khuyến mãi thành công',
                data: results
            });
        } catch (error) {
            console.error('Error in getAllKhuyenMai:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy danh sách khuyến mãi',
                error: error.message
            });
        }
    },

    // Lấy khuyến mãi theo ID
    async getKhuyenMaiById(req, res) {
        try {
            const { id } = req.params;
            const khuyenMai = new KhuyenMai();
            
            const result = await khuyenMai.findById(id);
            
            if (!result) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy khuyến mãi'
                });
            }

            res.status(200).json({
                success: true,
                message: 'Lấy thông tin khuyến mãi thành công',
                data: result
            });
        } catch (error) {
            console.error('Error in getKhuyenMaiById:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy thông tin khuyến mãi',
                error: error.message
            });
        }
    },

    // Lấy khuyến mãi đang hoạt động
    async getActivePromotions(req, res) {
        try {
            const { ma_khach_san } = req.query;
            const khuyenMai = new KhuyenMai();
            
            const query = `
                SELECT km.*, ks.ten_khach_san 
                FROM khuyen_mai km
                LEFT JOIN khach_san ks ON km.ma_khach_san = ks.ma_khach_san
                WHERE km.trang_thai = 1 
                  AND km.ngay_bat_dau <= GETDATE() 
                  AND km.ngay_ket_thuc >= GETDATE()
                  ${ma_khach_san ? 'AND km.ma_khach_san = @ma_khach_san' : ''}
                ORDER BY km.phan_tram_giam DESC
            `;
            
            const params = ma_khach_san ? { ma_khach_san } : {};
            const results = await khuyenMai.executeQuery(query, params);

            res.status(200).json({
                success: true,
                message: 'Lấy khuyến mãi đang hoạt động thành công',
                data: results
            });
        } catch (error) {
            console.error('Error in getActivePromotions:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy khuyến mãi đang hoạt động',
                error: error.message
            });
        }
    },

    // Tạo khuyến mãi mới
    async createKhuyenMai(req, res) {
        try {
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                return res.status(400).json({
                    success: false,
                    message: 'Dữ liệu không hợp lệ',
                    errors: errors.array()
                });
            }

            const khuyenMai = new KhuyenMai();
            const newKhuyenMai = await khuyenMai.create({
                ...req.body,
                ngay_tao: new Date(),
                trang_thai: 1
            });

            res.status(201).json({
                success: true,
                message: 'Tạo khuyến mãi thành công',
                data: newKhuyenMai
            });
        } catch (error) {
            console.error('Error in createKhuyenMai:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi tạo khuyến mãi',
                error: error.message
            });
        }
    },

    // Cập nhật khuyến mãi
    async updateKhuyenMai(req, res) {
        try {
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                return res.status(400).json({
                    success: false,
                    message: 'Dữ liệu không hợp lệ',
                    errors: errors.array()
                });
            }

            const { id } = req.params;
            const khuyenMai = new KhuyenMai();
            
            const updated = await khuyenMai.update(id, {
                ...req.body,
                ngay_cap_nhat: new Date()
            });
            
            if (!updated) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy khuyến mãi để cập nhật'
                });
            }

            res.status(200).json({
                success: true,
                message: 'Cập nhật khuyến mãi thành công',
                data: updated
            });
        } catch (error) {
            console.error('Error in updateKhuyenMai:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi cập nhật khuyến mãi',
                error: error.message
            });
        }
    },

    // Xóa khuyến mãi
    async deleteKhuyenMai(req, res) {
        try {
            const { id } = req.params;
            const khuyenMai = new KhuyenMai();
            
            const deleted = await khuyenMai.update(id, { 
                trang_thai: 0,
                ngay_cap_nhat: new Date()
            });
            
            if (!deleted) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy khuyến mãi để xóa'
                });
            }

            res.status(200).json({
                success: true,
                message: 'Xóa khuyến mãi thành công'
            });
        } catch (error) {
            console.error('Error in deleteKhuyenMai:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi xóa khuyến mãi',
                error: error.message
            });
        }
    },

    // Kiểm tra khuyến mãi có thể áp dụng
    async validatePromotion(req, res) {
        try {
            const { id } = req.params;
            const { tong_tien } = req.query;
            
            const khuyenMai = new KhuyenMai();
            const promotion = await khuyenMai.findById(id);

            if (!promotion) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy khuyến mãi'
                });
            }

            const currentDate = new Date();
            const isValid = promotion.trang_thai === 1 &&
                           new Date(promotion.ngay_bat_dau) <= currentDate &&
                           new Date(promotion.ngay_ket_thuc) >= currentDate;

            let discountAmount = 0;
            if (isValid && tong_tien) {
                discountAmount = (parseFloat(tong_tien) * promotion.phan_tram_giam) / 100;
                if (promotion.giam_toi_da && discountAmount > promotion.giam_toi_da) {
                    discountAmount = promotion.giam_toi_da;
                }
            }

            res.status(200).json({
                success: true,
                message: isValid ? 'Khuyến mãi hợp lệ' : 'Khuyến mãi không hợp lệ hoặc đã hết hạn',
                data: {
                    promotion,
                    isValid,
                    discountAmount
                }
            });
        } catch (error) {
            console.error('Error in validatePromotion:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi kiểm tra khuyến mãi',
                error: error.message
            });
        }
    },

    // Xóa khuyến mãi (Admin only)
    async deleteKhuyenMai(req, res) {
        try {
            const { id } = req.params;
            const khuyenMai = new KhuyenMai();
            
            const deleted = await khuyenMai.update(id, { 
                trang_thai: 0,
                ngay_cap_nhat: new Date()
            });
            
            if (!deleted) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy khuyến mãi để xóa'
                });
            }

            res.status(200).json({
                success: true,
                message: 'Xóa khuyến mãi thành công'
            });
        } catch (error) {
            console.error('Error in deleteKhuyenMai:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi xóa khuyến mãi',
                error: error.message
            });
        }
    },

    // Bật/tắt khuyến mãi (Admin only)
    async toggleKhuyenMai(req, res) {
        try {
            const { id } = req.params;
            const khuyenMai = new KhuyenMai();
            
            const existing = await khuyenMai.findById(id);
            if (!existing) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy khuyến mãi'
                });
            }

            const newStatus = existing.trang_thai === 1 ? 0 : 1;
            const updated = await khuyenMai.update(id, { 
                trang_thai: newStatus,
                ngay_cap_nhat: new Date()
            });

            res.status(200).json({
                success: true,
                message: `${newStatus === 1 ? 'Kích hoạt' : 'Vô hiệu hóa'} khuyến mãi thành công`,
                data: updated
            });
        } catch (error) {
            console.error('Error in toggleKhuyenMai:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi thay đổi trạng thái khuyến mãi',
                error: error.message
            });
        }
    }
};

module.exports = khuyenmaiController;