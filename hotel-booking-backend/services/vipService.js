/**
 * VIP Service - Tính toán VIP points và level cho TriphotelVIP
 * 
 * Hệ thống VIP giống AgodaVIP:
 * - Bronze: 0-999 points (mặc định)
 * - Silver: 1,000-4,999 points
 * - Gold: 5,000-9,999 points
 * - Diamond: 10,000+ points
 * 
 * Cách tính points:
 * - Mỗi booking thành công và đã thanh toán: 100 points + (finalPrice / 100)
 * - Ví dụ: Booking 2,000,000 VND = 100 + 20,000 = 20,100 points
 */

const { getPool } = require('../config/db');
const sql = require('mssql');

class VipService {
  /**
   * Tính VIP points dựa trên booking
   * @param {number} finalPrice - Giá cuối cùng sau discount (VND)
   * @returns {number} - Số points được cộng
   */
  static calculatePoints(finalPrice) {
    if (!finalPrice || finalPrice <= 0) return 0;
    
    // Base points cho mỗi booking
    const basePoints = 100;
    
    // Bonus points dựa trên giá tiền (1 point cho mỗi 100 VND)
    const bonusPoints = Math.floor(finalPrice / 100);
    
    // Tổng points
    const totalPoints = basePoints + bonusPoints;
    
    console.log(`💰 VIP Points calculation: Base=${basePoints}, Bonus=${bonusPoints}, Total=${totalPoints} for price=${finalPrice}`);
    
    return totalPoints;
  }

  /**
   * Xác định VIP level dựa trên tổng points
   * @param {number} totalPoints - Tổng VIP points của user
   * @returns {object} - {level: string, status: string, nextLevelPoints: number}
   */
  static determineVipLevel(totalPoints) {
    let level = 'Bronze';
    let status = 'Standard';
    let nextLevelPoints = 1000; // Points cần để lên Silver
    
    if (totalPoints >= 10000) {
      level = 'Diamond';
      status = 'VIP';
      nextLevelPoints = null; // Đã đạt hạng cao nhất
    } else if (totalPoints >= 5000) {
      level = 'Gold';
      status = 'VIP';
      nextLevelPoints = 10000; // Points cần để lên Diamond
    } else if (totalPoints >= 1000) {
      level = 'Silver';
      status = 'VIP';
      nextLevelPoints = 5000; // Points cần để lên Gold
    } else {
      level = 'Bronze';
      status = 'Standard';
      nextLevelPoints = 1000; // Points cần để lên Silver
    }

    return { level, status, nextLevelPoints };
  }

  /**
   * Cộng VIP points cho user sau khi booking thành công
   * @param {number} userId - ID của user
   * @param {number} finalPrice - Giá cuối cùng của booking (VND)
   * @returns {Promise<object>} - Thông tin VIP sau khi update
   */
  static async addPointsAfterBooking(userId, finalPrice) {
    try {
      console.log(`🔍 addPointsAfterBooking called: userId=${userId}, finalPrice=${finalPrice}`);
      
      if (!userId || userId <= 0) {
        console.error(`❌ Invalid userId: ${userId}`);
        return null;
      }
      
      if (!finalPrice || finalPrice <= 0) {
        console.error(`❌ Invalid finalPrice: ${finalPrice}`);
        return null;
      }
      
      const pool = await getPool();
      const request = pool.request();
      
      // Tính points được cộng
      const pointsToAdd = this.calculatePoints(finalPrice);
      console.log(`💰 Points to add: ${pointsToAdd} (from price: ${finalPrice})`);
      
      if (pointsToAdd <= 0) {
        console.log(`⚠️ No points to add for booking (price: ${finalPrice})`);
        return null;
      }

      // Lấy VIP points hiện tại
      const currentVipResult = await request
        .input('userId', sql.Int, userId)
        .query(`
          SELECT vip_points, vip_level, vip_status
          FROM nguoi_dung
          WHERE id = @userId
        `);

      if (currentVipResult.recordset.length === 0) {
        console.error(`❌ User not found: ${userId}`);
        return null;
      }
      
      console.log(`📊 Current VIP info: points=${currentVipResult.recordset[0].vip_points}, level=${currentVipResult.recordset[0].vip_level}`);

      const currentVipPoints = currentVipResult.recordset[0].vip_points || 0;
      const newTotalPoints = currentVipPoints + pointsToAdd;

      // Xác định VIP level mới
      const { level, status } = this.determineVipLevel(newTotalPoints);

      // Update VIP points và level trong database
      await request
        .input('userId', sql.Int, userId)
        .input('newPoints', sql.Int, newTotalPoints)
        .input('newLevel', sql.NVarChar(50), level)
        .input('newStatus', sql.NVarChar(50), status)
        .query(`
          UPDATE nguoi_dung
          SET 
            vip_points = @newPoints,
            vip_level = @newLevel,
            vip_status = @newStatus,
            updated_at = GETDATE()
          WHERE id = @userId
        `);

      console.log(`✅ VIP Points updated: User ${userId} received ${pointsToAdd} points. Total: ${newTotalPoints}. Level: ${level}`);

      // Kiểm tra xem có lên hạng không
      const oldLevel = currentVipResult.recordset[0].vip_level || 'Bronze';
      const leveledUp = oldLevel !== level;

      return {
        pointsAdded: pointsToAdd,
        previousPoints: currentVipPoints,
        newTotalPoints: newTotalPoints,
        previousLevel: oldLevel,
        newLevel: level,
        newStatus: status,
        leveledUp: leveledUp
      };
    } catch (error) {
      console.error('❌ Error adding VIP points:', error);
      throw error;
    }
  }

