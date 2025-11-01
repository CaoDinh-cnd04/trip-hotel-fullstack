const ViTri = require('../models/vitri');
const { validationResult } = require('express-validator');

// Helper function to transform location image URLs
const transformLocationImageUrl = (imagePath) => {
    if (!imagePath) return null;
    const baseUrl = process.env.BASE_URL || 'http://localhost:5000';
    
    if (imagePath.startsWith('http')) return imagePath;
    if (imagePath.startsWith('/')) return `${baseUrl}${imagePath}`;
    
    return `${baseUrl}/images/provinces/${imagePath}`;
};

const vitriController = {
    // Lấy tất cả vị trí
    async getAllViTri(req, res) {
        try {
            const { ma_tinh_thanh, ma_quoc_gia, page = 1, limit = 10 } = req.query;
            
            const viTri = new ViTri();
            let results;

            if (ma_tinh_thanh) {
                results = await viTri.getViTriByTinhThanh(ma_tinh_thanh);
            } else if (ma_quoc_gia) {
                results = await viTri.getViTriByQuocGia(ma_quoc_gia);
            } else {
                results = await viTri.findAll({
                    trang_thai: 1
                }, parseInt(page), parseInt(limit));
            }

            // Transform image URLs
            const transformedResults = Array.isArray(results) 
                ? results.map(loc => ({
                    ...loc,
                    hinh_anh: transformLocationImageUrl(loc.hinh_anh)
                  }))
                : results;

            res.status(200).json({
                success: true,
                message: 'Lấy danh sách vị trí thành công',
                data: transformedResults
            });
        } catch (error) {
            console.error('Error in getAllViTri:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy danh sách vị trí',
                error: error.message
            });
        }
    },

    // Lấy vị trí theo ID
    async getViTriById(req, res) {
        try {
            const { id } = req.params;
            const viTri = new ViTri();
            
            const result = await viTri.getViTriWithStats(id);
            
            if (!result) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy vị trí'
                });
            }

            // Transform image URL
            result.hinh_anh = transformLocationImageUrl(result.hinh_anh);

            res.status(200).json({
                success: true,
                message: 'Lấy thông tin vị trí thành công',
                data: result
            });
        } catch (error) {
            console.error('Error in getViTriById:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy thông tin vị trí',
                error: error.message
            });
        }
    },

    // Tìm kiếm vị trí
    async searchViTri(req, res) {
        try {
            const { keyword, ma_tinh_thanh, ma_quoc_gia } = req.query;
            const viTri = new ViTri();
            
            const results = await viTri.searchViTri(keyword, ma_tinh_thanh, ma_quoc_gia);

            // Transform image URLs
            const transformedResults = Array.isArray(results) 
                ? results.map(loc => ({
                    ...loc,
                    hinh_anh: transformLocationImageUrl(loc.hinh_anh)
                  }))
                : results;

            res.status(200).json({
                success: true,
                message: 'Tìm kiếm vị trí thành công',
                data: transformedResults
            });
        } catch (error) {
            console.error('Error in searchViTri:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi tìm kiếm vị trí',
                error: error.message
            });
        }
    },

    // Tạo vị trí mới
    async createViTri(req, res) {
        try {
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                return res.status(400).json({
                    success: false,
                    message: 'Dữ liệu không hợp lệ',
                    errors: errors.array()
                });
            }

            const viTri = new ViTri();
            const newViTri = await viTri.create(req.body);

            res.status(201).json({
                success: true,
                message: 'Tạo vị trí thành công',
                data: newViTri
            });
        } catch (error) {
            console.error('Error in createViTri:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi tạo vị trí',
                error: error.message
            });
        }
    },

    // Cập nhật vị trí
    async updateViTri(req, res) {
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
            const viTri = new ViTri();
            
            const updated = await viTri.update(id, req.body);
            
            if (!updated) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy vị trí để cập nhật'
                });
            }

            res.status(200).json({
                success: true,
                message: 'Cập nhật vị trí thành công',
                data: updated
            });
        } catch (error) {
            console.error('Error in updateViTri:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi cập nhật vị trí',
                error: error.message
            });
        }
    },

    // Xóa vị trí
    async deleteViTri(req, res) {
        try {
            const { id } = req.params;
            const viTri = new ViTri();
            
            const deleted = await viTri.update(id, { trang_thai: 0 });
            
            if (!deleted) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy vị trí để xóa'
                });
            }

            res.status(200).json({
                success: true,
                message: 'Xóa vị trí thành công'
            });
        } catch (error) {
            console.error('Error in deleteViTri:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi xóa vị trí',
                error: error.message
            });
        }
    }
};

module.exports = vitriController;