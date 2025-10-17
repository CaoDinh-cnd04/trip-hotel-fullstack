import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';
import 'user_management_screen.dart';
import 'application_review_screen.dart';
import 'role_management_screen.dart';
import 'feedback_management_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AdminDashboardScreen(),
    const UserManagementScreen(),
    const RoleManagementScreen(),
    const ApplicationReviewScreen(),
    const FeedbackManagementScreen(),
  ];

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
      icon: Icon(Icons.admin_panel_settings_outlined),
      activeIcon: Icon(Icons.admin_panel_settings),
      label: 'Quyền hạn',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.pending_actions_outlined),
      activeIcon: Icon(Icons.pending_actions),
      label: 'Duyệt hồ sơ',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.feedback_outlined),
      activeIcon: Icon(Icons.feedback),
      label: 'Phản hồi',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
