import 'package:flutter/material.dart';

/// Widget empty state tái sử dụng cho tất cả các màn hình
/// Đảm bảo consistency khi không có dữ liệu
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? customIcon;
  final Widget? customAction;

  const EmptyStateWidget({
    Key? key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.iconColor,
    this.actionLabel,
    this.onAction,
    this.customIcon,
    this.customAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            if (customIcon != null)
              customIcon!
            else
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: (iconColor ?? Colors.grey[400])!.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 64,
                  color: iconColor ?? Colors.grey[400],
                ),
              ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            
            // Subtitle
            if (subtitle != null) ...[
              const SizedBox(height: 12),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            // Action button
            if ((actionLabel != null && onAction != null) || customAction != null) ...[
              const SizedBox(height: 24),
              customAction ??
                  ElevatedButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.add, size: 20),
                    label: Text(actionLabel!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state cho bookings
class EmptyBookingsWidget extends StatelessWidget {
  final VoidCallback? onExplore;

  const EmptyBookingsWidget({
    Key? key,
    this.onExplore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'Chưa có đặt phòng nào',
      subtitle: 'Bắt đầu đặt phòng khách sạn đầu tiên của bạn để xem lịch sử ở đây',
      icon: Icons.hotel_outlined,
      iconColor: Colors.brown[400],
      actionLabel: 'Khám phá khách sạn',
      onAction: onExplore ?? () {
        Navigator.pushNamed(context, '/home');
      },
    );
  }
}

/// Empty state cho notifications
class EmptyNotificationsWidget extends StatelessWidget {
  const EmptyNotificationsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'Chưa có thông báo nào',
      subtitle: 'Thông báo mới sẽ xuất hiện ở đây khi có cập nhật',
      icon: Icons.notifications_none,
      iconColor: Colors.blue[400],
    );
  }
}

/// Empty state cho reviews
class EmptyReviewsWidget extends StatelessWidget {
  final bool isMyReviews;
  final VoidCallback? onExplore;

  const EmptyReviewsWidget({
    Key? key,
    this.isMyReviews = true,
    this.onExplore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isMyReviews) {
      return EmptyStateWidget(
        title: 'Chưa có đánh giá nào',
        subtitle: 'Sau khi hoàn thành đặt phòng, bạn có thể đánh giá khách sạn tại đây',
        icon: Icons.star_outline,
        iconColor: Colors.amber[600],
        actionLabel: 'Xem đặt phòng',
        onAction: onExplore ?? () {
          Navigator.pushNamed(context, '/booking-history');
        },
      );
    } else {
      return EmptyStateWidget(
        title: 'Chưa có đánh giá nào',
        subtitle: 'Hãy là người đầu tiên đánh giá khách sạn này',
        icon: Icons.star_outline,
        iconColor: Colors.amber[600],
      );
    }
  }
}

/// Empty state cho rooms
class EmptyRoomsWidget extends StatelessWidget {
  const EmptyRoomsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'Chưa có phòng nào',
      subtitle: 'Khách sạn này hiện chưa có phòng trống. Vui lòng thử lại sau.',
      icon: Icons.meeting_room_outlined,
      iconColor: Colors.grey[400],
    );
  }
}

/// Empty state cho search results
class EmptySearchResultsWidget extends StatelessWidget {
  final VoidCallback? onClearFilter;

  const EmptySearchResultsWidget({
    Key? key,
    this.onClearFilter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'Không tìm thấy kết quả',
      subtitle: 'Hãy thử thay đổi tiêu chí tìm kiếm hoặc xóa bộ lọc',
      icon: Icons.search_off,
      iconColor: Colors.grey[400],
      actionLabel: 'Xóa bộ lọc',
      onAction: onClearFilter,
    );
  }
}

/// Empty state cho saved items / favorites
class EmptySavedItemsWidget extends StatelessWidget {
  final VoidCallback? onExplore;

  const EmptySavedItemsWidget({
    Key? key,
    this.onExplore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'Chưa có mục yêu thích nào',
      subtitle: 'Nhấn vào biểu tượng yêu thích trên khách sạn để lưu vào danh sách này',
      icon: Icons.favorite_border,
      iconColor: Colors.red[300],
      actionLabel: 'Khám phá khách sạn',
      onAction: onExplore ?? () {
        Navigator.pushNamed(context, '/home');
      },
    );
  }
}

/// Empty state cho messages
class EmptyMessagesWidget extends StatelessWidget {
  const EmptyMessagesWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'Chưa có tin nhắn nào',
      subtitle: 'Tin nhắn của bạn sẽ xuất hiện ở đây',
      icon: Icons.chat_bubble_outline,
      iconColor: Colors.blue[400],
    );
  }
}

/// Empty state cho feedback
class EmptyFeedbackWidget extends StatelessWidget {
  final VoidCallback? onCreateFeedback;

  const EmptyFeedbackWidget({
    Key? key,
    this.onCreateFeedback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'Chưa có phản hồi nào',
      subtitle: 'Hãy tạo phản hồi đầu tiên của bạn',
      icon: Icons.feedback_outlined,
      iconColor: Colors.orange[400],
      actionLabel: 'Tạo phản hồi',
      onAction: onCreateFeedback,
    );
  }
}

