import 'package:cloud_firestore/cloud_firestore.dart';

/// Model đại diện cho tin nhắn trong chat (Firestore)
/// 
/// Chứa thông tin:
/// - Thông tin người gửi: senderId, senderName, senderEmail, senderRole
/// - Thông tin người nhận: receiverId, receiverName, receiverEmail, receiverRole
/// - Nội dung: content, type (text/image), imageUrl
/// - Trạng thái: isRead, timestamp
/// - Tính năng reply: replyToMessageId, replyToContent
/// - Metadata: metadata (chứa thông tin booking, hotel, v.v.)
class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final String senderRole; // 'user', 'hotelmanager', 'admin'
  final String receiverId;
  final String receiverName;
  final String receiverEmail;
  final String receiverRole;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;
  final String? replyToMessageId;
  final String? replyToContent;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderEmail,
    required this.senderRole,
    required this.receiverId,
    required this.receiverName,
    required this.receiverEmail,
    required this.receiverRole,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
    this.metadata,
    this.replyToMessageId,
    this.replyToContent,
  });

  /// Tạo đối tượng MessageModel từ Firestore DocumentSnapshot
  /// 
  /// [doc] - DocumentSnapshot từ Firestore
  /// 
  /// Xử lý:
  /// - Hỗ trợ cả camelCase và snake_case
  /// - Parse Timestamp thành DateTime
  /// - Xử lý các giá trị null an toàn
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // ✅ FIX: Handle null values safely - support both camelCase and snake_case
    final senderId = _parseField(data, ['senderId', 'sender_id']) ?? '';
    final receiverId = _parseField(data, ['receiverId', 'receiver_id']) ?? '';
    
    // Skip messages with invalid senderId/receiverId
    if (senderId.isEmpty && receiverId.isEmpty) {
      throw FormatException('Message ${doc.id} has no senderId or receiverId. Data: ${data.keys.toList()}');
    }
    
    return MessageModel(
      id: doc.id,
      senderId: senderId,
      senderName: data['senderName'] ?? data['sender_name'] ?? '',
      senderEmail: data['senderEmail'] ?? data['sender_email'] ?? '',
      senderRole: data['senderRole'] ?? data['sender_role'] ?? 'user',
      receiverId: receiverId,
      receiverName: data['receiverName'] ?? data['receiver_name'] ?? '',
      receiverEmail: data['receiverEmail'] ?? data['receiver_email'] ?? '',
      receiverRole: data['receiverRole'] ?? data['receiver_role'] ?? 'user',
      content: data['content'] ?? '',
      type: MessageType.fromString(data['type'] ?? 'text'),
      timestamp: data['timestamp'] != null 
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: data['isRead'] ?? data['is_read'] ?? false,
      imageUrl: data['imageUrl'] ?? data['image_url'],
      metadata: data['metadata'],
      replyToMessageId: data['replyToMessageId'] ?? data['reply_to_message_id'],
      replyToContent: data['replyToContent'] ?? data['reply_to_content'],
    );
  }

  /// Helper để parse field với nhiều tên có thể
  /// 
  /// [data] - Map chứa dữ liệu
  /// [fieldNames] - Danh sách tên field có thể (ví dụ: ['senderId', 'sender_id'])
  /// 
  /// Trả về giá trị string đầu tiên tìm thấy, hoặc null nếu không tìm thấy
  static String? _parseField(Map<String, dynamic> data, List<String> fieldNames) {
    for (final fieldName in fieldNames) {
      final value = data[fieldName];
      if (value != null && value is String && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  /// Tạo đối tượng MessageModel từ Map (dùng cho testing hoặc offline)
  /// 
  /// [data] - Map chứa dữ liệu
  /// [id] - ID của tin nhắn
  /// 
  /// Parse các trường từ Map, xử lý Timestamp
  factory MessageModel.fromMap(Map<String, dynamic> data, String id) {
    return MessageModel(
      id: id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderEmail: data['senderEmail'] ?? '',
      senderRole: data['senderRole'] ?? 'user',
      receiverId: data['receiverId'] ?? '',
      receiverName: data['receiverName'] ?? '',
      receiverEmail: data['receiverEmail'] ?? '',
      receiverRole: data['receiverRole'] ?? 'user',
      content: data['content'] ?? '',
      type: MessageType.fromString(data['type'] ?? 'text'),
      timestamp: data['timestamp'] is Timestamp 
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: data['isRead'] ?? false,
      imageUrl: data['imageUrl'],
      metadata: data['metadata'],
      replyToMessageId: data['replyToMessageId'],
      replyToContent: data['replyToContent'],
    );
  }

  /// Chuyển đổi đối tượng MessageModel sang Map để lưu vào Firestore
  /// 
  /// Trả về Map với các trường ở dạng camelCase
  /// Chuyển đổi DateTime sang Timestamp để lưu vào Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderEmail': senderEmail,
      'senderRole': senderRole,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverEmail': receiverEmail,
      'receiverRole': receiverRole,
      'content': content,
      'type': type.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'imageUrl': imageUrl,
      'metadata': metadata,
      'replyToMessageId': replyToMessageId,
      'replyToContent': replyToContent,
    };
  }

  /// Tạo bản sao của MessageModel với các trường được cập nhật
  /// 
  /// Cho phép cập nhật từng trường riêng lẻ mà không cần tạo mới toàn bộ object
  /// 
  /// Tất cả các tham số đều tùy chọn, nếu không cung cấp sẽ giữ nguyên giá trị cũ
  MessageModel copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderEmail,
    String? senderRole,
    String? receiverId,
    String? receiverName,
    String? receiverEmail,
    String? receiverRole,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isRead,
    String? imageUrl,
    Map<String, dynamic>? metadata,
    String? replyToMessageId,
    String? replyToContent,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderEmail: senderEmail ?? this.senderEmail,
      senderRole: senderRole ?? this.senderRole,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      receiverEmail: receiverEmail ?? this.receiverEmail,
      receiverRole: receiverRole ?? this.receiverRole,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
      metadata: metadata ?? this.metadata,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToContent: replyToContent ?? this.replyToContent,
    );
  }

  // Helper methods
  bool get isText => type == MessageType.text;
  bool get isImage => type == MessageType.image;
  bool get isFile => type == MessageType.file;
  bool get isSystem => type == MessageType.system;

  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m trước';
    } else {
      return 'Vừa xong';
    }
  }

  String get timeString {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  bool get isReply => replyToMessageId != null;
}

