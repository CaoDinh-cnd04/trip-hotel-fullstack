/**
 * Utility functions để kiểm tra điều kiện thời gian cho promotion
 * 
 * Hỗ trợ các điều kiện:
 * - Cuối tuần (thứ 6, 7, CN)
 * - Ngày thường (thứ 2-5)
 * - Thứ 3 cụ thể
 * - Ngày hè (tháng 6-8)
 * - Ngày lễ
 * - Mùa thu (tháng 9-11)
 */

/**
 * Kiểm tra xem ngày có phải cuối tuần không (thứ 6, 7, CN)
 */
function isWeekend(date) {
  const day = date.getDay(); // 0 = CN, 1 = T2, ..., 6 = T7
  return day === 0 || day === 5 || day === 6; // CN, T6, T7
}

/**
 * Kiểm tra xem ngày có phải ngày thường không (thứ 2-5)
 */
function isWeekday(date) {
  const day = date.getDay();
  return day >= 1 && day <= 4; // T2-T5
}

/**
 * Kiểm tra xem ngày có phải thứ 3 không
 */
function isTuesday(date) {
  return date.getDay() === 2; // T3
}

/**
 * Kiểm tra xem ngày có trong mùa hè không (tháng 6-8)
 */
function isSummer(date) {
  const month = date.getMonth() + 1; // getMonth() trả về 0-11
  return month >= 6 && month <= 8;
}

/**
 * Kiểm tra xem ngày có trong mùa thu không (tháng 9-11)
 */
function isAutumn(date) {
  const month = date.getMonth() + 1;
  return month >= 9 && month <= 11;
}

/**
 * Kiểm tra xem ngày có phải ngày lễ không
 * Hiện tại chỉ kiểm tra một số ngày lễ cố định của Việt Nam
 */
function isHoliday(date) {
  const month = date.getMonth() + 1;
  const day = date.getDate();
  
  // Tết Dương lịch (1/1)
  if (month === 1 && day === 1) return true;
  
  // Giải phóng miền Nam (30/4)
  if (month === 4 && day === 30) return true;
  
  // Quốc khánh (2/9)
  if (month === 9 && day === 2) return true;
  
  // Tết Nguyên Đán (mồng 1-3 tháng 1 âm lịch - xấp xỉ tháng 1-2 dương lịch)
  // TODO: Có thể cải thiện bằng cách tính lịch âm chính xác
  
  return false;
}

/**
 * Phân tích tên/mô tả promotion để xác định điều kiện thời gian
 * 
 * @param {string} ten - Tên promotion
 * @param {string} moTa - Mô tả promotion
 * @returns {Object} Object chứa các điều kiện thời gian
 */
function parsePromotionTimeConditions(ten, moTa) {
  const text = `${ten || ''} ${moTa || ''}`.toLowerCase();
  
  const conditions = {
    requiresWeekend: false,
    requiresWeekday: false,
    requiresTuesday: false,
    requiresSummer: false,
    requiresAutumn: false,
    requiresHoliday: false,
  };
  
  // Kiểm tra cuối tuần
  if (text.includes('cuối tuần') || 
      text.includes('thứ 6') || 
      text.includes('thứ 7') || 
      text.includes('chủ nhật') ||
      text.includes('weekend')) {
    conditions.requiresWeekend = true;
  }
  
  // Kiểm tra ngày thường
  if (text.includes('ngày thường') || 
      text.includes('thứ 2') || 
      text.includes('thứ 3') || 
      text.includes('thứ 4') || 
      text.includes('thứ 5') ||
      text.includes('weekday')) {
    // Nếu có "thứ 3" riêng, kiểm tra riêng
    if (text.includes('thứ 3') && !text.includes('thứ 3 vàng')) {
      conditions.requiresTuesday = true;
    } else {
      conditions.requiresWeekday = true;
    }
  }
  
  // Kiểm tra thứ 3 cụ thể
  if (text.includes('thứ 3 vàng') || 
      text.includes('thứ ba vàng')) {
    conditions.requiresTuesday = true;
  }
  
  // Kiểm tra mùa hè
  if (text.includes('mùa hè') || 
      text.includes('mua he') ||
      text.includes('summer')) {
    conditions.requiresSummer = true;
  }
  
  // Kiểm tra mùa thu
  if (text.includes('mùa thu') || 
      text.includes('mua thu') ||
      text.includes('thu vàng') ||
      text.includes('autumn')) {
    conditions.requiresAutumn = true;
  }
  
  // Kiểm tra ngày lễ
  if (text.includes('ngày lễ') || 
      text.includes('ngay le') ||
      text.includes('holiday') ||
      text.includes('lễ lớn')) {
    conditions.requiresHoliday = true;
  }
  
  return conditions;
}

/**
 * Kiểm tra xem check-in date có thỏa mãn điều kiện thời gian của promotion không
 * 
 * @param {Date} checkInDate - Ngày check-in
 * @param {Object} timeConditions - Điều kiện thời gian từ parsePromotionTimeConditions
 * @returns {Object} { isValid: boolean, reason: string }
 */
function validatePromotionTime(checkInDate, timeConditions) {
  // Nếu không có điều kiện thời gian nào, luôn hợp lệ
  const hasAnyCondition = Object.values(timeConditions).some(v => v === true);
  if (!hasAnyCondition) {
    return {
      isValid: true,
      reason: null,
    };
  }
  
  // Kiểm tra từng điều kiện
  if (timeConditions.requiresWeekend && !isWeekend(checkInDate)) {
    return {
      isValid: false,
      reason: 'Ưu đãi này chỉ áp dụng cho cuối tuần (thứ 6, thứ 7, Chủ nhật). Vui lòng chọn ngày check-in vào cuối tuần.',
    };
  }
  
  if (timeConditions.requiresWeekday && !isWeekday(checkInDate)) {
    return {
      isValid: false,
      reason: 'Ưu đãi này chỉ áp dụng cho ngày thường (thứ 2 đến thứ 5). Vui lòng chọn ngày check-in vào ngày thường.',
    };
  }
  
  if (timeConditions.requiresTuesday && !isTuesday(checkInDate)) {
    return {
      isValid: false,
      reason: 'Ưu đãi này chỉ áp dụng cho thứ 3. Vui lòng chọn ngày check-in vào thứ 3.',
    };
  }
  
  if (timeConditions.requiresSummer && !isSummer(checkInDate)) {
    return {
      isValid: false,
      reason: 'Ưu đãi này chỉ áp dụng cho mùa hè (tháng 6-8). Vui lòng chọn ngày check-in trong mùa hè.',
    };
  }
  
  if (timeConditions.requiresAutumn && !isAutumn(checkInDate)) {
    return {
      isValid: false,
      reason: 'Ưu đãi này chỉ áp dụng cho mùa thu (tháng 9-11). Vui lòng chọn ngày check-in trong mùa thu.',
    };
  }
  
  if (timeConditions.requiresHoliday && !isHoliday(checkInDate)) {
    return {
      isValid: false,
      reason: 'Ưu đãi này chỉ áp dụng cho ngày lễ. Vui lòng chọn ngày check-in vào ngày lễ.',
    };
  }
  
  // Tất cả điều kiện đều thỏa mãn
  return {
    isValid: true,
    reason: null,
  };
}

module.exports = {
  isWeekend,
  isWeekday,
  isTuesday,
  isSummer,
  isAutumn,
  isHoliday,
  parsePromotionTimeConditions,
  validatePromotionTime,
};

