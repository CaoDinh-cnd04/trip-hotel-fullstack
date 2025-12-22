/// Service đồng bộ tin nhắn từ Firestore sang SQL Server
/// 
/// Chức năng:
/// - Đồng bộ tin nhắn đã gửi trong Firestore lên SQL Server
/// - Lấy lịch sử cuộc trò chuyện từ SQL Server
/// - Tìm kiếm tin nhắn trong SQL Server
/// - Lấy thống kê chat
import 'package:dio/dio.dart';
import 'backend_auth_service.dart';
import '../models/message_model.dart';

class ChatSyncService {
  final Dio _dio;
  final BackendAuthService _authService = BackendAuthService();

  ChatSyncService() : _dio = Dio() {
    _dio.options.baseUrl = 'http://192.168.110.113:5000'; // Change to your IP
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    
    // Add auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = _authService.authToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  /// Đồng bộ tin nhắn lên SQL Server sau khi đã gửi vào Firestore
  /// 
  /// [message] - Đối tượng MessageModel cần đồng bộ
  /// [firestoreConversationId] - ID cuộc trò chuyện trong Firestore
  /// 
  /// Lưu ý: Lỗi đồng bộ sẽ không làm gián đoạn chat
  Future<void> syncMessage(MessageModel message, String firestoreConversationId) async {
    try {
      // Extract hotel/booking info from metadata for email context
      final metadata = message.metadata ?? {};
      final hotelName = metadata['hotel_name'] as String?;
      final bookingCode = metadata['booking_id'] as String?;
      
      await _dio.post(
        '/api/chat-sync/message',
        data: {
          'firestoreMessageId': message.id,
          'firestoreConversationId': firestoreConversationId,
          'senderId': int.tryParse(message.senderId) ?? 0,
          'receiverId': int.tryParse(message.receiverId) ?? 0,
          'content': message.content,
          'messageType': message.type.toString().split('.').last,
          'fileUrl': message.imageUrl,
          'senderName': message.senderName,
          'senderEmail': message.senderEmail,
          'senderRole': message.senderRole,
          'receiverName': message.receiverName,
          'receiverEmail': message.receiverEmail,
          'receiverRole': message.receiverRole,
          'replyToContent': message.replyToContent,
          'timestamp': message.timestamp.toIso8601String(),
          // Add context for email notification
          'hotelName': hotelName,
          'bookingCode': bookingCode,
        },
      );
      
      print('✅ Message synced to SQL Server: ${message.id}');
    } on DioException catch (e) {
      // Don't throw - sync failure shouldn't break chat
      print('⚠️  Failed to sync message to SQL Server: ${e.message}');
    }
  }

  /// Lấy lịch sử cuộc trò chuyện từ SQL Server
  /// 
  /// [page] - Trang cần lấy (mặc định: 1)
  /// [limit] - Số lượng cuộc trò chuyện mỗi trang (mặc định: 20)
  /// 
  /// Trả về danh sách cuộc trò chuyện (rỗng nếu có lỗi)
  Future<List<dynamic>> getConversationHistory({int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get(
        '/api/chat-sync/conversations',
        queryParameters: {'page': page, 'limit': limit},
      );

      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      print('❌ Get conversation history error: ${e.message}');
      return [];
    }
  }

  /// Lấy lịch sử tin nhắn của một cuộc trò chuyện từ SQL Server
  /// 
  /// [conversationId] - ID cuộc trò chuyện
  /// [page] - Trang cần lấy (mặc định: 1)
  /// [limit] - Số lượng tin nhắn mỗi trang (mặc định: 50)
  /// 
  /// Trả về danh sách tin nhắn (rỗng nếu có lỗi)
  Future<List<dynamic>> getMessageHistory(
    int conversationId, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _dio.get(
        '/api/chat-sync/conversations/$conversationId/messages',
        queryParameters: {'page': page, 'limit': limit},
      );

      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      print('❌ Get message history error: ${e.message}');
      return [];
    }
  }

  /// Tìm kiếm tin nhắn trong SQL Server
  /// 
  /// [query] - Từ khóa tìm kiếm
  /// [page] - Trang cần lấy (mặc định: 1)
  /// [limit] - Số lượng kết quả mỗi trang (mặc định: 20)
  /// 
  /// Trả về danh sách tin nhắn khớp (rỗng nếu có lỗi)
  Future<List<dynamic>> searchMessages(
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/api/chat-sync/search',
        queryParameters: {'q': query, 'page': page, 'limit': limit},
      );

      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      print('❌ Search messages error: ${e.message}');
      return [];
    }
  }

  /// Lấy thống kê chat từ SQL Server
  /// 
  /// Trả về Map chứa dữ liệu thống kê (null nếu có lỗi)
  /// Bao gồm: số lượng tin nhắn, cuộc trò chuyện, người dùng hoạt động, v.v.
  Future<Map<String, dynamic>?> getChatStatistics() async {
    try {
      final response = await _dio.get('/api/chat-sync/statistics');
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      print('❌ Get chat statistics error: ${e.message}');
      return null;
    }
  }
}