enum MessageType {
  text,
  image,
  file,
  system;

  static MessageType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }
}

// Chat conversation model
class ChatConversation {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String> participantEmails;
  final Map<String, String> participantRoles;
  final MessageModel? lastMessage;
  final DateTime lastActivity;
  final bool isActive;
  final Map<String, bool> readStatus; // userId -> isRead
  final Map<String, int> unreadCount; // userId -> count
  final Map<String, dynamic>? metadata; // ✅ NEW: Booking info, hotel info, etc.

  ChatConversation({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.participantEmails,
    required this.participantRoles,
    this.lastMessage,
    required this.lastActivity,
    this.isActive = true,
    this.readStatus = const {},
    this.unreadCount = const {},
    this.metadata, // ✅ NEW
  });

  factory ChatConversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // ✅ FIX: Handle null lastActivity safely
    DateTime lastActivity;
    if (data['lastActivity'] != null && data['lastActivity'] is Timestamp) {
      lastActivity = (data['lastActivity'] as Timestamp).toDate();
    } else if (data['last_activity'] != null && data['last_activity'] is Timestamp) {
      lastActivity = (data['last_activity'] as Timestamp).toDate();
    } else {
      // Use last message timestamp or current time as fallback
      if (data['lastMessage'] != null && data['lastMessage']['timestamp'] != null) {
        try {
          lastActivity = (data['lastMessage']['timestamp'] as Timestamp).toDate();
        } catch (e) {
          lastActivity = DateTime.now();
        }
      } else {
        lastActivity = DateTime.now();
      }
    }
    
    MessageModel? lastMessage;
    try {
      if (data['lastMessage'] != null) {
        lastMessage = MessageModel.fromMap(
          data['lastMessage'] as Map<String, dynamic>,
          data['lastMessage']['id'] ?? '',
        );
      }
    } catch (e) {
      print('⚠️ Error parsing lastMessage for conversation ${doc.id}: $e');
      lastMessage = null;
    }
    
    return ChatConversation(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      participantNames: Map<String, String>.from(data['participantNames'] ?? data['participant_names'] ?? {}),
      participantEmails: Map<String, String>.from(data['participantEmails'] ?? data['participant_emails'] ?? {}),
      participantRoles: Map<String, String>.from(data['participantRoles'] ?? data['participant_roles'] ?? {}),
      lastMessage: lastMessage,
      lastActivity: lastActivity,
      isActive: data['isActive'] ?? data['is_active'] ?? true,
      readStatus: Map<String, bool>.from(data['readStatus'] ?? data['read_status'] ?? {}),
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? data['unread_count'] ?? {}),
      metadata: data['metadata'] != null ? Map<String, dynamic>.from(data['metadata']) : null, // ✅ NEW
    );
  }

  /// Chuyển đổi đối tượng MessageModel sang Map để lưu vào Firestore
  /// 
  /// Trả về Map với các trường ở dạng camelCase
  /// Chuyển đổi DateTime sang Timestamp để lưu vào Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'participantNames': participantNames,
      'participantEmails': participantEmails,
      'participantRoles': participantRoles,
      'lastMessage': lastMessage?.toFirestore(),
      'lastActivity': Timestamp.fromDate(lastActivity),
      'isActive': isActive,
      'readStatus': readStatus,
      'unreadCount': unreadCount,
      'metadata': metadata, // ✅ NEW
    };
  }
  
  // ✅ NEW: Helper methods to get booking info from metadata (like web)
  Map<String, dynamic>? get bookingInfo {
    if (metadata == null) return null;
    final bookingId = metadata?['booking_id'];
    if (bookingId == null) return null;
    return {
      'booking_id': bookingId,
      'hotel_name': metadata?['hotel_name'],
      'room_name': metadata?['room_name'],
      'check_in': metadata?['check_in'],
      'check_out': metadata?['check_out'],
    };
  }
  
  String? get customerNameFromMetadata => metadata?['user_name'];
  String? get customerEmailFromMetadata => metadata?['user_email'];

  // Helper methods
  String getOtherParticipant(String currentUserId) {
    return participants.firstWhere((id) => id != currentUserId);
  }

  String getOtherParticipantName(String currentUserId) {
    final otherId = getOtherParticipant(currentUserId);
    return participantNames[otherId] ?? 'Unknown';
  }

  String getOtherParticipantRole(String currentUserId) {
    final otherId = getOtherParticipant(currentUserId);
    return participantRoles[otherId] ?? 'user';
  }

  int getUnreadCount(String userId) {
    return unreadCount[userId] ?? 0;
  }

  bool isRead(String userId) {
    return readStatus[userId] ?? false;
  }
}
