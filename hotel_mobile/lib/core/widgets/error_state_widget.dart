import 'package:flutter/material.dart';

/// Widget error state tái sử dụng cho tất cả các màn hình
/// Đảm bảo consistency trong error handling
class ErrorStateWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final IconData icon;
  final Color? iconColor;
  final String? retryLabel;

  const ErrorStateWidget({
    Key? key,
    this.title,
    this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
    this.iconColor,
    this.retryLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: (iconColor ?? Colors.red[400])!.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: iconColor ?? Colors.red[400],
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              title ?? 'Có lỗi xảy ra',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            
            // Message
            if (message != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  message!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            
            // Retry button
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 20),
                label: Text(retryLabel ?? 'Thử lại'),
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

/// Widget error state cho login required
class LoginRequiredWidget extends StatelessWidget {
  final VoidCallback? onLogin;

  const LoginRequiredWidget({
    Key? key,
    this.onLogin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      title: 'Yêu cầu đăng nhập',
      message: 'Bạn cần đăng nhập để sử dụng tính năng này',
      icon: Icons.lock_outline,
      iconColor: Colors.orange[400],
      onRetry: onLogin ?? () {
        Navigator.pushNamed(context, '/login');
      },
      retryLabel: 'Đăng nhập ngay',
    );
  }
}

/// Widget error state cho network errors
class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkErrorWidget({
    Key? key,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      title: 'Lỗi kết nối',
      message: 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối internet và thử lại.',
      icon: Icons.wifi_off,
      iconColor: Colors.orange[400],
      onRetry: onRetry,
    );
  }
}

/// Widget error state cho server errors
class ServerErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? message;

  const ServerErrorWidget({
    Key? key,
    this.onRetry,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      title: 'Lỗi máy chủ',
      message: message ?? 'Máy chủ đang gặp sự cố. Vui lòng thử lại sau.',
      icon: Icons.cloud_off,
      iconColor: Colors.red[400],
      onRetry: onRetry,
    );
  }
}

