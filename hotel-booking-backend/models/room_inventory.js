const BaseModel = require('./baseModel');
const sql = require('mssql');

/**
 * Room Inventory Model - Quản lý số lượng phòng trống
 * Cải tiến để xử lý:
 * 1. Hiển thị số phòng còn lại
 * 2. Xử lý race condition khi đặt cùng lúc
 * 3. Tự động cập nhật availability
 */
class RoomInventory extends BaseModel {
    constructor() {
        super('room_inventory');
    }

    /**
     * Lấy số phòng available theo loại phòng và ngày
     * Trả về: { total_rooms, booked_rooms, available_rooms }
     */
    async getRoomAvailability(ma_khach_san, ma_loai_phong, ngay_checkin, ngay_checkout) {
        try {
            const query = `
                -- Đếm tổng số phòng của loại này
                WITH TotalRooms AS (
                    SELECT COUNT(*) as total
                    FROM phong 
                    WHERE ma_khach_san = @ma_khach_san 
                      AND ma_loai_phong = @ma_loai_phong
                      AND trang_thai = 1
                ),
                -- Đếm số phòng đã được đặt trong khoảng thời gian
                BookedRooms AS (
                    SELECT COUNT(DISTINCT p.ma_phong) as booked
                    FROM phong p
                    INNER JOIN phieu_dat_phong pdp ON p.ma_phong = pdp.ma_phong
                    WHERE p.ma_khach_san = @ma_khach_san 
                      AND p.ma_loai_phong = @ma_loai_phong
                      AND p.trang_thai = 1
                      AND pdp.trang_thai IN ('confirmed', 'checked_in', 'pending')
                      AND NOT (
                          @ngay_checkout <= pdp.ngay_checkin 
                          OR @ngay_checkin >= pdp.ngay_checkout
                      )
                )
                SELECT 
                    tr.total as total_rooms,
                    ISNULL(br.booked, 0) as booked_rooms,
                    tr.total - ISNULL(br.booked, 0) as available_rooms
                FROM TotalRooms tr
                CROSS JOIN BookedRooms br
            `;
            
            const result = await this.executeQuery(query, { 
                ma_khach_san, 
                ma_loai_phong,
                ngay_checkin, 
                ngay_checkout 
            });
            
            return result[0];
        } catch (error) {
            throw error;
        }
    }

    /**
     * Lấy availability cho tất cả loại phòng của khách sạn
     */
    async getHotelRoomAvailability(ma_khach_san, ngay_checkin, ngay_checkout) {
        try {
            const query = `
                WITH RoomCounts AS (
                    SELECT 
                        lp.ma_loai_phong,
                        lp.ten_loai_phong,
                        lp.gia_co_ban,
                        lp.dien_tich,
                        COUNT(p.ma_phong) as total_rooms
                    FROM loai_phong lp
                    LEFT JOIN phong p ON lp.ma_loai_phong = p.ma_loai_phong 
                        AND p.ma_khach_san = @ma_khach_san 
                        AND p.trang_thai = 1
                    WHERE lp.ma_khach_san = @ma_khach_san
                    GROUP BY lp.ma_loai_phong, lp.ten_loai_phong, lp.gia_co_ban, lp.dien_tich
                ),
                BookedCounts AS (
                    SELECT 
                        p.ma_loai_phong,
                        COUNT(DISTINCT p.ma_phong) as booked_rooms
                    FROM phong p
                    INNER JOIN phieu_dat_phong pdp ON p.ma_phong = pdp.ma_phong
                    WHERE p.ma_khach_san = @ma_khach_san
                      AND p.trang_thai = 1
                      AND pdp.trang_thai IN ('confirmed', 'checked_in', 'pending')
                      AND NOT (
                          @ngay_checkout <= pdp.ngay_checkin 
                          OR @ngay_checkin >= pdp.ngay_checkout
                      )
                    GROUP BY p.ma_loai_phong
                )
                SELECT 
                    rc.ma_loai_phong,
                    rc.ten_loai_phong,
                    rc.gia_co_ban,
                    rc.dien_tich,
                    rc.total_rooms,
                    ISNULL(bc.booked_rooms, 0) as booked_rooms,
                    rc.total_rooms - ISNULL(bc.booked_rooms, 0) as available_rooms,
                    CASE 
                        WHEN (rc.total_rooms - ISNULL(bc.booked_rooms, 0)) <= 2 
                            AND (rc.total_rooms - ISNULL(bc.booked_rooms, 0)) > 0
                        THEN 1 
                        ELSE 0 
                    END as is_low_availability,
                    CASE 
                        WHEN (rc.total_rooms - ISNULL(bc.booked_rooms, 0)) = 0 
                        THEN 1 
                        ELSE 0 
                    END as is_sold_out
                FROM RoomCounts rc
                LEFT JOIN BookedCounts bc ON rc.ma_loai_phong = bc.ma_loai_phong
                ORDER BY rc.gia_co_ban ASC
            `;
            
            const result = await this.executeQuery(query, { 
                ma_khach_san,
                ngay_checkin, 
                ngay_checkout 
            });
            
            return result;
        } catch (error) {
            throw error;
        }
    }

