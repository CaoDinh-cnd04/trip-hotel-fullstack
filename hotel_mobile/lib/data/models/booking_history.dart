class BookingHistory {
  final String id;
  final String hotelId;
  final String hotelName;
  final String? hotelImage;
  final String location;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int nights;
  final int rooms;
  final int adults;
  final int children;
  final double totalAmount;
  final String status; // 'pending', 'confirmed', 'cancelled', 'completed'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? cancellationReason;
  final bool canCancel;

  BookingHistory({
    required this.id,
    required this.hotelId,
    required this.hotelName,
    this.hotelImage,
    required this.location,
    required this.checkInDate,
    required this.checkOutDate,
    required this.nights,
    required this.rooms,
    required this.adults,
    required this.children,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.cancellationReason,
    required this.canCancel,
  });

  factory BookingHistory.fromJson(Map<String, dynamic> json) {
    return BookingHistory(
      id: json['id']?.toString() ?? '',
      hotelId: json['hotel_id']?.toString() ?? '',
      hotelName: json['hotel_name'] ?? '',
      hotelImage: json['hotel_image'],
      location: json['location'] ?? '',
      checkInDate: DateTime.parse(json['check_in_date']),
      checkOutDate: DateTime.parse(json['check_out_date']),
      nights: json['nights'] ?? 0,
      rooms: json['rooms'] ?? 1,
      adults: json['adults'] ?? 1,
      children: json['children'] ?? 0,
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      cancellationReason: json['cancellation_reason'],
      canCancel: json['can_cancel'] == true || json['status'] == 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hotel_id': hotelId,
      'hotel_name': hotelName,
      'hotel_image': hotelImage,
      'location': location,
      'check_in_date': checkInDate.toIso8601String(),
      'check_out_date': checkOutDate.toIso8601String(),
      'nights': nights,
      'rooms': rooms,
      'adults': adults,
      'children': children,
      'total_amount': totalAmount,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'cancellation_reason': cancellationReason,
      'can_cancel': canCancel,
    };
  }

  String get statusText {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'cancelled':
        return 'Đã hủy';
      case 'completed':
        return 'Hoàn thành';
      default:
        return 'Không xác định';
    }
  }

  String get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'orange';
      case 'confirmed':
        return 'green';
      case 'cancelled':
        return 'red';
      case 'completed':
        return 'blue';
      default:
        return 'grey';
    }
  }
}
