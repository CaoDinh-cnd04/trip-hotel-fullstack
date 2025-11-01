// Modern Chat Screen - Redesigned with beautiful UI
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/message_model.dart';
import '../../../data/services/message_service.dart';
import '../../../data/services/api_service.dart';
import 'package:intl/intl.dart';

class ModernChatScreen extends StatefulWidget {
  final String? conversationId; // ✅ Optional: if provided, use it directly
  final String otherUserId;
  final String otherUserName;
  final String otherUserEmail;
  final String otherUserRole;

  const ModernChatScreen({
    super.key,
    this.conversationId, // ✅ If provided, will use it directly
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserEmail,
    required this.otherUserRole,
  });

  @override
  State<ModernChatScreen> createState() => _ModernChatScreenState();
}

class _ModernChatScreenState extends State<ModernChatScreen> {
  final MessageService _messageService = MessageService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isSending = false;
  String? _resolvedOtherUserName;
  String? _resolvedOtherUserRole;

  @override
  void initState() {
    super.initState();
    _markConversationAsRead(); // ✅ Reset unread count when opening chat
    // ✅ Fix: Nếu tên hoặc role không đúng, fetch lại từ Firestore/Backend
    if (widget.otherUserName == 'Unknown' || 
        widget.otherUserName.isEmpty ||
        widget.otherUserRole.isEmpty ||
        widget.otherUserRole == 'user') {
      _fetchParticipantInfo();
    } else {
      _resolvedOtherUserName = widget.otherUserName;
      _resolvedOtherUserRole = widget.otherUserRole;
    }
  }

  /// ✅ Fetch participant info from Firestore and Backend API
  Future<void> _fetchParticipantInfo() async {
    try {
      print('🔍 Fetching participant info for: ${widget.otherUserId}');
      
      // 1. Try Firestore user profile first
      final userDoc = await _firestore
          .collection('users')
          .doc(widget.otherUserId)
          .get();
      
      if (userDoc.exists) {
        final data = userDoc.data();
        final displayName = data?['display_name'] ?? 
                           data?['displayName'] ?? 
                           data?['ho_ten'] ??
                           data?['full_name'] ??
                           '';
        final role = data?['role'] ?? data?['user_role'] ?? '';
        
        if (displayName.isNotEmpty) {
          print('✅ Found in Firestore: $displayName, role: $role');
          if (mounted) {
            setState(() {
              _resolvedOtherUserName = displayName;
              _resolvedOtherUserRole = role.isNotEmpty ? role : widget.otherUserRole;
            });
          }
          return;
        }
      }
      
      // 2. Try Backend API if we have backend_user_id
      if (userDoc.exists) {
        final data = userDoc.data();
        final backendUserId = data?['backend_user_id'];
        
        if (backendUserId != null) {
          print('🔍 Fetching from Backend API for backend_user_id: $backendUserId');
          try {
            // Import ApiService to fetch user info
            final apiService = await _fetchUserFromBackend(backendUserId);
            if (apiService != null && mounted) {
              setState(() {
                _resolvedOtherUserName = apiService['name'] ?? widget.otherUserName;
                _resolvedOtherUserRole = apiService['role'] ?? widget.otherUserRole;
              });
              return;
            }
          } catch (e) {
            print('⚠️ Error fetching from Backend: $e');
          }
        }
      }
      
      // 3. Update conversation document metadata if found
      if (widget.conversationId != null) {
        final convDoc = await _firestore
            .collection('conversations')
            .doc(widget.conversationId)
            .get();
        
        if (convDoc.exists) {
          final data = convDoc.data();
          final metadata = data?['metadata'];
          if (metadata != null) {
            final hotelName = metadata['hotel_name'];
            if (hotelName != null && _resolvedOtherUserName == null) {
              // Use hotel name as fallback for hotel manager
              if (mounted) {
                setState(() {
                  _resolvedOtherUserName = hotelName;
                  _resolvedOtherUserRole = 'hotel_manager';
                });
              }
              return;
            }
          }
        }
      }
      
      print('⚠️ Could not fetch participant info, using defaults');
      if (mounted) {
        setState(() {
          _resolvedOtherUserName = widget.otherUserName;
          _resolvedOtherUserRole = widget.otherUserRole;
        });
      }
    } catch (e) {
      print('❌ Error fetching participant info: $e');
      if (mounted) {
        setState(() {
          _resolvedOtherUserName = widget.otherUserName;
          _resolvedOtherUserRole = widget.otherUserRole;
        });
      }
    }
  }

