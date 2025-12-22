import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../models/message_model.dart';
import '../models/user_role_model.dart';
import 'chat_sync_service.dart';
import 'backend_auth_service.dart';
import '../../core/constants/app_constants.dart';

class MessageService {
  static final MessageService _instance = MessageService._internal();
  factory MessageService() => _instance;
  MessageService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ChatSyncService _chatSyncService = ChatSyncService();

  // Collections
  static const String _messagesCollection = 'messages';
  static const String _conversationsCollection = 'conversations';

  // Get current user
  User? get currentUser => _auth.currentUser;

  /// ✅ Helper: Ensure user is authenticated with Firebase
  Future<User> _ensureFirebaseAuth() async {
    var currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('❌ User not authenticated with Firebase!');
      print('🔄 Attempting to sync with backend session...');
      
      // Try to sync from backend session
      final backendAuthService = await _tryBackendSync();
      if (backendAuthService) {
        currentUser = _auth.currentUser;
        if (currentUser != null) {
          print('✅ Successfully synced from backend!');
          return currentUser;
        }
      }
      
      throw Exception(
        'Bạn chưa đăng nhập Firebase.\n'
        'Vui lòng đăng xuất và đăng nhập lại để sử dụng tính năng chat.'
      );
    }
    
    // Check if user is anonymous (should not happen for chat)
    if (currentUser.isAnonymous) {
      print('❌ User is anonymous, chat requires proper authentication');
      throw Exception(
        'Tài khoản anonymous không thể sử dụng chat.\n'
        'Vui lòng đăng nhập với tài khoản thật.'
      );
    }
    
