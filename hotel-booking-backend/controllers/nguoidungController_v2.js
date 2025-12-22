const NguoiDung = require('../models/nguoidung');
const { validationResult } = require('express-validator');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const nguoidungController = {
    // Lấy tất cả người dùng (Admin only)
    async getAllUsers(req, res) {
        try {
            const { page = 1, limit = 100, vai_tro, trang_thai } = req.query;
            
            console.log('📋 Getting all users with params:', { page, limit, vai_tro, trang_thai });
            
            const nguoiDung = new NguoiDung();
            
            // Build WHERE clause - By default, exclude soft-deleted users (trang_thai = 0)
            // Admin can see deleted users by setting trang_thai = 0 explicitly
            const whereConditions = [];
            
            // Only filter by role if specified
            if (vai_tro && vai_tro !== 'all') {
                whereConditions.push(`chuc_vu = N'${vai_tro.replace(/'/g, "''")}'`); // Escape single quotes
            }
            
            // Filter by status if specified, otherwise default to active only
            if (trang_thai !== undefined && trang_thai !== '' && trang_thai !== null && trang_thai !== 'all') {
                const statusValue = trang_thai === '1' || trang_thai === 1 || trang_thai === true || trang_thai === 'active' ? 1 : 0;
                whereConditions.push(`trang_thai = CAST(${statusValue} AS BIT)`);
            } else {
                // By default, only show active users (exclude soft-deleted)
                whereConditions.push(`trang_thai = CAST(1 AS BIT)`);
            }
            
            const whereClause = whereConditions.length > 0 ? whereConditions.join(' AND ') : '';

            console.log('🔍 WHERE clause:', whereClause || '(no filter)');

            const results = await nguoiDung.findAll({
                page: parseInt(page) || 1,
                limit: parseInt(limit) || 100,
                where: whereClause,
                orderBy: 'id DESC'
            });

            console.log(`✅ Found ${results.data?.length || 0} users`);

            // Normalize trang_thai field (BIT to number for consistency)
            if (results.data && Array.isArray(results.data)) {
                results.data = results.data.map(user => ({
                    ...user,
                    trang_thai: user.trang_thai === true || user.trang_thai === 1 || user.trang_thai === '1' ? 1 : 0
                }));
            }

            res.status(200).json({
                success: true,
                message: 'Lấy danh sách người dùng thành công',
                data: results
            });
        } catch (error) {
            console.error('❌ Error in getAllUsers:', {
                message: error.message,
                stack: error.stack,
                code: error.code,
                number: error.number
            });
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy danh sách người dùng',
                error: error.message,
                stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
            });
        }
    },

    // Lấy thông tin người dùng theo ID với bookings và reviews
    async getUserById(req, res) {
        try {
            const { id } = req.params;
            const { include_bookings, include_reviews } = req.query;
            const nguoiDung = new NguoiDung();
            
            // Admin can view all users (including blocked), so use direct query
            let user;
            if (req.user.chuc_vu === 'Admin') {
                const query = `SELECT * FROM ${nguoiDung.tableName} WHERE ${nguoiDung.primaryKey} = @id`;
                const result = await nguoiDung.executeQuery(query, { id });
                user = result.recordset[0] || null;
            } else {
                user = await nguoiDung.findById(id);
            }
            
            if (!user) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy người dùng'
                });
            }

            // Kiểm tra quyền xem (chỉ Admin hoặc chính user đó)
            if (req.user.chuc_vu !== 'Admin' && req.user.id !== parseInt(id)) {
                return res.status(403).json({
                    success: false,
                    message: 'Bạn không có quyền xem thông tin này'
                });
            }

            // Không trả về mật khẩu
            delete user.mat_khau;

            const response = {
                success: true,
                message: 'Lấy thông tin người dùng thành công',
                data: user
            };

            // Get bookings if requested
            if (include_bookings === 'true') {
                try {
                    const { getPool } = require('../config/db');
                    const sql = require('mssql');
                    const pool = await getPool();
                    
                    const bookingsQuery = `
                        SELECT 
                            pdp.id,
                            pdp.ngay_dat,
                            pdp.ngay_checkin,
                            pdp.ngay_checkout,
                            pdp.tong_tien,
                            pdp.trang_thai,
                            ks.ten as ten_khach_san,
                            ks.dia_chi,
                            p.ma_phong,
                            p.loai_phong
                        FROM phieu_dat_phong pdp
                        LEFT JOIN phong p ON pdp.phong_id = p.id
                        LEFT JOIN khach_san ks ON p.khach_san_id = ks.id
                        WHERE pdp.nguoi_dung_id = @userId
                        ORDER BY pdp.ngay_dat DESC
                    `;
                    
                    const bookingsResult = await pool.request()
                        .input('userId', sql.Int, id)
                        .query(bookingsQuery);
                    
                    response.data.bookings = bookingsResult.recordset || [];
                } catch (error) {
                    console.error('Error fetching bookings:', error);
                    response.data.bookings = [];
                }
            }

            // Get reviews if requested
            if (include_reviews === 'true') {
                try {
                    const { getPool } = require('../config/db');
                    const sql = require('mssql');
                    const pool = await getPool();
                    
                    const reviewsQuery = `
                        SELECT 
                            dg.id,
                            dg.so_sao_tong as rating,
                            dg.binh_luan as content,
                            dg.ngay as review_date,
                            dg.trang_thai,
                            ks.ten as ten_khach_san,
                            ks.id as khach_san_id
                        FROM danh_gia dg
                        LEFT JOIN khach_san ks ON dg.khach_san_id = ks.id
                        WHERE dg.nguoi_dung_id = @userId
                        ORDER BY dg.ngay DESC
                    `;
                    
                    const reviewsResult = await pool.request()
                        .input('userId', sql.Int, id)
                        .query(reviewsQuery);
                    
                    response.data.reviews = reviewsResult.recordset || [];
                } catch (error) {
                    console.error('Error fetching reviews:', error);
                    response.data.reviews = [];
                }
            }

            res.status(200).json(response);
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

    // Xóa người dùng (Admin only) - Soft delete
    async deleteUser(req, res) {
        try {
            const { id } = req.params;
            console.log(`🗑️ Deleting user with ID: ${id}`);
            const nguoiDung = new NguoiDung();
            
            // Find user by ID without status check (to delete blocked users)
            const checkQuery = `SELECT * FROM ${nguoiDung.tableName} WHERE ${nguoiDung.primaryKey} = @id`;
            console.log(`🔍 Checking user existence with query: ${checkQuery}`);
            const checkResult = await nguoiDung.executeQuery(checkQuery, { id });
            const user = checkResult.recordset[0];
            
            if (!user) {
                console.log(`❌ User ${id} not found`);
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy người dùng để xóa'
                });
            }
            
            console.log(`✅ User found: ${user.email}, current status: ${user.trang_thai}`);
            
            // Soft delete - set trang_thai = 0 using direct query
            // (Don't use update() because it calls findById which filters by trang_thai = 1)
            // Note: nguoi_dung table doesn't have updated_at column, so don't include it
            // Sử dụng transaction để đảm bảo commit
            const sql = require('mssql');
            const { getPool } = require('../config/db');
            const pool = await getPool();
            const transaction = new sql.Transaction(pool);
            
            try {
                await transaction.begin();
                console.log(`🔄 Transaction started for deleting user ${id}`);
                
                const deleteQuery = `
                    UPDATE ${nguoiDung.tableName} 
                    SET trang_thai = CAST(0 AS BIT)
                    WHERE ${nguoiDung.primaryKey} = @id
                `;
                
                console.log(`🔄 Executing delete query: ${deleteQuery}`);
                const request = new sql.Request(transaction);
                const updateResult = await request
                    .input('id', sql.Int, parseInt(id))
                    .query(deleteQuery);
                
                console.log(`✅ Update result - rows affected: ${updateResult.rowsAffected[0]}`);
                
                if (updateResult.rowsAffected[0] === 0) {
                    await transaction.rollback();
                    console.log(`⚠️ No rows affected for user ${id}, rolling back`);
                    return res.status(500).json({
                        success: false,
                        message: 'Không thể xóa người dùng - không có dòng nào được cập nhật'
                    });
                }
                
                // Commit transaction
                await transaction.commit();
                console.log(`✅ Transaction committed for user ${id}`);
                
                // Verify deletion sau khi commit
                await new Promise(resolve => setTimeout(resolve, 200));
                
                // Verify deletion by checking if trang_thai was updated
                // Note: SQL Server BIT can return 0, 1, true, false, or null
                const verifyQuery = `SELECT ${nguoiDung.primaryKey}, trang_thai FROM ${nguoiDung.tableName} WHERE ${nguoiDung.primaryKey} = @id`;
                const verifyResult = await pool.request()
                    .input('id', sql.Int, parseInt(id))
                    .query(verifyQuery);
                const updatedUser = verifyResult.recordset[0];
                
                console.log(`🔍 Verification result:`, updatedUser);
                
                // Check if trang_thai is falsy (0, false, null) - means deleted
                const isDeleted = !updatedUser || 
                                 updatedUser.trang_thai === 0 || 
                                 updatedUser.trang_thai === false || 
                                 updatedUser.trang_thai === null ||
                                 updatedUser.trang_thai === '0';
                
                if (!isDeleted) {
                    console.log(`❌ User status not updated correctly. Current status: ${updatedUser.trang_thai}`);
                    return res.status(500).json({
                        success: false,
                        message: 'Không thể xóa người dùng - trạng thái không được cập nhật'
                    });
                }

                console.log(`✅ User ${id} deleted successfully`);
                res.status(200).json({
                    success: true,
                    message: 'Xóa người dùng thành công'
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
                        message: 'Không thể xóa người dùng vì đang được sử dụng trong hệ thống (có dữ liệu liên quan)',
                        error: process.env.NODE_ENV === 'development' ? {
                            message: deleteError.message,
                            number: deleteError.number
                        } : undefined
                    });
                }
                throw deleteError; // Re-throw để catch block xử lý
            }
        } catch (error) {
            console.error('❌ Error in deleteUser:', error);
            console.error('Error details:', {
                message: error.message,
                code: error.code,
                number: error.number,
                stack: error.stack
            });
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi xóa người dùng',
                error: error.message,
                stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
            });
        }
    },

    // Phê duyệt người dùng (Admin only) - Kích hoạt tài khoản
    async approveUser(req, res) {
        try {
            const { id } = req.params;
            console.log(`✅ Approving user with ID: ${id}`);
            const nguoiDung = new NguoiDung();
            
            // Find user by ID without status check (to approve inactive users)
            const checkQuery = `SELECT * FROM ${nguoiDung.tableName} WHERE ${nguoiDung.primaryKey} = @id`;
            console.log(`🔍 Checking user existence: ${checkQuery}`);
            const checkResult = await nguoiDung.executeQuery(checkQuery, { id });
            const user = checkResult.recordset[0];
            
            if (!user) {
                console.log(`❌ User ${id} not found`);
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy người dùng'
                });
            }

            console.log(`✅ User found: ${user.email}, current status: ${user.trang_thai}`);

            // Update status to active using direct query
            // (Can use update() here because we're setting trang_thai = 1, so findById will find it)
            // But for consistency, let's use direct query
            // Note: nguoi_dung table doesn't have updated_at column, so don't include it
            const approveQuery = `
                UPDATE ${nguoiDung.tableName} 
                SET trang_thai = CAST(1 AS BIT)
                WHERE ${nguoiDung.primaryKey} = @id
            `;
            
            console.log(`🔄 Executing approve query: ${approveQuery}`);
            await nguoiDung.executeQuery(approveQuery, { id });
            
            // Verify update - can use findById now since status is 1
            const updated = await nguoiDung.findById(id);
            
            if (!updated) {
                // If findById doesn't find it, verify with direct query
                const verifyQuery = `SELECT ${nguoiDung.primaryKey}, trang_thai FROM ${nguoiDung.tableName} WHERE ${nguoiDung.primaryKey} = @id`;
                const verifyResult = await nguoiDung.executeQuery(verifyQuery, { id });
                const verifiedUser = verifyResult.recordset[0];
                
                if (!verifiedUser || (verifiedUser.trang_thai !== 1 && verifiedUser.trang_thai !== true)) {
                    console.log(`❌ User status not updated correctly. Current status: ${verifiedUser?.trang_thai}`);
                    return res.status(500).json({
                        success: false,
                        message: 'Không thể phê duyệt người dùng - trạng thái không được cập nhật'
                    });
                }
                
                // Use verified user data
                const normalizedUser = {
                    ...user,
                    trang_thai: 1
                };
                delete normalizedUser.mat_khau;
                
                console.log(`✅ User ${id} approved successfully (verified)`);
                return res.status(200).json({
                    success: true,
                    message: 'Phê duyệt người dùng thành công',
                    data: normalizedUser
                });
            }

            // Normalize trang_thai in response
            const normalizedUser = {
                ...updated,
                trang_thai: updated.trang_thai === true || updated.trang_thai === 1 || updated.trang_thai === '1' ? 1 : 0
            };
            delete normalizedUser.mat_khau; // Don't return password

            console.log(`✅ User ${id} approved successfully`);
            res.status(200).json({
                success: true,
                message: 'Phê duyệt người dùng thành công',
                data: normalizedUser
            });
        } catch (error) {
            console.error('❌ Error in approveUser:', error);
            console.error('Error details:', {
                message: error.message,
                code: error.code,
                number: error.number,
                stack: error.stack
            });
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi phê duyệt người dùng',
                error: error.message,
                stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
            });
        }
    },

    // Chặn người dùng (Admin only) - Vô hiệu hóa tài khoản
    async blockUser(req, res) {
        try {
            const { id } = req.params;
            console.log(`🔒 Blocking user with ID: ${id}`);
            const nguoiDung = new NguoiDung();
            
            // Find user by ID without status check
            const checkQuery = `SELECT * FROM ${nguoiDung.tableName} WHERE ${nguoiDung.primaryKey} = @id`;
            console.log(`🔍 Checking user existence: ${checkQuery}`);
            const checkResult = await nguoiDung.executeQuery(checkQuery, { id });
            const user = checkResult.recordset[0];
            
            if (!user) {
                console.log(`❌ User ${id} not found`);
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy người dùng'
                });
            }

            console.log(`✅ User found: ${user.email}, current status: ${user.trang_thai}`);

            // Update status to inactive using direct query
            // (Don't use update() because it calls findById which filters by trang_thai = 1)
            // Note: nguoi_dung table doesn't have updated_at column, so don't include it
            const blockQuery = `
                UPDATE ${nguoiDung.tableName} 
                SET trang_thai = CAST(0 AS BIT)
                WHERE ${nguoiDung.primaryKey} = @id
            `;
            
            console.log(`🔄 Executing block query: ${blockQuery}`);
            await nguoiDung.executeQuery(blockQuery, { id });
            
            // Verify update by checking if trang_thai was updated
            const verifyQuery = `SELECT ${nguoiDung.primaryKey}, trang_thai FROM ${nguoiDung.tableName} WHERE ${nguoiDung.primaryKey} = @id`;
            const verifyResult = await nguoiDung.executeQuery(verifyQuery, { id });
            const updatedUser = verifyResult.recordset[0];
            
            console.log(`🔍 Verification result:`, updatedUser);
            
            // Check if trang_thai is falsy (0, false, null) - means blocked
            const isBlocked = !updatedUser || 
                             updatedUser.trang_thai === 0 || 
                             updatedUser.trang_thai === false || 
                             updatedUser.trang_thai === null ||
                             updatedUser.trang_thai === '0';
            
            if (!isBlocked) {
                console.log(`❌ User status not updated correctly. Current status: ${updatedUser.trang_thai}`);
                return res.status(500).json({
                    success: false,
                    message: 'Không thể chặn người dùng - trạng thái không được cập nhật'
                });
            }

            // Return user data with normalized status
            const normalizedUser = {
                ...user,
                trang_thai: 0
            };
            delete normalizedUser.mat_khau; // Don't return password

            console.log(`✅ User ${id} blocked successfully`);
            res.status(200).json({
                success: true,
                message: 'Chặn người dùng thành công',
                data: normalizedUser
            });
        } catch (error) {
            console.error('❌ Error in blockUser:', error);
            console.error('Error details:', {
                message: error.message,
                code: error.code,
                number: error.number,
                stack: error.stack
            });
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi chặn người dùng',
                error: error.message,
                stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
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

    // Lấy thống kê cá nhân của người dùng hiện tại
    async getMyStats(req, res) {
        try {
            const nguoiDung = new NguoiDung();
            const userId = req.user.ma_nguoi_dung;
            
            // Lấy thống kê từ database
            const stats = await nguoiDung.getMyStats(userId);
            
            res.status(200).json({
                success: true,
                message: 'Lấy thống kê cá nhân thành công',
                data: stats
            });
        } catch (error) {
            console.error('Error in getMyStats:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy thống kê cá nhân',
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
            
            // Use COALESCE to handle different date column names - remove ngay_tao as it doesn't exist
            const statsQuery = `
                SELECT 
                    COUNT(*) as tong_nguoi_dung,
                    SUM(CASE WHEN trang_thai = CAST(1 AS BIT) THEN 1 ELSE 0 END) as nguoi_dung_hoat_dong,
                    SUM(CASE WHEN trang_thai = CAST(0 AS BIT) THEN 1 ELSE 0 END) as nguoi_dung_bi_khoa,
                    SUM(CASE WHEN chuc_vu = N'Admin' THEN 1 ELSE 0 END) as admin,
                    SUM(CASE WHEN chuc_vu = N'User' THEN 1 ELSE 0 END) as khach_hang,
                    SUM(CASE WHEN chuc_vu = N'HotelManager' THEN 1 ELSE 0 END) as quan_ly_khach_san,
                    SUM(CASE WHEN COALESCE(created_at, ngay_dang_ky, GETDATE()) >= DATEADD(DAY, -7, GETDATE()) THEN 1 ELSE 0 END) as dang_ky_7_ngay,
                    SUM(CASE WHEN COALESCE(created_at, ngay_dang_ky, GETDATE()) >= DATEADD(DAY, -30, GETDATE()) THEN 1 ELSE 0 END) as dang_ky_30_ngay
                FROM ${nguoiDung.tableName}
            `;
            
            console.log('📊 Getting user stats...');
            const result = await nguoiDung.executeQuery(statsQuery);
            const stats = result.recordset[0] || {};

            console.log('✅ User stats:', stats);

            res.status(200).json({
                success: true,
                message: 'Lấy thống kê người dùng thành công',
                data: stats
            });
        } catch (error) {
            console.error('❌ Error in getUserStats:', {
                message: error.message,
                stack: error.stack,
                code: error.code,
                number: error.number
            });
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy thống kê người dùng',
                error: error.message,
                stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
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

            // Create instance and update
            const nguoiDung = new NguoiDung();
            await nguoiDung.update(userId, { 
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
    },

    // Reset password cho user (Admin only)
    async resetPassword(req, res) {
        try {
            const { id } = req.params;
            const { new_password } = req.body;
            
            if (!new_password || new_password.length < 6) {
                return res.status(400).json({
                    success: false,
                    message: 'Mật khẩu mới phải có ít nhất 6 ký tự'
                });
            }

            const nguoiDung = new NguoiDung();
            // Admin can reset password for blocked users, so use direct query
            const query = `SELECT * FROM ${nguoiDung.tableName} WHERE ${nguoiDung.primaryKey} = @id`;
            const result = await nguoiDung.executeQuery(query, { id });
            const user = result.recordset[0] || null;
            
            if (!user) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy người dùng'
                });
            }

            // Hash new password
            const hashedPassword = await bcrypt.hash(new_password, 10);
            
            // Update password
            await nguoiDung.update(id, { mat_khau: hashedPassword });

            res.status(200).json({
                success: true,
                message: 'Đặt lại mật khẩu thành công'
            });
        } catch (error) {
            console.error('Error in resetPassword:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi đặt lại mật khẩu',
                error: error.message
            });
        }
    },

    // Update user role (Admin only)
    async updateRole(req, res) {
        try {
            const { id } = req.params;
            const { chuc_vu } = req.body;
            
            if (!chuc_vu || !['User', 'HotelManager', 'Admin'].includes(chuc_vu)) {
                return res.status(400).json({
                    success: false,
                    message: 'Vai trò không hợp lệ. Chỉ chấp nhận: User, HotelManager, Admin'
                });
            }

            const nguoiDung = new NguoiDung();
            // Admin can update role for blocked users, so use direct query
            const query = `SELECT * FROM ${nguoiDung.tableName} WHERE ${nguoiDung.primaryKey} = @id`;
            const result = await nguoiDung.executeQuery(query, { id });
            const user = result.recordset[0] || null;
            
            if (!user) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy người dùng'
                });
            }

            // Update role
            await nguoiDung.update(id, { chuc_vu });

            res.status(200).json({
                success: true,
                message: `Cập nhật vai trò thành ${chuc_vu} thành công`,
                data: { id, chuc_vu }
            });
        } catch (error) {
            console.error('Error in updateRole:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi cập nhật vai trò',
                error: error.message
            });
        }
    },

    // Get user activity logs (placeholder - cần tạo bảng activity_log)
    async getActivityLogs(req, res) {
        try {
            const { id } = req.params;
            const { limit = 50 } = req.query;
            
            // Placeholder - trong thực tế cần tạo bảng activity_log
            // và log các hoạt động như login, logout, thao tác CRUD
            res.status(200).json({
                success: true,
                message: 'Lấy nhật ký hoạt động thành công',
                data: []
            });
        } catch (error) {
            console.error('Error in getActivityLogs:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy nhật ký hoạt động',
                error: error.message
            });
        }
    }
};

module.exports = nguoidungController;