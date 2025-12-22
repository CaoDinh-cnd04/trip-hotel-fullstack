const MaGiamGia = require('../models/magiamgia');
const { validationResult } = require('express-validator');

const magiamgiaController = {
    // Lấy tất cả mã giảm giá
    async getAllMaGiamGia(req, res) {
        try {
            const { page = 1, limit = 10, trang_thai, loai_ma } = req.query;
            
            // Sử dụng MaGiamGia object thay vì new MaGiamGia()
            MaGiamGia.getAll((error, results) => {
                if (error) {
                    console.error('Error in getAllMaGiamGia:', error);
                    return res.status(500).json({
                        success: false,
                        message: 'Lỗi server khi lấy danh sách mã giảm giá',
                        error: error.message
                    });
                }

                // Filter results if needed
                let filteredResults = results;
                
                if (trang_thai !== undefined) {
                    filteredResults = filteredResults.filter(mgg => 
                        mgg.trang_thai === parseInt(trang_thai)
                    );
                }
                
                if (loai_ma) {
                    filteredResults = filteredResults.filter(mgg => 
                        mgg.loai === loai_ma
                    );
                }

                // Pagination
                const startIndex = (parseInt(page) - 1) * parseInt(limit);
                const endIndex = startIndex + parseInt(limit);
                const paginatedResults = filteredResults.slice(startIndex, endIndex);

                res.status(200).json({
                    success: true,
                    message: 'Lấy danh sách mã giảm giá thành công',
                    data: paginatedResults,
                    pagination: {
                        page: parseInt(page),
                        limit: parseInt(limit),
                        total: filteredResults.length,
                        totalPages: Math.ceil(filteredResults.length / parseInt(limit))
                    }
                });
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
            
            // Sử dụng MaGiamGia object để lấy tất cả mã giảm giá
            MaGiamGia.getAll((error, results) => {
                if (error) {
                    console.error('Error in getActiveMaGiamGia:', error);
                    return res.status(500).json({
                        success: false,
                        message: 'Lỗi server khi lấy danh sách mã giảm giá đang hoạt động',
                        error: error.message
                    });
                }

                // Filter active discount codes
                const now = new Date();
                let activeCodes = results.filter(mgg => 
                    mgg.trang_thai === 1 && 
                    new Date(mgg.ngay_bat_dau) <= now && 
                    new Date(mgg.ngay_ket_thuc) >= now &&
                    (mgg.so_luong === null || mgg.so_luong_da_dung < mgg.so_luong)
                );

                // Sort by creation date
                activeCodes.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));

                // Pagination
                const startIndex = (parseInt(page) - 1) * parseInt(limit);
                const endIndex = startIndex + parseInt(limit);
                const paginatedResults = activeCodes.slice(startIndex, endIndex);

                res.status(200).json({
                    success: true,
                    message: 'Lấy danh sách mã giảm giá đang hoạt động thành công',
                    data: paginatedResults,
                    pagination: {
                        page: parseInt(page),
                        limit: parseInt(limit),
                        total: activeCodes.length,
                        totalPages: Math.ceil(activeCodes.length / parseInt(limit))
                    }
                });
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
            
            if (!id || id.trim() === '') {
                return res.status(400).json({
                    success: false,
                    message: 'ID không được để trống'
                });
            }
            
            console.log(`📋 Getting discount code by ID: ${id}`);
            const { getPool } = require('../config/db');
            const sql = require('mssql');
            const pool = await getPool();
            
            // id là string (FLASH20, NEWUSER, etc.)
            const query = `SELECT * FROM dbo.ma_giam_gia WHERE id = @id`;
            const result = await pool.request()
                .input('id', sql.NVarChar(50), id.trim())
                .query(query);
            
            if (!result.recordset || result.recordset.length === 0) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy mã giảm giá'
                });
            }

            res.status(200).json({
                success: true,
                message: 'Lấy thông tin mã giảm giá thành công',
                data: result.recordset[0]
            });
        } catch (error) {
            console.error('❌ Error in getMaGiamGiaById:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy thông tin mã giảm giá',
                error: process.env.NODE_ENV === 'development' ? error.message : undefined
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
                console.error('❌ Validation errors:', errors.array());
                return res.status(400).json({
                    success: false,
                    message: 'Dữ liệu không hợp lệ',
                    errors: errors.array()
                });
            }

            console.log('📝 Creating discount code with data:', req.body);
            const { getPool } = require('../config/db');
            const sql = require('mssql');
            const pool = await getPool();
            
            // Map từ frontend sang database
            // id = ma_giam_gia (string)
            // ten = ten_ma_giam_gia
            // loai = loai_giam_gia (Phần trăm / Số tiền cố định)
            // gia_tri = gia_tri_giam
            // giam_toi_da = gia_tri_giam_toi_da
            // so_luong = so_luong_gioi_han
            // trang_thai = trang_thai (BIT)
            
            const id = req.body.ma_giam_gia || req.body.id
            if (!id) {
                return res.status(400).json({
                    success: false,
                    message: 'Mã giảm giá (id) không được để trống'
                });
            }
            
            // Kiểm tra mã đã tồn tại chưa
            const checkQuery = `SELECT id FROM dbo.ma_giam_gia WHERE id = @id`;
            const checkResult = await pool.request()
                .input('id', sql.NVarChar(50), id.trim().toUpperCase())
                .query(checkQuery);
            
            if (checkResult.recordset && checkResult.recordset.length > 0) {
                return res.status(400).json({
                    success: false,
                    message: 'Mã giảm giá đã tồn tại'
                });
            }
            
            // Map loai_giam_gia sang loai
            let loai = 'Phần trăm'
            if (req.body.loai_giam_gia === 'fixed_amount' || req.body.loai_giam_gia === 'so_tien_co_dinh') {
                loai = 'Số tiền cố định'
            }
            
            // Insert query
            const insertQuery = `
                INSERT INTO dbo.ma_giam_gia (
                    id, ten, loai, gia_tri, giam_toi_da, 
                    ngay_bat_dau, ngay_ket_thuc, 
                    dieu_kien, gia_tri_don_hang_toi_thieu, 
                    so_luong, so_luong_da_dung, trang_thai
                )
                VALUES (
                    @id, @ten, @loai, @gia_tri, @giam_toi_da,
                    @ngay_bat_dau, @ngay_ket_thuc,
                    @dieu_kien, @gia_tri_don_hang_toi_thieu,
                    @so_luong, 0, CAST(@trang_thai AS BIT)
                )
            `;
            
            const request = pool.request()
                .input('id', sql.NVarChar(50), id.trim().toUpperCase())
                .input('ten', sql.NVarChar(200), req.body.ten_ma_giam_gia || req.body.ten || '')
                .input('loai', sql.NVarChar(50), loai)
                .input('gia_tri', sql.Decimal(18, 2), parseFloat(req.body.gia_tri_giam) || 0)
                .input('giam_toi_da', sql.Decimal(18, 2), req.body.gia_tri_giam_toi_da ? parseFloat(req.body.gia_tri_giam_toi_da) : null)
                .input('ngay_bat_dau', sql.DateTime2, new Date(req.body.ngay_bat_dau))
                .input('ngay_ket_thuc', sql.DateTime2, new Date(req.body.ngay_ket_thuc))
                .input('dieu_kien', sql.NVarChar(1000), req.body.mo_ta || req.body.dieu_kien || '')
                .input('gia_tri_don_hang_toi_thieu', sql.Decimal(18, 2), req.body.gia_tri_don_hang_toi_thieu ? parseFloat(req.body.gia_tri_don_hang_toi_thieu) : null)
                .input('so_luong', sql.Int, req.body.so_luong_gioi_han ? parseInt(req.body.so_luong_gioi_han) : null)
                .input('trang_thai', sql.Bit, req.body.trang_thai === true || req.body.trang_thai === 1 || req.body.trang_thai === 'active' ? 1 : 0)
            
            const insertResult = await request.query(insertQuery);
            
            // Lấy lại record vừa tạo
            const getQuery = `SELECT * FROM dbo.ma_giam_gia WHERE id = @id`;
            const getResult = await pool.request()
                .input('id', sql.NVarChar(50), id.trim().toUpperCase())
                .query(getQuery);

            res.status(201).json({
                success: true,
                message: 'Tạo mã giảm giá thành công',
                data: getResult.recordset[0]
            });
        } catch (error) {
            console.error('❌ Error in createMaGiamGia:', error);
            console.error('Error details:', {
                message: error.message,
                code: error.code,
                number: error.number
            });
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi tạo mã giảm giá',
                error: process.env.NODE_ENV === 'development' ? error.message : undefined
            });
        }
    },

    // Cập nhật mã giảm giá
    async updateMaGiamGia(req, res) {
        try {
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                console.error('❌ Validation errors:', errors.array());
                return res.status(400).json({
                    success: false,
                    message: 'Dữ liệu không hợp lệ',
                    errors: errors.array()
                });
            }

            const { id } = req.params;
            
            if (!id || id.trim() === '') {
                return res.status(400).json({
                    success: false,
                    message: 'ID không được để trống'
                });
            }
            
            console.log(`📝 Updating discount code ${id} with data:`, req.body);
            const { getPool } = require('../config/db');
            const sql = require('mssql');
            const pool = await getPool();
            
            // Kiểm tra tồn tại
            const checkQuery = `SELECT id FROM dbo.ma_giam_gia WHERE id = @id`;
            const checkResult = await pool.request()
                .input('id', sql.NVarChar(50), id.trim())
                .query(checkQuery);
            
            if (!checkResult.recordset || checkResult.recordset.length === 0) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy mã giảm giá để cập nhật'
                });
            }
            
            // Map loai_giam_gia sang loai
            let loai = null
            if (req.body.loai_giam_gia) {
                if (req.body.loai_giam_gia === 'fixed_amount' || req.body.loai_giam_gia === 'so_tien_co_dinh') {
                    loai = 'Số tiền cố định'
                } else {
                    loai = 'Phần trăm'
                }
            }
            
            // Build UPDATE query
            const updateFields = []
            const request = pool.request().input('id', sql.NVarChar(50), id.trim())
            
            if (req.body.ten_ma_giam_gia !== undefined || req.body.ten !== undefined) {
                updateFields.push('ten = @ten')
                request.input('ten', sql.NVarChar(200), req.body.ten_ma_giam_gia || req.body.ten)
            }
            if (loai !== null) {
                updateFields.push('loai = @loai')
                request.input('loai', sql.NVarChar(50), loai)
            }
            if (req.body.gia_tri_giam !== undefined) {
                updateFields.push('gia_tri = @gia_tri')
                request.input('gia_tri', sql.Decimal(18, 2), parseFloat(req.body.gia_tri_giam))
            }
            if (req.body.gia_tri_giam_toi_da !== undefined) {
                updateFields.push('giam_toi_da = @giam_toi_da')
                request.input('giam_toi_da', sql.Decimal(18, 2), req.body.gia_tri_giam_toi_da ? parseFloat(req.body.gia_tri_giam_toi_da) : null)
            }
            if (req.body.ngay_bat_dau !== undefined) {
                updateFields.push('ngay_bat_dau = @ngay_bat_dau')
                request.input('ngay_bat_dau', sql.DateTime2, new Date(req.body.ngay_bat_dau))
            }
            if (req.body.ngay_ket_thuc !== undefined) {
                updateFields.push('ngay_ket_thuc = @ngay_ket_thuc')
                request.input('ngay_ket_thuc', sql.DateTime2, new Date(req.body.ngay_ket_thuc))
            }
            if (req.body.mo_ta !== undefined || req.body.dieu_kien !== undefined) {
                updateFields.push('dieu_kien = @dieu_kien')
                request.input('dieu_kien', sql.NVarChar(1000), req.body.mo_ta || req.body.dieu_kien || '')
            }
            if (req.body.gia_tri_don_hang_toi_thieu !== undefined) {
                updateFields.push('gia_tri_don_hang_toi_thieu = @gia_tri_don_hang_toi_thieu')
                request.input('gia_tri_don_hang_toi_thieu', sql.Decimal(18, 2), req.body.gia_tri_don_hang_toi_thieu ? parseFloat(req.body.gia_tri_don_hang_toi_thieu) : null)
            }
            if (req.body.so_luong_gioi_han !== undefined) {
                updateFields.push('so_luong = @so_luong')
                request.input('so_luong', sql.Int, req.body.so_luong_gioi_han ? parseInt(req.body.so_luong_gioi_han) : null)
            }
            if (req.body.trang_thai !== undefined) {
                updateFields.push('trang_thai = CAST(@trang_thai AS BIT)')
                const trangThai = req.body.trang_thai === true || req.body.trang_thai === 1 || req.body.trang_thai === 'active' ? 1 : 0
                request.input('trang_thai', sql.Bit, trangThai)
            }
            
            if (updateFields.length === 0) {
                return res.status(400).json({
                    success: false,
                    message: 'Không có dữ liệu để cập nhật'
                });
            }
            
            const updateQuery = `UPDATE dbo.ma_giam_gia SET ${updateFields.join(', ')} WHERE id = @id`;
            const updateResult = await request.query(updateQuery);
            
            if (updateResult.rowsAffected[0] === 0) {
                return res.status(404).json({
                    success: false,
                    message: 'Không thể cập nhật mã giảm giá'
                });
            }
            
            // Lấy lại record đã cập nhật
            const getQuery = `SELECT * FROM dbo.ma_giam_gia WHERE id = @id`;
            const getResult = await pool.request()
                .input('id', sql.NVarChar(50), id.trim())
                .query(getQuery);

            res.status(200).json({
                success: true,
                message: 'Cập nhật mã giảm giá thành công',
                data: getResult.recordset[0]
            });
        } catch (error) {
            console.error('❌ Error in updateMaGiamGia:', error);
            console.error('Error details:', {
                message: error.message,
                code: error.code,
                number: error.number
            });
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi cập nhật mã giảm giá',
                error: process.env.NODE_ENV === 'development' ? error.message : undefined
            });
        }
    },

    // Xóa mã giảm giá
    async deleteMaGiamGia(req, res) {
        try {
            const { id } = req.params;
            
            if (!id || id.trim() === '') {
                return res.status(400).json({
                    success: false,
                    message: 'ID không được để trống'
                });
            }
            
            console.log(`🗑️ Deleting discount code with ID: ${id}`);
            const { getPool } = require('../config/db');
            const sql = require('mssql');
            const pool = await getPool();
            
            // Kiểm tra xem mã giảm giá có tồn tại không
            // id là string (FLASH20, NEWUSER, etc.)
            const checkQuery = `SELECT id, trang_thai FROM dbo.ma_giam_gia WHERE id = @id`;
            const checkResult = await pool.request()
                .input('id', sql.NVarChar(50), id.trim())
                .query(checkQuery);
            
            if (!checkResult.recordset || checkResult.recordset.length === 0) {
                console.log(`❌ Discount code ${id} not found`);
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy mã giảm giá'
                });
            }
            
            console.log(`✅ Found discount code ${id}, proceeding with hard delete`);
            
            // Hard delete - xóa thực sự khỏi database
            // Sử dụng transaction để đảm bảo commit
            const transaction = new sql.Transaction(pool);
            
            try {
                await transaction.begin();
                console.log(`🔄 Transaction started for deleting discount code ${id}`);
                
                const deleteQuery = `
                    DELETE FROM dbo.ma_giam_gia 
                    WHERE id = @id
                `;
                
                console.log(`🔄 Executing DELETE query for ID: ${id}`);
                const request = new sql.Request(transaction);
                const deleteResult = await request
                    .input('id', sql.NVarChar(50), id.trim())
                    .query(deleteQuery);
                
                console.log(`📊 Delete result - rowsAffected:`, deleteResult.rowsAffected);
                
                if (deleteResult.rowsAffected[0] === 0) {
                    await transaction.rollback();
                    console.log(`⚠️ No rows affected for discount code ${id}, rolling back`);
                    return res.status(404).json({
                        success: false,
                        message: 'Không tìm thấy mã giảm giá để xóa hoặc không thể xóa'
                    });
                }
                
                // Commit transaction
                await transaction.commit();
                console.log(`✅ Transaction committed for discount code ${id}`);
                
                // Verify deletion sau khi commit
                await new Promise(resolve => setTimeout(resolve, 200));
                
                const verifyQuery = `SELECT id FROM dbo.ma_giam_gia WHERE id = @id`;
                const verifyResult = await pool.request()
                    .input('id', sql.NVarChar(50), id.trim())
                    .query(verifyQuery);
                
                console.log(`🔍 Verification query result:`, {
                    recordCount: verifyResult.recordset?.length || 0,
                    records: verifyResult.recordset
                });
                
                if (verifyResult.recordset && verifyResult.recordset.length > 0) {
                    console.log(`⚠️ Discount code ${id} still exists after delete`);
                    return res.status(500).json({
                        success: false,
                        message: 'Xóa không thành công - mã giảm giá vẫn còn trong database',
                        error: {
                            message: 'Record still exists after delete operation',
                            id: id
                        }
                    });
                }

                console.log(`✅ Successfully deleted discount code ${id} from database`);
                res.status(200).json({
                    success: true,
                    message: 'Xóa mã giảm giá thành công',
                    data: {
                        deletedId: id
                    }
                });
            } catch (deleteError) {
                // Rollback transaction nếu có lỗi
                if (transaction) {
                    try {
                        await transaction.rollback();
                        console.log(`🔄 Transaction rolled back due to error`);
                    } catch (rollbackError) {
                        console.error('❌ Error rolling back transaction:', rollbackError);
                    }
                }
                
                console.error('❌ Delete query error:', deleteError);
                // Kiểm tra xem có phải lỗi foreign key constraint không
                if (deleteError.number === 547) {
                    return res.status(400).json({
                        success: false,
                        message: 'Không thể xóa mã giảm giá vì đang được sử dụng trong hệ thống (có đơn đặt phòng đang sử dụng mã này)',
                        error: process.env.NODE_ENV === 'development' ? {
                            message: deleteError.message,
                            number: deleteError.number
                        } : undefined
                    });
                }
                throw deleteError; // Re-throw để catch block xử lý
            }
        } catch (error) {
            console.error('❌ Error in deleteMaGiamGia:', error);
            console.error('Error details:', {
                message: error.message,
                code: error.code,
                number: error.number,
                originalError: error.originalError?.message
            });
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi xóa mã giảm giá',
                error: process.env.NODE_ENV === 'development' ? {
                    message: error.message,
                    code: error.code,
                    number: error.number
                } : undefined
            });
        }
    },

    // Bật/tắt mã giảm giá (Admin only)
    async toggleMaGiamGia(req, res) {
        try {
            const { id } = req.params;
            
            if (!id || id.trim() === '') {
                return res.status(400).json({
                    success: false,
                    message: 'ID không được để trống'
                });
            }
            
            console.log(`🔄 Toggling discount code with ID: ${id}`);
            const { getPool } = require('../config/db');
            const sql = require('mssql');
            const pool = await getPool();
            
            // Kiểm tra xem mã giảm giá có tồn tại không
            // id là string (FLASH20, NEWUSER, etc.)
            const checkQuery = `SELECT id, trang_thai FROM dbo.ma_giam_gia WHERE id = @id`;
            const checkResult = await pool.request()
                .input('id', sql.NVarChar(50), id.trim())
                .query(checkQuery);
            
            if (!checkResult.recordset || checkResult.recordset.length === 0) {
                console.log(`❌ Discount code ${id} not found`);
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy mã giảm giá'
                });
            }
            
            const existing = checkResult.recordset[0];
            // Xử lý trang_thai - có thể là BIT (true/false) hoặc số (1/0)
            const currentStatus = existing.trang_thai === true || existing.trang_thai === 1 || existing.trang_thai === '1';
            const newStatus = currentStatus ? 0 : 1;
            
            console.log(`📊 Current status: ${currentStatus}, New status: ${newStatus}`);
            
            // Update trang_thai - kiểm tra xem cột là BIT hay INT
            // Thử với BIT trước, nếu không được thì dùng INT
            const updateQuery = `
                UPDATE dbo.ma_giam_gia 
                SET trang_thai = CAST(@newStatus AS BIT)
                WHERE id = @id
            `;
            
            console.log(`🔄 Executing UPDATE query for ID: ${id}`);
            const updateResult = await pool.request()
                .input('id', sql.NVarChar(50), id.trim())
                .input('newStatus', sql.Bit, newStatus)
                .query(updateQuery);
            
            console.log(`📊 Update result - rowsAffected:`, updateResult.rowsAffected);
            
            if (updateResult.rowsAffected[0] === 0) {
                console.log(`⚠️ No rows affected for discount code ${id}`);
                return res.status(404).json({
                    success: false,
                    message: 'Không thể cập nhật mã giảm giá. Có thể mã giảm giá không tồn tại hoặc đã được cập nhật.'
                });
            }

            // Verify update
            const verifyQuery = `SELECT id, trang_thai FROM dbo.ma_giam_gia WHERE id = @id`;
            const verifyResult = await pool.request()
                .input('id', sql.NVarChar(50), id.trim())
                .query(verifyQuery);
            
            const updatedDiscount = verifyResult.recordset[0];
            const updatedStatus = updatedDiscount.trang_thai === true || updatedDiscount.trang_thai === 1 || updatedDiscount.trang_thai === '1';
            console.log(`✅ Verified - Discount code ${id} status updated to: ${updatedStatus}`);

            res.status(200).json({
                success: true,
                message: `${newStatus === 1 ? 'Kích hoạt' : 'Vô hiệu hóa'} mã giảm giá thành công`,
                data: {
                    id: id,
                    trang_thai: updatedStatus ? 1 : 0
                }
            });
        } catch (error) {
            console.error('❌ Error in toggleMaGiamGia:', error);
            console.error('Error details:', {
                message: error.message,
                code: error.code,
                number: error.number,
                originalError: error.originalError?.message
            });
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi thay đổi trạng thái mã giảm giá',
                error: process.env.NODE_ENV === 'development' ? {
                    message: error.message,
                    code: error.code,
                    number: error.number
                } : undefined
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