/// Model đại diện cho đặt phòng (phiên bản chi tiết với payment)
/// 
/// Chứa thông tin:
/// - Thông tin booking: bookingCode, userId, userEmail, userName, userPhone
/// - Thông tin khách sạn/phòng: hotelId, hotelName, roomId, roomNumber, roomType
/// - Thông tin đặt phòng: checkInDate, checkOutDate, guestCount, roomCount, nights
/// - Giá cả: roomPrice, totalPrice, discountAmount, finalPrice
/// - Thanh toán: paymentMethod, paymentStatus, paymentTransactionId, paymentDate
/// - Hoàn tiền: refundStatus, refundAmount, refundTransactionId, refundDate, refundReason
/// - Trạng thái: bookingStatus, cancellationAllowed, canCancelNow, secondsLeftToCancel
/// - Thời gian: createdAt, updatedAt, cancelledAt
/// - Ghi chú: specialRequests, adminNotes
class BookingModel {
  final int id;
  final String bookingCode;
  final int userId;
  final String userEmail;
  final String? userName;
  final String? userPhone;
  final int hotelId;
  final String? hotelName;
  final int roomId;
  final String? roomNumber;
  final String? roomType;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guestCount;
  final int roomCount;
  final int nights;
  final double roomPrice;
  final double totalPrice;
  final double discountAmount;
  final double finalPrice;
  final String paymentMethod;
  final String paymentStatus;
  final String? paymentTransactionId;
  final DateTime? paymentDate;
  final String? refundStatus;
  final double refundAmount;
  final String? refundTransactionId;
  final DateTime? refundDate;
  final String? refundReason;
  final String bookingStatus;
  final bool cancellationAllowed;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? cancelledAt;
  final String? specialRequests;
  final String? adminNotes;
  
  // Calculated fields
  final bool canCancelNow;
  final int secondsLeftToCancel;

  BookingModel({
    required this.id,
    required this.bookingCode,
    required this.userId,
    required this.userEmail,
    this.userName,
    this.userPhone,
    required this.hotelId,
    this.hotelName,
    required this.roomId,
    this.roomNumber,
    this.roomType,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guestCount,
    required this.roomCount,
    required this.nights,
    required this.roomPrice,
    required this.totalPrice,
    required this.discountAmount,
    required this.finalPrice,
    required this.paymentMethod,
    required this.paymentStatus,
    this.paymentTransactionId,
    this.paymentDate,
    this.refundStatus,
    required this.refundAmount,
    this.refundTransactionId,
    this.refundDate,
    this.refundReason,
    required this.bookingStatus,
    required this.cancellationAllowed,
    required this.createdAt,
    required this.updatedAt,
    this.cancelledAt,
    this.specialRequests,
    this.adminNotes,
    required this.canCancelNow,
    required this.secondsLeftToCancel,
  });