    /**
     * Đặt phòng với transaction lock để tránh race condition
     * ⚠️ QUAN TRỌNG: Xử lý khi 2 người đặt cùng lúc
     */
    async bookRoomWithLock(bookingData) {
        const transaction = new sql.Transaction(this.pool);
        
        try {
            await transaction.begin();
            
            const { ma_khach_san, ma_loai_phong, ngay_checkin, ngay_checkout, ma_nguoi_dung, so_khach, tong_tien } = bookingData;
            
            // 1. Lock và kiểm tra availability
            const checkQuery = `
                -- Tìm phòng available với UPDLOCK để lock ngay
                WITH AvailableRooms AS (
                    SELECT TOP 1 p.ma_phong
                    FROM phong p WITH (UPDLOCK, ROWLOCK)
                    WHERE p.ma_khach_san = @ma_khach_san 
                      AND p.ma_loai_phong = @ma_loai_phong
                      AND p.trang_thai = 1
                      AND p.ma_phong NOT IN (
                          SELECT pdp.ma_phong 
                          FROM phieu_dat_phong pdp WITH (NOLOCK)
                          WHERE pdp.trang_thai IN ('confirmed', 'checked_in', 'pending')
                            AND NOT (
                                @ngay_checkout <= pdp.ngay_checkin 
                                OR @ngay_checkin >= pdp.ngay_checkout
                            )
                      )
                    ORDER BY p.ma_phong
                )
                SELECT ma_phong FROM AvailableRooms
            `;
            
            const request = new sql.Request(transaction);
            request.input('ma_khach_san', sql.VarChar, ma_khach_san);
            request.input('ma_loai_phong', sql.VarChar, ma_loai_phong);
            request.input('ngay_checkin', sql.DateTime, ngay_checkin);
            request.input('ngay_checkout', sql.DateTime, ngay_checkout);
            
            const availableRoom = await request.query(checkQuery);
            
            if (availableRoom.recordset.length === 0) {
                await transaction.rollback();
                return {
                    success: false,
                    message: 'Không còn phòng trống trong khoảng thời gian này'
                };
            }
            
            const ma_phong = availableRoom.recordset[0].ma_phong;
            
            // 2. Tạo phiếu đặt phòng
            const insertQuery = `
                INSERT INTO phieu_dat_phong (
                    ma_phieu_dat_phong, ma_nguoi_dung, ma_phong, 
                    ngay_checkin, ngay_checkout, so_khach, tong_tien,
                    trang_thai, ngay_dat, ngay_tao
                )
                OUTPUT INSERTED.*
                VALUES (
                    @ma_phieu_dat_phong, @ma_nguoi_dung, @ma_phong,
                    @ngay_checkin, @ngay_checkout, @so_khach, @tong_tien,
                    'pending', GETDATE(), GETDATE()
                )
            `;
            
            const insertRequest = new sql.Request(transaction);
            insertRequest.input('ma_phieu_dat_phong', sql.VarChar, `PDP${Date.now()}`);
            insertRequest.input('ma_nguoi_dung', sql.VarChar, ma_nguoi_dung);
            insertRequest.input('ma_phong', sql.VarChar, ma_phong);
            insertRequest.input('ngay_checkin', sql.DateTime, ngay_checkin);
            insertRequest.input('ngay_checkout', sql.DateTime, ngay_checkout);
            insertRequest.input('so_khach', sql.Int, so_khach);
            insertRequest.input('tong_tien', sql.Decimal(18, 2), tong_tien);
            
            const result = await insertRequest.query(insertQuery);
            
            // 3. Commit transaction
            await transaction.commit();
            
            return {
                success: true,
                message: 'Đặt phòng thành công',
                data: result.recordset[0]
            };
            
        } catch (error) {
            await transaction.rollback();
            console.error('Book room error:', error);
            throw error;
        }
    }

    /**
     * Lấy lịch sử booking để tự động update availability
     * Không cần reset - hệ thống tự động tính based on booking records
     */
    async getUpcomingCheckouts() {
        try {
            const query = `
                SELECT 
                    pdp.*,
                    p.ma_khach_san,
                    p.ma_loai_phong
                FROM phieu_dat_phong pdp
                INNER JOIN phong p ON pdp.ma_phong = p.ma_phong
                WHERE pdp.trang_thai = 'checked_in'
                  AND pdp.ngay_checkout <= DATEADD(day, 1, GETDATE())
                ORDER BY pdp.ngay_checkout ASC
            `;
            
            return await this.executeQuery(query);
        } catch (error) {
            throw error;
        }
    }

    /**
     * Tự động checkout các phòng đã hết hạn
     * Chạy bằng CRON job mỗi ngày
     */
    async autoCheckoutExpiredBookings() {
        try {
            const query = `
                UPDATE phieu_dat_phong
                SET 
                    trang_thai = 'checked_out',
                    ngay_checkout_thuc_te = GETDATE(),
                    ngay_cap_nhat = GETDATE()
                WHERE trang_thai = 'checked_in'
                  AND ngay_checkout < CAST(GETDATE() AS DATE)
            `;
            
            const result = await this.executeQuery(query);
            return result.rowsAffected[0];
        } catch (error) {
            throw error;
        }
    }

    /**
     * Hủy tự động các booking pending quá lâu (15 phút)
     */
    async autoCancelExpiredPendingBookings() {
        try {
            const query = `
                UPDATE phieu_dat_phong
                SET 
                    trang_thai = 'cancelled',
                    ghi_chu = N'Tự động hủy do không thanh toán',
                    ngay_cap_nhat = GETDATE()
                WHERE trang_thai = 'pending'
                  AND ngay_dat < DATEADD(minute, -15, GETDATE())
            `;
            
            const result = await this.executeQuery(query);
            return result.rowsAffected[0];
        } catch (error) {
            throw error;
        }
    }
}

module.exports = RoomInventory;

