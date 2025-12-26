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
      -- Cập nhật booking thành 'completed' khi qua ngày checkout
      -- Đơn giản: chỉ cần qua 23:59:59 của ngày checkout là hoàn thành
      UPDATE bookings
      SET 
        booking_status = 'completed',
        updated_at = GETDATE()
      WHERE booking_status IN ('confirmed', 'in_progress', 'checked_in')
        AND CAST(check_out_date AS DATE) < CAST(GETDATE() AS DATE);
      
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
 * Tự động hủy booking quá thời gian xác nhận (pending quá 24h) hoặc quá thời gian check-in
 */
async function autoCancelExpiredBookings() {
  try {
    const pool = getPool();
    const sql = require('mssql');
    
    console.log('🔄 Checking for expired bookings to auto-cancel...');
    
    const result = await pool.request().query(`
      -- Tự động hủy booking pending quá 24h (không được xác nhận)
      -- Hoặc booking confirmed nhưng đã qua thời gian check-in (quá 24h sau check-in date)
      UPDATE bookings
      SET 
        booking_status = 'cancelled',
        cancelled_at = GETDATE(),
        refund_status = 'requested',
        refund_reason = CASE 
          WHEN booking_status = 'pending' AND DATEDIFF(hour, created_at, GETDATE()) > 24 
            THEN N'Tự động hủy: Quá thời gian xác nhận (24 giờ)'
          WHEN booking_status = 'confirmed' AND CAST(check_in_date AS DATE) < CAST(GETDATE() AS DATE)
            THEN N'Tự động hủy: Quá thời gian check-in'
          ELSE N'Tự động hủy: Quá thời gian'
        END,
        updated_at = GETDATE()
      WHERE (
        -- Pending quá 24h
        (booking_status = 'pending' 
         AND DATEDIFF(hour, created_at, GETDATE()) > 24)
        OR
        -- Confirmed nhưng đã qua ngày check-in (quá 24h sau check-in date)
        (booking_status = 'confirmed' 
         AND CAST(check_in_date AS DATE) < CAST(GETDATE() AS DATE))
      )
      AND booking_status NOT IN ('cancelled', 'completed');
      
      SELECT @@ROWCOUNT as cancelledCount;
    `);
    
    const cancelledCount = result.recordset[0]?.cancelledCount || 0;
    
    if (cancelledCount > 0) {
      console.log(`✅ Auto-cancelled ${cancelledCount} expired booking(s)`);
      
      // Gửi email thông báo cho user (nếu cần)
      // TODO: Có thể thêm logic gửi email ở đây
    } else {
      console.log('ℹ️  No expired bookings to cancel');
    }
    
    return cancelledCount;
  } catch (error) {
    console.error('❌ Error auto-cancelling expired bookings:', error);
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
    await autoCancelExpiredBookings(); // ✅ NEW: Tự động hủy booking quá hạn
    
    console.log('✅ Booking status update completed\n');
  } catch (error) {
    console.error('❌ Booking status update failed:', error);
  }
}

module.exports = {
  updateCompletedBookings,
  updateInProgressBookings,
  autoCancelExpiredBookings,
  runAllBookingUpdates,
};
