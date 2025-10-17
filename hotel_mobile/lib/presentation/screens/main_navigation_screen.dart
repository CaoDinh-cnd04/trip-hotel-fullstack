import 'package:flutter/material.dart';
import 'package:hotel_mobile/presentation/screens/home_screen.dart';
import 'package:hotel_mobile/presentation/screens/deals/deals_screen.dart';
import 'package:hotel_mobile/presentation/screens/favorites/favorites_screen.dart';
import 'package:hotel_mobile/data/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hotel_mobile/data/services/backend_auth_service.dart';

class MainNavigationScreen extends StatefulWidget {
  final bool isAuthenticated;
  final VoidCallback? onAuthStateChanged;

  const MainNavigationScreen({
    super.key,
    this.isAuthenticated = false,
    this.onAuthStateChanged,
  });

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
    _isLoggedIn = widget.isAuthenticated;
    _checkLoginStatus();
  }

  @override
  void didUpdateWidget(MainNavigationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isAuthenticated != widget.isAuthenticated) {
      setState(() {
        _isLoggedIn = widget.isAuthenticated;
      });
    }
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
    setState(() {
      _selectedIndex = index;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeScreen(
            isAuthenticated: _isLoggedIn,
            onAuthStateChanged: widget.onAuthStateChanged,
          ),
          const DealsScreen(),
          const FavoritesScreen(),
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
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Đã lưu'),
        ],
      ),
    );
  }
}

