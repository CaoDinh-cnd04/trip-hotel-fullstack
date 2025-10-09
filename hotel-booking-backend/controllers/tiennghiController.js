const TienNghi = require('../models/tiennghi');
const { validationResult } = require('express-validator');

const tiennghiController = {
    // Lấy tất cả tiện nghi
    async getAllTienNghi(req, res) {
        try {
            const { loai_tien_nghi, page = 1, limit = 10 } = req.query;
            
            const tienNghi = new TienNghi();
            let results;

            if (loai_tien_nghi) {
                results = await tienNghi.getTienNghiByType(loai_tien_nghi);
            } else {
                results = await tienNghi.findAll({
                    trang_thai: 1
                }, parseInt(page), parseInt(limit));
            }

            res.status(200).json({
                success: true,
                message: 'Lấy danh sách tiện nghi thành công',
                data: results
            });
        } catch (error) {
            console.error('Error in getAllTienNghi:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy danh sách tiện nghi',
                error: error.message
            });
        }
    },

    // Lấy tiện nghi theo ID
    async getTienNghiById(req, res) {
        try {
            const { id } = req.params;
            const tienNghi = new TienNghi();
            
            const result = await tienNghi.findById(id);
            
            if (!result) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy tiện nghi'
                });
            }

            res.status(200).json({
                success: true,
                message: 'Lấy thông tin tiện nghi thành công',
                data: result
            });
        } catch (error) {
            console.error('Error in getTienNghiById:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy thông tin tiện nghi',
                error: error.message
            });
        }
    },

    // Tìm kiếm tiện nghi
    async searchTienNghi(req, res) {
        try {
            const { keyword } = req.query;
            const tienNghi = new TienNghi();
            
            const results = await tienNghi.searchTienNghi(keyword);

            res.status(200).json({
                success: true,
                message: 'Tìm kiếm tiện nghi thành công',
                data: results
            });
        } catch (error) {
            console.error('Error in searchTienNghi:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi tìm kiếm tiện nghi',
                error: error.message
            });
        }
    },

    // Lấy tiện nghi của khách sạn
    async getTienNghiByKhachSan(req, res) {
        try {
            const { ma_khach_san } = req.params;
            const tienNghi = new TienNghi();
            
            const results = await tienNghi.getTienNghiByKhachSan(ma_khach_san);

            res.status(200).json({
                success: true,
                message: 'Lấy tiện nghi khách sạn thành công',
                data: results
            });
        } catch (error) {
            console.error('Error in getTienNghiByKhachSan:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy tiện nghi khách sạn',
                error: error.message
            });
        }
    },

    // Tạo tiện nghi mới
    async createTienNghi(req, res) {
        try {
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                return res.status(400).json({
                    success: false,
                    message: 'Dữ liệu không hợp lệ',
                    errors: errors.array()
                });
            }

            const tienNghi = new TienNghi();
            const newTienNghi = await tienNghi.create(req.body);

            res.status(201).json({
                success: true,
                message: 'Tạo tiện nghi thành công',
                data: newTienNghi
            });
        } catch (error) {
            console.error('Error in createTienNghi:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi tạo tiện nghi',
                error: error.message
            });
        }
    },

    // Cập nhật tiện nghi
    async updateTienNghi(req, res) {
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
            const tienNghi = new TienNghi();
            
            const updated = await tienNghi.update(id, req.body);
            
            if (!updated) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy tiện nghi để cập nhật'
                });
            }

            res.status(200).json({
                success: true,
                message: 'Cập nhật tiện nghi thành công',
                data: updated
            });
        } catch (error) {
            console.error('Error in updateTienNghi:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi cập nhật tiện nghi',
                error: error.message
            });
        }
    },

    // Xóa tiện nghi
    async deleteTienNghi(req, res) {
        try {
            const { id } = req.params;
            const tienNghi = new TienNghi();
            
            const deleted = await tienNghi.update(id, { trang_thai: 0 });
            
            if (!deleted) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy tiện nghi để xóa'
                });
            }

            res.status(200).json({
                success: true,
                message: 'Xóa tiện nghi thành công'
            });
        } catch (error) {
            console.error('Error in deleteTienNghi:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi xóa tiện nghi',
                error: error.message
            });
        }
    }
};

module.exports = tiennghiController;