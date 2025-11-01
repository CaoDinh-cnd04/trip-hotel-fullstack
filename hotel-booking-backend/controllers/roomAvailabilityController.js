const { getPool } = require('../config/db');
const sql = require('mssql');

/**
 * Check room availability based on bookings
 * Returns real-time availability status for each room TYPE (not individual rooms)
 * ✅ FIXED: Count total rooms vs booked rooms per room type
 */
exports.getRoomAvailability = async (req, res) => {
  try {
    const { hotel_id } = req.params;
    const { check_in, check_out } = req.query;
    
    const pool = await getPool();
    
    // ✅ NEW LOGIC: Count rooms by type, not individual room occupancy
    const query = `
      WITH RoomCounts AS (
        -- Đếm tổng số phòng theo từng loại
        SELECT 
          p.loai_phong_id,
          lp.ten AS ten_loai_phong,
          MIN(p.gia_tien) as gia_tien,
          MIN(p.mo_ta) as mo_ta,
          MIN(p.hinh_anh) as hinh_anh,
          MIN(p.dien_tich) as dien_tich,
          COUNT(DISTINCT p.id) as total_rooms,
          MIN(p.id) as sample_room_id
        FROM dbo.phong p
        INNER JOIN dbo.loai_phong lp ON p.loai_phong_id = lp.id
        WHERE p.khach_san_id = @hotel_id
        GROUP BY p.loai_phong_id, lp.ten
      ),
      BookedCounts AS (
        -- Đếm số phòng đã được đặt theo từng loại
        SELECT 
          p.loai_phong_id,
          COUNT(DISTINCT b.room_id) as booked_rooms
        FROM dbo.bookings b
        INNER JOIN dbo.phong p ON b.room_id = p.id
        WHERE p.khach_san_id = @hotel_id
          AND b.booking_status NOT IN ('pending', 'cancelled', 'completed')
          ${check_in && check_out ? `
          AND (
            (b.check_in_date < @check_out AND b.check_out_date > @check_in)
          )` : `AND b.check_out_date >= GETDATE()`}
        GROUP BY p.loai_phong_id
      )
      SELECT 
        rc.sample_room_id as id,
        rc.loai_phong_id,
        rc.ten_loai_phong,
        rc.gia_tien,
        rc.mo_ta,
        rc.hinh_anh,
        rc.dien_tich,
        @hotel_id as khach_san_id,
        CAST(2 AS INT) as suc_chua,
        CAST(0 AS INT) as so_giuong_don,
        CAST(1 AS INT) as so_giuong_doi,
        
        -- Total rooms of this type
        rc.total_rooms,
        
        -- Available rooms (total - booked)
        (rc.total_rooms - ISNULL(bc.booked_rooms, 0)) as available_count,
        
        -- Occupied rooms
        ISNULL(bc.booked_rooms, 0) as occupied_count,
        
        -- Overall availability status
        CASE 
          WHEN (rc.total_rooms - ISNULL(bc.booked_rooms, 0)) > 0 THEN 1
          ELSE 0
        END as is_available,
        
        -- Status text with count
        CASE 
          WHEN (rc.total_rooms - ISNULL(bc.booked_rooms, 0)) > 0 
            THEN N'Còn trống (' + CAST((rc.total_rooms - ISNULL(bc.booked_rooms, 0)) AS NVARCHAR) + N')'
          ELSE N'Hết phòng'
        END as trang_thai_text,
        
        -- Status color
        CASE 
          WHEN (rc.total_rooms - ISNULL(bc.booked_rooms, 0)) > 0 THEN '#008000'
          ELSE '#FF0000'
        END as trang_thai_color
        
      FROM RoomCounts rc
      LEFT JOIN BookedCounts bc ON rc.loai_phong_id = bc.loai_phong_id
      ORDER BY rc.gia_tien ASC
    `;
    
    const request = pool.request().input('hotel_id', sql.Int, hotel_id);
    
    if (check_in && check_out) {
      request.input('check_in', sql.Date, check_in);
      request.input('check_out', sql.Date, check_out);
    }
    
    const result = await request.query(query);
    
    console.log(`✅ Room availability for hotel ${hotel_id}:`, result.recordset.map(r => ({
      type: r.ten_loai_phong,
      total: r.total_rooms,
      available: r.available_count,
      occupied: r.occupied_count
    })));
    
    res.json({
      success: true,
      data: result.recordset,
      summary: {
        total_room_types: result.recordset.length,
        total_rooms: result.recordset.reduce((sum, r) => sum + r.total_rooms, 0),
        available_rooms: result.recordset.reduce((sum, r) => sum + r.available_count, 0),
        occupied_rooms: result.recordset.reduce((sum, r) => sum + r.occupied_count, 0)
      }
    });
    
  } catch (error) {
    console.error('❌ Error getting room availability:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi lấy trạng thái phòng',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

/**
 * Get availability summary for a hotel
 */
exports.getHotelAvailabilitySummary = async (req, res) => {
  try {
    const { hotel_id } = req.params;
    const pool = await getPool();
    
    const query = `
      SELECT 
        COUNT(p.id) as total_rooms,
        SUM(CASE 
          WHEN NOT EXISTS (
            SELECT 1 FROM bookings b
            WHERE b.room_id = p.id
              AND b.booking_status NOT IN ('pending', 'cancelled', 'completed')
              AND b.check_out_date >= GETDATE()
          ) THEN 1
          ELSE 0
        END) as available_now,
        SUM(CASE 
          WHEN EXISTS (
            SELECT 1 FROM bookings b
            WHERE b.room_id = p.id
              AND b.booking_status NOT IN ('pending', 'cancelled', 'completed')
              AND b.check_out_date >= GETDATE()
          ) THEN 1
          ELSE 0
        END) as occupied_now
      FROM phong p
      WHERE p.khach_san_id = @hotel_id
    `;
    
    const result = await pool.request()
      .input('hotel_id', sql.Int, hotel_id)
      .query(query);
    
    res.json({
      success: true,
      data: result.recordset[0]
    });
    
  } catch (error) {
    console.error('❌ Error getting availability summary:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi lấy thống kê phòng',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