  /// Helper method to safely extract string from field that might be array or string
  static String? _extractString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    if (value is List && value.isNotEmpty) {
      // ✅ FIX: Check if first element is actually null
      final first = value.first;
      if (first == null) return null;
      final str = first.toString();
      return str.isEmpty || str == 'null' ? null : str;
    }
    final str = value.toString();
    return str.isEmpty || str == 'null' ? null : str;
  }

  /// Tạo đối tượng BookingModel từ JSON
  /// 
  /// [json] - Map chứa dữ liệu JSON từ API
  /// 
  /// Parse các trường từ snake_case sang camelCase
  /// Chuyển đổi an toàn các kiểu dữ liệu số và DateTime
  /// ⚠️ FIX: Handle fields that might be arrays (hotel_name, refund_status, etc.)
  factory BookingModel.fromJson(Map<String, dynamic> json) {
    try {
      // ✅ FIX: Safe parse DateTime với null check
      DateTime? _parseDateTime(dynamic value) {
        if (value == null) return null;
        final str = _extractString(value);
        if (str == null || str.isEmpty) return null;
        try {
          return DateTime.parse(str);
        } catch (e) {
          print('⚠️ Error parsing DateTime from "$str": $e');
          return null;
        }
      }

      // ✅ FIX: Safe parse String với null check
      String? _parseString(dynamic value) {
        if (value == null) return null;
        if (value is String) return value.isEmpty ? null : value;
        return value.toString();
      }

      // ✅ FIX: Safe parse num với null check
      int _parseInt(dynamic value, {int defaultValue = 0}) {
        if (value == null) return defaultValue;
        if (value is num) return value.toInt();
        if (value is String) {
          final parsed = int.tryParse(value);
          return parsed ?? defaultValue;
        }
        return defaultValue;
      }

      double _parseDouble(dynamic value, {double defaultValue = 0.0}) {
        if (value == null) return defaultValue;
        if (value is num) return value.toDouble();
        if (value is String) {
          final parsed = double.tryParse(value);
          return parsed ?? defaultValue;
        }
        return defaultValue;
      }

      return BookingModel(
        id: _parseInt(json['id']),
        bookingCode: _parseString(json['booking_code']) ?? '',
        userId: _parseInt(json['user_id']),
        userEmail: _parseString(json['user_email']) ?? '',
        userName: _extractString(json['user_name']),
        userPhone: _extractString(json['user_phone']),
        hotelId: _parseInt(json['hotel_id']),
        hotelName: _extractString(json['hotel_name']),  // ✅ FIX: Handle array
        roomId: _parseInt(json['room_id']),
        roomNumber: _extractString(json['room_number']),
        roomType: _extractString(json['room_type']),
        checkInDate: _parseDateTime(json['check_in_date']) ?? DateTime.now(),
        checkOutDate: _parseDateTime(json['check_out_date']) ?? DateTime.now(),
        guestCount: _parseInt(json['guest_count'], defaultValue: 1),
        roomCount: _parseInt(json['room_count'], defaultValue: 1),
        nights: _parseInt(json['nights'], defaultValue: 1),
        roomPrice: _parseDouble(json['room_price']),
        totalPrice: _parseDouble(json['total_price']),
        discountAmount: _parseDouble(json['discount_amount']),
        finalPrice: _parseDouble(json['final_price']),
        paymentMethod: _parseString(json['payment_method']) ?? 'cash',
        paymentStatus: _parseString(json['payment_status']) ?? 'pending',
        paymentTransactionId: _extractString(json['payment_transaction_id']),
        paymentDate: _parseDateTime(json['payment_date']),
        refundStatus: _extractString(json['refund_status']),  // ✅ FIX: Handle array
        refundAmount: _parseDouble(json['refund_amount']),
        refundTransactionId: _extractString(json['refund_transaction_id']),
        refundDate: _parseDateTime(json['refund_date']),
        refundReason: _extractString(json['refund_reason']),  // ✅ FIX: Handle array
        bookingStatus: _parseString(json['booking_status']) ?? 'pending',
        cancellationAllowed: json['cancellation_allowed'] is bool 
            ? json['cancellation_allowed'] as bool
            : (json['cancellation_allowed'] as int?) == 1,
        createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
        updatedAt: _parseDateTime(json['updated_at']) ?? DateTime.now(),
        cancelledAt: _parseDateTime(json['cancelled_at']),  // ✅ FIX: Handle array
        specialRequests: _parseString(json['special_requests']),
        adminNotes: _parseString(json['admin_notes']),
        // ✅ FIX: Backend returns 'can_cancel', not 'can_cancel_now'
        canCancelNow: json['can_cancel_now'] is bool
            ? json['can_cancel_now'] as bool
            : (json['can_cancel_now'] as num?)?.toInt() == 1
                ? true
                : json['can_cancel'] is bool
                    ? json['can_cancel'] as bool
                    : (json['can_cancel'] as num?)?.toInt() == 1,
        secondsLeftToCancel: (json['cancel_time_left_minutes'] as num?)?.toInt() ?? 
                             (json['seconds_left_to_cancel'] as num?)?.toInt() ?? 0,
      );
    } catch (e, stackTrace) {
      print('❌ Error parsing BookingModel from JSON: $e');
      print('❌ Stack trace: $stackTrace');
      print('❌ JSON data: $json');
      rethrow;
    }
  }

  /// Chuyển đổi đối tượng BookingModel sang JSON
  /// 
  /// Trả về Map chứa tất cả các trường dưới dạng JSON (snake_case)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_code': bookingCode,
      'user_id': userId,
      'user_email': userEmail,
      'user_name': userName,
      'user_phone': userPhone,
      'hotel_id': hotelId,
      'hotel_name': hotelName,
      'room_id': roomId,
      'room_number': roomNumber,
      'room_type': roomType,
      'check_in_date': checkInDate.toIso8601String(),
      'check_out_date': checkOutDate.toIso8601String(),
      'guest_count': guestCount,
      'room_count': roomCount,
      'nights': nights,
      'room_price': roomPrice,
      'total_price': totalPrice,
      'discount_amount': discountAmount,
      'final_price': finalPrice,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'payment_transaction_id': paymentTransactionId,
      'payment_date': paymentDate?.toIso8601String(),
      'refund_status': refundStatus,
      'refund_amount': refundAmount,
      'refund_transaction_id': refundTransactionId,
      'refund_date': refundDate?.toIso8601String(),
      'refund_reason': refundReason,
      'booking_status': bookingStatus,
      'cancellation_allowed': cancellationAllowed ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'special_requests': specialRequests,
      'admin_notes': adminNotes,
      'can_cancel_now': canCancelNow ? 1 : 0,
      'seconds_left_to_cancel': secondsLeftToCancel,
    };
  }

  /// Lấy text hiển thị trạng thái booking bằng tiếng Việt
  /// 
  /// Hỗ trợ cả tiếng Anh và tiếng Việt
  /// Trả về: "Đã xác nhận", "Đã hủy", "Hoàn thành", "Không đến", "Đang tiến hành", "Chờ xác nhận", v.v.
  String get bookingStatusText {
    switch (bookingStatus.toLowerCase()) {
      case 'confirmed':
      case 'xac_nhan':
        return 'Đã xác nhận';
      case 'cancelled':
      case 'huy':
      case 'cancelled_by_user':
      case 'cancelled_by_hotel':
        return 'Đã hủy';
      case 'completed':
      case 'hoan_thanh':
        return 'Hoàn thành';
      case 'no_show':
      case 'khong_den':
        return 'Không đến';
      case 'in_progress':
      case 'dang_tien_hanh':
      case 'pending':
      case 'cho':
        return 'Đang tiến hành';
      case 'pending_confirmation':
      case 'cho_xac_nhan':
        return 'Chờ xác nhận';
      case 'checked_in':
      case 'da_nhan_phong':
        return 'Đã nhận phòng';
      case 'checked_out':
      case 'da_tra_phong':
        return 'Đã trả phòng';
      default:
        // ✅ FIX: Trả về tiếng Việt thay vì raw status
        return 'Đang xử lý';
    }
  }

  /// Lấy text hiển thị phương thức thanh toán bằng tiếng Việt
  /// 
  /// Trả về: "VNPay", "MoMo", "Tiền mặt"
  String get paymentMethodText {
    switch (paymentMethod.toLowerCase()) {
      case 'vnpay':
        return 'VNPay';
      case 'momo':
        return 'MoMo';
      case 'cash':
      case 'tien_mat':
        return 'Tiền mặt';
      default:
        // ✅ FIX: Trả về tiếng Việt thay vì raw method
        return 'Tiền mặt';
    }
  }

  /// Lấy text hiển thị trạng thái thanh toán bằng tiếng Việt
  /// 
  /// Trả về: "Chờ thanh toán", "Đã thanh toán", "Đã hoàn tiền", "Thất bại"
  String get paymentStatusText {
    switch (paymentStatus) {
      case 'pending':
        return 'Chờ thanh toán';
      case 'paid':
        return 'Đã thanh toán';
      case 'refunded':
        return 'Đã hoàn tiền';
      case 'failed':
        return 'Thất bại';
      default:
        return paymentStatus;
    }
  }

  /// Lấy text hiển thị trạng thái hoàn tiền bằng tiếng Việt
  /// 
  /// Trả về: "Đang yêu cầu", "Đang xử lý", "Hoàn thành", "Từ chối", hoặc chuỗi rỗng nếu không có
  String get refundStatusText {
    if (refundStatus == null) return '';
    switch (refundStatus) {
      case 'requested':
        return 'Đang yêu cầu';
      case 'processing':
        return 'Đang xử lý';
      case 'completed':
        return 'Đã hoàn tiền';
      case 'failed':
        return 'Hoàn tiền thất bại';
      default:
        return refundStatus!;
    }
  }
}

