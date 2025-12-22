/// Model đại diện cho tin nhắn/thông báo từ hệ thống
/// 
/// Chứa thông tin:
/// - Thông tin cơ bản: id, tiêu đề, loại, nội dung
/// - Thông tin khách sạn: hotelId, hotelName, hotelImage
/// - Trạng thái: isRead
/// - Thông tin booking: bookingDateRange (nếu liên quan đến booking)
/// - Action: hasAction, actionType, actionText (nếu tin nhắn có hành động)
class Message {
  final String id;
  final String title;
  final String type;
  final String hotelId;
  final String hotelName;
  final String? hotelImage;
  final String content;
  final DateTime createdAt;
  bool isRead;
  final String? bookingDateRange;
  final bool hasAction;
  final String? actionType;
  final String? actionText;

  Message({
    required this.id,
    required this.title,
    required this.type,
    required this.hotelId,
    required this.hotelName,
    this.hotelImage,
    required this.content,
    required this.createdAt,
    required this.isRead,
    this.bookingDateRange,
    required this.hasAction,
    this.actionType,
    this.actionText,
  });

  /// Tạo đối tượng Message từ JSON
  /// 
  /// [json] - Map chứa dữ liệu JSON từ API
  /// 
  /// Parse các trường từ snake_case sang camelCase
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? '',
      hotelId: json['hotel_id']?.toString() ?? '',
      hotelName: json['hotel_name'] ?? '',
      hotelImage: json['hotel_image'],
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      bookingDateRange: json['booking_date_range'],
      hasAction: json['has_action'] == 1 || json['has_action'] == true,
      actionType: json['action_type'],
      actionText: json['action_text'],
    );
  }

  /// Chuyển đổi đối tượng Message sang JSON
  /// 
  /// Trả về Map chứa tất cả các trường dưới dạng JSON (snake_case)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'hotel_id': hotelId,
      'hotel_name': hotelName,
      'hotel_image': hotelImage,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead ? 1 : 0,
      'booking_date_range': bookingDateRange,
      'has_action': hasAction ? 1 : 0,
      'action_type': actionType,
      'action_text': actionText,
    };
  }
}
