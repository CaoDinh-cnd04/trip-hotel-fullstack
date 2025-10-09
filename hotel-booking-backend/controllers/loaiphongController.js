const LoaiPhong = require('../models/loaiphong');
const { validationResult } = require('express-validator');

const loaiphongController = {
    // Lấy tất cả loại phòng
    async getAllLoaiPhong(req, res) {
        try {
            const { ma_khach_san, page = 1, limit = 10 } = req.query;
            
            const loaiPhong = new LoaiPhong();
            let results;

            if (ma_khach_san) {
                results = await loaiPhong.getLoaiPhongByKhachSan(ma_khach_san);
            } else {
                results = await loaiPhong.findAll({
                    trang_thai: 1
                }, parseInt(page), parseInt(limit));
            }

            res.status(200).json({
                success: true,
                message: 'Lấy danh sách loại phòng thành công',
                data: results
            });
        } catch (error) {
            console.error('Error in getAllLoaiPhong:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy danh sách loại phòng',
                error: error.message
            });
        }
    },

    // Lấy loại phòng theo ID với chi tiết
    async getLoaiPhongById(req, res) {
        try {
            const { id } = req.params;
            const loaiPhong = new LoaiPhong();
            
            const result = await loaiPhong.getLoaiPhongWithDetails(id);
            
            if (!result) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy loại phòng'
                });
            }

            res.status(200).json({
                success: true,
                message: 'Lấy thông tin loại phòng thành công',
                data: result
            });
        } catch (error) {
            console.error('Error in getLoaiPhongById:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy thông tin loại phòng',
                error: error.message
            });
        }
    },

    // Lấy loại phòng theo khách sạn
    async getLoaiPhongByKhachSan(req, res) {
        try {
            const { ma_khach_san } = req.params;
            const loaiPhong = new LoaiPhong();
            
            const results = await loaiPhong.getLoaiPhongByKhachSan(ma_khach_san);

            res.status(200).json({
                success: true,
                message: 'Lấy loại phòng khách sạn thành công',
                data: results
            });
        } catch (error) {
            console.error('Error in getLoaiPhongByKhachSan:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy loại phòng khách sạn',
                error: error.message
            });
        }
    },

    // Tạo loại phòng mới
    async createLoaiPhong(req, res) {
        try {
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                return res.status(400).json({
                    success: false,
                    message: 'Dữ liệu không hợp lệ',
                    errors: errors.array()
                });
            }

            const loaiPhong = new LoaiPhong();
            const newLoaiPhong = await loaiPhong.create(req.body);

            res.status(201).json({
                success: true,
                message: 'Tạo loại phòng thành công',
                data: newLoaiPhong
            });
        } catch (error) {
            console.error('Error in createLoaiPhong:', error);
            res.status(500).json({
                success: false,
                message: error.message || 'Lỗi server khi tạo loại phòng',
                error: error.message
            });
        }
    },

    // Cập nhật loại phòng
    async updateLoaiPhong(req, res) {
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
            const loaiPhong = new LoaiPhong();
            
            const updated = await loaiPhong.update(id, req.body);
            
            if (!updated) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy loại phòng để cập nhật'
                });
            }

            res.status(200).json({
                success: true,
                message: 'Cập nhật loại phòng thành công',
                data: updated
            });
        } catch (error) {
            console.error('Error in updateLoaiPhong:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi cập nhật loại phòng',
                error: error.message
            });
        }
    },

    // Xóa loại phòng
    async deleteLoaiPhong(req, res) {
        try {
            const { id } = req.params;
            const loaiPhong = new LoaiPhong();
            
            const deleted = await loaiPhong.update(id, { trang_thai: 0 });
            
            if (!deleted) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy loại phòng để xóa'
                });
            }

            res.status(200).json({
                success: true,
                message: 'Xóa loại phòng thành công'
            });
        } catch (error) {
            console.error('Error in deleteLoaiPhong:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi xóa loại phòng',
                error: error.message
            });
        }
    }
};

module.exports = loaiphongController;