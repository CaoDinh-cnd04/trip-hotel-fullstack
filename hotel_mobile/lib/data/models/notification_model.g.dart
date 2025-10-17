// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationModel _$NotificationModelFromJson(Map<String, dynamic> json) =>
    NotificationModel(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      recipientEmail: json['recipientEmail'] as String,
      recipientName: json['recipientName'] as String,
      bookingId: json['bookingId'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      sentAt: json['sentAt'] == null
          ? null
          : DateTime.parse(json['sentAt'] as String),
      errorMessage: json['errorMessage'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$NotificationModelToJson(NotificationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'title': instance.title,
      'message': instance.message,
      'recipientEmail': instance.recipientEmail,
      'recipientName': instance.recipientName,
      'bookingId': instance.bookingId,
      'status': instance.status,
      'createdAt': instance.createdAt.toIso8601String(),
      'sentAt': instance.sentAt?.toIso8601String(),
      'errorMessage': instance.errorMessage,
      'metadata': instance.metadata,
    };

EmailNotificationRequest _$EmailNotificationRequestFromJson(
  Map<String, dynamic> json,
) => EmailNotificationRequest(
  toEmail: json['toEmail'] as String,
  toName: json['toName'] as String,
  templateType: json['templateType'] as String,
  subject: json['subject'] as String,
  data: json['data'] as Map<String, dynamic>,
  bookingId: json['bookingId'] as String?,
);

Map<String, dynamic> _$EmailNotificationRequestToJson(
  EmailNotificationRequest instance,
) => <String, dynamic>{
  'toEmail': instance.toEmail,
  'toName': instance.toName,
  'templateType': instance.templateType,
  'subject': instance.subject,
  'data': instance.data,
  'bookingId': instance.bookingId,
};

NotificationSettings _$NotificationSettingsFromJson(
  Map<String, dynamic> json,
) => NotificationSettings(
  emailNotificationsEnabled: json['emailNotificationsEnabled'] as bool,
  smsNotificationsEnabled: json['smsNotificationsEnabled'] as bool,
  pushNotificationsEnabled: json['pushNotificationsEnabled'] as bool,
  enabledNotificationTypes: (json['enabledNotificationTypes'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  emailTemplate: json['emailTemplate'] as String?,
  customSettings: json['customSettings'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$NotificationSettingsToJson(
  NotificationSettings instance,
) => <String, dynamic>{
  'emailNotificationsEnabled': instance.emailNotificationsEnabled,
  'smsNotificationsEnabled': instance.smsNotificationsEnabled,
  'pushNotificationsEnabled': instance.pushNotificationsEnabled,
  'enabledNotificationTypes': instance.enabledNotificationTypes,
  'emailTemplate': instance.emailTemplate,
  'customSettings': instance.customSettings,
};