    print('✅ Firebase authenticated: ${currentUser.uid} (${currentUser.email})');
    return currentUser;
  }

  /// Try to sync Firebase from backend session
  Future<bool> _tryBackendSync() async {
    try {
      // Import BackendAuthService dynamically to avoid circular dependency
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      final userRole = prefs.getString('user_role');
      
      if (userData == null) {
        print('⚠️ No backend session found');
        return false;
      }
      
      print('🔄 Found backend session, attempting Firebase sync...');
      
      // User needs to re-login to sync Firebase
      // For now, we can't auto-sync without password
      return false;
    } catch (e) {
      print('❌ Backend sync failed: $e');
      return false;
    }
  }

  // Create initial conversation after booking (auto-send welcome message)
  Future<void> createBookingConversation({
    required String hotelManagerId,
    required String hotelManagerName,
    required String hotelManagerEmail,
    required String hotelName,
    required String bookingId,
  }) async {
    final currentUser = await _ensureFirebaseAuth();

    try {
      print('💬 Creating offline conversation...');
      print('   - Hotel Manager ID: $hotelManagerId');
      print('   - Hotel Manager Email: $hotelManagerEmail');
      print('   - Booking ID: $bookingId');

      // Create offline conversation (no need to check if manager is online)
      await _createOfflineConversation(
        currentUser: currentUser,
        hotelManagerId: hotelManagerId,
        hotelManagerName: hotelManagerName,
        hotelManagerEmail: hotelManagerEmail,
        hotelName: hotelName,
        bookingId: bookingId,
      );

      print('✅ Offline conversation created successfully');
    } catch (e) {
      print('❌ Error creating booking conversation: $e');
      rethrow;
    }
  }

  /// Tạo cuộc trò chuyện offline - hoạt động ngay cả khi manager không online
  /// 
  /// [currentUser] - User hiện tại (Firebase User)
  /// [hotelManagerId] - ID của hotel manager (backend ID)
  /// [hotelManagerName] - Tên hotel manager
  /// [hotelManagerEmail] - Email hotel manager
  /// [hotelName] - Tên khách sạn
  /// [bookingId] - ID đặt phòng
  /// 
  /// Tự động gửi tin nhắn chào mừng và gửi email thông báo cho manager
  Future<void> _createOfflineConversation({
    required User currentUser,
    required String hotelManagerId,
    required String hotelManagerName,
    required String hotelManagerEmail,
    required String hotelName,
    required String bookingId,
  }) async {
    try {
      // Try to get Firebase UID, but don't fail if not found
      String? firebaseUid = await _getFirebaseUidFromBackendId(hotelManagerId);
      
      if (firebaseUid == null) {
        // Manager not in Firebase yet - create placeholder
        firebaseUid = 'offline_$hotelManagerId';
        print('⚠️ Manager not online, using placeholder: $firebaseUid');
      }

      // Create conversation ID
      final conversationId = _getConversationId(currentUser.uid, firebaseUid);
      print('🔍 === CREATE CONVERSATION DEBUG ===');
      print('🔍 Current User UID: ${currentUser.uid}');
      print('🔍 Manager Firebase UID: $firebaseUid');
      print('🔍 Created Conversation ID: $conversationId');
      print('🔍 Firestore path: conversations/$conversationId');
      print('🔍 ================================');

      // Prepare welcome message
      final welcomeMessage = '''
Xin chào! Tôi vừa đặt phòng tại $hotelName.

Mã đặt phòng: $bookingId

Tôi có một số câu hỏi về đặt phòng.
''';

      // ✅ FIX: Save message with camelCase field names (same as sendMessage)
      final messageData = {
        'senderId': currentUser.uid,
        'senderName': currentUser.displayName ?? 'Khách hàng',
        'senderEmail': currentUser.email ?? '',
        'senderRole': 'user',
        'receiverId': firebaseUid,
        'receiverName': hotelManagerName,
        'receiverEmail': hotelManagerEmail,
        'receiverRole': 'hotel_manager',
        'content': welcomeMessage,
        'type': 'text',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'metadata': {
          'booking_id': bookingId,
          'hotel_name': hotelName,
          'backend_hotel_manager_id': hotelManagerId,
          'manager_email': hotelManagerEmail,
          'auto_generated': true,
        },
      };

      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add(messageData);

      // Update conversation metadata
      await _firestore.collection('conversations').doc(conversationId).set({
        'participants': [currentUser.uid, firebaseUid],
        'last_message': welcomeMessage.substring(0, 50),
        'last_message_time': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
        'metadata': {
          'booking_id': bookingId,
          'hotel_name': hotelName,
          'backend_hotel_manager_id': hotelManagerId,
          'manager_name': hotelManagerName,
          'manager_email': hotelManagerEmail,
          'user_name': currentUser.displayName ?? 'Khách hàng',
          'user_email': currentUser.email ?? '',
        },
      }, SetOptions(merge: true));

      print('✅ Message saved to Firestore');

      // Send email notification to manager
      await _sendEmailNotification(
        hotelManagerId: hotelManagerId,
        hotelManagerEmail: hotelManagerEmail,
        userName: currentUser.displayName ?? 'Khách hàng',
        userEmail: currentUser.email ?? '',
        hotelName: hotelName,
        bookingId: bookingId,
        messageContent: welcomeMessage,
      );

    } catch (e) {
      print('❌ Error in _createOfflineConversation: $e');
      rethrow;
    }
  }

  /// Gửi email thông báo cho manager qua backend API
  /// 
  /// [hotelManagerId] - ID của hotel manager
  /// [hotelManagerEmail] - Email của hotel manager
  /// [userName] - Tên người dùng
  /// [userEmail] - Email người dùng
  /// [hotelName] - Tên khách sạn
  /// [bookingId] - ID đặt phòng
  /// [messageContent] - Nội dung tin nhắn
  /// 
  /// Lưu ý: Lỗi gửi email sẽ không làm gián đoạn quá trình
  Future<void> _sendEmailNotification({
    required String hotelManagerId,
    required String hotelManagerEmail,
    required String userName,
    required String userEmail,
    required String hotelName,
    required String bookingId,
    required String messageContent,
  }) async {
    try {
      print('📧 Sending email notification to manager...');
      
      final dio = Dio(BaseOptions(
        baseUrl: '${AppConstants.baseUrl}/api',
        connectTimeout: const Duration(seconds: 10),
      ));

      // Add auth token
      final authService = BackendAuthService();
      final token = await authService.getToken();
      if (token != null) {
        dio.options.headers['Authorization'] = 'Bearer $token';
      }

      final response = await dio.post('/chat/notify-manager', data: {
        'hotel_manager_id': int.parse(hotelManagerId),
        'user_name': userName,
        'user_email': userEmail,
        'hotel_name': hotelName,
        'booking_id': bookingId,
        'message_content': messageContent,
      });

      if (response.data['success'] == true) {
        print('✅ Email notification sent successfully');
      } else {
        print('⚠️ Email notification failed: ${response.data['message']}');
      }
    } catch (e) {
      print('❌ Error sending email notification: $e');
      // Don't throw - email is not critical
    }
  }

  /// Tạo ID cuộc trò chuyện duy nhất từ 2 user ID
  /// 
  /// [userId1] - ID của user thứ nhất
  /// [userId2] - ID của user thứ hai
  /// 
  /// Trả về ID được sắp xếp theo thứ tự để đảm bảo tính nhất quán
  String _getConversationId(String userId1, String userId2) {
    // Sort IDs to ensure consistency regardless of order
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// Lấy Firebase UID từ backend user ID
  /// 
  /// [backendUserId] - ID của user trong backend database
  /// 
  /// Trả về Firebase UID nếu tìm thấy, null nếu không tìm thấy
  /// Tìm trong collection 'user_mapping' hoặc 'users'
  Future<String?> _getFirebaseUidFromBackendId(String backendUserId) async {
    try {
      // Try user_mapping collection first
      final mappingDoc = await _firestore
          .collection('user_mapping')
          .doc(backendUserId)
          .get();
      
      if (mappingDoc.exists) {
        return mappingDoc.data()?['firebase_uid'] as String?;
      }
      
      // If not found, try querying users collection by backend_user_id
      final usersSnapshot = await _firestore
          .collection('users')
          .where('backend_user_id', isEqualTo: backendUserId)
          .limit(1)
          .get();
      
      if (usersSnapshot.docs.isNotEmpty) {
        return usersSnapshot.docs.first.id;
      }
      
      return null;
    } catch (e) {
      print('❌ Error looking up Firebase UID: $e');
      return null;
    }
  }

  /// Chuyển đổi offline placeholder hoặc backend ID sang Firebase UID
  /// 
  /// [userId] - ID có thể là Firebase UID, offline placeholder, hoặc backend ID
  /// 
  /// Trả về Firebase UID nếu có thể, nếu không trả về ID ban đầu
  Future<String> _normalizeUserId(String userId) async {
    // If it's already a Firebase UID (doesn't start with 'offline_' and is not a number), return as is
    if (!userId.startsWith('offline_') && userId.length > 20) {
      // Likely a Firebase UID (Firebase UIDs are typically 28 characters)
      return userId;
    }
    
    // If it's an offline placeholder (e.g., "offline_1015")
    if (userId.startsWith('offline_')) {
      final backendId = userId.replaceAll('offline_', '');
      print('🔍 Converting offline placeholder $userId to Firebase UID...');
      
      // Try to get real Firebase UID
      final firebaseUid = await _getFirebaseUidFromBackendId(backendId);
      if (firebaseUid != null) {
        print('✅ Found Firebase UID: $firebaseUid for backend ID: $backendId');
        return firebaseUid;
      }
      
      // If not found, return offline placeholder (conversation might still use it)
      print('⚠️ Firebase UID not found for $backendId, using offline placeholder');
      return userId;
    }
    
    // If it's a pure backend ID (just numbers), try to convert
    if (RegExp(r'^\d+$').hasMatch(userId)) {
      print('🔍 Converting backend ID $userId to Firebase UID...');
      final firebaseUid = await _getFirebaseUidFromBackendId(userId);
      if (firebaseUid != null) {
        print('✅ Found Firebase UID: $firebaseUid for backend ID: $userId');
        return firebaseUid;
      }
    }
    
    // Return as is if we can't convert
    return userId;
  }

  /// Gửi tin nhắn
  /// 
  /// [receiverId] - ID người nhận (bắt buộc)
  /// [receiverName] - Tên người nhận (bắt buộc)
  /// [receiverEmail] - Email người nhận (bắt buộc)
  /// [receiverRole] - Vai trò người nhận (bắt buộc)
  /// [content] - Nội dung tin nhắn (bắt buộc)
  /// [type] - Loại tin nhắn (text/image, mặc định: text)
  /// [imageUrl] - URL hình ảnh (tùy chọn)
  /// [metadata] - Dữ liệu bổ sung (tùy chọn)
  /// [replyToMessageId] - ID tin nhắn đang trả lời (tùy chọn)
  /// [replyToContent] - Nội dung tin nhắn đang trả lời (tùy chọn)
  /// 
  /// Trả về MessageModel của tin nhắn đã được gửi
  /// Tự động đồng bộ lên SQL Server (non-blocking)
  Future<MessageModel> sendMessage({
    required String receiverId,
    required String receiverName,
    required String receiverEmail,
    required String receiverRole,
    required String content,
    MessageType type = MessageType.text,
    String? imageUrl,
    Map<String, dynamic>? metadata,
    String? replyToMessageId,
    String? replyToContent,
  }) async {
    final currentUser = await _ensureFirebaseAuth();

    // ✅ FIX: Lấy tên từ Firestore user profile
    String currentUserName = currentUser.displayName ?? 'Unknown User';
    String currentUserEmail = currentUser.email ?? '';
    
    try {
      final userProfile = await _firestore.collection('users').doc(currentUser.uid).get();
      if (userProfile.exists) {
        final data = userProfile.data();
        currentUserName = data?['display_name'] ?? data?['displayName'] ?? currentUserName;
        currentUserEmail = data?['email'] ?? currentUserEmail;
        print('✅ Sender name from Firestore: $currentUserName');
      }
    } catch (e) {
      print('⚠️ Error getting sender profile: $e');
    }

    // ✅ FIX: Find actual conversation ID (same logic as getMessages)
    String conversationId;
    
    try {
      print('🔍 [SEND] Looking for conversation between ${currentUser.uid} and $receiverId');
      
      // First, try direct conversation IDs
      final expectedId1 = _generateConversationId(currentUser.uid, receiverId);
      final expectedId2 = _generateConversationId(receiverId, currentUser.uid);
      
      print('🔍 [SEND] Expected conversation IDs: $expectedId1, $expectedId2');
      
      String? foundConversationId;
      
      // Check both expected IDs
      for (final expectedId in [expectedId1, expectedId2]) {
        final convDoc = await _firestore
            .collection(_conversationsCollection)
            .doc(expectedId)
            .get();
        
        if (convDoc.exists) {
          foundConversationId = expectedId;
          final participants = List<String>.from(convDoc.data()?['participants'] ?? []);
          print('✅ [SEND] Found conversation by ID: $expectedId');
          print('✅ [SEND] Participants: $participants');
          break;
        }
      }
      
      // If not found, search all conversations
      if (foundConversationId == null) {
        print('🔍 [SEND] Conversation not found by ID, searching all conversations...');
        final conversations = await _firestore
            .collection(_conversationsCollection)
            .where('participants', arrayContains: currentUser.uid)
            .get();
        
        print('🔍 [SEND] Searching in ${conversations.docs.length} conversations...');
        
        // Find conversation that includes the receiver (with better matching logic)
        for (var convDoc in conversations.docs) {
          final participants = List<String>.from(convDoc.data()['participants'] ?? []);
          print('🔍 [SEND] Checking conversation ${convDoc.id} with participants: $participants');
          
          // Check if this conversation involves the receiver
          final hasReceiver = participants.any((p) {
            // Direct match
            if (p == receiverId) {
              print('✅ [SEND] Direct match: $p == $receiverId');
              return true;
            }
            
            // Offline placeholder matching
            if (p.startsWith('offline_')) {
              final offlineId = p.replaceAll('offline_', '');
              if (receiverId.contains(offlineId) || offlineId.contains(receiverId)) {
                print('✅ [SEND] Offline placeholder match: $p matches $receiverId');
                return true;
              }
            }
            if (receiverId.startsWith('offline_')) {
              final offlineId = receiverId.replaceAll('offline_', '');
              if (p.contains(offlineId) || offlineId.contains(p)) {
                print('✅ [SEND] Offline placeholder match (reverse): $p matches $receiverId');
                return true;
              }
            }
            
            // Backend ID number matching
            final pNum = p.replaceAll(RegExp(r'[^0-9]'), '');
            final receiverNum = receiverId.replaceAll(RegExp(r'[^0-9]'), '');
            if (pNum.isNotEmpty && receiverNum.isNotEmpty && pNum == receiverNum) {
              print('✅ [SEND] Backend ID match: $p matches $receiverId');
              return true;
            }
            
            return false;
          });
          
          if (hasReceiver) {
            foundConversationId = convDoc.id;
            print('✅ [SEND] Found existing conversation: $foundConversationId');
            print('✅ [SEND] Participants: $participants');
            break;
          }
        }
      }
      
      conversationId = foundConversationId ?? _generateConversationId(currentUser.uid, receiverId);
      if (foundConversationId == null) {
        print('⚠️ [SEND] No existing conversation found, will create/use: $conversationId');
      }
    } catch (e) {
      print('❌ [SEND] Error searching conversation: $e');
      conversationId = _generateConversationId(currentUser.uid, receiverId);
      print('⚠️ [SEND] Using fallback conversation ID: $conversationId');
    }
    
    final messageId = _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .collection('messages')
        .doc().id;
    
    final message = MessageModel(
      id: messageId,
      senderId: currentUser.uid,
      senderName: currentUserName, // ✅ FIX: Dùng tên từ Firestore
      senderEmail: currentUserEmail, // ✅ FIX: Dùng email từ Firestore
      senderRole: _getUserRole(), // This should be determined from user data
      receiverId: receiverId,
      receiverName: receiverName,
      receiverEmail: receiverEmail,
      receiverRole: receiverRole,
      content: content,
      type: type,
      timestamp: DateTime.now(),
      imageUrl: imageUrl,
      metadata: metadata,
      replyToMessageId: replyToMessageId,
      replyToContent: replyToContent,
    );

    // Save message to conversation sub-collection
    await _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .set(message.toFirestore());

    // Update conversation metadata
    await _updateConversation(message);

    // Sync to SQL Server (non-blocking)
    _chatSyncService.syncMessage(message, conversationId).catchError((error) {
      print('⚠️  Message sync failed (non-critical): $error');
    });

    return message;
  }

  // ✅ NEW: Get messages directly by conversation ID (more reliable)
  Stream<List<MessageModel>> getMessagesByConversationId({
    required String conversationId,
    int limit = 100,
  }) async* {
    print('🔍 === GET MESSAGES BY CONVERSATION ID ===');
    print('🔍 Conversation ID: $conversationId');
    
    try {
      // First verify conversation exists
      final convDoc = await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .get();
      
      if (!convDoc.exists) {
        print('❌ Conversation $conversationId does not exist!');
        yield [];
        return;
      }
      
      final participants = List<String>.from(convDoc.data()?['participants'] ?? []);
      print('✅ Conversation exists with participants: $participants');
      
      // Stream messages directly from conversation
      // Try with orderBy first, fallback to simple query if index is missing
      try {
        await for (var snapshot in _firestore
            .collection(_conversationsCollection)
            .doc(conversationId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(limit)
            .snapshots()) {
          print('📨 Loaded ${snapshot.docs.length} messages from conversation $conversationId');
          
          // ✅ DEBUG: Log all message senderIds before parsing
          print('📋 Raw message senderIds:');
          for (var doc in snapshot.docs.take(5)) {
            final data = doc.data();
            print('   - ${doc.id}: senderId=${data['senderId']}, receiverId=${data['receiverId']}');
          }
          
          final messages = snapshot.docs
              .map((doc) {
                try {
                  final msg = MessageModel.fromFirestore(doc);
                  print('✅ Parsed message: senderId=${msg.senderId}, receiverId=${msg.receiverId}, content="${msg.content.substring(0, msg.content.length > 30 ? 30 : msg.content.length)}"');
                  return msg;
                } catch (e) {
                  print('❌ Error parsing message ${doc.id}: $e');
                  print('📋 Message data: ${doc.data()}');
                  // Return null instead of rethrowing, will filter out later
                  return null;
                }
              })
              .whereType<MessageModel>() // Filter out nulls
              .toList();
          
          // Sort on client side (in case orderBy didn't work properly)
          messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          
          yield messages;
        }
      } catch (e) {
        print('⚠️ Error with orderBy query, trying without orderBy: $e');
        // Fallback: query without orderBy and sort on client
        await for (var snapshot in _firestore
            .collection(_conversationsCollection)
            .doc(conversationId)
            .collection('messages')
            .limit(limit * 2) // Get more to ensure we have enough after filtering
            .snapshots()) {
          print('📨 Loaded ${snapshot.docs.length} messages (no orderBy) from conversation $conversationId');
          
          final messages = snapshot.docs
            .map((doc) {
                try {
                  return MessageModel.fromFirestore(doc);
                } catch (e) {
                  print('❌ Error parsing message ${doc.id}: $e');
                  print('📋 Message data: ${doc.data()}');
                  return null;
                }
              })
              .whereType<MessageModel>()
              .toList();
          
          // Sort by timestamp descending
          messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          
          // Limit to requested amount
          yield messages.take(limit).toList();
        }
      }
    } catch (e) {
      print('❌ Error in getMessagesByConversationId: $e');
      yield [];
    }
  }

  // Get messages between two users
  Stream<List<MessageModel>> getMessages({
    required String otherUserId,
    String? conversationId, // ✅ Optional: if provided, use it directly
    int limit = 50,
  }) async* {
    // ✅ FIX: If conversationId is provided, use it directly (more reliable)
    if (conversationId != null && conversationId.isNotEmpty) {
      print('🔍 Using provided conversation ID: $conversationId');
      yield* getMessagesByConversationId(conversationId: conversationId, limit: limit);
      return;
    }
    final currentUser = _auth.currentUser;
    print('🔍 === GET MESSAGES DEBUG ===');
    print('🔍 Current User UID: ${currentUser?.uid ?? "NOT LOGGED IN"}');
    print('🔍 Other User ID (raw): $otherUserId');
    
    if (currentUser == null) {
      print('❌ Not logged in to Firebase!');
      yield [];
      return;
    }

    // ✅ FIX: Normalize otherUserId (convert offline placeholder to Firebase UID if possible)
    final normalizedOtherUserId = await _normalizeUserId(otherUserId);
    print('🔍 Normalized Other User ID: $normalizedOtherUserId');
    
    // Try to find the actual conversation ID (may be different due to offline placeholders)
    String? actualConversationId;
    
    try {
      // First, try direct conversation IDs (both original and normalized)
      final expectedIds = [
        _generateConversationId(currentUser.uid, otherUserId),
        _generateConversationId(otherUserId, currentUser.uid),
        if (normalizedOtherUserId != otherUserId) _generateConversationId(currentUser.uid, normalizedOtherUserId),
        if (normalizedOtherUserId != otherUserId) _generateConversationId(normalizedOtherUserId, currentUser.uid),
      ];
      
      print('🔍 Expected conversation IDs: $expectedIds');
      
      // Check all expected IDs
      for (final expectedId in expectedIds) {
        final convDoc = await _firestore
            .collection(_conversationsCollection)
            .doc(expectedId)
            .get();
        
        if (convDoc.exists) {
          actualConversationId = expectedId;
          final participants = List<String>.from(convDoc.data()?['participants'] ?? []);
          print('✅ Found conversation by ID: $expectedId');
          print('✅ Participants: $participants');
          break;
        }
      }
      
      // If not found, search all conversations where current user is a participant
      if (actualConversationId == null) {
        print('🔍 Conversation not found by ID, searching all conversations...');
        final conversations = await _firestore
            .collection(_conversationsCollection)
            .where('participants', arrayContains: currentUser.uid)
            .get();
        
        print('🔍 Searching in ${conversations.docs.length} conversations...');
        
        // Find conversation that includes the other user (or their offline placeholder)
        for (var convDoc in conversations.docs) {
          final participants = List<String>.from(convDoc.data()['participants'] ?? []);
          print('🔍 Checking conversation ${convDoc.id} with participants: $participants');
          
          // Check if this conversation involves the other user (both original and normalized)
          final hasOtherUser = participants.any((p) {
            // Direct match with original ID
            if (p == otherUserId) {
              print('✅ Direct match found: $p == $otherUserId');
              return true;
            }
            
            // Direct match with normalized ID
            if (p == normalizedOtherUserId) {
              print('✅ Normalized match found: $p == $normalizedOtherUserId');
              return true;
            }
            
            // Check if offline placeholder matches
            if (p.startsWith('offline_')) {
              final offlineId = p.replaceAll('offline_', '');
              if (otherUserId.contains(offlineId) || offlineId.contains(otherUserId) ||
                  normalizedOtherUserId.contains(offlineId) || offlineId.contains(normalizedOtherUserId)) {
                print('✅ Offline placeholder match: $p matches');
                return true;
              }
            }
            if (otherUserId.startsWith('offline_') || normalizedOtherUserId.startsWith('offline_')) {
              final checkId = otherUserId.startsWith('offline_') ? otherUserId : normalizedOtherUserId;
              final offlineId = checkId.replaceAll('offline_', '');
              if (p.contains(offlineId) || offlineId.contains(p)) {
                print('✅ Offline placeholder match (reverse): $p matches');
                return true;
              }
            }
            
            // Check if backend ID matches (extract number from UID if possible)
            final pNum = p.replaceAll(RegExp(r'[^0-9]'), '');
            final otherNum = otherUserId.replaceAll(RegExp(r'[^0-9]'), '');
            final normalizedNum = normalizedOtherUserId.replaceAll(RegExp(r'[^0-9]'), '');
            if (pNum.isNotEmpty && (otherNum.isNotEmpty && pNum == otherNum || 
                                     normalizedNum.isNotEmpty && pNum == normalizedNum)) {
              print('✅ Backend ID match: $p matches');
              return true;
            }
            
            return false;
          });
          
          if (hasOtherUser) {
            actualConversationId = convDoc.id;
            print('✅ Found conversation: $actualConversationId');
            print('✅ Participants: $participants');
            final convData = convDoc.data();
            print('📋 Participant roles: ${convData['participantRoles']}');
            break;
          }
        }
      }
    } catch (e) {
      print('❌ Error searching conversations: $e');
    }
    
    // If no conversation found, try the expected ID (use normalized if available)
    if (actualConversationId == null) {
      actualConversationId = _generateConversationId(currentUser.uid, normalizedOtherUserId);
      print('⚠️ No existing conversation found, using expected ID: $actualConversationId');
      print('⚠️ This conversation may not exist yet or participants do not match');
    }
    
    print('🔍 Querying messages from: $actualConversationId');
    print('🔍 =========================');
    
    // Stream messages from the found conversation
    print('🔍 Setting up stream for conversation: $actualConversationId');
    
    // Query messages with better error handling
    try {
      await for (var snapshot in _firestore
          .collection(_conversationsCollection)
          .doc(actualConversationId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots()) {
        print('📨 Stream update: Loaded ${snapshot.docs.length} messages from $actualConversationId');
        
        if (snapshot.docs.isEmpty) {
          print('⚠️ No messages found in conversation $actualConversationId');
          print('🔍 Checking if conversation exists...');
          
          // Check if conversation document exists
          final convDoc = await _firestore
              .collection(_conversationsCollection)
              .doc(actualConversationId)
              .get();
          
          if (!convDoc.exists) {
            print('❌ Conversation $actualConversationId does not exist!');
            print('🔍 Current User UID: ${currentUser.uid}');
            print('🔍 Other User ID (raw): $otherUserId');
            print('🔍 Other User ID (normalized): $normalizedOtherUserId');
            
            // Try to find ALL conversations to see what exists
            final allConvs = await _firestore
                .collection(_conversationsCollection)
                .where('participants', arrayContains: currentUser.uid)
                .get();
            
            print('📋 All conversations with current user:');
            for (var conv in allConvs.docs) {
              final participants = List<String>.from(conv.data()['participants'] ?? []);
              print('   - ${conv.id}: participants = $participants');
            }
          } else {
            print('✅ Conversation exists but has no messages');
            final convData = convDoc.data();
            print('📋 Conversation participants: ${convData?['participants']}');
            print('📋 Participant roles: ${convData?['participantRoles']}');
            
            // Try to check messages collection directly
            final messagesSnapshot = await _firestore
                .collection(_conversationsCollection)
                .doc(actualConversationId)
                .collection('messages')
                .orderBy('timestamp', descending: true)
                .limit(5)
                .get();
            
            print('📋 Direct query found ${messagesSnapshot.docs.length} messages');
            if (messagesSnapshot.docs.isNotEmpty) {
              print('📋 Sample message IDs: ${messagesSnapshot.docs.map((d) => d.id).toList()}');
              final sampleMsg = messagesSnapshot.docs.first.data();
              print('📋 Sample message data: senderId=${sampleMsg['senderId']}, receiverId=${sampleMsg['receiverId']}');
            }
          }
        } else {
          // Log messages for debugging
          print('📋 Messages breakdown:');
          for (var doc in snapshot.docs.take(3)) {
            final msgData = doc.data();
            print('   - ${doc.id}: senderId=${msgData['senderId']}, receiverId=${msgData['receiverId']}, content="${msgData['content']}"');
          }
          
          // Check if messages are from both sides
          final senderIds = snapshot.docs.map((d) => d.data()['senderId'] as String).toSet();
          print('📋 Unique sender IDs in conversation: $senderIds');
          print('📋 Current user UID: ${currentUser.uid}');
          print('📋 Other user ID (raw): $otherUserId');
          print('📋 Other user ID (normalized): $normalizedOtherUserId');
          
          final hasCurrentUserMessages = senderIds.contains(currentUser.uid);
          final hasOtherUserMessages = senderIds.contains(otherUserId) || 
                                       senderIds.contains(normalizedOtherUserId) ||
                                       senderIds.any((sid) => sid.contains(otherUserId) || otherUserId.contains(sid) ||
                                                             sid.contains(normalizedOtherUserId) || normalizedOtherUserId.contains(sid));
          
          print('📋 Has current user messages: $hasCurrentUserMessages');
          print('📋 Has other user messages: $hasOtherUserMessages');
        }
        
        final messages = snapshot.docs
            .map((doc) {
              try {
                return MessageModel.fromFirestore(doc);
              } catch (e) {
                print('❌ Error parsing message ${doc.id}: $e');
                print('📋 Message data: ${doc.data()}');
                return null; // Return null instead of rethrowing
              }
            })
            .whereType<MessageModel>() // Filter out nulls
            .toList();
        
        yield messages;
      }
    } catch (e) {
      print('❌ Error in message stream: $e');
      print('🔍 Conversation ID: $actualConversationId');
      print('🔍 Current User: ${currentUser.uid}');
      print('🔍 Other User (raw): $otherUserId');
      print('🔍 Other User (normalized): $normalizedOtherUserId');
      
      // Return empty list on error instead of crashing
      yield [];
    }
  }

  // Get conversations for current user
  // ✅ FIX: Query with both real Firebase UID and offline UID (like web)
  Stream<List<ChatConversation>> getConversations() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('⚠️ getConversations: Firebase user is null');
      return Stream.value([]);
    }

    // Get backend user ID for offline UID fallback
    final backendAuthService = BackendAuthService();
    final backendUser = backendAuthService.currentUser;
    final backendUserId = backendUser?.id;
    final offlineUid = backendUserId != null ? 'offline_$backendUserId' : null;
    final realFirebaseUid = currentUser.uid;

    print('✅ getConversations: Querying for user $realFirebaseUid');
    if (offlineUid != null && offlineUid != realFirebaseUid) {
      print('🔍 Also checking for offline UID: $offlineUid');
    }
    
    // Query conversations with real Firebase UID (main query)
    return _firestore
        .collection(_conversationsCollection)
        .where('participants', arrayContains: realFirebaseUid)
        .snapshots()
        .handleError((error) {
          print('❌ getConversations error: $error');
          return Stream.value(<QuerySnapshot>[]); // Return empty on error
        })
        .asyncMap((mainSnapshot) async {
          // If offline UID exists and is different, also query for it
          if (offlineUid != null && offlineUid != realFirebaseUid) {
            try {
              final offlineSnapshot = await _firestore
                  .collection(_conversationsCollection)
                  .where('participants', arrayContains: offlineUid)
                  .get();
              
              // Combine and deduplicate conversations
              final allDocs = <String, DocumentSnapshot>{};
              for (var doc in mainSnapshot.docs) {
                allDocs[doc.id] = doc;
              }
              for (var doc in offlineSnapshot.docs) {
                allDocs[doc.id] = doc; // Will overwrite if duplicate, which is fine
              }
              
              print('📊 getConversations: Found ${allDocs.length} unique conversations (${mainSnapshot.docs.length} from main, ${offlineSnapshot.docs.length} from offline)');
              
              final conversations = allDocs.values
                  .map((doc) {
                    try {
                      return ChatConversation.fromFirestore(doc);
                    } catch (e) {
                      print('⚠️ Error parsing conversation ${doc.id}: $e');
                      print('📋 Conversation data: ${doc.data()}');
                      return null;
                    }
                  })
                  .whereType<ChatConversation>()
                  .toList();
              
              // Sort by lastActivity on client-side
              conversations.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
              
              return conversations;
            } catch (e) {
              print('⚠️ Error querying offline conversations: $e');
              // Fall through to main query only
            }
          }
          
          // Main query only (or fallback if offline query failed)
          print('📊 getConversations: Found ${mainSnapshot.docs.length} conversations');
          final conversations = mainSnapshot.docs
              .map((doc) {
                try {
                  return ChatConversation.fromFirestore(doc);
                } catch (e) {
                  print('⚠️ Error parsing conversation ${doc.id}: $e');
                  print('📋 Conversation data: ${doc.data()}');
                  return null;
                }
              })
              .whereType<ChatConversation>()
              .toList();
          
          // Sort by lastActivity on client-side
          conversations.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
          
          return conversations;
        });
  }

  // ✅ NEW: Get total unread messages count across all conversations
  Stream<int> getTotalUnreadCount() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection(_conversationsCollection)
        .where('participants', arrayContains: currentUser.uid)
        .snapshots()
        .map((snapshot) {
      int totalUnread = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final unreadCount = data['unreadCount'] as Map<String, dynamic>?;
        if (unreadCount != null && unreadCount.containsKey(currentUser.uid)) {
          totalUnread += (unreadCount[currentUser.uid] as num?)?.toInt() ?? 0;
        }
      }
      print('📊 Total unread messages: $totalUnread');
      return totalUnread;
    });
  }

  // Mark message as read
  Future<void> markMessageAsRead(String messageId) async {
    await _firestore
        .collection(_messagesCollection)
        .doc(messageId)
        .update({'isRead': true});
  }

  // Mark all messages in conversation as read
  Future<void> markConversationAsRead(String conversationId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .update({
      'readStatus.${currentUser.uid}': true,
      'unreadCount.${currentUser.uid}': 0,
    });
  }

  // ✅ NEW: Mark conversation as read by other user ID
  Future<void> markConversationAsReadByUserId(String otherUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final conversationId = _generateConversationId(currentUser.uid, otherUserId);
    await markConversationAsRead(conversationId);
  }

  // Get or create conversation between two users
  Future<ChatConversation> getOrCreateConversation({
    required String otherUserId,
    required String otherUserName,
    required String otherUserEmail,
    required String otherUserRole,
  }) async {
    final currentUser = await _ensureFirebaseAuth();

    // Try to find existing conversation
    final existingConversation = await _firestore
        .collection(_conversationsCollection)
        .where('participants', arrayContains: currentUser.uid)
        .get();

    for (final doc in existingConversation.docs) {
      final conversation = ChatConversation.fromFirestore(doc);
      if (conversation.participants.contains(otherUserId) &&
          conversation.participants.contains(currentUser.uid)) {
        return conversation;
      }
    }

    // ✅ FIX: Lấy tên từ Firestore user profile thay vì Firebase Auth displayName
    String currentUserName = currentUser.displayName ?? 'Unknown User';
    String currentUserEmail = currentUser.email ?? '';
    
    try {
      final userProfile = await _firestore.collection('users').doc(currentUser.uid).get();
      if (userProfile.exists) {
        final data = userProfile.data();
        currentUserName = data?['display_name'] ?? data?['displayName'] ?? currentUserName;
        currentUserEmail = data?['email'] ?? currentUserEmail;
        print('✅ Got current user name from Firestore: $currentUserName');
      } else {
        print('⚠️ User profile not found in Firestore for ${currentUser.uid}');
      }
    } catch (e) {
      print('⚠️ Error getting user profile from Firestore: $e');
      // Fallback to Firebase Auth displayName
    }

    // Create new conversation
    final conversationId = _firestore.collection(_conversationsCollection).doc().id;
    final conversation = ChatConversation(
      id: conversationId,
      participants: [currentUser.uid, otherUserId],
      participantNames: {
        currentUser.uid: currentUserName, // ✅ FIX: Dùng tên từ Firestore
        otherUserId: otherUserName,
      },
      participantEmails: {
        currentUser.uid: currentUserEmail, // ✅ FIX: Dùng email từ Firestore
        otherUserId: otherUserEmail,
      },
      participantRoles: {
        currentUser.uid: _getUserRole(),
        otherUserId: otherUserRole,
      },
      lastActivity: DateTime.now(),
      readStatus: {
        currentUser.uid: true,
        otherUserId: false,
      },
      unreadCount: {
        currentUser.uid: 0,
        otherUserId: 0,
      },
    );

    await _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .set(conversation.toFirestore());

    return conversation;
  }

  // Update conversation with latest message
  Future<void> _updateConversation(MessageModel message) async {
    final conversationId = _generateConversationId(message.senderId, message.receiverId);
    
    // ✅ FIX: Fetch participant names from Firestore if missing
    String senderName = message.senderName;
    String receiverName = message.receiverName;
    
    // Fetch sender name from Firestore if empty or "Unknown"
    if (senderName.isEmpty || senderName == 'Unknown') {
      try {
        final senderDoc = await _firestore.collection('users').doc(message.senderId).get();
        if (senderDoc.exists) {
          final data = senderDoc.data();
          senderName = data?['display_name'] ?? 
                      data?['displayName'] ?? 
                      data?['ho_ten'] ??
                      data?['full_name'] ??
                      senderName;
        }
      } catch (e) {
        print('⚠️ Error fetching sender name: $e');
      }
    }
    
    // Fetch receiver name from Firestore if empty or "Unknown"
    if (receiverName.isEmpty || receiverName == 'Unknown') {
      try {
        final receiverDoc = await _firestore.collection('users').doc(message.receiverId).get();
        if (receiverDoc.exists) {
          final data = receiverDoc.data();
          receiverName = data?['display_name'] ?? 
                         data?['displayName'] ?? 
                         data?['ho_ten'] ??
                         data?['full_name'] ??
                         receiverName;
        }
      } catch (e) {
        print('⚠️ Error fetching receiver name: $e');
      }
    }
    
    // ✅ FIX: Update receiver's unread count using dot notation to avoid resetting sender's count
    await _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .set({
      'participants': [message.senderId, message.receiverId],
      'participantNames': {
        message.senderId: senderName,
        message.receiverId: receiverName,
      },
      'participantEmails': {
        message.senderId: message.senderEmail,
        message.receiverId: message.receiverEmail,
      },
      'participantRoles': {
        message.senderId: message.senderRole,
        message.receiverId: message.receiverRole,
      },
      'lastMessage': message.toFirestore(),
      'lastActivity': Timestamp.fromDate(message.timestamp),
      'isActive': true,
      'unreadCount.${message.receiverId}': FieldValue.increment(1), // ✅ Only update receiver
      'readStatus.${message.senderId}': true,
      'readStatus.${message.receiverId}': false,
    }, SetOptions(merge: true));
  }

  // Generate conversation ID from two user IDs
  String _generateConversationId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  // Get user role from BackendAuthService
  String _getUserRole() {
    try {
      final backendAuthService = BackendAuthService();
      final userRoleModel = backendAuthService.currentUserRole;
      
      if (userRoleModel != null) {
        // Use switch to get role value directly
        String roleValue;
        switch (userRoleModel.role) {
          case UserRole.user:
            roleValue = 'user';
            break;
          case UserRole.hotelManager:
            roleValue = 'hotel_manager';
            break;
          case UserRole.admin:
            roleValue = 'admin';
            break;
        }
        print('🎭 Current user role: $roleValue');
        return roleValue;
      }
      
      // Fallback: check from user data in shared preferences
      // (synchronous check, async will be handled by backend)
      print('⚠️ No role found in BackendAuthService, defaulting to "user"');
      return 'user';
    } catch (e) {
      print('❌ Error getting user role: $e');
      return 'user';
    }
  }

  // ✅ DELETE: Delete a single message
  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {
    try {
      // Delete the message document
      await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .delete();

      print('✅ Message deleted: $messageId');

      // Update conversation's lastMessage if needed
      await _updateLastMessageAfterDelete(conversationId);
    } catch (e) {
      print('❌ Error deleting message: $e');
      rethrow;
    }
  }

  // ✅ DELETE: Delete entire conversation
  Future<void> deleteConversation(String conversationId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Get all messages in the conversation
      final messagesSnapshot = await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .collection('messages')
          .get();

      // Delete all messages
      for (var doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the conversation document
      await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .delete();

      print('✅ Conversation deleted: $conversationId');
    } catch (e) {
      print('❌ Error deleting conversation: $e');
      rethrow;
    }
  }

  // ✅ DELETE: Delete conversation by other user ID
  Future<void> deleteConversationByUserId(String otherUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final conversationId = _generateConversationId(currentUser.uid, otherUserId);
    await deleteConversation(conversationId);
  }

  // Helper: Update lastMessage after deleting a message
  Future<void> _updateLastMessageAfterDelete(String conversationId) async {
    try {
      // Get the most recent message
      final messagesSnapshot = await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (messagesSnapshot.docs.isEmpty) {
        // No messages left - update conversation with null lastMessage
        await _firestore
            .collection(_conversationsCollection)
            .doc(conversationId)
            .update({
          'lastMessage': null,
          'lastActivity': FieldValue.serverTimestamp(),
        });
      } else {
        // Update with the new last message
        MessageModel? lastMessage;
        try {
          lastMessage = MessageModel.fromFirestore(messagesSnapshot.docs.first);
        } catch (e) {
          print('⚠️ Error parsing lastMessage: $e');
          // Try to find first valid message
          for (var doc in messagesSnapshot.docs) {
            try {
              lastMessage = MessageModel.fromFirestore(doc);
              break;
            } catch (e2) {
              continue; // Try next message
            }
          }
        }
        
        // ✅ FIX: Only update if we have a valid lastMessage
        if (lastMessage != null) {
          await _firestore
              .collection(_conversationsCollection)
              .doc(conversationId)
              .update({
            'lastMessage': lastMessage.toFirestore(),
            'lastActivity': Timestamp.fromDate(lastMessage.timestamp),
          });
        } else {
          // No valid messages found, just update lastActivity
          await _firestore
              .collection(_conversationsCollection)
              .doc(conversationId)
              .update({
            'lastActivity': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      print('⚠️ Error updating lastMessage: $e');
      // Non-critical error
    }
  }

  // Set user role in Firestore
  Future<void> setUserRole(String userId, String role) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .set({
      'role': role,
      'lastUpdated': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  // Get user role from Firestore
  Future<String> getUserRole(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data()?['role'] ?? 'user';
  }


  // Search messages
  Stream<List<MessageModel>> searchMessages(String query) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_messagesCollection)
        .where('senderId', isEqualTo: currentUser.uid)
        .where('content', isGreaterThanOrEqualTo: query)
        .where('content', isLessThanOrEqualTo: query + '\uf8ff')
        .orderBy('content')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return MessageModel.fromFirestore(doc);
            } catch (e) {
              print('❌ Error parsing message ${doc.id} in searchMessages: $e');
              return null;
            }
          })
          .whereType<MessageModel>()
          .toList();
    });
  }

  // Get unread message count for current user
  Stream<int> getUnreadCount() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection(_conversationsCollection)
        .where('participants', arrayContains: currentUser.uid)
        .snapshots()
        .map((snapshot) {
      int totalUnread = 0;
      for (final doc in snapshot.docs) {
        final conversation = ChatConversation.fromFirestore(doc);
        totalUnread += conversation.getUnreadCount(currentUser.uid);
      }
      return totalUnread;
    });
  }

  // Get available users to chat with (for admin/hotel manager)
  Future<List<Map<String, dynamic>>> getAvailableUsers({
    String? userRole,
    String? searchQuery,
  }) async {
    Query query = _firestore.collection('users');

    if (userRole != null) {
      query = query.where('role', isEqualTo: userRole);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.where('name', isGreaterThanOrEqualTo: searchQuery)
          .where('name', isLessThanOrEqualTo: searchQuery + '\uf8ff');
    }

    final snapshot = await query.limit(50).get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        'name': data['name'] ?? 'Unknown User',
        'email': data['email'] ?? '',
        'role': data['role'] ?? 'user',
        'avatar': data['avatar'],
        'isOnline': data['isOnline'] ?? false,
      };
    }).toList();
  }

  /// Lookup Firebase UID from user email
  Future<String?> _getFirebaseUidFromEmail(String email) async {
    try {
      // Query users collection by email
      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id; // Document ID is the Firebase UID
      }
      return null;
    } catch (e) {
      print('❌ Error looking up Firebase UID from email: $e');
      return null;
    }
  }

  /// Create conversation with customer (for hotel manager)
  Future<void> createConversationWithCustomer({
    required String customerEmail,
    required String customerName,
    required String bookingCode,
  }) async {
    final currentUser = await _ensureFirebaseAuth();

    try {
      // Lookup Firebase UID for customer from email
      final firebaseUid = await _getFirebaseUidFromEmail(customerEmail);
      if (firebaseUid == null) {
        print('⚠️ Customer not found in Firebase. Email: $customerEmail');
        throw Exception('Khách hàng chưa có trên hệ thống chat');
      }

      // Send automated welcome message from hotel manager
      final welcomeMessage = '''
Xin chào $customerName!

Cảm ơn bạn đã đặt phòng với chúng tôi.

Mã đặt phòng: $bookingCode

Nếu bạn có bất kỳ câu hỏi nào, đừng ngần ngại liên hệ với chúng tôi.
''';

      await sendMessage(
        receiverId: firebaseUid, // Use Firebase UID of customer
        receiverName: customerName,
        receiverEmail: customerEmail,
        receiverRole: 'user',
        content: welcomeMessage,
        type: MessageType.text,
        metadata: {
          'booking_code': bookingCode,
          'auto_generated': true,
          'from_hotel_manager': true,
        },
      );
    } catch (e) {
      print('❌ Error creating conversation with customer: $e');
      rethrow;
    }
  }
}