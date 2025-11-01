const NguoiDung = require('../models/nguoidung');
const { validationResult } = require('express-validator');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const nguoidungController = {
    // Lấy tất cả người dùng (Admin only)
    async getAllUsers(req, res) {
        try {
            const { page = 1, limit = 10, vai_tro, trang_thai } = req.query;
            
            const nguoiDung = new NguoiDung();
            const filters = {};
            
            if (vai_tro) filters.vai_tro = vai_tro;
            if (trang_thai) filters.trang_thai = trang_thai;

            const results = await nguoiDung.findAll(filters, parseInt(page), parseInt(limit));

            res.status(200).json({
                success: true,
                message: 'Lấy danh sách người dùng thành công',
                data: results
            });
        } catch (error) {
            console.error('Error in getAllUsers:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy danh sách người dùng',
                error: error.message
            });
        }
    },

    // Lấy thông tin người dùng theo ID
    async getUserById(req, res) {
        try {
            const { id } = req.params;
            const nguoiDung = new NguoiDung();
            
            const user = await nguoiDung.findById(id);
            
            if (!user) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy người dùng'
                });
            }

            // Kiểm tra quyền xem (chỉ Admin hoặc chính user đó)
            if (req.user.vai_tro !== 'Admin' && req.user.ma_nguoi_dung !== parseInt(id)) {
                return res.status(403).json({
                    success: false,
                    message: 'Bạn không có quyền xem thông tin này'
                });
            }

            // Không trả về mật khẩu
            delete user.mat_khau;

            res.status(200).json({
                success: true,
                message: 'Lấy thông tin người dùng thành công',
                data: user
            });
        } catch (error) {
            console.error('Error in getUserById:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy thông tin người dùng',
                error: error.message
            });
        }
    },

    // Đăng ký người dùng mới
    async register(req, res) {
        try {
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                return res.status(400).json({
                    success: false,
                    message: 'Dữ liệu không hợp lệ',
                    errors: errors.array()
                });
            }

            const { ho_ten, email, mat_khau, so_dien_thoai, vai_tro = 'Customer' } = req.body;
            const nguoiDung = new NguoiDung();
            
            // Kiểm tra email đã tồn tại
            const existingUser = await nguoiDung.findByCondition({ email });
            if (existingUser) {
                return res.status(400).json({
                    success: false,
                    message: 'Email đã được sử dụng'
                });
            }

            // Mã hóa mật khẩu
            const saltRounds = 10;
            const hashedPassword = await bcrypt.hash(mat_khau, saltRounds);

            // Tạo người dùng mới
            const userData = {
                ho_ten,
                email,
                mat_khau: hashedPassword,
                so_dien_thoai,
                vai_tro,
                ngay_tao: new Date(),
                trang_thai: 1,
                anh_dai_dien: req.file ? `/uploads/${req.file.filename}` : null
            };

            const newUser = await nguoiDung.create(userData);

            // Tạo JWT token
            const token = jwt.sign(
                { 
                    ma_nguoi_dung: newUser.ma_nguoi_dung,
                    email: newUser.email,
                    vai_tro: newUser.vai_tro
                },
                process.env.JWT_SECRET,
                { expiresIn: '7d' }
            );

            // Không trả về mật khẩu
            delete newUser.mat_khau;

            res.status(201).json({
                success: true,
                message: 'Đăng ký thành công',
                data: {
                    user: newUser,
                    token
                }
            });
        } catch (error) {
            console.error('Error in register:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi đăng ký',
                error: error.message
            });
        }
    },

    // Cập nhật thông tin người dùng
    async updateUser(req, res) {
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
            const nguoiDung = new NguoiDung();
            
            // Kiểm tra người dùng tồn tại
            const existingUser = await nguoiDung.findById(id);
            if (!existingUser) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy người dùng'
                });
            }

            // Kiểm tra quyền cập nhật
            if (req.user.vai_tro !== 'Admin' && req.user.ma_nguoi_dung !== parseInt(id)) {
                return res.status(403).json({
                    success: false,
                    message: 'Bạn không có quyền cập nhật thông tin này'
                });
            }

            const updateData = { ...req.body };
            
            // Xử lý mật khẩu nếu có
            if (updateData.mat_khau) {
                const saltRounds = 10;
                updateData.mat_khau = await bcrypt.hash(updateData.mat_khau, saltRounds);
            }

            // Xử lý ảnh đại diện
            if (req.file) {
                updateData.anh_dai_dien = `/uploads/${req.file.filename}`;
            }

            updateData.ngay_cap_nhat = new Date();

            const updatedUser = await nguoiDung.update(id, updateData);
            
            // Không trả về mật khẩu
            delete updatedUser.mat_khau;

            res.status(200).json({
                success: true,
                message: 'Cập nhật thông tin thành công',
                data: updatedUser
            });
        } catch (error) {
            console.error('Error in updateUser:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi cập nhật thông tin',
                error: error.message
            });
        }
    },

    // Xóa người dùng (Admin only)
    async deleteUser(req, res) {
        try {
            const { id } = req.params;
            const nguoiDung = new NguoiDung();
            
            const deleted = await nguoiDung.update(id, { 
                trang_thai: 0,
                ngay_cap_nhat: new Date()
            });
            
            if (!deleted) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy người dùng để xóa'
                });
            }

            res.status(200).json({
                success: true,
                message: 'Xóa người dùng thành công'
            });
        } catch (error) {
            console.error('Error in deleteUser:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi xóa người dùng',
                error: error.message
            });
        }
    },

    // Lấy profile của người dùng hiện tại
    async getMyProfile(req, res) {
        try {
            const nguoiDung = new NguoiDung();
            const user = await nguoiDung.findById(req.user.ma_nguoi_dung);
            
            if (!user) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy thông tin người dùng'
                });
            }

            // Không trả về mật khẩu
            delete user.mat_khau;

            res.status(200).json({
                success: true,
                message: 'Lấy thông tin profile thành công',
                data: user
            });
        } catch (error) {
            console.error('Error in getMyProfile:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy thông tin profile',
                error: error.message
            });
        }
    },

    // Cập nhật profile của người dùng hiện tại
    async updateMyProfile(req, res) {
        try {
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                return res.status(400).json({
                    success: false,
                    message: 'Dữ liệu không hợp lệ',
                    errors: errors.array()
                });
            }

            const nguoiDung = new NguoiDung();
            const updateData = { ...req.body };
            
            // Xử lý mật khẩu nếu có
            if (updateData.mat_khau) {
                const saltRounds = 10;
                updateData.mat_khau = await bcrypt.hash(updateData.mat_khau, saltRounds);
            }

            // Xử lý ảnh đại diện
            if (req.file) {
                updateData.anh_dai_dien = `/uploads/${req.file.filename}`;
            }

            updateData.ngay_cap_nhat = new Date();

            const updatedUser = await nguoiDung.update(req.user.ma_nguoi_dung, updateData);
            
            // Không trả về mật khẩu
            delete updatedUser.mat_khau;

            res.status(200).json({
                success: true,
                message: 'Cập nhật profile thành công',
                data: updatedUser
            });
        } catch (error) {
            console.error('Error in updateMyProfile:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi cập nhật profile',
                error: error.message
            });
        }
    },

    // Đổi mật khẩu
    async changePassword(req, res) {
        try {
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                return res.status(400).json({
                    success: false,
                    message: 'Dữ liệu không hợp lệ',
                    errors: errors.array()
                });
            }

            const { mat_khau_cu, mat_khau_moi } = req.body;
            const nguoiDung = new NguoiDung();
            
            // Lấy thông tin người dùng
            const user = await nguoiDung.findById(req.user.ma_nguoi_dung);
            if (!user) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy người dùng'
                });
            }

            // Kiểm tra mật khẩu cũ
            const isValidPassword = await bcrypt.compare(mat_khau_cu, user.mat_khau);
            if (!isValidPassword) {
                return res.status(400).json({
                    success: false,
                    message: 'Mật khẩu cũ không đúng'
                });
            }

            // Mã hóa mật khẩu mới
            const saltRounds = 10;
            const hashedNewPassword = await bcrypt.hash(mat_khau_moi, saltRounds);

            await nguoiDung.update(req.user.ma_nguoi_dung, {
                mat_khau: hashedNewPassword,
                ngay_cap_nhat: new Date()
            });

            res.status(200).json({
                success: true,
                message: 'Đổi mật khẩu thành công'
            });
        } catch (error) {
            console.error('Error in changePassword:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi đổi mật khẩu',
                error: error.message
            });
        }
    },

    // Tìm kiếm người dùng (Admin only)
    async searchUsers(req, res) {
        try {
            const { keyword, vai_tro, page = 1, limit = 10 } = req.query;
            
            const nguoiDung = new NguoiDung();
            let searchQuery = `
                SELECT ma_nguoi_dung, ho_ten, email, so_dien_thoai, vai_tro, 
                       ngay_tao, trang_thai, anh_dai_dien
                FROM nguoi_dung 
                WHERE trang_thai = 1
            `;
            
            const params = {};

            if (keyword) {
                searchQuery += ` AND (ho_ten LIKE @keyword OR email LIKE @keyword OR so_dien_thoai LIKE @keyword)`;
                params.keyword = `%${keyword}%`;
            }

            if (vai_tro) {
                searchQuery += ` AND vai_tro = @vai_tro`;
                params.vai_tro = vai_tro;
            }

            searchQuery += ` ORDER BY ngay_tao DESC OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY`;
            
            const offset = (parseInt(page) - 1) * parseInt(limit);
            params.offset = offset;
            params.limit = parseInt(limit);

            const users = await nguoiDung.executeQuery(searchQuery, params);

            res.status(200).json({
                success: true,
                message: 'Tìm kiếm người dùng thành công',
                data: {
                    users,
                    pagination: {
                        page: parseInt(page),
                        limit: parseInt(limit)
                    }
                }
            });
        } catch (error) {
            console.error('Error in searchUsers:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi tìm kiếm người dùng',
                error: error.message
            });
        }
    },

    // Thống kê người dùng (Admin only)
    async getUserStats(req, res) {
        try {
            const nguoiDung = new NguoiDung();
            
            const statsQuery = `
                SELECT 
                    COUNT(*) as tong_nguoi_dung,
                    COUNT(CASE WHEN trang_thai = 1 THEN 1 END) as nguoi_dung_hoat_dong,
                    COUNT(CASE WHEN trang_thai = 0 THEN 1 END) as nguoi_dung_bi_khoa,
                    COUNT(CASE WHEN vai_tro = 'Admin' THEN 1 END) as admin,
                    COUNT(CASE WHEN vai_tro = 'Customer' THEN 1 END) as khach_hang,
                    COUNT(CASE WHEN DATEDIFF(DAY, ngay_tao, GETDATE()) <= 7 THEN 1 END) as dang_ky_7_ngay,
                    COUNT(CASE WHEN DATEDIFF(DAY, ngay_tao, GETDATE()) <= 30 THEN 1 END) as dang_ky_30_ngay
                FROM nguoi_dung
            `;
            
            const stats = await nguoiDung.executeQuery(statsQuery);

            res.status(200).json({
                success: true,
                message: 'Lấy thống kê người dùng thành công',
                data: stats[0]
            });
        } catch (error) {
            console.error('Error in getUserStats:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy thống kê người dùng',
                error: error.message
            });
        }
    },

    // Cập nhật cài đặt nhận email thông báo
    async updateEmailNotificationPreference(req, res) {
        try {
            const userId = req.user.id; // From auth middleware
            const { nhan_thong_bao_email } = req.body;

            if (typeof nhan_thong_bao_email !== 'boolean') {
                return res.status(400).json({
                    success: false,
                    message: 'Giá trị nhan_thong_bao_email phải là boolean'
                });
            }

            // NguoiDung is already an instance, not a class
            await NguoiDung.update(userId, { 
                nhan_thong_bao_email: nhan_thong_bao_email ? 1 : 0 
            });

            res.status(200).json({
                success: true,
                message: `Đã ${nhan_thong_bao_email ? 'bật' : 'tắt'} nhận email thông báo`,
                data: { nhan_thong_bao_email }
            });
        } catch (error) {
            console.error('Error in updateEmailNotificationPreference:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi cập nhật cài đặt email',
                error: error.message
            });
        }
    }
};

module.exports = nguoidungController;