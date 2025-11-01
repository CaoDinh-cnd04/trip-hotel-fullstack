const { getPool } = require('../config/db');

/**
 * Auto-update room status - runs every hour
 * NOTE: Disabled due to CHECK constraint on room status
 * Room availability is managed through booking records
 */
async function updateRoomStatus() {
  try {
    console.log('🕐 Running scheduled room status update... (DISABLED)');
    // Room availability is now managed through booking records
    // No direct room status updates needed
  } catch (error) {
    console.error('❌ Error in scheduled room status update:', error);
  }
}

/**
 * Start the scheduler - runs every hour
 */
function startRoomStatusScheduler() {
  // Run immediately on startup
  updateRoomStatus();
  
  // Run every hour (3600000 ms)
  setInterval(updateRoomStatus, 3600000);
  
  console.log('✅ Room status scheduler started (runs every hour)');
}

module.exports = { startRoomStatusScheduler };

