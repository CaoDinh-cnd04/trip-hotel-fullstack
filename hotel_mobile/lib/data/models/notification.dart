class NotificationModel {
  final int id;
  final String title;
  final String content;
  final String type; // 'promotion', 'new_room', 'app_program', 'booking_success'
  final String? imageUrl;
  final String? actionUrl;
  final String? actionText;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String? senderName; // Admin, Hotel Manager name
  final String? senderType; // 'admin', 'hotel_manager'
  final int? hotelId; // For hotel-specific notifications
  final Map<String, dynamic>? metadata; // Additional data

  NotificationModel({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    this.imageUrl,
    this.actionUrl,
    this.actionText,
    this.isRead = false,
    required this.createdAt,
    this.expiresAt,
    this.senderName,
    this.senderType,
    this.hotelId,
    this.metadata,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Safe parsing for id
    int? parseId(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    // Safe parsing for dates
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      try {
        if (value is String) {
          return DateTime.parse(value);
        } else if (value is DateTime) {
          return value;
        }
        return null;
      } catch (e) {
        print('⚠️ Error parsing date: $value');
        return null;
      }
    }

    // Safe parsing for hotel_id
    int? parseHotelId(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    // Get fields with fallbacks
    final id = parseId(json['id']) ?? parseId(json['ma_thong_bao']) ?? 0;
    final title = json['title'] ?? json['tieu_de'] ?? '';
    final content = json['content'] ?? json['noi_dung'] ?? '';
    final type = json['type'] ?? json['loai_thong_bao'] ?? 'promotion';
    final createdAt = parseDate(json['created_at'] ?? json['ngay_tao']) ?? DateTime.now();
    
    return NotificationModel(
      id: id,
      title: title.toString(),
      content: content.toString(),
      type: type.toString(),
      imageUrl: json['image_url']?.toString() ?? json['url_hinh_anh']?.toString(),
      actionUrl: json['action_url']?.toString() ?? json['url_hanh_dong']?.toString(),
      actionText: json['action_text']?.toString() ?? json['van_ban_nut']?.toString(),
      isRead: json['is_read'] == true || json['da_doc'] == 1 || json['da_doc'] == true,
      createdAt: createdAt,
      expiresAt: parseDate(json['expires_at'] ?? json['ngay_het_han']),
      senderName: json['sender_name']?.toString() ?? json['nguoi_tao']?.toString(),
      senderType: json['sender_type']?.toString() ?? json['loai_nguoi_gui']?.toString(),
      hotelId: parseHotelId(json['hotel_id'] ?? json['khach_san_id']),
      metadata: json['metadata'] is Map<String, dynamic> ? json['metadata'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type,
      'image_url': imageUrl,
      'action_url': actionUrl,
      'action_text': actionText,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'sender_name': senderName,
      'sender_type': senderType,
      'hotel_id': hotelId,
      'metadata': metadata,
    };
  }

  NotificationModel copyWith({
    int? id,
    String? title,
    String? content,
    String? type,
    String? imageUrl,
    String? actionUrl,
    String? actionText,
    bool? isRead,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? senderName,
    String? senderType,
    int? hotelId,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      actionText: actionText ?? this.actionText,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      senderName: senderName ?? this.senderName,
      senderType: senderType ?? this.senderType,
      hotelId: hotelId ?? this.hotelId,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  String get typeDisplayName {
    switch (type) {
      case 'promotion':
        return 'Ưu đãi';
      case 'new_room':
        return 'Phòng mới';
      case 'app_program':
        return 'Chương trình';
      case 'booking_success':
        return 'Đặt phòng';
      default:
        return 'Thông báo';
    }
  }

  String get typeIcon {
    switch (type) {
      case 'promotion':
        return '🎉';
      case 'new_room':
        return '🏨';
      case 'app_program':
        return '📱';
      case 'booking_success':
        return '✅';
      default:
        return '📢';
    }
  }

  String get formattedCreatedAt {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
}
