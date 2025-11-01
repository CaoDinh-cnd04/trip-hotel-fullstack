const { getPool } = require('../config/db');

/**
 * Auto-update room status based on checkout dates
 * This should be called periodically (e.g., daily cron job)
 */
exports.autoUpdateRoomStatus = async (req, res) => {
  try {
    const pool = getPool();
    
    // Find all rooms that should be available now
    // (bookings with checkout date < today and room status is 'Đã thuê')
    const updateQuery = `
      UPDATE phong
      SET trang_thai = N'Trống'
      WHERE id IN (
        SELECT DISTINCT b.room_id
        FROM bookings b
        WHERE b.check_out_date < CAST(GETDATE() AS DATE)
          AND b.booking_status != 'cancelled'
          AND EXISTS (
            SELECT 1 FROM phong p 
            WHERE p.id = b.room_id AND p.trang_thai = N'Đã thuê'
          )
      )
    `;
    
    const result = await pool.request().query(updateQuery);
    const updatedCount = result.rowsAffected[0];
    
    console.log(`✅ Auto-updated ${updatedCount} rooms to 'Trống' status`);
    
    res.json({
      success: true,
      message: `Đã cập nhật ${updatedCount} phòng về trạng thái trống`,
      data: {
        updatedCount
      }
    });
  } catch (error) {
    console.error('❌ Error auto-updating room status:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi cập nhật trạng thái phòng tự động',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

/**
 * Get rooms availability statistics
 */
exports.getRoomAvailability = async (req, res) => {
  try {
    const pool = getPool();
    const { hotelId } = req.query;
    
    let query = `
      SELECT 
        ks.id as hotel_id,
        ks.ten as hotel_name,
        COUNT(p.id) as total_rooms,
        SUM(CASE WHEN p.trang_thai = N'Trống' THEN 1 ELSE 0 END) as available_rooms,
        SUM(CASE WHEN p.trang_thai = N'Đã thuê' THEN 1 ELSE 0 END) as occupied_rooms
      FROM khach_san ks
      LEFT JOIN phong p ON p.khach_san_id = ks.id
    `;
    
    if (hotelId) {
      query += ` WHERE ks.id = @hotelId`;
    }
    
    query += ` GROUP BY ks.id, ks.ten ORDER BY ks.ten`;
    
    const request = pool.request();
    if (hotelId) {
      request.input('hotelId', hotelId);
    }
    
    const result = await request.query(query);
    
    res.json({
      success: true,
      data: result.recordset
    });
  } catch (error) {
    console.error('❌ Error getting room availability:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi lấy thông tin phòng trống',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

module.exports = exports;

