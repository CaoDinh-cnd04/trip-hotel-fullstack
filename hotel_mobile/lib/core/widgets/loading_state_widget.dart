import 'package:flutter/material.dart';

/// Widget loading state đơn giản với message tùy chỉnh
/// Dùng cho các trường hợp loading đơn giản, không cần skeleton
class LoadingStateWidget extends StatelessWidget {
  final String? message;
  final Color? color;

  const LoadingStateWidget({
    Key? key,
    this.message,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: color != null ? AlwaysStoppedAnimation<Color>(color!) : null,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget loading state cho full screen với background
class FullScreenLoadingWidget extends StatelessWidget {
  final String? message;
  final Color? backgroundColor;

  const FullScreenLoadingWidget({
    Key? key,
    this.message,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.grey[50],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