  /**
   * Lấy thông tin VIP chi tiết của user
   * @param {number} userId - ID của user
   * @returns {Promise<object>} - Thông tin VIP
   */
  static async getVipInfo(userId) {
    try {
      const pool = await getPool();
      const request = pool.request();
      
      const result = await request
        .input('userId', sql.Int, userId)
        .query(`
          SELECT 
            id,
            ten as name,
            email,
            vip_points as vipPoints,
            vip_level as vipLevel,
            vip_status as vipStatus,
            created_at as memberSince
          FROM nguoi_dung
          WHERE id = @userId
        `);

      if (result.recordset.length === 0) {
        return null;
      }

      const user = result.recordset[0];
      const totalPoints = user.vipPoints || 0;
      
      // Xác định VIP level và thông tin liên quan
      const { level, status, nextLevelPoints } = VipService.determineVipLevel(totalPoints);
      
      // Tính progress đến level tiếp theo (0-100%)
      let progressToNextLevel = 0;
      if (nextLevelPoints) {
        const currentLevelMinPoints = VipService.getLevelMinPoints(level);
        const range = nextLevelPoints - currentLevelMinPoints;
        const progress = totalPoints - currentLevelMinPoints;
        progressToNextLevel = Math.min(100, Math.max(0, (progress / range) * 100));
      }

      return {
        id: user.id,
        name: user.name,
        email: user.email,
        vipPoints: totalPoints,
        vipLevel: level,
        vipStatus: status,
        nextLevelPoints: nextLevelPoints,
        progressToNextLevel: Math.round(progressToNextLevel),
        memberSince: user.memberSince,
        benefits: VipService.getLevelBenefits(level)
      };
    } catch (error) {
      console.error('❌ Error getting VIP info:', error);
      throw error;
    }
  }

  /**
   * Lấy điểm tối thiểu của level
   * @param {string} level - VIP level
   * @returns {number} - Điểm tối thiểu
   */
  static getLevelMinPoints(level) {
    const levelMap = {
      'Bronze': 0,
      'Silver': 1000,
      'Gold': 5000,
      'Diamond': 10000
    };
    return levelMap[level] || 0;
  }

  /**
   * Lấy quyền lợi của từng level
   * @param {string} level - VIP level
   * @returns {array} - Danh sách quyền lợi
   */
  static getLevelBenefits(level) {
    const benefitsMap = {
      'Bronze': [
        'Ưu tiên hỗ trợ khách hàng',
        'Tích điểm cho mỗi booking',
      ],
      'Silver': [
        'Tất cả quyền lợi Bronze',
        'Giảm giá 5% cho mọi booking',
        'Check-in sớm và check-out muộn (nếu có phòng)',
        'Đổi điểm thành voucher',
      ],
      'Gold': [
        'Tất cả quyền lợi Silver',
        'Giảm giá 10% cho mọi booking',
        'Nâng cấp phòng miễn phí (khi có sẵn)',
        'Phòng chờ VIP tại sân bay',
        'Hoàn tiền linh hoạt hơn',
      ],
      'Diamond': [
        'Tất cả quyền lợi Gold',
        'Giảm giá 15% cho mọi booking',
        'Nâng cấp phòng miễn phí ưu tiên',
        'Điểm thưởng x2 cho mỗi booking',
        'Gói ưu đãi đặc biệt theo mùa',
        'Nhân viên chăm sóc VIP riêng',
      ]
    };
    return benefitsMap[level] || benefitsMap['Bronze'];
  }

  /**
   * Tính discount dựa trên VIP level
   * @param {string} level - VIP level
   * @param {number} originalPrice - Giá gốc
   * @returns {number} - Số tiền được giảm
   */
  static calculateDiscount(level, originalPrice) {
    const discountPercent = {
      'Bronze': 0,
      'Silver': 5,
      'Gold': 10,
      'Diamond': 15
    };
    
    const percent = discountPercent[level] || 0;
    return Math.floor((originalPrice * percent) / 100);
  }
}

module.exports = VipService;

