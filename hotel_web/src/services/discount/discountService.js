// Service for handling discount codes and promotions
import { API_BASE_URL, getApiUrl } from '../../config/api'

export const discountService = {
  /**
   * Validate discount code (mã giảm giá - áp dụng cho tất cả khách sạn)
   * @param {string} code - Discount code
   * @param {number} orderAmount - Order total amount
   * @param {string} token - User auth token
   */
  validateDiscountCode: async (code, orderAmount, token) => {
    try {
      const response = await fetch(getApiUrl('/v2/magiamgia/validate'), {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({
          code: code.toUpperCase(),
          orderAmount
        })
      });

      const data = await response.json();
      return data;
    } catch (error) {
      console.error('Error validating discount code:', error);
      return {
        success: false,
        message: 'Lỗi kết nối khi kiểm tra mã giảm giá'
      };
    }
  },

  /**
   * Get available discount codes
   */
  getAvailableDiscounts: async () => {
    try {
      const response = await fetch(getApiUrl('/v2/magiamgia/active'));
      const data = await response.json();
      return data;
    } catch (error) {
      console.error('Error getting available discounts:', error);
      return {
        success: false,
        message: 'Lỗi kết nối khi lấy danh sách mã giảm giá'
      };
    }
  },

  /**
   * Validate hotel promotion code (ưu đãi khách sạn)
   * @param {string} code - Promotion code
   * @param {number} hotelId - Hotel ID
   * @param {number} orderAmount - Order total amount
   */
  validatePromotionCode: async (code, hotelId, orderAmount) => {
    try {
      const response = await fetch(getApiUrl(`/v2/khuyenmai/validate/${code}?ma_khach_san=${hotelId}&orderAmount=${orderAmount}`));
      const data = await response.json();
      return data;
    } catch (error) {
      console.error('Error validating promotion code:', error);
      return {
        success: false,
        message: 'Lỗi kết nối khi kiểm tra mã ưu đãi'
      };
    }
  },

  /**
   * Get active promotions for a hotel
   * @param {number} hotelId - Hotel ID
   */
  getHotelPromotions: async (hotelId) => {
    try {
      const response = await fetch(getApiUrl(`/v2/khuyenmai/active?ma_khach_san=${hotelId}`));
      const data = await response.json();
      return data;
    } catch (error) {
      console.error('Error getting hotel promotions:', error);
      return {
        success: false,
        message: 'Lỗi kết nối khi lấy danh sách ưu đãi'
      };
    }
  },

  /**
   * Calculate discount amount
   * @param {Object} discount - Discount/promotion data
   * @param {number} orderAmount - Original order amount
   */
  calculateDiscountAmount: (discount, orderAmount) => {
    if (!discount || !discount.discountValue) return 0;

    let discountAmount = 0;
    const isPercentage = discount.discountType?.toLowerCase().includes('percentage') || 
                        discount.discountType?.toLowerCase().includes('phần trăm');

    if (isPercentage) {
      // Percentage discount
      discountAmount = (orderAmount * discount.discountValue) / 100;
      
      // Apply maximum discount limit
      if (discount.maxDiscountValue && discountAmount > discount.maxDiscountValue) {
        discountAmount = discount.maxDiscountValue;
      }
    } else {
      // Fixed amount discount
      discountAmount = discount.discountValue;
      
      // Don't exceed order amount
      if (discountAmount > orderAmount) {
        discountAmount = orderAmount;
      }
    }

    return Math.floor(discountAmount); // Round down to avoid cents
  },

  /**
   * Format discount description for display
   * @param {Object} discount - Discount/promotion data
   */
  formatDiscountDescription: (discount) => {
    if (!discount) return '';

    const isPercentage = discount.discountType?.toLowerCase().includes('percentage') || 
                        discount.discountType?.toLowerCase().includes('phần trăm');
    
    if (isPercentage) {
      let desc = `Giảm ${discount.discountValue}%`;
      if (discount.maxDiscountValue) {
        desc += ` (tối đa ${discount.maxDiscountValue.toLocaleString('vi-VN')}₫)`;
      }
      return desc;
    } else {
      return `Giảm ${discount.discountValue.toLocaleString('vi-VN')}₫`;
    }
  }
};

