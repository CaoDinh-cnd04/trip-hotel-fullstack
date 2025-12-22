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
            
            console.log(`📊 Total promotions from DB: ${filteredResults.length}`);
            if (filteredResults.length > 0) {
                console.log(`📋 Sample promotion: ${JSON.stringify({
                    id: filteredResults[0].id,
                    ten: filteredResults[0].ten || filteredResults[0].ten_khuyen_mai,
                    trang_thai: filteredResults[0].trang_thai,
                    ngay_bat_dau: filteredResults[0].ngay_bat_dau,
                    ngay_ket_thuc: filteredResults[0].ngay_ket_thuc,
                    phan_tram: filteredResults[0].phan_tram
                })}`);
            }
            
            // Support both 'active' and 'active_only' parameters
            const shouldFilterActive = active === 'true' || active_only === 'true';
            
            if (shouldFilterActive) {
                const now = new Date();
                // Set time to start of day để so sánh chính xác với ngày
                const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
                console.log(`🔍 Filtering active promotions (current time: ${now.toISOString()}, today: ${today.toISOString()})`);
                const beforeFilter = filteredResults.length;
                
                // Log tất cả promotions trước khi filter để debug
                console.log(`📋 All promotions before filter:`);
                filteredResults.forEach((km, idx) => {
                    const isActive = km.trang_thai === true || km.trang_thai === 1 || km.trang_thai === '1';
                    const startDate = new Date(km.ngay_bat_dau);
                    const endDate = new Date(km.ngay_ket_thuc);
                    // Set time to start of day để so sánh chính xác
                    const startDateOnly = new Date(startDate.getFullYear(), startDate.getMonth(), startDate.getDate());
                    const endDateOnly = new Date(endDate.getFullYear(), endDate.getMonth(), endDate.getDate());
                    
                    // Promotion còn hiệu lực nếu: trang_thai = true VÀ endDate >= today (chưa hết hạn)
                    // Cho phép cả promotions sắp bắt đầu (startDate > today) và đang hoạt động (startDate <= today)
                    const isValid = isActive && endDateOnly >= today;
                    
                    console.log(`   ${idx + 1}. ID: ${km.id}, Ten: ${km.ten || km.ten_khuyen_mai || 'N/A'}, ` +
                        `trang_thai: ${km.trang_thai} (${typeof km.trang_thai}), ` +
                        `start: ${startDateOnly.toISOString()}, end: ${endDateOnly.toISOString()}, ` +
                        `today: ${today.toISOString()}, valid: ${isValid}`);
                });
                
                filteredResults = filteredResults.filter(km => {
                    // Support both boolean and integer for trang_thai
                    const isActive = km.trang_thai === true || km.trang_thai === 1 || km.trang_thai === '1';
                    if (!isActive) return false;
                    
                    const startDate = new Date(km.ngay_bat_dau);
                    const endDate = new Date(km.ngay_ket_thuc);
                    // Set time to start of day để so sánh chính xác
                    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
                    const startDateOnly = new Date(startDate.getFullYear(), startDate.getMonth(), startDate.getDate());
                    const endDateOnly = new Date(endDate.getFullYear(), endDate.getMonth(), endDate.getDate());
                    
                    // Promotion còn hiệu lực nếu: endDate >= today (chưa hết hạn)
                    // Không cần kiểm tra startDate vì có thể promotion sắp bắt đầu trong tương lai
                    // Chỉ cần đảm bảo endDate chưa qua (>= today)
                    const isValid = endDateOnly >= today;
                    
                    return isValid;
                });
                console.log(`   ✅ After active filter: ${filteredResults.length}/${beforeFilter} promotions`);
                
                if (filteredResults.length === 0 && beforeFilter > 0) {
                    console.log(`⚠️ WARNING: All ${beforeFilter} promotions were filtered out!`);
                    console.log(`   This might be because:`);
                    console.log(`   - All promotions have trang_thai = false/0`);
                    console.log(`   - All promotions have endDate < today (đã hết hạn)`);
                    console.log(`   - Date parsing issue`);
                }
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

            console.log(`✅ Retrieved ${paginatedResults.length} promotions from page ${page} (limit: ${limit}, total available: ${filteredResults.length}, active filter: ${shouldFilterActive})`);
            
            if (paginatedResults.length < filteredResults.length) {
                console.log(`⚠️ Pagination: Showing ${paginatedResults.length} of ${filteredResults.length} promotions. Increase limit or use page parameter to see more.`);
            }

            // Map database fields to Flutter-friendly format
            const mappedResults = paginatedResults.map((km, index) => {
                const mapped = {
                    ...km,
                    phan_tram_giam: km.phan_tram, // Add Flutter-expected field
                    location: km.ten_vi_tri || km.ten_tinh_thanh || 'Việt Nam', // Location for display (prioritize vi_tri)
                    hotel_name: km.ten_khach_san,
                    hotel_address: km.dia_chi,
                    image: km.hotel_image
                };
                
                // Log first 3 promotions for debugging
                if (index < 3) {
                    console.log(`   📦 Mapped promotion ${index + 1}: id=${mapped.id}, ten=${mapped.ten || mapped.ten_khuyen_mai}, phan_tram_giam=${mapped.phan_tram_giam}`);
                }
                
                return mapped;
            });

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
            const { tong_tien, check_in_date } = req.query;
            
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
                
                // Kiểm tra thời gian hiệu lực cơ bản
                const isWithinValidPeriod = isActive &&
                                           new Date(promotion.ngay_bat_dau) <= currentDate &&
                                           new Date(promotion.ngay_ket_thuc) >= currentDate;

                // Kiểm tra điều kiện thời gian (cuối tuần, ngày hè, v.v.)
                let timeValidation = { isValid: true, reason: null };
                if (check_in_date && isWithinValidPeriod) {
                    const { parsePromotionTimeConditions, validatePromotionTime } = require('../utils/promotionTimeValidator');
                    
                    try {
                        const checkInDate = new Date(check_in_date);
                        if (!isNaN(checkInDate.getTime())) {
                            // Phân tích điều kiện thời gian từ tên và mô tả
                            const timeConditions = parsePromotionTimeConditions(
                                promotion.ten || promotion.ten_khuyen_mai,
                                promotion.mo_ta
                            );
                            
                            // Kiểm tra xem check-in date có thỏa mãn điều kiện không
                            timeValidation = validatePromotionTime(checkInDate, timeConditions);
                            
                            console.log(`🔍 Promotion ${id} time validation:`, {
                                checkInDate: checkInDate.toISOString(),
                                conditions: timeConditions,
                                isValid: timeValidation.isValid,
                                reason: timeValidation.reason,
                            });
                        }
                    } catch (dateError) {
                        console.error('Error parsing check_in_date:', dateError);
                        // Nếu không parse được date, bỏ qua validation thời gian
                    }
                }

                // Promotion hợp lệ nếu: trong thời gian hiệu lực VÀ thỏa mãn điều kiện thời gian
                const isValid = isWithinValidPeriod && timeValidation.isValid;

                let discountAmount = 0;
                if (isValid && tong_tien) {
                    // Use phan_tram field from database
                    discountAmount = (parseFloat(tong_tien) * promotion.phan_tram) / 100;
                    if (promotion.giam_toi_da && discountAmount > promotion.giam_toi_da) {
                        discountAmount = promotion.giam_toi_da;
                    }
                }

                // Tạo message phù hợp
                let message = 'Khuyến mãi hợp lệ';
                if (!isWithinValidPeriod) {
                    message = 'Khuyến mãi không hợp lệ hoặc đã hết hạn';
                } else if (!timeValidation.isValid) {
                    message = timeValidation.reason || 'Không thể áp dụng ưu đãi này vào thời điểm này';
                }

                res.status(200).json({
                    success: true,
                    message: message,
                    data: {
                        promotion,
                        isValid,
                        discountAmount,
                        timeValidation: {
                            isValid: timeValidation.isValid,
                            reason: timeValidation.reason,
                        },
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
            const parsedId = parseInt(id);
            
            if (isNaN(parsedId)) {
                return res.status(400).json({
                    success: false,
                    message: 'ID không hợp lệ'
                });
            }
            
            console.log(`🗑️ Deleting promotion offer with ID: ${parsedId}`);
            const { getPool } = require('../config/db');
            const sql = require('mssql');
            const pool = await getPool();
            
            // Kiểm tra xem ưu đãi có tồn tại không
            const checkQuery = `SELECT id, trang_thai FROM dbo.khuyen_mai WHERE id = @id`;
            const checkResult = await pool.request()
                .input('id', sql.Int, parsedId)
                .query(checkQuery);
            
            if (!checkResult.recordset || checkResult.recordset.length === 0) {
                console.log(`❌ Promotion offer ${parsedId} not found`);
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy khuyến mãi'
                });
            }
            
            console.log(`✅ Found promotion offer ${parsedId}, proceeding with hard delete`);
            
            // Hard delete - xóa thực sự khỏi database
            // Sử dụng transaction để đảm bảo commit
            const transaction = new sql.Transaction(pool);
            
            try {
                await transaction.begin();
                console.log(`🔄 Transaction started for deleting promotion offer ${parsedId}`);
                
                const deleteQuery = `
                    DELETE FROM dbo.khuyen_mai 
                    WHERE id = @id
                `;
                
                console.log(`🔄 Executing DELETE query for ID: ${parsedId}`);
                console.log(`Query: ${deleteQuery}`);
                
                const request = new sql.Request(transaction);
                const deleteResult = await request
                    .input('id', sql.Int, parsedId)
                    .query(deleteQuery);
                
                console.log(`📊 Delete result:`, {
                    rowsAffected: deleteResult.rowsAffected,
                    rowsAffectedArray: deleteResult.rowsAffected[0],
                    recordset: deleteResult.recordset
                });
                
                if (deleteResult.rowsAffected[0] === 0) {
                    await transaction.rollback();
                    console.log(`⚠️ No rows affected for promotion offer ${parsedId}, rolling back`);
                    return res.status(404).json({
                        success: false,
                        message: 'Không tìm thấy khuyến mãi để xóa hoặc không thể xóa'
                    });
                }
                
                // Commit transaction
                await transaction.commit();
                console.log(`✅ Transaction committed for promotion offer ${parsedId}`);
                
                // Verify deletion sau khi commit
                await new Promise(resolve => setTimeout(resolve, 200));
                
                const verifyQuery = `SELECT id FROM dbo.khuyen_mai WHERE id = @id`;
                const verifyResult = await pool.request()
                    .input('id', sql.Int, parsedId)
                    .query(verifyQuery);
                
                console.log(`🔍 Verification query result:`, {
                    recordCount: verifyResult.recordset?.length || 0,
                    records: verifyResult.recordset
                });
                
                if (verifyResult.recordset && verifyResult.recordset.length > 0) {
                    console.log(`⚠️ Promotion offer ${parsedId} still exists after delete`);
                    return res.status(500).json({
                        success: false,
                        message: 'Xóa không thành công - ưu đãi vẫn còn trong database',
                        error: {
                            message: 'Record still exists after delete operation',
                            id: parsedId
                        }
                    });
                }

                console.log(`✅ Successfully deleted promotion offer ${parsedId} from database`);
                res.status(200).json({
                    success: true,
                    message: 'Xóa khuyến mãi thành công',
                    data: {
                        deletedId: parsedId
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
                        message: 'Không thể xóa khuyến mãi vì đang được sử dụng trong hệ thống (có đơn đặt phòng đang sử dụng mã này)',
                        error: process.env.NODE_ENV === 'development' ? {
                            message: deleteError.message,
                            number: deleteError.number
                        } : undefined
                    });
                }
                throw deleteError; // Re-throw để catch block xử lý
            }
        } catch (error) {
            console.error('❌ Error in deleteKhuyenMai:', error);
            console.error('Error details:', {
                message: error.message,
                code: error.code,
                number: error.number,
                originalError: error.originalError?.message
            });
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi xóa khuyến mãi',
                error: process.env.NODE_ENV === 'development' ? {
                    message: error.message,
                    code: error.code,
                    number: error.number
                } : undefined
            });
        }
    },

    // Bật/tắt khuyến mãi (Admin only)
    async toggleKhuyenMai(req, res) {
        try {
            const { id } = req.params;
            const { getPool } = require('../config/db');
            const sql = require('mssql');
            const pool = await getPool();
            
            // Kiểm tra xem ưu đãi có tồn tại không
            const checkQuery = `SELECT id, trang_thai FROM dbo.khuyen_mai WHERE id = @id`;
            const checkResult = await pool.request()
                .input('id', sql.Int, parseInt(id))
                .query(checkQuery);
            
            if (!checkResult.recordset || checkResult.recordset.length === 0) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy khuyến mãi'
                });
            }

            const existing = checkResult.recordset[0];
            // Xử lý trang_thai - có thể là BIT (true/false) hoặc số (1/0)
            const currentStatus = existing.trang_thai === true || existing.trang_thai === 1 || existing.trang_thai === '1';
            const newStatus = currentStatus ? 0 : 1;
            
            // Update với CAST BIT
            const updateQuery = `
                UPDATE dbo.khuyen_mai 
                SET trang_thai = CAST(@newStatus AS BIT)
                WHERE id = @id
            `;
            
            const updateResult = await pool.request()
                .input('id', sql.Int, parseInt(id))
                .input('newStatus', sql.Int, newStatus)
                .query(updateQuery);
            
            if (updateResult.rowsAffected[0] === 0) {
                return res.status(500).json({
                    success: false,
                    message: 'Không thể thay đổi trạng thái khuyến mãi'
                });
            }

            res.status(200).json({
                success: true,
                message: `${newStatus === 1 ? 'Kích hoạt' : 'Vô hiệu hóa'} khuyến mãi thành công`
            });
        } catch (error) {
            console.error('Error in toggleKhuyenMai:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi thay đổi trạng thái khuyến mãi',
                error: process.env.NODE_ENV === 'development' ? error.message : undefined
            });
        }
    }
};

module.exports = khuyenmaiController;