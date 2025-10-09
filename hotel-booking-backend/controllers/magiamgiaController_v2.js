const MaGiamGia = require('../models/magiamgia');
const { validationResult } = require('express-validator');

const magiamgiaController = {
    // Lấy tất cả mã giảm giá
    async getAllMaGiamGia(req, res) {
        try {
            const { page = 1, limit = 10, trang_thai, loai_ma } = req.query;
            
            const maGiamGia = new MaGiamGia();
            const filters = {};
            
            if (trang_thai !== undefined) filters.trang_thai = parseInt(trang_thai);
            if (loai_ma) filters.loai_ma = loai_ma;

            const results = await maGiamGia.findAll(filters, parseInt(page), parseInt(limit));

            res.status(200).json({
                success: true,
                message: 'Lấy danh sách mã giảm giá thành công',
                data: results
            });
        } catch (error) {
            console.error('Error in getAllMaGiamGia:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy danh sách mã giảm giá',
                error: error.message
            });
        }
    },

    // Lấy mã giảm giá đang hoạt động
    async getActiveMaGiamGia(req, res) {
        try {
            const { page = 1, limit = 10 } = req.query;
            const maGiamGia = new MaGiamGia();
            
            const now = new Date();
            const activeQuery = `
                SELECT * FROM ma_giam_gia
                WHERE trang_thai = 1
                    AND ngay_bat_dau <= @now
                    AND ngay_ket_thuc >= @now
                    AND (so_luong_gioi_han IS NULL OR so_luong_da_su_dung < so_luong_gioi_han)
                ORDER BY ngay_tao DESC
                OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY
            `;

            const offset = (parseInt(page) - 1) * parseInt(limit);
            const results = await maGiamGia.executeQuery(activeQuery, {
                now,
                offset,
                limit: parseInt(limit)
            });

            res.status(200).json({
                success: true,
                message: 'Lấy danh sách mã giảm giá đang hoạt động thành công',
                data: results
            });
        } catch (error) {
            console.error('Error in getActiveMaGiamGia:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy danh sách mã giảm giá đang hoạt động',
                error: error.message
            });
        }
    },

    // Lấy mã giảm giá của người dùng hiện tại
    async getMyMaGiamGia(req, res) {
        try {
            const { page = 1, limit = 10 } = req.query;
            const maGiamGia = new MaGiamGia();
            
            // Lấy mã giảm giá mà user có thể sử dụng (chưa hết lượt sử dụng cá nhân)
            const myVouchersQuery = `
                SELECT mgd.*, COALESCE(usage.so_lan_da_su_dung, 0) as so_lan_da_su_dung_cua_toi
                FROM ma_giam_gia mgd
                LEFT JOIN (
                    SELECT ma_giam_gia, COUNT(*) as so_lan_da_su_dung
                    FROM lich_su_su_dung_voucher
                    WHERE ma_nguoi_dung = @ma_nguoi_dung
                    GROUP BY ma_giam_gia
                ) usage ON mgd.ma_giam_gia = usage.ma_giam_gia
                WHERE mgd.trang_thai = 1
                    AND mgd.ngay_bat_dau <= GETDATE()
                    AND mgd.ngay_ket_thuc >= GETDATE()
                    AND (mgd.so_luong_gioi_han IS NULL OR mgd.so_luong_da_su_dung < mgd.so_luong_gioi_han)
                    AND (mgd.gioi_han_su_dung_moi_nguoi IS NULL OR COALESCE(usage.so_lan_da_su_dung, 0) < mgd.gioi_han_su_dung_moi_nguoi)
                ORDER BY mgd.ngay_tao DESC
                OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY
            `;

            const offset = (parseInt(page) - 1) * parseInt(limit);
            const results = await maGiamGia.executeQuery(myVouchersQuery, {
                ma_nguoi_dung: req.user.ma_nguoi_dung,
                offset,
                limit: parseInt(limit)
            });

            res.status(200).json({
                success: true,
                message: 'Lấy danh sách mã giảm giá của bạn thành công',
                data: results
            });
        } catch (error) {
            console.error('Error in getMyMaGiamGia:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy danh sách mã giảm giá của bạn',
                error: error.message
            });
        }
    },

    // Lấy mã giảm giá theo code
    async getMaGiamGiaByCode(req, res) {
        try {
            const { code } = req.params;
            const maGiamGia = new MaGiamGia();
            
            const result = await maGiamGia.findByCondition({ ma_giam_gia: code });
            
            if (!result) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy mã giảm giá'
                });
            }

            res.status(200).json({
                success: true,
                message: 'Lấy thông tin mã giảm giá thành công',
                data: result
            });
        } catch (error) {
            console.error('Error in getMaGiamGiaByCode:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy thông tin mã giảm giá',
                error: error.message
            });
        }
    },

    // Lấy mã giảm giá theo ID
    async getMaGiamGiaById(req, res) {
        try {
            const { id } = req.params;
            const maGiamGia = new MaGiamGia();
            
            const result = await maGiamGia.findById(id);
            
            if (!result) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy mã giảm giá'
                });
            }

            res.status(200).json({
                success: true,
                message: 'Lấy thông tin mã giảm giá thành công',
                data: result
            });
        } catch (error) {
            console.error('Error in getMaGiamGiaById:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy thông tin mã giảm giá',
                error: error.message
            });
        }
    },

    // Kiểm tra mã giảm giá
    async validateVoucher(req, res) {
        try {
            const { ma_giam_gia } = req.params;
            const { tong_tien, ma_nguoi_dung } = req.query;
            
            const maGiamGia = new MaGiamGia();
            
            // Tìm mã giảm giá theo mã
            const voucher = await maGiamGia.findByField('ma_giam_gia', ma_giam_gia);
            
            if (!voucher) {
                return res.status(404).json({
                    success: false,
                    message: 'Mã giảm giá không tồn tại'
                });
            }

            // Kiểm tra các điều kiện
            const currentDate = new Date();
            const errors = [];

            if (voucher.trang_thai !== 1) {
                errors.push('Mã giảm giá đã bị vô hiệu hóa');
            }

            if (new Date(voucher.ngay_bat_dau) > currentDate) {
                errors.push('Mã giảm giá chưa có hiệu lực');
            }

            if (new Date(voucher.ngay_ket_thuc) < currentDate) {
                errors.push('Mã giảm giá đã hết hạn');
            }

            if (voucher.so_luong_con_lai <= 0) {
                errors.push('Mã giảm giá đã hết lượt sử dụng');
            }

            if (voucher.gia_tri_don_hang_toi_thieu && tong_tien < voucher.gia_tri_don_hang_toi_thieu) {
                errors.push(`Đơn hàng tối thiểu ${voucher.gia_tri_don_hang_toi_thieu.toLocaleString()}đ`);
            }

            // Kiểm tra người dùng đã sử dụng chưa (nếu có ma_nguoi_dung)
            if (ma_nguoi_dung && voucher.gioi_han_su_dung_moi_nguoi > 0) {
                const usageQuery = `
                    SELECT COUNT(*) as used_count 
                    FROM phieu_dat_phong 
                    WHERE ma_giam_gia = @ma_giam_gia AND ma_nguoi_dung = @ma_nguoi_dung
                `;
                const usageResult = await maGiamGia.executeQuery(usageQuery, { 
                    ma_giam_gia: voucher.ma_giam_gia, 
                    ma_nguoi_dung 
                });
                
                if (usageResult[0]?.used_count >= voucher.gioi_han_su_dung_moi_nguoi) {
                    errors.push('Bạn đã sử dụng hết lượt sử dụng mã này');
                }
            }

            const isValid = errors.length === 0;
            let discountAmount = 0;

            if (isValid && tong_tien) {
                if (voucher.loai_giam === 'phan_tram') {
                    discountAmount = (parseFloat(tong_tien) * voucher.gia_tri_giam) / 100;
                    if (voucher.giam_toi_da && discountAmount > voucher.giam_toi_da) {
                        discountAmount = voucher.giam_toi_da;
                    }
                } else {
                    discountAmount = voucher.gia_tri_giam;
                }
            }

            res.status(200).json({
                success: isValid,
                message: isValid ? 'Mã giảm giá hợp lệ' : errors.join(', '),
                data: {
                    voucher,
                    isValid,
                    discountAmount,
                    errors: isValid ? [] : errors
                }
            });
        } catch (error) {
            console.error('Error in validateVoucher:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi kiểm tra mã giảm giá',
                error: error.message
            });
        }
    },

    // Tạo mã giảm giá mới
    async createMaGiamGia(req, res) {
        try {
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                return res.status(400).json({
                    success: false,
                    message: 'Dữ liệu không hợp lệ',
                    errors: errors.array()
                });
            }

            const maGiamGia = new MaGiamGia();
            
            // Kiểm tra mã đã tồn tại chưa
            const existingVoucher = await maGiamGia.findByField('ma_giam_gia', req.body.ma_giam_gia);
            if (existingVoucher) {
                return res.status(400).json({
                    success: false,
                    message: 'Mã giảm giá đã tồn tại'
                });
            }

            const newMaGiamGia = await maGiamGia.create({
                ...req.body,
                ngay_tao: new Date(),
                trang_thai: 1,
                so_luong_con_lai: req.body.so_luong_ban_dau || req.body.so_luong_con_lai
            });

            res.status(201).json({
                success: true,
                message: 'Tạo mã giảm giá thành công',
                data: newMaGiamGia
            });
        } catch (error) {
            console.error('Error in createMaGiamGia:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi tạo mã giảm giá',
                error: error.message
            });
        }
    },

    // Cập nhật mã giảm giá
    async updateMaGiamGia(req, res) {
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
            const maGiamGia = new MaGiamGia();
            
            const updated = await maGiamGia.update(id, {
                ...req.body,
                ngay_cap_nhat: new Date()
            });
            
            if (!updated) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy mã giảm giá để cập nhật'
                });
            }

            res.status(200).json({
                success: true,
                message: 'Cập nhật mã giảm giá thành công',
                data: updated
            });
        } catch (error) {
            console.error('Error in updateMaGiamGia:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi cập nhật mã giảm giá',
                error: error.message
            });
        }
    },

    // Xóa mã giảm giá
    async deleteMaGiamGia(req, res) {
        try {
            const { id } = req.params;
            const maGiamGia = new MaGiamGia();
            
            const deleted = await maGiamGia.update(id, { 
                trang_thai: 0,
                ngay_cap_nhat: new Date()
            });
            
            if (!deleted) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy mã giảm giá để xóa'
                });
            }

            res.status(200).json({
                success: true,
                message: 'Xóa mã giảm giá thành công'
            });
        } catch (error) {
            console.error('Error in deleteMaGiamGia:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi xóa mã giảm giá',
                error: error.message
            });
        }
    },

    // Bật/tắt mã giảm giá (Admin only)
    async toggleMaGiamGia(req, res) {
        try {
            const { id } = req.params;
            const maGiamGia = new MaGiamGia();
            
            const existing = await maGiamGia.findById(id);
            if (!existing) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy mã giảm giá'
                });
            }

            const newStatus = existing.trang_thai === 1 ? 0 : 1;
            const updated = await maGiamGia.update(id, { 
                trang_thai: newStatus,
                ngay_cap_nhat: new Date()
            });

            res.status(200).json({
                success: true,
                message: `${newStatus === 1 ? 'Kích hoạt' : 'Vô hiệu hóa'} mã giảm giá thành công`,
                data: updated
            });
        } catch (error) {
            console.error('Error in toggleMaGiamGia:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi thay đổi trạng thái mã giảm giá',
                error: error.message
            });
        }
    },

    // Sử dụng mã giảm giá
    async useMaGiamGia(req, res) {
        try {
            const { id } = req.params;
            const { gia_tri_don_hang } = req.body;
            const maGiamGia = new MaGiamGia();
            
            const voucher = await maGiamGia.findById(id);
            if (!voucher) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy mã giảm giá'
                });
            }

            // Kiểm tra trạng thái và thời hạn
            const now = new Date();
            if (voucher.trang_thai !== 1) {
                return res.status(400).json({
                    success: false,
                    message: 'Mã giảm giá đã bị vô hiệu hóa'
                });
            }

            if (new Date(voucher.ngay_ket_thuc) < now) {
                return res.status(400).json({
                    success: false,
                    message: 'Mã giảm giá đã hết hạn'
                });
            }

            if (new Date(voucher.ngay_bat_dau) > now) {
                return res.status(400).json({
                    success: false,
                    message: 'Mã giảm giá chưa có hiệu lực'
                });
            }

            // Kiểm tra giá trị đơn hàng tối thiểu
            if (voucher.gia_tri_don_hang_toi_thieu && gia_tri_don_hang < voucher.gia_tri_don_hang_toi_thieu) {
                return res.status(400).json({
                    success: false,
                    message: `Đơn hàng phải có giá trị tối thiểu ${voucher.gia_tri_don_hang_toi_thieu} VND`
                });
            }

            // Cập nhật số lượng đã sử dụng
            const newUsedCount = (voucher.so_luong_da_su_dung || 0) + 1;
            if (voucher.so_luong_gioi_han && newUsedCount > voucher.so_luong_gioi_han) {
                return res.status(400).json({
                    success: false,
                    message: 'Mã giảm giá đã hết lượt sử dụng'
                });
            }

            // Cập nhật số lượng đã sử dụng
            await maGiamGia.update(id, {
                so_luong_da_su_dung: newUsedCount,
                ngay_cap_nhat: new Date()
            });

            // Tính toán giá trị giảm
            let discountAmount = 0;
            if (voucher.loai_giam_gia === 'percentage') {
                discountAmount = (gia_tri_don_hang * voucher.gia_tri_giam) / 100;
                if (voucher.gia_tri_giam_toi_da && discountAmount > voucher.gia_tri_giam_toi_da) {
                    discountAmount = voucher.gia_tri_giam_toi_da;
                }
            } else {
                discountAmount = voucher.gia_tri_giam;
            }

            res.status(200).json({
                success: true,
                message: 'Sử dụng mã giảm giá thành công',
                data: {
                    voucher: voucher,
                    discountAmount,
                    finalAmount: gia_tri_don_hang - discountAmount
                }
            });
        } catch (error) {
            console.error('Error in useMaGiamGia:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi sử dụng mã giảm giá',
                error: error.message
            });
        }
    }
};

module.exports = magiamgiaController;