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
    return NotificationModel(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      type: json['type'] as String,
      imageUrl: json['image_url'] as String?,
      actionUrl: json['action_url'] as String?,
      actionText: json['action_text'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: json['expires_at'] != null 
          ? DateTime.parse(json['expires_at'] as String) 
          : null,
      senderName: json['sender_name'] as String?,
      senderType: json['sender_type'] as String?,
      hotelId: json['hotel_id'] as int?,
      metadata: json['metadata'] as Map<String, dynamic>?,
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
