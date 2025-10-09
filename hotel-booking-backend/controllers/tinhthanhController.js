const TinhThanh = require('../models/tinhthanh');
const { validationResult } = require('express-validator');

const tinhthanhController = {
    // Lấy tất cả tỉnh thành
    async getAllTinhThanh(req, res) {
        try {
            const { ma_quoc_gia, page = 1, limit = 10 } = req.query;
            
            const tinhThanh = new TinhThanh();
            let results;

            if (ma_quoc_gia) {
                results = await tinhThanh.getTinhThanhByQuocGia(ma_quoc_gia);
            } else {
                results = await tinhThanh.findAll({
                    trang_thai: 1
                }, parseInt(page), parseInt(limit));
            }

            res.status(200).json({
                success: true,
                message: 'Lấy danh sách tỉnh thành thành công',
                data: results,
                pagination: {
                    page: parseInt(page),
                    limit: parseInt(limit)
                }
            });
        } catch (error) {
            console.error('Error in getAllTinhThanh:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy danh sách tỉnh thành',
                error: error.message
            });
        }
    },

    // Lấy tỉnh thành theo ID
    async getTinhThanhById(req, res) {
        try {
            const { id } = req.params;
            const tinhThanh = new TinhThanh();
            
            const result = await tinhThanh.getTinhThanhWithStats(id);
            
            if (!result) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy tỉnh thành'
                });
            }

            res.status(200).json({
                success: true,
                message: 'Lấy thông tin tỉnh thành thành công',
                data: result
            });
        } catch (error) {
            console.error('Error in getTinhThanhById:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy thông tin tỉnh thành',
                error: error.message
            });
        }
    },

    // Tìm kiếm tỉnh thành
    async searchTinhThanh(req, res) {
        try {
            const { keyword, ma_quoc_gia } = req.query;
            const tinhThanh = new TinhThanh();
            
            const results = await tinhThanh.searchTinhThanh(keyword, ma_quoc_gia);

            res.status(200).json({
                success: true,
                message: 'Tìm kiếm tỉnh thành thành công',
                data: results
            });
        } catch (error) {
            console.error('Error in searchTinhThanh:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi tìm kiếm tỉnh thành',
                error: error.message
            });
        }
    },

    // Lấy tỉnh thành phổ biến
    async getPopularTinhThanh(req, res) {
        try {
            const { limit = 10 } = req.query;
            const tinhThanh = new TinhThanh();
            
            const results = await tinhThanh.getPopularTinhThanh(parseInt(limit));

            res.status(200).json({
                success: true,
                message: 'Lấy danh sách tỉnh thành phổ biến thành công',
                data: results
            });
        } catch (error) {
            console.error('Error in getPopularTinhThanh:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy tỉnh thành phổ biến',
                error: error.message
            });
        }
    },

    // Tạo tỉnh thành mới
    async createTinhThanh(req, res) {
        try {
            // Kiểm tra validation errors
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                return res.status(400).json({
                    success: false,
                    message: 'Dữ liệu không hợp lệ',
                    errors: errors.array()
                });
            }

            const tinhThanh = new TinhThanh();
            const newTinhThanh = await tinhThanh.create(req.body);

            res.status(201).json({
                success: true,
                message: 'Tạo tỉnh thành thành công',
                data: newTinhThanh
            });
        } catch (error) {
            console.error('Error in createTinhThanh:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi tạo tỉnh thành',
                error: error.message
            });
        }
    },

    // Cập nhật tỉnh thành
    async updateTinhThanh(req, res) {
        try {
            // Kiểm tra validation errors
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                return res.status(400).json({
                    success: false,
                    message: 'Dữ liệu không hợp lệ',
                    errors: errors.array()
                });
            }

            const { id } = req.params;
            const tinhThanh = new TinhThanh();
            
            const updated = await tinhThanh.update(id, req.body);
            
            if (!updated) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy tỉnh thành để cập nhật'
                });
            }

            res.status(200).json({
                success: true,
                message: 'Cập nhật tỉnh thành thành công',
                data: updated
            });
        } catch (error) {
            console.error('Error in updateTinhThanh:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi cập nhật tỉnh thành',
                error: error.message
            });
        }
    },

    // Xóa tỉnh thành (soft delete)
    async deleteTinhThanh(req, res) {
        try {
            const { id } = req.params;
            const tinhThanh = new TinhThanh();
            
            // Soft delete by setting trang_thai = 0
            const deleted = await tinhThanh.update(id, { trang_thai: 0 });
            
            if (!deleted) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy tỉnh thành để xóa'
                });
            }

            res.status(200).json({
                success: true,
                message: 'Xóa tỉnh thành thành công'
            });
        } catch (error) {
            console.error('Error in deleteTinhThanh:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi xóa tỉnh thành',
                error: error.message
            });
        }
    }
};

module.exports = tinhthanhController;