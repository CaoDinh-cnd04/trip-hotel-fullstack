// Chat Sync Service - Sync messages from Firestore to SQL Server
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

  /// Sync message to SQL Server after sending to Firestore
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

  /// Get conversation history from SQL Server
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

  /// Get message history for a conversation from SQL Server
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

  /// Search messages in SQL Server
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

  /// Get chat statistics from SQL Server
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

