import 'package:flutter/material.dart';
import 'package:hotel_mobile/presentation/screens/home/triphotel_style_home_screen.dart';
import 'package:hotel_mobile/presentation/screens/deals/deals_screen.dart';
import 'package:hotel_mobile/presentation/screens/saved/favorites_hotels_screen.dart';
import 'package:hotel_mobile/presentation/screens/chat/modern_conversation_list_screen.dart';
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
  int _favoritesKey = 0; // Key để force rebuild tab Đã lưu

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
    print('🔄 MainNavigation: Chuyển sang tab $index');
    if (index == 2) {
      // Tab "Đã lưu" - force rebuild để reload data
      print('❤️ Vào tab Đã lưu - Force rebuild với key mới');
      _favoritesKey = DateTime.now().millisecondsSinceEpoch;
    }
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
          TriphotelStyleHomeScreen(
            isAuthenticated: _isLoggedIn,
            onAuthStateChanged: widget.onAuthStateChanged,
          ),
          const DealsScreen(),
          FavoritesHotelsScreen(key: ValueKey(_favoritesKey)),
          const ModernConversationListScreen(),
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
          BottomNavigationBarItem(icon: Icon(Icons.chat_outlined), label: 'Tin nhắn'),
        ],
      ),
    );
  }
}

