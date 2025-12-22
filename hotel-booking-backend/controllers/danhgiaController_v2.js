const DanhGia = require('../models/danhgia');
const { validationResult } = require('express-validator');

const danhgiaController = {
    // Lấy tất cả đánh giá
    async getAllDanhGia(req, res) {
        try {
            const { page = 1, limit = 10, ma_khach_san, ma_nguoi_dung, diem_danh_gia } = req.query;
            
            const danhGia = new DanhGia();
            const filters = {};
            
            if (ma_khach_san) filters.ma_khach_san = ma_khach_san;
            if (ma_nguoi_dung) filters.ma_nguoi_dung = ma_nguoi_dung;
            if (diem_danh_gia) filters.diem_danh_gia = diem_danh_gia;

            const results = await danhGia.findAll(filters, parseInt(page), parseInt(limit));

            res.status(200).json({
                success: true,
                message: 'Lấy danh sách đánh giá thành công',
                data: results
            });
        } catch (error) {
            console.error('Error in getAllDanhGia:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy danh sách đánh giá',
                error: error.message
            });
        }
    },

    // Lấy đánh giá theo khách sạn với thống kê
    async getDanhGiaByKhachSan(req, res) {
        try {
            const { ma_khach_san } = req.params;
            const { page = 1, limit = 10 } = req.query;
            
            const danhGia = new DanhGia();
            
            // Lấy đánh giá với thông tin người dùng
            const reviewsQuery = `
                SELECT dg.*, nd.ho_ten, nd.anh_dai_dien
                FROM danh_gia dg
                INNER JOIN nguoi_dung nd ON dg.ma_nguoi_dung = nd.ma_nguoi_dung
                WHERE dg.ma_khach_san = @ma_khach_san AND dg.trang_thai = 1
                ORDER BY dg.ngay_tao DESC
                OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY
            `;
            
            // Thống kê đánh giá
            const statsQuery = `
                SELECT 
                    COUNT(*) as tong_danh_gia,
                    AVG(CAST(diem_danh_gia as FLOAT)) as diem_trung_binh,
                    COUNT(CASE WHEN diem_danh_gia = 5 THEN 1 END) as sao_5,
                    COUNT(CASE WHEN diem_danh_gia = 4 THEN 1 END) as sao_4,
                    COUNT(CASE WHEN diem_danh_gia = 3 THEN 1 END) as sao_3,
                    COUNT(CASE WHEN diem_danh_gia = 2 THEN 1 END) as sao_2,
                    COUNT(CASE WHEN diem_danh_gia = 1 THEN 1 END) as sao_1
                FROM danh_gia 
                WHERE ma_khach_san = @ma_khach_san AND trang_thai = 1
            `;

            const offset = (parseInt(page) - 1) * parseInt(limit);
            
            const [reviews, stats] = await Promise.all([
                danhGia.executeQuery(reviewsQuery, { ma_khach_san, offset, limit: parseInt(limit) }),
                danhGia.executeQuery(statsQuery, { ma_khach_san })
            ]);

            res.status(200).json({
                success: true,
                message: 'Lấy đánh giá khách sạn thành công',
                data: {
                    reviews,
                    stats: stats[0],
                    pagination: {
                        page: parseInt(page),
                        limit: parseInt(limit),
                        total: stats[0]?.tong_danh_gia || 0
                    }
                }
            });
        } catch (error) {
            console.error('Error in getDanhGiaByKhachSan:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy đánh giá khách sạn',
                error: error.message
            });
        }
    },

    // Lấy đánh giá theo ID
    async getDanhGiaById(req, res) {
        try {
            const { id } = req.params;
            const danhGia = new DanhGia();
            
            const result = await danhGia.findById(id);
            
            if (!result) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy đánh giá'
                });
            }

            res.status(200).json({
                success: true,
                message: 'Lấy thông tin đánh giá thành công',
                data: result
            });
        } catch (error) {
            console.error('Error in getDanhGiaById:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy thông tin đánh giá',
                error: error.message
            });
        }
    },

    // Tạo đánh giá mới
    async createDanhGia(req, res) {
        try {
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                return res.status(400).json({
                    success: false,
                    message: 'Dữ liệu không hợp lệ',
                    errors: errors.array()
                });
            }

            const danhGia = new DanhGia();
            
            // Kiểm tra người dùng đã đánh giá khách sạn này chưa
            const existingReview = await danhGia.findByCondition({
                ma_nguoi_dung: req.user.ma_nguoi_dung,
                ma_khach_san: req.body.ma_khach_san
            });

            if (existingReview) {
                return res.status(400).json({
                    success: false,
                    message: 'Bạn đã đánh giá khách sạn này rồi'
                });
            }

            const newDanhGia = await danhGia.create({
                ...req.body,
                ma_nguoi_dung: req.user.ma_nguoi_dung,
                ngay_tao: new Date(),
                trang_thai: 1
            });

            res.status(201).json({
                success: true,
                message: 'Tạo đánh giá thành công',
                data: newDanhGia
            });
        } catch (error) {
            console.error('Error in createDanhGia:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi tạo đánh giá',
                error: error.message
            });
        }
    },

    // Cập nhật đánh giá
    async updateDanhGia(req, res) {
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
            const danhGia = new DanhGia();
            
            // Kiểm tra đánh giá tồn tại và thuộc về user hiện tại
            const existingReview = await danhGia.findById(id);
            if (!existingReview) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy đánh giá'
                });
            }

            if (req.user.vai_tro !== 'Admin' && existingReview.ma_nguoi_dung !== req.user.ma_nguoi_dung) {
                return res.status(403).json({
                    success: false,
                    message: 'Bạn không có quyền cập nhật đánh giá này'
                });
            }

            const updated = await danhGia.update(id, {
                ...req.body,
                ngay_cap_nhat: new Date()
            });

            res.status(200).json({
                success: true,
                message: 'Cập nhật đánh giá thành công',
                data: updated
            });
        } catch (error) {
            console.error('Error in updateDanhGia:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi cập nhật đánh giá',
                error: error.message
            });
        }
    },

    // Xóa đánh giá (Admin only)
    async deleteDanhGia(req, res) {
        try {
            const { id } = req.params;
            const danhGia = new DanhGia();
            
            const deleted = await danhGia.update(id, { 
                trang_thai: 0,
                ngay_cap_nhat: new Date()
            });
            
            if (!deleted) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy đánh giá để xóa'
                });
            }

            res.status(200).json({
                success: true,
                message: 'Xóa đánh giá thành công'
            });
        } catch (error) {
            console.error('Error in deleteDanhGia:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi xóa đánh giá',
                error: error.message
            });
        }
    },

    // Lấy đánh giá của người dùng hiện tại
    async getMyDanhGia(req, res) {
        try {
            const { page = 1, limit = 10 } = req.query;
            const danhGia = new DanhGia();
            
            const results = await danhGia.findAll({
                ma_nguoi_dung: req.user.ma_nguoi_dung,
                trang_thai: 1
            }, parseInt(page), parseInt(limit));

            res.status(200).json({
                success: true,
                message: 'Lấy đánh giá của bạn thành công',
                data: results
            });
        } catch (error) {
            console.error('Error in getMyDanhGia:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy đánh giá của bạn',
                error: error.message
            });
        }
    },

    // Update review status (Admin only - for moderation)
    async updateReviewStatus(req, res) {
        try {
            const { id } = req.params;
            const { trang_thai } = req.body;
            
            if (!trang_thai || !['Đã duyệt', 'Chờ duyệt', 'Từ chối'].includes(trang_thai)) {
                return res.status(400).json({
                    success: false,
                    message: 'Trạng thái không hợp lệ. Chỉ chấp nhận: Đã duyệt, Chờ duyệt, Từ chối'
                });
            }

            const danhGia = new DanhGia();
            const review = await danhGia.findById(id);
            
            if (!review) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy đánh giá'
                });
            }

            // Update status
            await danhGia.update(id, { trang_thai });

            res.status(200).json({
                success: true,
                message: `Cập nhật trạng thái đánh giá thành "${trang_thai}"`,
                data: { id, trang_thai }
            });
        } catch (error) {
            console.error('Error in updateReviewStatus:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi cập nhật trạng thái đánh giá',
                error: error.message
            });
        }
    }
};

module.exports = danhgiaController;