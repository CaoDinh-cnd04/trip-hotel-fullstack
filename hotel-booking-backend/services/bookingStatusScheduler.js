const { getPool } = require('../config/db');

/**
 * Tự động cập nhật trạng thái booking thành 'completed'
 * khi khách đã check-out (qua ngày trả phòng + giờ trả phòng)
 */
async function updateCompletedBookings() {
  try {
    console.log('🕐 Running booking status update...');
    const pool = getPool();
    
    const result = await pool.request().query(`
      -- Cập nhật booking thành 'completed' khi qua checkout time
      UPDATE bookings
      SET 
        booking_status = 'completed',
        updated_at = GETDATE()
      WHERE booking_status IN ('confirmed', 'in_progress')
        AND DATEADD(
          HOUR, 
          ISNULL(DATEPART(HOUR, (SELECT TOP 1 gio_tra_phong FROM khach_san WHERE id = bookings.hotel_id)), 12),
          CAST(check_out_date AS DATETIME)
        ) <= GETDATE();
      
      -- Return số bookings đã update
      SELECT @@ROWCOUNT as updatedCount;
    `);
    
    const updatedCount = result.recordset[0]?.updatedCount || 0;
    
    if (updatedCount > 0) {
      console.log(`✅ Updated ${updatedCount} booking(s) to 'completed'`);
    } else {
      console.log('ℹ️  No bookings to update');
    }
    
    return updatedCount;
  } catch (error) {
    console.error('❌ Error updating booking status:', error);
    throw error;
  }
}

/**
 * Tự động cập nhật trạng thái booking thành 'in_progress' (đang diễn ra)
 * khi khách đã check-in (qua ngày nhận phòng + giờ nhận phòng)
 */
async function updateInProgressBookings() {
  try {
    const pool = getPool();
    
    const result = await pool.request().query(`
      -- Cập nhật booking thành 'in_progress' khi qua check-in time
      UPDATE bookings
      SET 
        booking_status = 'in_progress',
        updated_at = GETDATE()
      WHERE booking_status = 'confirmed'
        AND DATEADD(
          HOUR, 
          ISNULL(DATEPART(HOUR, (SELECT TOP 1 gio_nhan_phong FROM khach_san WHERE id = bookings.hotel_id)), 14),
          CAST(check_in_date AS DATETIME)
        ) <= GETDATE()
        AND DATEADD(
          HOUR, 
          ISNULL(DATEPART(HOUR, (SELECT TOP 1 gio_tra_phong FROM khach_san WHERE id = bookings.hotel_id)), 12),
          CAST(check_out_date AS DATETIME)
        ) > GETDATE();
      
      SELECT @@ROWCOUNT as updatedCount;
    `);
    
    const updatedCount = result.recordset[0]?.updatedCount || 0;
    
    if (updatedCount > 0) {
      console.log(`✅ Updated ${updatedCount} booking(s) to 'in_progress'`);
    }
    
    return updatedCount;
  } catch (error) {
    console.error('❌ Error updating in-progress bookings:', error);
    throw error;
  }
}

/**
 * Chạy tất cả updates
 */
async function runAllBookingUpdates() {
  try {
    console.log('\n📋 === BOOKING STATUS AUTO-UPDATE ===');
    console.log('⏰ Time:', new Date().toLocaleString());
    
    await updateInProgressBookings();
    await updateCompletedBookings();
    
    console.log('✅ Booking status update completed\n');
  } catch (error) {
    console.error('❌ Booking status update failed:', error);
  }
}

module.exports = {
  updateCompletedBookings,
  updateInProgressBookings,
  runAllBookingUpdates,
};
