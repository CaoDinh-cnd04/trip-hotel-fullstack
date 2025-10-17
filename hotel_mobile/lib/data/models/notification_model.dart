import 'package:json_annotation/json_annotation.dart';

part 'notification_model.g.dart';

@JsonSerializable()
class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String message;
  final String recipientEmail;
  final String recipientName;
  final String? bookingId;
  final String status;
  final DateTime createdAt;
  final DateTime? sentAt;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.recipientEmail,
    required this.recipientName,
    this.bookingId,
    required this.status,
    required this.createdAt,
    this.sentAt,
    this.errorMessage,
    this.metadata,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationModelToJson(this);

  NotificationModel copyWith({
    String? id,
    String? type,
    String? title,
    String? message,
    String? recipientEmail,
    String? recipientName,
    String? bookingId,
    String? status,
    DateTime? createdAt,
    DateTime? sentAt,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      recipientName: recipientName ?? this.recipientName,
      bookingId: bookingId ?? this.bookingId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      sentAt: sentAt ?? this.sentAt,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get isPending => status == 'pending';
  bool get isSent => status == 'sent';
  bool get isFailed => status == 'failed';

  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'Chờ gửi';
      case 'sent':
        return 'Đã gửi';
      case 'failed':
        return 'Gửi thất bại';
      default:
        return 'Không xác định';
    }
  }

  String get typeDisplayName {
    switch (type) {
      case 'booking_confirmation':
        return 'Xác nhận đặt phòng';
      case 'booking_cancellation':
        return 'Hủy đặt phòng';
      case 'checkin_reminder':
        return 'Nhắc nhở check-in';
      case 'review_request':
        return 'Yêu cầu đánh giá';
      case 'payment_confirmation':
        return 'Xác nhận thanh toán';
      case 'custom':
        return 'Thông báo tùy chỉnh';
      default:
        return type;
    }
  }

  String get formattedCreatedAt => 
      '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

  String get formattedSentAt => sentAt != null
      ? '${sentAt!.day.toString().padLeft(2, '0')}/${sentAt!.month.toString().padLeft(2, '0')}/${sentAt!.year} ${sentAt!.hour.toString().padLeft(2, '0')}:${sentAt!.minute.toString().padLeft(2, '0')}'
      : 'Chưa gửi';
}

@JsonSerializable()
class EmailNotificationRequest {
  final String toEmail;
  final String toName;
  final String templateType;
  final String subject;
  final Map<String, dynamic> data;
  final String? bookingId;

  const EmailNotificationRequest({
    required this.toEmail,
    required this.toName,
    required this.templateType,
    required this.subject,
    required this.data,
    this.bookingId,
  });

  factory EmailNotificationRequest.fromJson(Map<String, dynamic> json) =>
      _$EmailNotificationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$EmailNotificationRequestToJson(this);

  EmailNotificationRequest copyWith({
    String? toEmail,
    String? toName,
    String? templateType,
    String? subject,
    Map<String, dynamic>? data,
    String? bookingId,
  }) {
    return EmailNotificationRequest(
      toEmail: toEmail ?? this.toEmail,
      toName: toName ?? this.toName,
      templateType: templateType ?? this.templateType,
      subject: subject ?? this.subject,
      data: data ?? this.data,
      bookingId: bookingId ?? this.bookingId,
    );
  }
}

@JsonSerializable()
class NotificationSettings {
  final bool emailNotificationsEnabled;
  final bool smsNotificationsEnabled;
  final bool pushNotificationsEnabled;
  final List<String> enabledNotificationTypes;
  final String? emailTemplate;
  final Map<String, dynamic>? customSettings;

  const NotificationSettings({
    required this.emailNotificationsEnabled,
    required this.smsNotificationsEnabled,
    required this.pushNotificationsEnabled,
    required this.enabledNotificationTypes,
    this.emailTemplate,
    this.customSettings,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      _$NotificationSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationSettingsToJson(this);

  NotificationSettings copyWith({
    bool? emailNotificationsEnabled,
    bool? smsNotificationsEnabled,
    bool? pushNotificationsEnabled,
    List<String>? enabledNotificationTypes,
    String? emailTemplate,
    Map<String, dynamic>? customSettings,
  }) {
    return NotificationSettings(
      emailNotificationsEnabled: emailNotificationsEnabled ?? this.emailNotificationsEnabled,
      smsNotificationsEnabled: smsNotificationsEnabled ?? this.smsNotificationsEnabled,
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      enabledNotificationTypes: enabledNotificationTypes ?? this.enabledNotificationTypes,
      emailTemplate: emailTemplate ?? this.emailTemplate,
      customSettings: customSettings ?? this.customSettings,
    );
  }

  bool isNotificationTypeEnabled(String type) {
    return enabledNotificationTypes.contains(type);
  }
}
