const HoSo = require('../models/hoso');
const NguoiDung = require('../models/nguoidung');
const { validationResult } = require('express-validator');

const hosoController = {
    // Lấy tất cả hồ sơ (Admin only)
    async getAllHoSo(req, res) {
        try {
            const { page = 1, limit = 10, ma_nguoi_dung, trang_thai } = req.query;
            
            const hoSo = new HoSo();
            const filters = {};
            
            if (ma_nguoi_dung) filters.ma_nguoi_dung = ma_nguoi_dung;
            if (trang_thai) filters.trang_thai = trang_thai;

            const results = await hoSo.findAll(filters, parseInt(page), parseInt(limit));

            res.status(200).json({
                success: true,
                message: 'Lấy danh sách hồ sơ thành công',
                data: results
            });
        } catch (error) {
            console.error('Error in getAllHoSo:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy danh sách hồ sơ',
                error: error.message
            });
        }
    },

    // Lấy hồ sơ theo ID
    async getHoSoById(req, res) {
        try {
            const { id } = req.params;
            const hoSo = new HoSo();
            
            const profileQuery = `
                SELECT hs.*, nd.ho_ten, nd.email, nd.so_dien_thoai, nd.anh_dai_dien
                FROM ho_so hs
                INNER JOIN nguoi_dung nd ON hs.ma_nguoi_dung = nd.ma_nguoi_dung
                WHERE hs.ma_ho_so = @ma_ho_so AND hs.trang_thai = 1
            `;
            
            const result = await hoSo.executeQuery(profileQuery, { ma_ho_so: id });
            
            if (!result || result.length === 0) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy hồ sơ'
                });
            }

            // Kiểm tra quyền truy cập (chỉ chủ sở hữu hoặc Admin)
            if (req.user.vai_tro !== 'Admin' && result[0].ma_nguoi_dung !== req.user.ma_nguoi_dung) {
                return res.status(403).json({
                    success: false,
                    message: 'Bạn không có quyền xem hồ sơ này'
                });
            }

            res.status(200).json({
                success: true,
                message: 'Lấy thông tin hồ sơ thành công',
                data: result[0]
            });
        } catch (error) {
            console.error('Error in getHoSoById:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy thông tin hồ sơ',
                error: error.message
            });
        }
    },

    // Lấy hồ sơ của người dùng hiện tại
    async getMyHoSo(req, res) {
        try {
            const hoSo = new HoSo();
            
            const profileQuery = `
                SELECT hs.*, nd.ho_ten, nd.email, nd.so_dien_thoai, nd.anh_dai_dien
                FROM ho_so hs
                INNER JOIN nguoi_dung nd ON hs.ma_nguoi_dung = nd.ma_nguoi_dung
                WHERE hs.ma_nguoi_dung = @ma_nguoi_dung AND hs.trang_thai = 1
            `;
            
            const result = await hoSo.executeQuery(profileQuery, { 
                ma_nguoi_dung: req.user.ma_nguoi_dung 
            });
            
            if (!result || result.length === 0) {
                return res.status(404).json({
                    success: false,
                    message: 'Chưa có hồ sơ, vui lòng tạo hồ sơ mới'
                });
            }

            res.status(200).json({
                success: true,
                message: 'Lấy hồ sơ của bạn thành công',
                data: result[0]
            });
        } catch (error) {
            console.error('Error in getMyHoSo:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy hồ sơ của bạn',
                error: error.message
            });
        }
    },

    // Tạo hồ sơ mới
    async createHoSo(req, res) {
        try {
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                return res.status(400).json({
                    success: false,
                    message: 'Dữ liệu không hợp lệ',
                    errors: errors.array()
                });
            }

            const hoSo = new HoSo();
            
            // Kiểm tra người dùng đã có hồ sơ chưa
            const existingProfile = await hoSo.findByCondition({
                ma_nguoi_dung: req.user.ma_nguoi_dung,
                trang_thai: 1
            });

            if (existingProfile) {
                return res.status(400).json({
                    success: false,
                    message: 'Bạn đã có hồ sơ rồi, vui lòng cập nhật thay vì tạo mới'
                });
            }

            const newHoSo = await hoSo.create({
                ...req.body,
                ma_nguoi_dung: req.user.ma_nguoi_dung,
                ngay_tao: new Date(),
                trang_thai: 1
            });

            res.status(201).json({
                success: true,
                message: 'Tạo hồ sơ thành công',
                data: newHoSo
            });
        } catch (error) {
            console.error('Error in createHoSo:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi tạo hồ sơ',
                error: error.message
            });
        }
    },

    // Cập nhật hồ sơ
    async updateHoSo(req, res) {
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
            const hoSo = new HoSo();
            
            // Kiểm tra hồ sơ tồn tại
            const existingProfile = await hoSo.findById(id);
            if (!existingProfile) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy hồ sơ'
                });
            }

            // Kiểm tra quyền sở hữu (chỉ chủ sở hữu hoặc Admin)
            if (req.user.vai_tro !== 'Admin' && existingProfile.ma_nguoi_dung !== req.user.ma_nguoi_dung) {
                return res.status(403).json({
                    success: false,
                    message: 'Bạn không có quyền cập nhật hồ sơ này'
                });
            }

            const updated = await hoSo.update(id, {
                ...req.body,
                ngay_cap_nhat: new Date()
            });

            res.status(200).json({
                success: true,
                message: 'Cập nhật hồ sơ thành công',
                data: updated
            });
        } catch (error) {
            console.error('Error in updateHoSo:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi cập nhật hồ sơ',
                error: error.message
            });
        }
    },

    // Cập nhật hồ sơ của người dùng hiện tại
    async updateMyHoSo(req, res) {
        try {
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                return res.status(400).json({
                    success: false,
                    message: 'Dữ liệu không hợp lệ',
                    errors: errors.array()
                });
            }

            const hoSo = new HoSo();
            
            // Tìm hồ sơ của người dùng hiện tại
            const existingProfile = await hoSo.findByCondition({
                ma_nguoi_dung: req.user.ma_nguoi_dung,
                trang_thai: 1
            });

            if (!existingProfile) {
                return res.status(404).json({
                    success: false,
                    message: 'Chưa có hồ sơ, vui lòng tạo hồ sơ mới'
                });
            }

            const updated = await hoSo.update(existingProfile.ma_ho_so, {
                ...req.body,
                ngay_cap_nhat: new Date()
            });

            res.status(200).json({
                success: true,
                message: 'Cập nhật hồ sơ thành công',
                data: updated
            });
        } catch (error) {
            console.error('Error in updateMyHoSo:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi cập nhật hồ sơ',
                error: error.message
            });
        }
    },

    // Xóa hồ sơ (Admin only)
    async deleteHoSo(req, res) {
        try {
            const { id } = req.params;
            const hoSo = new HoSo();
            
            const deleted = await hoSo.update(id, { 
                trang_thai: 0,
                ngay_cap_nhat: new Date()
            });
            
            if (!deleted) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy hồ sơ để xóa'
                });
            }

            res.status(200).json({
                success: true,
                message: 'Xóa hồ sơ thành công'
            });
        } catch (error) {
            console.error('Error in deleteHoSo:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi xóa hồ sơ',
                error: error.message
            });
        }
    },

    // Lấy thống kê hồ sơ (Admin only)
    async getHoSoStats(req, res) {
        try {
            const hoSo = new HoSo();
            
            const statsQuery = `
                SELECT 
                    COUNT(*) as tong_ho_so,
                    COUNT(CASE WHEN trang_thai = 1 THEN 1 END) as ho_so_hoat_dong,
                    COUNT(CASE WHEN trang_thai = 0 THEN 1 END) as ho_so_bi_xoa,
                    COUNT(CASE WHEN gioi_tinh = N'Nam' THEN 1 END) as nam,
                    COUNT(CASE WHEN gioi_tinh = N'Nữ' THEN 1 END) as nu,
                    COUNT(CASE WHEN DATEDIFF(YEAR, ngay_sinh, GETDATE()) BETWEEN 18 AND 25 THEN 1 END) as tuoi_18_25,
                    COUNT(CASE WHEN DATEDIFF(YEAR, ngay_sinh, GETDATE()) BETWEEN 26 AND 35 THEN 1 END) as tuoi_26_35,
                    COUNT(CASE WHEN DATEDIFF(YEAR, ngay_sinh, GETDATE()) BETWEEN 36 AND 50 THEN 1 END) as tuoi_36_50,
                    COUNT(CASE WHEN DATEDIFF(YEAR, ngay_sinh, GETDATE()) > 50 THEN 1 END) as tuoi_tren_50
                FROM ho_so
            `;
            
            const stats = await hoSo.executeQuery(statsQuery);

            res.status(200).json({
                success: true,
                message: 'Lấy thống kê hồ sơ thành công',
                data: stats[0]
            });
        } catch (error) {
            console.error('Error in getHoSoStats:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy thống kê hồ sơ',
                error: error.message
            });
        }
    },

    // Tìm kiếm hồ sơ (Admin only)
    async searchHoSo(req, res) {
        try {
            const { keyword, gioi_tinh, tu_tuoi, den_tuoi, page = 1, limit = 10 } = req.query;
            
            const hoSo = new HoSo();
            let searchQuery = `
                SELECT hs.*, nd.ho_ten, nd.email, nd.so_dien_thoai
                FROM ho_so hs
                INNER JOIN nguoi_dung nd ON hs.ma_nguoi_dung = nd.ma_nguoi_dung
                WHERE hs.trang_thai = 1
            `;
            
            const params = {};

            if (keyword) {
                searchQuery += ` AND (nd.ho_ten LIKE @keyword OR hs.cmnd_cccd LIKE @keyword)`;
                params.keyword = `%${keyword}%`;
            }

            if (gioi_tinh) {
                searchQuery += ` AND hs.gioi_tinh = @gioi_tinh`;
                params.gioi_tinh = gioi_tinh;
            }

            if (tu_tuoi) {
                searchQuery += ` AND DATEDIFF(YEAR, hs.ngay_sinh, GETDATE()) >= @tu_tuoi`;
                params.tu_tuoi = parseInt(tu_tuoi);
            }

            if (den_tuoi) {
                searchQuery += ` AND DATEDIFF(YEAR, hs.ngay_sinh, GETDATE()) <= @den_tuoi`;
                params.den_tuoi = parseInt(den_tuoi);
            }

            searchQuery += ` ORDER BY hs.ngay_tao DESC OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY`;
            
            const offset = (parseInt(page) - 1) * parseInt(limit);
            params.offset = offset;
            params.limit = parseInt(limit);

            const results = await hoSo.executeQuery(searchQuery, params);

            res.status(200).json({
                success: true,
                message: 'Tìm kiếm hồ sơ thành công',
                data: {
                    profiles: results,
                    pagination: {
                        page: parseInt(page),
                        limit: parseInt(limit)
                    }
                }
            });
        } catch (error) {
            console.error('Error in searchHoSo:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi tìm kiếm hồ sơ',
                error: error.message
            });
        }
    }
};

module.exports = hosoController;