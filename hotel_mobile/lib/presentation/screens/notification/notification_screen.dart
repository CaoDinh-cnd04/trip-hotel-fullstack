import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/models/notification.dart';
import 'package:hotel_mobile/data/services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      print('🔄 Loading notifications...');
      final response = await _notificationService.getNotifications();
      
      print('📥 Response received: success=${response.success}, data length=${response.data?.length ?? 0}');
      
      if (response.success) {
        final notifications = response.data ?? [];
        print('✅ Loaded ${notifications.length} notifications');
        
        if (notifications.isEmpty) {
          print('⚠️ No notifications in response, but API call was successful');
          print('⚠️ This might mean:');
          print('   1. User has no notifications');
          print('   2. All notifications are filtered out (visible=false, expired, etc.)');
          print('   3. Parsing failed silently');
        } else {
          print('📋 Notification titles: ${notifications.map((n) => n.title).toList()}');
        }
        
        setState(() {
          _notifications = notifications;
          _isLoading = false;
          _hasError = false;
        });
        
        // Update unread count
        _updateUnreadCount();
      } else {
        print('❌ Response not successful: ${response.message}');
        setState(() {
          _hasError = true;
          _errorMessage = response.message ?? 'Không thể tải thông báo';
          _isLoading = false;
          _notifications = []; // Clear notifications on error
        });
      }
    } catch (e, stackTrace) {
      print('❌ Error loading notifications: $e');
      print('❌ Stack trace: $stackTrace');
      setState(() {
        _hasError = true;
        _errorMessage = 'Lỗi: ${e.toString()}';
        _isLoading = false;
        _notifications = []; // Clear notifications on error
      });
    }
  }

  Future<void> _updateUnreadCount() async {
    final count = await _notificationService.getUnreadCount();
    setState(() {
      _unreadCount = count;
    });
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    final success = await _notificationService.markAsRead(notification.id);
    if (success) {
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = notification.copyWith(isRead: true);
        }
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    final success = await _notificationService.markAllAsRead();
    if (success) {
      setState(() {
        _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
        _unreadCount = 0;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã đánh dấu tất cả thông báo là đã đọc'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Đánh dấu tất cả',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? _buildErrorState()
              : _notifications.isEmpty
                  ? _buildEmptyState()
                  : _buildNotificationList(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Có lỗi xảy ra',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có thông báo nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bạn sẽ nhận được thông báo về ưu đãi, phòng mới và chương trình của app',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: notification.isRead ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: notification.isRead 
            ? BorderSide.none 
            : BorderSide(color: Colors.blue[200]!, width: 1),
      ),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    notification.typeIcon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Notification content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: notification.isRead 
                                  ? FontWeight.w500 
                                  : FontWeight.bold,
                              color: notification.isRead 
                                  ? Colors.grey[700] 
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Content
                    Text(
                      notification.content,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Footer row
                    Row(
                      children: [
                        // Type badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getNotificationColor(notification.type).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            notification.typeDisplayName,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getNotificationColor(notification.type),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // Time
                        Text(
                          notification.formattedCreatedAt,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    
                    // Sender info
                    if (notification.senderName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Từ: ${notification.senderName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'promotion':
        return Colors.orange;
      case 'new_room':
        return Colors.green;
      case 'app_program':
        return Colors.purple;
      case 'booking_success':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Mark as read if not already read
    _markAsRead(notification);
    
    // Handle action if available
    if (notification.actionUrl != null) {
      _handleNotificationAction(notification);
    } else {
      // Show full content in dialog
      _showNotificationDetail(notification);
    }
  }

  void _handleNotificationAction(NotificationModel notification) {
    // Handle different action types
    switch (notification.type) {
      case 'promotion':
        // Navigate to deals screen
        Navigator.pushNamed(context, '/deals');
        break;
      case 'new_room':
        // Navigate to hotel list or specific hotel
        if (notification.hotelId != null) {
          Navigator.pushNamed(context, '/hotel-detail', arguments: notification.hotelId);
        } else {
          Navigator.pushNamed(context, '/hotels');
        }
        break;
      case 'app_program':
        // Navigate to app program screen
        Navigator.pushNamed(context, '/app-programs');
        break;
      case 'booking_success':
        // Navigate to booking history
        Navigator.pushNamed(context, '/booking-history');
        break;
      default:
        // Show detail dialog
        _showNotificationDetail(notification);
    }
  }

  void _showNotificationDetail(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(notification.typeIcon),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                notification.title,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                notification.content,
                style: const TextStyle(fontSize: 16, height: 1.4),
              ),
              
              if (notification.senderName != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Người gửi: ${notification.senderName}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              
              const SizedBox(height: 8),
              Text(
                'Thời gian: ${notification.formattedCreatedAt}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (notification.actionUrl != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleNotificationAction(notification);
              },
              child: Text(notification.actionText ?? 'Xem chi tiết'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
