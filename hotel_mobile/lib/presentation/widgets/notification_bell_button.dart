// Notification Bell Button Widget
import 'package:flutter/material.dart';
import '../../data/services/notification_service_api.dart';
import '../screens/notifications/notifications_screen.dart';
import 'dart:async';

class NotificationBellButton extends StatefulWidget {
  const NotificationBellButton({super.key});

  @override
  State<NotificationBellButton> createState() => _NotificationBellButtonState();
}

class _NotificationBellButtonState extends State<NotificationBellButton> {
  final NotificationServiceApi _notificationService = NotificationServiceApi();
  int _unreadCount = 0;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    
    // Poll every 30 seconds for new notifications
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadUnreadCount();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    try {
      print('🔔 NotificationBellButton: Loading unread count...');
      final count = await _notificationService.getUnreadCount();
      print('🔔 NotificationBellButton: Got unread count = $count');
      if (mounted) {
        setState(() {
          _unreadCount = count;
          print('🔔 NotificationBellButton: Updated UI with count = $_unreadCount');
        });
      }
    } catch (e) {
      print('❌ NotificationBellButton: Failed to load unread count: $e');
      if (mounted) {
        setState(() => _unreadCount = 0);
      }
    }
  }

  void _onBellTapped() async {
    // Navigate to notifications screen
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    );
    
    // Refresh count after returning
    _loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: _onBellTapped,
          color: Colors.black87,
          tooltip: 'Thông báo',
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                _unreadCount > 99 ? '99+' : '$_unreadCount',
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
    );
  }
}

