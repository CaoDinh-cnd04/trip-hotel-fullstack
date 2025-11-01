// Notifications Screen - User's notification list
import 'package:flutter/material.dart';
import '../../../core/widgets/skeleton_loading_widget.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/services/notification_service_api.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationServiceApi _notificationService = NotificationServiceApi();
  final ScrollController _scrollController = ScrollController();

  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreNotifications();
    }
  }

  Future<void> _loadNotifications() async {
    if (_currentPage > 1) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _notificationService.getNotifications(
        page: _currentPage,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _notifications = response['notifications'] as List<NotificationModel>;
          _totalPages = response['pagination']['totalPages'] ?? 1;
          _hasMore = _currentPage < _totalPages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      _currentPage++;
      final response = await _notificationService.getNotifications(
        page: _currentPage,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _notifications.addAll(response['notifications'] as List<NotificationModel>);
          _totalPages = response['pagination']['totalPages'] ?? 1;
          _hasMore = _currentPage < _totalPages;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentPage--;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _onNotificationTap(NotificationModel notification) async {
    // Mark as read
    if (!notification.daDoc) {
      await _notificationService.markAsRead(notification.id);
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = NotificationModel(
            id: notification.id,
            tieuDe: notification.tieuDe,
            noiDung: notification.noiDung,
            loaiThongBao: notification.loaiThongBao,
            urlHinhAnh: notification.urlHinhAnh,
            urlHanhDong: notification.urlHanhDong,
            vanBanNut: notification.vanBanNut,
            khachSanId: notification.khachSanId,
            ngayHetHan: notification.ngayHetHan,
            hienThi: notification.hienThi,
            doiTuongNhan: notification.doiTuongNhan,
            nguoiDungId: notification.nguoiDungId,
            guiEmail: notification.guiEmail,
            nguoiTaoId: notification.nguoiTaoId,
            ngayTao: notification.ngayTao,
            ngayCapNhat: notification.ngayCapNhat,
            daDoc: true,
          );
        }
      });
    }

    // Show notification detail dialog
    _showNotificationDetail(notification);
  }

  void _showNotificationDetail(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Text(
              notification.emoji,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                notification.tieuDe,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Notification content
              Text(
                notification.noiDung,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Notification image if available
              if (notification.urlHinhAnh != null && notification.urlHinhAnh!.isNotEmpty)
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(notification.urlHinhAnh!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              
              // Notification metadata
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    notification.timeAgo,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              if (notification.loaiThongBao != 'system') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.category, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      _getTypeLabel(notification.loaiThongBao),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          // Action button if URL available
          if (notification.urlHanhDong != null && notification.urlHanhDong!.isNotEmpty)
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final uri = Uri.parse(notification.urlHanhDong!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Không thể mở liên kết'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text(notification.vanBanNut ?? 'Xem thêm'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'promotion':
        return 'Ưu đãi';
      case 'new_room':
        return 'Phòng mới';
      case 'app_program':
        return 'Chương trình app';
      case 'booking_success':
        return 'Đặt phòng thành công';
      default:
        return 'Thông báo hệ thống';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Thông báo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return SkeletonLoadingWidget(
        itemType: LoadingItemType.notificationCard,
        itemCount: 5,
      );
    }

    if (_error != null) {
      // Check error type
      if (_error!.toLowerCase().contains('network') || 
          _error!.toLowerCase().contains('kết nối')) {
        return NetworkErrorWidget(
          onRetry: () {
            _currentPage = 1;
            _loadNotifications();
          },
        );
      }

      return ErrorStateWidget(
        title: 'Không thể tải thông báo',
        message: _error,
        onRetry: () {
          _currentPage = 1;
          _loadNotifications();
        },
      );
    }

    if (_notifications.isEmpty) {
      return EmptyNotificationsWidget();
    }

    return RefreshIndicator(
      onRefresh: () async {
        _currentPage = 1;
        await _loadNotifications();
      },
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _notifications.length + (_isLoadingMore ? 1 : 0),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          if (index == _notifications.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final notification = _notifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: notification.daDoc ? Colors.white : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onNotificationTap(notification),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon/Emoji
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: notification.daDoc ? Colors.grey[200] : Colors.blue[100],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      notification.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.tieuDe,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: notification.daDoc ? FontWeight.w500 : FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.noiDung,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            notification.timeAgo,
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                          if (!notification.daDoc) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

