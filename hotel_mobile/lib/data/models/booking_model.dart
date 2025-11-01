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

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: (json['id'] as num).toInt(),
      bookingCode: json['booking_code'] as String,
      userId: (json['user_id'] as num).toInt(),
      userEmail: json['user_email'] as String,
      userName: json['user_name'] as String?,
      userPhone: json['user_phone'] as String?,
      hotelId: (json['hotel_id'] as num).toInt(),
      hotelName: json['hotel_name'] as String?,
      roomId: (json['room_id'] as num).toInt(),
      roomNumber: json['room_number'] as String?,
      roomType: json['room_type'] as String?,
      checkInDate: DateTime.parse(json['check_in_date'] as String),
      checkOutDate: DateTime.parse(json['check_out_date'] as String),
      guestCount: (json['guest_count'] as num).toInt(),
      roomCount: (json['room_count'] as num).toInt(),
      nights: (json['nights'] as num).toInt(),
      roomPrice: (json['room_price'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      finalPrice: (json['final_price'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String,
      paymentStatus: json['payment_status'] as String,
      paymentTransactionId: json['payment_transaction_id'] as String?,
      paymentDate: json['payment_date'] != null 
          ? DateTime.parse(json['payment_date'] as String) 
          : null,
      refundStatus: json['refund_status'] as String?,
      refundAmount: (json['refund_amount'] as num?)?.toDouble() ?? 0,
      refundTransactionId: json['refund_transaction_id'] as String?,
      refundDate: json['refund_date'] != null 
          ? DateTime.parse(json['refund_date'] as String) 
          : null,
      refundReason: json['refund_reason'] as String?,
      bookingStatus: json['booking_status'] as String,
      cancellationAllowed: json['cancellation_allowed'] is bool 
          ? json['cancellation_allowed'] as bool
          : (json['cancellation_allowed'] as int?) == 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      cancelledAt: json['cancelled_at'] != null 
          ? DateTime.parse(json['cancelled_at'] as String) 
          : null,
      specialRequests: json['special_requests'] as String?,
      adminNotes: json['admin_notes'] as String?,
      canCancelNow: json['can_cancel_now'] is bool
          ? json['can_cancel_now'] as bool
          : (json['can_cancel_now'] as num?)?.toInt() == 1,
      secondsLeftToCancel: (json['cancel_time_left_minutes'] as num?)?.toInt() ?? 
                           (json['seconds_left_to_cancel'] as num?)?.toInt() ?? 0,
    );
  }

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

  /// Lấy tên trạng thái booking bằng tiếng Việt
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

  /// Lấy tên phương thức thanh toán
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

  /// Lấy tên trạng thái thanh toán
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

  /// Lấy tên trạng thái hoàn tiền
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