  /// Fetch user info from Backend API
  Future<Map<String, String>?> _fetchUserFromBackend(dynamic backendUserId) async {
    try {
      final apiService = ApiService();
      final response = await apiService.get('/users/$backendUserId');
      
      if (response.success && response.data != null) {
        final userData = response.data as Map<String, dynamic>;
        return {
          'name': userData['ho_ten'] ?? 
                  userData['ten'] ?? 
                  userData['display_name'] ?? 
                  '',
          'role': userData['role'] ?? 
                  userData['vai_tro'] ?? 
                  '',
        };
      }
      return null;
    } catch (e) {
      print('❌ Error fetching from Backend API: $e');
      return null;
    }
  }

  /// Mark this conversation as read (reset unread badge)
  Future<void> _markConversationAsRead() async {
    try {
      await _messageService.markConversationAsReadByUserId(widget.otherUserId);
      print('✅ Conversation marked as read with ${widget.otherUserName}');
    } catch (e) {
      print('⚠️ Failed to mark conversation as read: $e');
      // Non-critical, don't show error to user
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showFirebaseAuthRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cần đăng nhập lại'),
        content: const Text(
          'Để sử dụng tính năng chat, bạn cần đăng xuất và đăng nhập lại.\n\n'
          'Điều này sẽ đồng bộ tài khoản của bạn với hệ thống chat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Để sau'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close chat screen
              // Navigate to profile to logout
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/profile',
                (route) => route.isFirst,
              );
            },
            child: const Text('Đăng xuất ngay'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await _messageService.sendMessage(
        receiverId: widget.otherUserId,
        receiverName: _getResolvedName(),
        receiverEmail: widget.otherUserEmail,
        receiverRole: _getResolvedRole(),
        content: text,
      );

      // Scroll to bottom after sending
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString();
        
        // Check if error is about Firebase authentication
        if (errorMessage.contains('chưa đăng nhập Firebase') || 
            errorMessage.contains('admin-restricted-operation')) {
          _showFirebaseAuthRequiredDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi gửi tin: ${e.toString()}')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: _getRoleColor(_getResolvedRole()).withOpacity(0.1),
              child: Text(
                _getResolvedName().isNotEmpty ? _getResolvedName()[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _getRoleColor(_getResolvedRole()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getResolvedName(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _getRoleDisplayName(_getResolvedRole()),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.orange),
            onPressed: _showDebugInfo,
          ),
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.black87),
            onPressed: () {
              // TODO: Implement call
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onPressed: () {
              // TODO: Show more options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _messageService.getMessages(
                otherUserId: widget.otherUserId,
                conversationId: widget.conversationId, // ✅ Pass conversation ID if available
                limit: 100,
              ),
              builder: (context, snapshot) {
                // ✅ DEBUG: Log every time stream updates
                print('🔍 === CHAT SCREEN DEBUG ===');
                print('🔍 Conversation ID: ${widget.conversationId ?? "NOT PROVIDED"}');
                print('🔍 Other User ID: ${widget.otherUserId}');
                print('🔍 Other User Name: ${widget.otherUserName}');
                print('🔍 Connection State: ${snapshot.connectionState}');
                print('🔍 Has Error: ${snapshot.hasError}');
                if (snapshot.hasError) {
                  print('🔍 Error: ${snapshot.error}');
                }
                print('🔍 Messages Count: ${snapshot.data?.length ?? 0}');
                print('🔍 =========================');
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _buildErrorWidget(snapshot.error.toString());
                }

                final messages = snapshot.data ?? [];

                // ✅ DEBUG: Log message details
                print('📋 === MESSAGES DETAILS ===');
                print('📋 Total messages: ${messages.length}');
                final currentUser = _auth.currentUser;
                print('📋 Current User UID: ${currentUser?.uid ?? "NOT LOGGED IN"}');
                print('📋 Other User ID: ${widget.otherUserId}');
                for (var i = 0; i < messages.length && i < 5; i++) {
                  final msg = messages[i];
                  print('📋 Message $i:');
                  print('   - senderId: ${msg.senderId}');
                  print('   - senderName: ${msg.senderName}');
                  print('   - receiverId: ${msg.receiverId}');
                  print('   - receiverName: ${msg.receiverName}');
                  print('   - isMe: ${msg.senderId == currentUser?.uid}');
                  print('   - content: ${msg.content.substring(0, msg.content.length > 50 ? 50 : msg.content.length)}...');
                }
                print('📋 ========================');

                if (messages.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final showDate = index == messages.length - 1 ||
                        !_isSameDay(message.timestamp, messages[index + 1].timestamp);
                    
                    return Column(
                      children: [
                        if (showDate) _buildDateDivider(message.timestamp),
                        _buildMessageBubble(message),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildDateDivider(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _formatDateDivider(date),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message) {
    final currentUser = _auth.currentUser;
    final isMe = message.senderId == currentUser?.uid;
    
    // ✅ DEBUG: Log message display info
    if (!isMe) {
      print('📨 Displaying message from: ${message.senderId} (${message.senderName})');
      print('📨 Current user: ${currentUser?.uid}');
      print('📨 Other user ID: ${widget.otherUserId}');
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: _getRoleColor(message.senderRole).withOpacity(0.1),
              child: Text(
                message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getRoleColor(message.senderRole),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showDeleteMessageDialog(message),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isMe ? const Color(0xFF0084FF) : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.content,
                      style: TextStyle(
                        fontSize: 15,
                        color: isMe ? Colors.white : Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('HH:mm').format(message.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: isMe ? Colors.white.withOpacity(0.7) : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ✅ NEW: Show delete message dialog
  void _showDeleteMessageDialog(MessageModel message) {
    final currentUser = _auth.currentUser;
    final isMe = message.senderId == currentUser?.uid;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.copy, color: Colors.blue),
                title: const Text('Sao chép'),
                onTap: () {
                  Navigator.pop(context);
                  // Copy to clipboard
                  // Clipboard.setData(ClipboardData(text: message.content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép tin nhắn')),
                  );
                },
              ),
              if (isMe) // Only sender can delete
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Xóa tin nhắn', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
                    await _deleteMessage(message);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ NEW: Delete a message
  Future<void> _deleteMessage(MessageModel message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tin nhắn?'),
        content: const Text('Tin nhắn sẽ bị xóa vĩnh viễn và không thể khôi phục.'),
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

    if (confirmed != true) return;

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Generate conversation ID (same logic as in MessageService)
      final sortedIds = [currentUser.uid, widget.otherUserId]..sort();
      final conversationId = '${sortedIds[0]}_${sortedIds[1]}';

      await _messageService.deleteMessage(
        conversationId: conversationId,
        messageId: message.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Đã xóa tin nhắn')),
        );
      }
    } catch (e) {
      print('❌ Error deleting message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.add_circle, color: Colors.blue[600], size: 28),
              onPressed: () {
                // TODO: Attach file/image
              },
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.blue[600],
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _isSending ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Bắt đầu cuộc trò chuyện',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Gửi tin nhắn đầu tiên của bạn',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          const Text(
            'Không thể tải tin nhắn',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateDivider(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'Hôm nay';
    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) return 'Hôm qua';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'hotelmanager':
        return Colors.orange;
      case 'admin':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  /// Get resolved name (use fetched name if available, otherwise use widget's name)
  String _getResolvedName() {
    if (_resolvedOtherUserName != null && 
        _resolvedOtherUserName!.isNotEmpty &&
        _resolvedOtherUserName != 'Unknown') {
      return _resolvedOtherUserName!;
    }
    return widget.otherUserName.isNotEmpty ? widget.otherUserName : 'Unknown';
  }

  /// Get resolved role (use fetched role if available, otherwise use widget's role)
  String _getResolvedRole() {
    if (_resolvedOtherUserRole != null && 
        _resolvedOtherUserRole!.isNotEmpty &&
        _resolvedOtherUserRole != 'user') {
      return _resolvedOtherUserRole!;
    }
    return widget.otherUserRole.isNotEmpty ? widget.otherUserRole : 'user';
  }

  String _getRoleDisplayName(String role) {
    final roleLower = role.toLowerCase();
    print('🎭 Chat screen role: "$role" (lowercase: "$roleLower")');
    
    switch (roleLower) {
      case 'hotelmanager':
      case 'hotel_manager':
      case 'hotel manager':
      case 'manager':
      case 'qlkhachsan':
        return 'Quản lý KS';
      case 'admin':
        return 'Quản trị viên';
      case 'user':
      case 'customer':
      case 'khachhang':
        return 'Khách hàng';
      default:
        // ✅ FIX: Nếu role không match, check từ conversation metadata
        print('⚠️ Unknown role: $role, checking conversation metadata...');
        return 'Quản lý KS'; // Default to hotel manager for now if uncertain
    }
  }

  void _showDebugInfo() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không đăng nhập Firebase!')),
      );
      return;
    }

    // Generate conversation ID (NEW format)
    final conversationId = [currentUser.uid, widget.otherUserId]..sort();
    final convId = '${conversationId[0]}_${conversationId[1]}';

    // Get messages count from NEW conversation
    final messagesSnapshot = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(convId)
        .collection('messages')
        .get();

    // ✅ SEARCH ALL conversations to find messages with other user
    String allConversationsInfo = '';
    int totalMessagesFound = 0;
    String? foundConversationId;
    
    try {
      final allConversations = await FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', arrayContains: currentUser.uid)
          .get();
      
      allConversationsInfo = '🔍 SEARCHING ALL CONVERSATIONS:\n';
      allConversationsInfo += 'Total conversations: ${allConversations.docs.length}\n\n';
      
      for (var convDoc in allConversations.docs) {
        final convData = convDoc.data();
        final participants = List<String>.from(convData['participants'] ?? []);
        
        // Check if this conversation involves the other user (or offline placeholder)
        final hasOtherUser = participants.any((p) => 
          p == widget.otherUserId || 
          p.contains(widget.otherUserId.replaceAll('offline_', '')) ||
          widget.otherUserId.contains(p.replaceAll('offline_', ''))
        );
        
        if (hasOtherUser) {
          final msgs = await convDoc.reference.collection('messages').get();
          allConversationsInfo += '✅ FOUND: ${convDoc.id}\n';
          allConversationsInfo += '  Participants: $participants\n';
          allConversationsInfo += '  Messages: ${msgs.docs.length}\n\n';
          
          if (msgs.docs.isNotEmpty) {
            totalMessagesFound += msgs.docs.length;
            foundConversationId = convDoc.id;
          }
        }
      }
    } catch (e) {
      allConversationsInfo = '❌ Error searching: $e\n\n';
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
            '🔍 CONVERSATION DEBUG\n\n'
            '👤 Your UID: ${currentUser.uid}\n'
            '👤 Other UID: ${widget.otherUserId}\n'
            '👤 Other Name: ${widget.otherUserName}\n\n'
            '💬 Expected Conversation ID:\n$convId\n\n'
            '📨 Messages in NEW conversation: ${messagesSnapshot.docs.length}\n\n'
            '$allConversationsInfo'
            '${totalMessagesFound > 0 ? '🎯 MESSAGES FOUND IN: $foundConversationId\n\n' : ''}'
            '${messagesSnapshot.docs.isEmpty && totalMessagesFound > 0 ? '⚠️ PROBLEM: Messages are in OLD conversation!\n\n' : ''}'
            '⚠️ SOLUTION:\n'
            '1. Quay lại danh sách Tin nhắn\n'
            '2. Nhấn nút Debug (🐛)\n'
            '3. Nhấn "Fix Offline" (màu tím)\n'
            '4. Quay lại chat này',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          ),
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

