const KhuyenMai = require('../models/khuyenmai');
const { validationResult } = require('express-validator');

const khuyenmaiController = {
    // Lấy tất cả khuyến mãi
    async getAllKhuyenMai(req, res) {
        try {
            const { page = 1, limit = 10, active, active_only, ma_khach_san } = req.query;
            const { getPool } = require('../config/db');
            const pool = getPool();
            
            // JOIN with khach_san to get location info
            const query = `
                SELECT 
                    km.*,
                    ks.ten as ten_khach_san,
                    ks.dia_chi,
                    vt.tinh_thanh_id,
                    tt.ten as ten_tinh_thanh,
                    vt.ten as ten_vi_tri,
                    ks.hinh_anh as hotel_image
                FROM khuyen_mai km
                LEFT JOIN khach_san ks ON km.khach_san_id = ks.id
                LEFT JOIN vi_tri vt ON ks.vi_tri_id = vt.id
                LEFT JOIN tinh_thanh tt ON vt.tinh_thanh_id = tt.id
            `;
            
            const result = await pool.request().query(query);
            let filteredResults = result.recordset;
            
            // Support both 'active' and 'active_only' parameters
            const shouldFilterActive = active === 'true' || active_only === 'true';
            
            if (shouldFilterActive) {
                const now = new Date();
                filteredResults = filteredResults.filter(km => {
                    // Support both boolean and integer for trang_thai
                    const isActive = km.trang_thai === true || km.trang_thai === 1;
                    const startDate = new Date(km.ngay_bat_dau);
                    const endDate = new Date(km.ngay_ket_thuc);
                    
                    return isActive && startDate <= now && endDate >= now;
                });
            }
            
            if (ma_khach_san) {
                filteredResults = filteredResults.filter(km => 
                    km.khach_san_id == ma_khach_san
                );
            }

            // Pagination
            const startIndex = (parseInt(page) - 1) * parseInt(limit);
            const endIndex = startIndex + parseInt(limit);
            const paginatedResults = filteredResults.slice(startIndex, endIndex);

            console.log(`✅ Retrieved ${paginatedResults.length} promotions (active filter: ${shouldFilterActive})`);

            // Map database fields to Flutter-friendly format
            const mappedResults = paginatedResults.map(km => ({
                ...km,
                phan_tram_giam: km.phan_tram, // Add Flutter-expected field
                location: km.ten_vi_tri || km.ten_tinh_thanh || 'Việt Nam', // Location for display (prioritize vi_tri)
                hotel_name: km.ten_khach_san,
                hotel_address: km.dia_chi,
                image: km.hotel_image
            }));

            res.status(200).json({
                success: true,
                message: 'Lấy danh sách khuyến mãi thành công',
                data: mappedResults,
                pagination: {
                    page: parseInt(page),
                    limit: parseInt(limit),
                    total: filteredResults.length,
                    totalPages: Math.ceil(filteredResults.length / parseInt(limit))
                }
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
            
            KhuyenMai.getById(id, (error, results) => {
                if (error) {
                    console.error('Error in getKhuyenMaiById:', error);
                    return res.status(500).json({
                        success: false,
                        message: 'Lỗi server khi lấy thông tin khuyến mãi',
                        error: error.message
                    });
                }
                
                if (!results || results.length === 0) {
                    return res.status(404).json({
                        success: false,
                        message: 'Không tìm thấy khuyến mãi'
                    });
                }

                res.status(200).json({
                    success: true,
                    message: 'Lấy thông tin khuyến mãi thành công',
                    data: results[0]
                });
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
            
            // Sử dụng KhuyenMai object để lấy tất cả khuyến mãi
            KhuyenMai.getAll((error, results) => {
                if (error) {
                    console.error('Error in getActivePromotions:', error);
                    return res.status(500).json({
                        success: false,
                        message: 'Lỗi server khi lấy khuyến mãi đang hoạt động',
                        error: error.message
                    });
                }

                // Filter active promotions
                const now = new Date();
                let activePromotions = results.filter(km => {
                    const isActive = km.trang_thai === true || km.trang_thai === 1;
                    const startDate = new Date(km.ngay_bat_dau);
                    const endDate = new Date(km.ngay_ket_thuc);
                    return isActive && startDate <= now && endDate >= now;
                });

                // Filter by hotel if specified
                if (ma_khach_san) {
                    activePromotions = activePromotions.filter(km => 
                        km.khach_san_id == ma_khach_san
                    );
                }

                // Sort by discount percentage
                activePromotions.sort((a, b) => (b.phan_tram || 0) - (a.phan_tram || 0));

                // Map to Flutter-friendly format
                const mappedPromotions = activePromotions.map(km => ({
                    ...km,
                    phan_tram_giam: km.phan_tram,
                }));

                res.status(200).json({
                    success: true,
                    message: 'Lấy khuyến mãi đang hoạt động thành công',
                    data: mappedPromotions
                });
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

            KhuyenMai.create({
                ...req.body,
                ngay_tao: new Date(),
                trang_thai: 1
            }, (error, newKhuyenMai) => {
                if (error) {
                    console.error('Error in createKhuyenMai:', error);
                    return res.status(500).json({
                        success: false,
                        message: 'Lỗi server khi tạo khuyến mãi',
                        error: error.message
                    });
                }

                res.status(201).json({
                    success: true,
                    message: 'Tạo khuyến mãi thành công',
                    data: newKhuyenMai
                });
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
            
            KhuyenMai.update(id, {
                ...req.body,
                ngay_cap_nhat: new Date()
            }, (error, updated) => {
                if (error) {
                    console.error('Error in updateKhuyenMai:', error);
                    return res.status(500).json({
                        success: false,
                        message: 'Lỗi server khi cập nhật khuyến mãi',
                        error: error.message
                    });
                }
                
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

    // Kiểm tra khuyến mãi có thể áp dụng
    async validatePromotion(req, res) {
        try {
            const { id } = req.params;
            const { tong_tien } = req.query;
            
            KhuyenMai.getById(id, (error, results) => {
                if (error) {
                    console.error('Error in validatePromotion:', error);
                    return res.status(500).json({
                        success: false,
                        message: 'Lỗi server khi kiểm tra khuyến mãi',
                        error: error.message
                    });
                }

                if (!results || results.length === 0) {
                    return res.status(404).json({
                        success: false,
                        message: 'Không tìm thấy khuyến mãi'
                    });
                }

                const promotion = results[0];
                const currentDate = new Date();
                // Hỗ trợ cả boolean và number cho trang_thai
                const isActive = promotion.trang_thai === true || 
                                promotion.trang_thai === 1 || 
                                promotion.trang_thai === '1';
                const isValid = isActive &&
                               new Date(promotion.ngay_bat_dau) <= currentDate &&
                               new Date(promotion.ngay_ket_thuc) >= currentDate;

                let discountAmount = 0;
                if (isValid && tong_tien) {
                    // Use phan_tram field from database
                    discountAmount = (parseFloat(tong_tien) * promotion.phan_tram) / 100;
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
            
            KhuyenMai.update(id, { 
                trang_thai: 0,
                ngay_cap_nhat: new Date()
            }, (error, deleted) => {
                if (error) {
                    console.error('Error in deleteKhuyenMai:', error);
                    return res.status(500).json({
                        success: false,
                        message: 'Lỗi server khi xóa khuyến mãi',
                        error: error.message
                    });
                }
                
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
            
            KhuyenMai.getById(id, (error, results) => {
                if (error) {
                    console.error('Error in toggleKhuyenMai:', error);
                    return res.status(500).json({
                        success: false,
                        message: 'Lỗi server khi thay đổi trạng thái khuyến mãi',
                        error: error.message
                    });
                }

                if (!results || results.length === 0) {
                    return res.status(404).json({
                        success: false,
                        message: 'Không tìm thấy khuyến mãi'
                    });
                }

                const existing = results[0];
                const newStatus = existing.trang_thai === 1 ? 0 : 1;
                
                KhuyenMai.update(id, { 
                    trang_thai: newStatus,
                    ngay_cap_nhat: new Date()
                }, (updateError, updated) => {
                    if (updateError) {
                        console.error('Error updating status:', updateError);
                        return res.status(500).json({
                            success: false,
                            message: 'Lỗi server khi thay đổi trạng thái khuyến mãi',
                            error: updateError.message
                        });
                    }

                    res.status(200).json({
                        success: true,
                        message: `${newStatus === 1 ? 'Kích hoạt' : 'Vô hiệu hóa'} khuyến mãi thành công`,
                        data: updated
                    });
                });
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