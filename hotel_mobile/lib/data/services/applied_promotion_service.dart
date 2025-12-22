import '../models/promotion.dart';

/// Service để quản lý promotion đang được áp dụng
/// Lưu promotion trong memory để có thể truy cập từ các màn hình khác
class AppliedPromotionService {
  static final AppliedPromotionService _instance = AppliedPromotionService._internal();
  factory AppliedPromotionService() => _instance;
  AppliedPromotionService._internal();

  Promotion? _appliedPromotion;
  int? _appliedHotelId;

  /// Áp dụng promotion cho một hotel
  void applyPromotion(Promotion promotion, {int? hotelId}) {
    _appliedPromotion = promotion;
    _appliedHotelId = hotelId;
    print('✅ Applied promotion: ${promotion.ten} (${promotion.phanTramGiam}%) for hotel: $hotelId');
  }

  /// Lấy promotion đang được áp dụng cho hotel
  Promotion? getAppliedPromotion({int? hotelId}) {
    // Nếu có hotelId, chỉ trả về promotion nếu match
    if (hotelId != null && _appliedHotelId != null) {
      if (hotelId == _appliedHotelId || _appliedPromotion?.khachSanId == hotelId) {
        return _appliedPromotion;
      }
      return null;
    }
    // Nếu không có hotelId, trả về promotion nếu có
    return _appliedPromotion;
  }

  /// Kiểm tra xem có promotion đang được áp dụng không
  bool hasAppliedPromotion({int? hotelId}) {
    return getAppliedPromotion(hotelId: hotelId) != null;
  }

  /// Xóa promotion đang được áp dụng
  void clearAppliedPromotion() {
    _appliedPromotion = null;
    _appliedHotelId = null;
    print('🗑️ Cleared applied promotion');
  }

  /// Tính giá sau khi áp dụng promotion
  double calculateDiscountedPrice(double originalPrice, {int? hotelId}) {
    final promotion = getAppliedPromotion(hotelId: hotelId);
    if (promotion == null) {
      return originalPrice;
    }

    final discountAmount = originalPrice * (promotion.phanTramGiam / 100);
    final discountedPrice = originalPrice - discountAmount;
    
    print('💰 Price calculation: $originalPrice - ${promotion.phanTramGiam}% = $discountedPrice');
    
    return discountedPrice > 0 ? discountedPrice : 0;
  }

  /// Lấy phần trăm giảm giá
  double? getDiscountPercentage({int? hotelId}) {
    final promotion = getAppliedPromotion(hotelId: hotelId);
    return promotion?.phanTramGiam;
  }
}

