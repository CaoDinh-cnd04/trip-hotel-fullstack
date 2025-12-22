// Modern Conversation List Screen - Redesigned
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/user.dart' as backend_user;
import '../../../data/services/message_service.dart';
import '../../../data/services/backend_auth_service.dart';
import '../../../data/models/user_role_model.dart';
import '../../../data/services/api_service.dart';
import '../../../core/widgets/empty_state_widget.dart';
import 'modern_chat_screen.dart';
import 'hotel_manager_new_chat_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class ModernConversationListScreen extends StatefulWidget {
  const ModernConversationListScreen({super.key});

  @override
  State<ModernConversationListScreen> createState() => _ModernConversationListScreenState();
}

class _ModernConversationListScreenState extends State<ModernConversationListScreen> {
  final MessageService _messageService = MessageService();
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final BackendAuthService _backendAuthService = BackendAuthService();
  
  UserRole? _userRole;
  bool _isLoadingRole = true;

  @override
  void initState() {
    super.initState();
    // Configure timeago to Vietnamese
    timeago.setLocaleMessages('vi', timeago.ViMessages());
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      // Get user role from BackendAuthService (synchronous getter)
      final userRoleModel = _backendAuthService.currentUserRole;
      if (mounted) {
        setState(() {
          _userRole = userRoleModel?.role;
          _isLoadingRole = false;
        });
      }
    } catch (e) {
      print('❌ Error loading user role: $e');
      if (mounted) {
        setState(() => _isLoadingRole = false);
      }
    }
  }

  bool get _canCreateNewChat {
    return _userRole == UserRole.hotelManager || _userRole == UserRole.admin;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Tin nhắn',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          // Debug button to check Firebase status
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Debug Info',
            onPressed: _showDebugInfo,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      floatingActionButton: _canCreateNewChat
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HotelManagerNewChatScreen(),
                  ),
                );
              },
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: StreamBuilder<List<ChatConversation>>(
        stream: _messageService.getConversations(),
        builder: (context, snapshot) {
          // Debug logging
          final currentUser = _auth.currentUser;
          print('🔍 === CONVERSATION LIST DEBUG ===');
          print('🔍 Current Firebase User: ${currentUser?.uid ?? "NOT LOGGED IN"}');
          print('🔍 User Email: ${currentUser?.email ?? "N/A"}');
          print('🔍 Connection State: ${snapshot.connectionState}');
          print('🔍 Has Error: ${snapshot.hasError}');
          if (snapshot.hasError) {
            print('🔍 Error: ${snapshot.error}');
          }
          print('🔍 Conversations Count: ${snapshot.data?.length ?? 0}');
          if (snapshot.data != null && snapshot.data!.isNotEmpty) {
            for (var conv in snapshot.data!) {
              print('🔍 Conversation: ${conv.id} - Participants: ${conv.participants}');
            }
          }
          print('🔍 ================================');

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: conversations.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 88),
            itemBuilder: (context, index) {
              return _buildConversationTile(conversations[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildConversationTile(ChatConversation conversation) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    final otherUserId = conversation.getOtherParticipant(currentUser.uid);
    // ✅ FIX: Lấy tên từ participantNames hoặc metadata (giống web)
    String otherUserName = conversation.getOtherParticipantName(currentUser.uid);
    if (otherUserName == 'Unknown' || otherUserName.isEmpty) {
      // Fallback to metadata (like web does)
      otherUserName = conversation.customerNameFromMetadata ?? 'Khách hàng';
    }
    final otherUserRole = conversation.getOtherParticipantRole(currentUser.uid);
    final unreadCount = conversation.getUnreadCount(currentUser.uid);
    final lastMessage = conversation.lastMessage;
    final bookingInfo = conversation.bookingInfo; // ✅ NEW: Get booking info
    
    // ✅ FIX: Luôn fetch nếu tên là "Unknown" hoặc empty (bất kể role)
    // Vì có thể role đã đúng nhưng tên chưa được load từ Firestore
    if (otherUserName == 'Unknown' || otherUserName.isEmpty || otherUserName == 'Khách hàng') {
      print('🔍 Triggering fetch for participant: $otherUserId (current name: "$otherUserName", role: "$otherUserRole")');
      _fetchAndUpdateParticipantInfo(conversation.id, otherUserId, currentUser.uid);
    } else if (otherUserRole.isEmpty || otherUserRole == 'user') {
      // Nếu tên đã có nhưng role không đúng, vẫn fetch để update role
      print('🔍 Triggering fetch for role update: $otherUserId (name: "$otherUserName", role: "$otherUserRole")');
      _fetchAndUpdateParticipantInfo(conversation.id, otherUserId, currentUser.uid);
    }

    return Dismissible(
      key: Key(conversation.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text(
              'Xóa',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xóa cuộc trò chuyện?'),
            content: Text(
              'Bạn có chắc muốn xóa cuộc trò chuyện với $otherUserName?\n\n'
              'Tất cả tin nhắn sẽ bị xóa vĩnh viễn.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Xóa'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        try {
          await _messageService.deleteConversation(conversation.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('✅ Đã xóa cuộc trò chuyện với $otherUserName')),
            );
          }
        } catch (e) {
          print('❌ Error deleting conversation: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi: ${e.toString()}')),
            );
          }
        }
      },
      child: InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ModernChatScreen(
              conversationId: conversation.id, // ✅ Pass conversation ID directly
              otherUserId: otherUserId,
              otherUserName: otherUserName,
              otherUserEmail: conversation.participantEmails[otherUserId] ?? '',
              otherUserRole: otherUserRole,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: unreadCount > 0 ? Colors.blue.withOpacity(0.02) : Colors.white,
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: _getRoleColor(otherUserRole).withOpacity(0.1),
                  child: Text(
                    otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: _getRoleColor(otherUserRole),
                    ),
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          otherUserName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        lastMessage != null
                            ? timeago.format(lastMessage.timestamp, locale: 'vi')
                            : '',
                        style: TextStyle(
                          fontSize: 12,
                          color: unreadCount > 0 ? Colors.blue[600] : Colors.grey[600],
                          fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Role badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getRoleColor(otherUserRole).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getRoleDisplayName(otherUserRole),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getRoleColor(otherUserRole),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          lastMessage?.content ?? 'Bắt đầu cuộc trò chuyện',
                          style: TextStyle(
                            fontSize: 14,
                            color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                            fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  // ✅ NEW: Show booking info if available (like web)
                  if (bookingInfo != null && bookingInfo!['room_name'] != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.bed, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            bookingInfo!['room_name'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      ), // Close Dismissible
    );
  }

  Widget _buildEmptyState() {
    return EmptyMessagesWidget();
  }

  Widget _buildErrorState(String error) {
    // Check if Firebase auth issue
    final isAuthError = _auth.currentUser == null;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isAuthError ? Icons.account_circle : Icons.error_outline,
            size: 80,
            color: isAuthError ? Colors.orange[300] : Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            isAuthError ? 'Chưa đăng nhập Firebase' : 'Không thể tải tin nhắn',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isAuthError ? Colors.orange[700] : Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              isAuthError 
                ? 'Vui lòng đăng xuất và đăng nhập lại để sử dụng chức năng chat'
                : 'Vui lòng kiểm tra kết nối mạng và thử lại\n\nLỗi: $error',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isAuthError ? Colors.orange : Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'hotel_manager':
      case 'hotelmanager':
      case 'manager':
        return Colors.orange;
      case 'admin':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  String _getRoleDisplayName(String role) {
    print('🎭 Role value: "$role" (lowercase: "${role.toLowerCase()}")'); // Debug
    switch (role.toLowerCase()) {
      case 'hotel_manager':
      case 'hotelmanager':
      case 'manager':
        return 'Quản lý KS';
      case 'admin':
        return 'Quản trị viên';
      default:
        return 'Khách hàng'; // Default: $role
    }
  }

  // Debug function to check Firebase and Firestore status
  Future<void> _showDebugInfo() async {
    final currentUser = _auth.currentUser;
    final backendUser = _backendAuthService.currentUser;
    final backendRole = _backendAuthService.currentUserRole;

    String debugInfo = '';
    
    // Firebase Auth Status
    debugInfo += '🔥 FIREBASE AUTH:\n';
    if (currentUser != null) {
      debugInfo += '✅ Logged In\n';
      debugInfo += '  UID: ${currentUser.uid}\n';
      debugInfo += '  Email: ${currentUser.email}\n';
      debugInfo += '  Name: ${currentUser.displayName}\n';
    } else {
      debugInfo += '❌ NOT Logged In\n';
    }
    
    debugInfo += '\n📱 BACKEND AUTH:\n';
    if (backendUser != null) {
      debugInfo += '✅ Backend Session Active\n';
      debugInfo += '  ID: ${backendUser.id}\n';
      debugInfo += '  Email: ${backendUser.email}\n';
      debugInfo += '  Name: ${backendUser.hoTen}\n';
    } else {
      debugInfo += '❌ No Backend Session\n';
    }
    
    if (backendRole != null) {
      debugInfo += '\n🎭 USER ROLE:\n';
      debugInfo += '  Role: ${backendRole.role.value}\n';
      debugInfo += '  Is Admin: ${backendRole.isAdmin}\n';
      debugInfo += '  Is Hotel Manager: ${backendRole.role == UserRole.hotelManager}\n';
    }
    
    // Check Firestore user profile
    if (currentUser != null) {
      debugInfo += '\n💾 FIRESTORE PROFILE:\n';
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        if (userDoc.exists) {
          final data = userDoc.data();
          debugInfo += '✅ Profile Exists\n';
          debugInfo += '  Role: ${data?['role']}\n';
          debugInfo += '  Backend ID: ${data?['backend_user_id']}\n';
          debugInfo += '  Hotel ID: ${data?['hotel_id']}\n';
        } else {
          debugInfo += '❌ No Profile in Firestore\n';
          debugInfo += '⚠️ Need to logout and login again!\n';
        }
      } catch (e) {
        debugInfo += '❌ Error: $e\n';
      }
      
      // Check conversations
      debugInfo += '\n💬 CONVERSATIONS:\n';
      try {
        final convSnapshot = await FirebaseFirestore.instance
            .collection('conversations')
            .where('participants', arrayContains: currentUser.uid)
            .get();
        
        debugInfo += 'Count: ${convSnapshot.docs.length}\n';
        for (var doc in convSnapshot.docs) {
          final data = doc.data();
          debugInfo += '\nConv ID: ${doc.id}\n';
          debugInfo += '  Participants: ${data['participants']}\n';
          if (data['metadata'] != null) {
            debugInfo += '  Hotel: ${data['metadata']['hotel_name']}\n';
          }
        }
      } catch (e) {
        debugInfo += '❌ Error: $e\n';
      }
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.bug_report, color: Colors.orange),
            SizedBox(width: 8),
            Text('Debug Info'),
          ],
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            debugInfo,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ),
        actions: [
          if (currentUser == null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showReloginDialog();
              },
              child: const Text('Đăng xuất & Đăng nhập lại'),
            ),
          // ✅ NEW: Button to force sync Firestore profile
          if (currentUser != null && backendUser != null && backendRole != null)
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _forceSyncFirestoreProfile(currentUser, backendUser, backendRole);
              },
              icon: const Icon(Icons.sync, size: 18),
              label: const Text('Đồng bộ Firestore'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          // ✅ NEW: Button to fix conversation roles
          if (currentUser != null && backendUser != null && backendRole != null)
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _fixConversationRoles();
              },
              icon: const Icon(Icons.build, size: 18),
              label: const Text('Fix Roles'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          // ✅ NEW: Button to fix offline conversations
          if (currentUser != null && backendUser != null && backendRole != null)
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _fixOfflineConversations(currentUser, backendUser);
              },
              icon: const Icon(Icons.autorenew, size: 18),
              label: const Text('Fix Offline'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showReloginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cần đăng nhập lại'),
        content: const Text(
          'Để sử dụng tính năng chat, bạn cần đăng xuất và đăng nhập lại để đồng bộ Firebase.\n\n'
          'Điều này sẽ:\n'
          '• Đăng xuất khỏi tài khoản hiện tại\n'
          '• Cho phép bạn đăng nhập lại\n'
          '• Đồng bộ dữ liệu với Firebase cho chat',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Logout
              await _backendAuthService.signOut();
              // Navigate to login
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đăng xuất ngay'),
          ),
        ],
      ),
    );
  }

  /// Force sync Firestore profile (for hotel managers with missing profile)
  Future<void> _forceSyncFirestoreProfile(
    firebase_auth.User firebaseUser,
    backend_user.User backendUser,
    UserRoleModel backendRole,
  ) async {
    try {
      print('🔄 Force syncing Firestore profile...');
      
      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang đồng bộ Firestore...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Create/update user profile in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .set({
        'email': backendUser.email?.toLowerCase() ?? '',
        'display_name': backendUser.hoTen ?? '',
        'photo_url': backendUser.anhDaiDien,
        'role': backendRole.role.value, // ✅ Use .value for correct format
        'backend_user_id': backendUser.id,
        'is_active': backendRole.isActive,
        'hotel_id': backendRole.hotelId,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Firestore profile synced successfully!');
      
      // Close loading dialog
      if (!mounted) return;
      Navigator.pop(context);
      
      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Thành công!'),
            ],
          ),
          content: const Text(
            'Đã đồng bộ Firestore profile.\n\n'
            'Bạn có thể thấy tin nhắn từ khách hàng ngay bây giờ!',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Refresh the conversation list
                setState(() {});
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      
    } catch (e) {
      print('❌ Error syncing Firestore profile: $e');
      
      // Close loading dialog if open
      if (mounted) Navigator.pop(context);
      
      // Show error dialog
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Lỗi'),
            ],
          ),
          content: Text(
            'Không thể đồng bộ Firestore profile:\n\n$e',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    }
  }

  /// Fix role in all conversations
  Future<void> _fixConversationRoles() async {
    final currentUser = _auth.currentUser;
    final backendUser = _backendAuthService.currentUser;
    final backendRole = _backendAuthService.currentUserRole;

    if (currentUser == null || backendUser == null || backendRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập đầy đủ!')),
      );
      return;
    }

    try {
      // Get all conversations where current user is a participant
      final conversationsSnapshot = await FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', arrayContains: currentUser.uid)
          .get();

      int updated = 0;
      for (var doc in conversationsSnapshot.docs) {
        // Update participantRoles for current user
        await doc.reference.update({
          'participantRoles.${currentUser.uid}': backendRole.role.value,
          'participantNames.${currentUser.uid}': backendUser.hoTen ?? 'Unknown',
        });
        updated++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Đã cập nhật $updated conversations')),
        );
        setState(() {}); // Refresh UI
      }
    } catch (e) {
      print('❌ Error fixing roles: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  /// Fix offline conversations by replacing offline_ID with real Firebase UID
  Future<void> _fixOfflineConversations(
    firebase_auth.User firebaseUser,
    backend_user.User backendUser,
  ) async {
    try {
      print('🔧 Fixing offline conversations for user ${backendUser.id}...');
      
      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang fix offline conversations...'),
                ],
              ),
            ),
          ),
        ),
      );

      final offlinePlaceholder = 'offline_${backendUser.id}';
      final realFirebaseUid = firebaseUser.uid;
      
      // Query conversations with offline placeholder
      final conversationsSnapshot = await FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', arrayContains: offlinePlaceholder)
          .get();
      
      if (conversationsSnapshot.docs.isEmpty) {
        print('✅ No offline conversations to fix');
        
        // Close loading dialog
        if (!mounted) return;
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Không có conversation nào cần fix')),
        );
        return;
      }
      
      print('🔍 Found ${conversationsSnapshot.docs.length} offline conversations to fix');
      
      int fixed = 0;
      for (var doc in conversationsSnapshot.docs) {
        try {
          final data = doc.data();
          final participants = List<String>.from(data['participants'] ?? []);
          final participantRoles = Map<String, dynamic>.from(data['participantRoles'] ?? {});
          final participantNames = Map<String, dynamic>.from(data['participantNames'] ?? {});
          final participantEmails = Map<String, dynamic>.from(data['participantEmails'] ?? {});
          
          // Replace offline placeholder with real UID
          final index = participants.indexOf(offlinePlaceholder);
          if (index != -1) {
            participants[index] = realFirebaseUid;
            
            // Update roles, names, emails
            if (participantRoles.containsKey(offlinePlaceholder)) {
              participantRoles[realFirebaseUid] = participantRoles[offlinePlaceholder];
              participantRoles.remove(offlinePlaceholder);
            }
            if (participantNames.containsKey(offlinePlaceholder)) {
              participantNames[realFirebaseUid] = participantNames[offlinePlaceholder];
              participantNames.remove(offlinePlaceholder);
            }
            if (participantEmails.containsKey(offlinePlaceholder)) {
              participantEmails[realFirebaseUid] = participantEmails[offlinePlaceholder];
              participantEmails.remove(offlinePlaceholder);
            }
            
            // Update Firestore
            await doc.reference.update({
              'participants': participants,
              'participantRoles': participantRoles,
              'participantNames': participantNames,
              'participantEmails': participantEmails,
              'updated_at': FieldValue.serverTimestamp(),
            });
            
            fixed++;
            print('✅ Fixed conversation ${doc.id}: $offlinePlaceholder → $realFirebaseUid');
          }
        } catch (e) {
          print('❌ Error fixing conversation ${doc.id}: $e');
          // Continue with other conversations
        }
      }
      
      print('✅ Fixed $fixed offline conversations');
      
      // Close loading dialog
      if (!mounted) return;
      Navigator.pop(context);
      
      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Thành công!'),
            ],
          ),
          content: Text(
            'Đã fix $fixed conversations.\n\n'
            'Bạn có thể thấy tin nhắn từ khách hàng ngay bây giờ!',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Refresh the conversation list
                setState(() {});
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      
    } catch (e) {
      print('❌ Error fixing offline conversations: $e');
      
      // Close loading dialog if open
      if (mounted) Navigator.pop(context);
      
      // Show error dialog
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Lỗi'),
            ],
          ),
          content: Text(
            'Không thể fix offline conversations:\n\n$e',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    }
  }

  /// ✅ FIX: Fetch participant name AND role from Firestore/Backend and update conversation
  Future<void> _fetchAndUpdateParticipantInfo(
    String conversationId,
    String participantId,
    String currentUserId,
  ) async {
    try {
      print('🔍 Fetching participant info for: $participantId');
      String? displayName;
      String? role;
      
      // 1. Try Firestore user profile first
      print('🔍 Step 1: Checking Firestore users collection for: $participantId');
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(participantId)
          .get();
      
      if (userDoc.exists) {
        final data = userDoc.data();
        print('✅ User doc exists. Data keys: ${data?.keys.toList()}');
        
        // Try multiple possible field names
        displayName = data?['display_name'] ?? 
                     data?['displayName'] ?? 
                     data?['ho_ten'] ??
                     data?['full_name'] ??
                     data?['name'] ??
                     '';
        role = data?['role'] ?? 
               data?['user_role'] ??
               data?['vai_tro'] ??
               data?['userRole'] ??
               '';
        
        print('🔍 Extracted: displayName="$displayName", role="$role"');
        
        if (displayName != null && displayName.isNotEmpty) {
          print('✅ Found in Firestore: name=$displayName, role=$role');
        } else {
          print('⚠️ Firestore profile exists but no display name found. Available fields: ${data?.keys.toList()}');
        }
      } else {
        print('⚠️ User profile not found in Firestore users collection: $participantId');
        
        // Try user_mapping collection if we have backend_user_id from somewhere
        print('🔍 Checking user_mapping collection...');
        try {
          final mappingQuery = await FirebaseFirestore.instance
              .collection('user_mapping')
              .where('firebase_uid', isEqualTo: participantId)
              .limit(1)
              .get();
          
          if (mappingQuery.docs.isNotEmpty) {
            final mappingData = mappingQuery.docs.first.data();
            final backendId = mappingData['firebase_uid'];
            print('✅ Found mapping, backend_id: $backendId');
          }
        } catch (e) {
          print('⚠️ Error checking user_mapping: $e');
        }
      }
      
      // 2. If we have backend_user_id, try Backend API
      if ((displayName == null || displayName.isEmpty || role == null || role.isEmpty) && userDoc.exists) {
        final data = userDoc.data();
        final backendUserId = data?['backend_user_id'];
        
        if (backendUserId != null) {
          print('🔍 Fetching from Backend API for backend_user_id: $backendUserId');
          try {
            final apiService = ApiService();
            final response = await apiService.get('/users/$backendUserId');
            
            if (response.success && response.data != null) {
              final userData = response.data as Map<String, dynamic>;
              if (displayName == null || displayName.isEmpty) {
                displayName = userData['ho_ten'] ?? 
                              userData['ten'] ?? 
                              userData['display_name'] ?? 
                              '';
              }
              if (role == null || role.isEmpty) {
                role = userData['role'] ?? 
                       userData['vai_tro'] ??
                       '';
              }
              print('✅ Found in Backend API: name=$displayName, role=$role');
            }
          } catch (e) {
            print('⚠️ Error fetching from Backend API: $e');
          }
        }
      }
      
      // 3. Try conversation metadata as fallback (hotel_name for hotel managers)
      if ((displayName == null || displayName.isEmpty) && conversationId.isNotEmpty) {
        try {
          final convDoc = await FirebaseFirestore.instance
              .collection('conversations')
              .doc(conversationId)
              .get();
          
          if (convDoc.exists) {
            final convData = convDoc.data();
            final metadata = convData?['metadata'];
            if (metadata != null) {
              final hotelName = metadata['hotel_name'];
              if (hotelName != null) {
                displayName = hotelName;
                role = 'hotel_manager'; // Assume hotel manager if from hotel metadata
                print('✅ Using hotel name from metadata: $displayName');
              }
            }
          }
        } catch (e) {
          print('⚠️ Error fetching conversation metadata: $e');
        }
      }
      
      // 4. Update conversation document if we found info
      if (displayName != null && displayName.isNotEmpty) {
        final updates = <String, dynamic>{
          'participantNames.$participantId': displayName,
        };
        
        // Update role if we found a valid one (even if it's already in conversation, update to ensure consistency)
        if (role != null && role.isNotEmpty) {
          updates['participantRoles.$participantId'] = role;
          print('✅ Will update role to: $role');
        } else {
          print('⚠️ No role found, keeping existing role in conversation');
        }
        
        print('📝 Updating conversation $conversationId with: $updates');
        await FirebaseFirestore.instance
            .collection('conversations')
            .doc(conversationId)
            .update(updates);
        
        print('✅ Successfully updated conversation with name="$displayName", role="$role"');
        
        // Refresh UI after a short delay to ensure Firestore update propagates
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {});
              print('✅ UI refreshed');
            }
          });
        }
      } else {
        print('❌ Could not fetch participant info for $participantId');
        print('   - displayName: $displayName');
        print('   - role: $role');
      }
    } catch (e) {
      print('❌ Error fetching participant info: $e');
    }
  }
}

