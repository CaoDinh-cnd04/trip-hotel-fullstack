import 'package:flutter/material.dart';
import 'package:hotel_mobile/presentation/screens/home_screen.dart';
import 'package:hotel_mobile/presentation/screens/deals/deals_screen.dart';
import 'package:hotel_mobile/presentation/screens/booking/booking_management_screen.dart';
import 'package:hotel_mobile/presentation/screens/profile/profile_screen.dart';
import 'package:hotel_mobile/data/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hotel_mobile/data/services/backend_auth_service.dart';
import 'package:hotel_mobile/presentation/screens/login_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await _authService.isSignedIn();
    final isFirebaseLoggedIn = FirebaseAuth.instance.currentUser != null;
    if (isFirebaseLoggedIn) {
      await BackendAuthService().ensureBackendSessionFromFirebase();
    }
    setState(() {
      _isLoggedIn = isLoggedIn || isFirebaseLoggedIn;
    });
  }

  void _onItemTapped(int index) {
    print('Navigation tapped: index $index, isLoggedIn: $_isLoggedIn');

    // Check if user needs to be logged in for certain tabs
    // Chỉ Profile tab (index 3) cần đăng nhập
    if (!_isLoggedIn && index == 3) {
      print('Showing login dialog for Profile tab');
      _showLoginDialog();
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yêu cầu đăng nhập'),
        content: const Text('Bạn cần đăng nhập để sử dụng chức năng này.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToLogin();
            },
            child: const Text('Đăng nhập'),
          ),
        ],
      ),
    );
  }

  void _navigateToLogin() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );

    if (result == true) {
      _checkLoginStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const HomeScreen(),
          const DealsScreen(),
          const BookingManagementScreen(),
          _isLoggedIn
              ? const ProfileScreen()
              : const _LoginRequiredScreen(title: 'Tài khoản'),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer),
            label: 'Ưu đãi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_online),
            label: 'Đặt phòng',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
      ),
    );
  }
}

class _LoginRequiredScreen extends StatelessWidget {
  final String title;

  const _LoginRequiredScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.login, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            const Text(
              'Bạn cần đăng nhập để sử dụng chức năng này',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text('Đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }
}
