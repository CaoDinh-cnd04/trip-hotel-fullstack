import 'package:intl/intl.dart';

class PromotionOffer {
  final String id;
  final int hotelId;
  final int roomTypeId;
  final String title;
  final String description;
  final double originalPrice;
  final double discountedPrice;
  final int totalRooms; // Tổng số phòng ưu đãi
  final int availableRooms; // Số phòng còn lại
  final DateTime startTime;
  final DateTime endTime;
  final List<String> conditions; // Điều kiện (không hủy, không hoàn tiền)
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  PromotionOffer({
    required this.id,
    required this.hotelId,
    required this.roomTypeId,
    required this.title,
    required this.description,
    required this.originalPrice,
    required this.discountedPrice,
    required this.totalRooms,
    required this.availableRooms,
    required this.startTime,
    required this.endTime,
    required this.conditions,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  // Tính phần trăm giảm giá
  double get discountPercentage {
    if (originalPrice <= 0 || discountedPrice >= originalPrice) {
      return 0.0; // Không có giảm giá nếu giá ưu đãi >= giá gốc
    }
    final percentage = ((originalPrice - discountedPrice) / originalPrice * 100);
    return percentage.isFinite && !percentage.isNaN ? percentage.roundToDouble() : 0.0;
  }

  // Tính số tiền tiết kiệm
  double get savingsAmount {
    if (originalPrice <= 0 || discountedPrice >= originalPrice) {
      return 0.0; // Không tiết kiệm nếu giá ưu đãi >= giá gốc
    }
    return originalPrice - discountedPrice;
  }

  // Kiểm tra xem ưu đãi có còn hiệu lực không
  bool get isExpired {
    return DateTime.now().isAfter(endTime);
  }

  // Kiểm tra xem ưu đãi có đang diễn ra không
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive && 
           now.isAfter(startTime) && 
           now.isBefore(endTime) && 
           availableRooms > 0;
  }

  // Kiểm tra xem có thể đặt phòng không
  bool get canBook {
    return isCurrentlyActive && availableRooms > 0;
  }

  // Thời gian còn lại (phút)
  int get remainingMinutes {
    if (isExpired) return 0;
    return endTime.difference(DateTime.now()).inMinutes;
  }

  // Thời gian còn lại (giờ:phút)
  String get remainingTimeFormatted {
    final minutes = remainingMinutes;
    if (minutes <= 0) return 'Hết hạn';
    
    final hours = minutes ~/ 60;
    final remainingMins = minutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${remainingMins}m';
    } else {
      return '${remainingMins}m';
    }
  }

  // Format giá tiền
  String get formattedOriginalPrice {
    return NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(originalPrice);
  }

  String get formattedDiscountedPrice {
    return NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(discountedPrice);
  }

  String get formattedSavings {
    return NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(savingsAmount);
  }

  factory PromotionOffer.fromJson(Map<String, dynamic> json) {
    return PromotionOffer(
      id: json['id']?.toString() ?? '',
      hotelId: json['hotel_id'] as int,
      roomTypeId: json['room_type_id'] as int,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      originalPrice: (json['original_price'] as num).toDouble(),
      discountedPrice: (json['discounted_price'] as num).toDouble(),
      totalRooms: json['total_rooms'] as int,
      availableRooms: json['available_rooms'] as int,
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      conditions: List<String>.from(json['conditions'] ?? []),
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hotel_id': hotelId,
      'room_type_id': roomTypeId,
      'title': title,
      'description': description,
      'original_price': originalPrice,
      'discounted_price': discountedPrice,
      'total_rooms': totalRooms,
      'available_rooms': availableRooms,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'conditions': conditions,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PromotionOffer copyWith({
    String? id,
    int? hotelId,
    int? roomTypeId,
    String? title,
    String? description,
    double? originalPrice,
    double? discountedPrice,
    int? totalRooms,
    int? availableRooms,
    DateTime? startTime,
    DateTime? endTime,
    List<String>? conditions,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PromotionOffer(
      id: id ?? this.id,
      hotelId: hotelId ?? this.hotelId,
      roomTypeId: roomTypeId ?? this.roomTypeId,
      title: title ?? this.title,
      description: description ?? this.description,
      originalPrice: originalPrice ?? this.originalPrice,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      totalRooms: totalRooms ?? this.totalRooms,
      availableRooms: availableRooms ?? this.availableRooms,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      conditions: conditions ?? this.conditions,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
