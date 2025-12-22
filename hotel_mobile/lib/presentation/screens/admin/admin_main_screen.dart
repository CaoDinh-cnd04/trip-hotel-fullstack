import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';
import 'user_management_screen.dart';
import 'hotel_registration_management_screen.dart';
import 'feedback_management_screen.dart';
import '../auth/triphotel_style_login_screen.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/backend_auth_service.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  List<Widget> get _screens => [
    AdminDashboardScreen(onNavigateToTab: _changeTab),
    const UserManagementScreen(),
    const HotelRegistrationManagementScreen(), // ✅ FIX: Use correct screen with proper model
    const FeedbackManagementScreen(),
  ];

  void _changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  final List<BottomNavigationBarItem> _bottomNavItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_outlined),
      activeIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.people_outlined),
      activeIcon: Icon(Icons.people),
      label: 'Người dùng',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.pending_actions_outlined),
      activeIcon: Icon(Icons.pending_actions),
      label: 'Duyệt Hồ sơ',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.feedback_outlined),
      activeIcon: Icon(Icons.feedback),
      label: 'Phản hồi',
    ),
  ];

  Future<void> _showLogoutDialog() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await _logout();
    }
  }

  Future<void> _logout() async {
    try {
      final authService = AuthService();
      final backendAuthService = BackendAuthService();
      
      await authService.signOut();
      await backendAuthService.signOut();
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const TriphotelStyleLoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đăng xuất: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 0 ? AppBar(
        backgroundColor: Colors.purple[700],
        title: const Text('Admin Panel', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _showLogoutDialog,
            tooltip: 'Đăng xuất',
          ),
        ],
      ) : null,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.purple[700],
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 12,
          ),
          items: _bottomNavItems,
        ),
      ),
    );
  }
}
