import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/models/hotel.dart';
import 'package:hotel_mobile/data/models/promotion.dart';
import 'package:hotel_mobile/data/services/api_service.dart';
import 'package:hotel_mobile/core/services/firebase_auth_service.dart';
import 'package:hotel_mobile/presentation/screens/room/room_detail_screen.dart';
import 'package:hotel_mobile/presentation/screens/hotel/hotel_list_screen.dart';
import 'package:hotel_mobile/presentation/screens/main_navigation_screen.dart';
import 'package:hotel_mobile/presentation/screens/deals/deals_screen.dart';
import 'package:hotel_mobile/presentation/screens/booking/booking_history_screen.dart';
import 'package:hotel_mobile/presentation/screens/notification/notification_screen.dart';
import 'package:hotel_mobile/presentation/widgets/hotel_card_with_favorite.dart';
import 'package:hotel_mobile/presentation/widgets/notification_icon.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  final bool isAuthenticated;
  final VoidCallback? onAuthStateChanged;

  const HomeScreen({
    super.key,
    this.isAuthenticated = false,
    this.onAuthStateChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final PageController _promotionPageController = PageController();
  final PageController _hotelPageController = PageController(viewportFraction: 0.9);
  late TabController _serviceTabController;
  Timer? _hotelCarouselTimer;
  int _currentHotelPage = 0;

  List<Hotel> _hotels = [];
  List<Hotel> _promotionHotels = [];
  List<Promotion> _promotions = [];
  bool _isLoading = true;
  String? _error;
  User? _currentUser;
  bool _isLoggedIn = false;

  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int _guestCount = 1;
  int _roomCount = 1;
  int _selectedServiceIndex = 0; // 0: Khách sạn, 1: Căn hộ

  @override
  void initState() {
    super.initState();
    _serviceTabController = TabController(length: 2, vsync: this);
    _apiService.initialize();
    _testConnection();
    _isLoggedIn = widget.isAuthenticated;
    _checkLoginStatus();
    _loadHotels();
    _loadPromotions();
    _startHotelCarousel();
  }
  
  void _startHotelCarousel() {
    _hotelCarouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || _hotels.isEmpty) return;
      
      setState(() {
        _currentHotelPage = (_currentHotelPage + 1) % (_hotels.length > 6 ? 6 : _hotels.length);
      });
      
      if (_hotelPageController.hasClients && _hotelPageController.positions.isNotEmpty) {
        _hotelPageController.animateToPage(
          _currentHotelPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isAuthenticated != widget.isAuthenticated) {
      if (mounted) {
        setState(() {
          _isLoggedIn = widget.isAuthenticated;
        });
      }
    }
  }

  Future<void> _testConnection() async {
    try {
      print('Testing API connection...');
      final isConnected = await _apiService.testConnection();
      print('Connection test result: $isConnected');
    } catch (e) {
      print('Connection test error: $e');
    }
  }

  Future<void> _checkLoginStatus() async {
    try {
      // Ưu tiên Firebase user (đăng nhập social)
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        _currentUser = firebaseUser;
        _isLoggedIn = true;
        print('✅ User đã đăng nhập: ${firebaseUser.email}');
      } else {
        _currentUser = _authService.currentUser;
        _isLoggedIn = _currentUser != null;
        if (_isLoggedIn) {
          print('✅ User đã đăng nhập: ${_currentUser?.email}');
        } else {
          print('ℹ️ User chưa đăng nhập');
        }
      }
    } catch (e) {
      print('❌ Error checking login status: $e');
      _isLoggedIn = false;
      _currentUser = null;
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _searchController.dispose();
    _hotelCarouselTimer?.cancel();
    _promotionPageController.dispose();
    _hotelPageController.dispose();
    _serviceTabController.dispose();
    super.dispose();
  }

  Future<void> _loadHotels({int retryCount = 0}) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('Loading hotels from API... (attempt ${retryCount + 1})');
      final response = await _apiService.getHotels(limit: 50); // Tăng limit
      print('API Response: ${response.success}, Message: ${response.message}');
      print('Raw response data: ${response.data}');

      if (!mounted) return;

      if (response.success && response.data != null) {
        print('✅ Hotels loaded: ${response.data!.length}');
        for (var hotel in response.data!) {
          print('🏨 Hotel: ${hotel.ten}');
          print('   ⭐ Stars: ${hotel.soSao}');
          print('   📸 Image: ${hotel.hinhAnh}');
        }

        if (mounted) {
          setState(() {
            _hotels = response.data!;
            _promotionHotels = _hotels
                .where((hotel) => (hotel.soSao ?? 0) >= 4)
                .toList();
            _isLoading = false;
          });
        }
        print('Promotion hotels: ${_promotionHotels.length}');
      } else {
        print('API Error: ${response.message}');
        if (mounted) {
          setState(() {
            _error = response.message.isNotEmpty
                ? response.message
                : 'Không thể tải danh sách khách sạn';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Exception loading hotels: $e');

      if (!mounted) return;

      // Auto retry once for network errors
      if (retryCount < 1 && e.toString().contains('Connection')) {
        await Future.delayed(const Duration(seconds: 2));
        return _loadHotels(retryCount: retryCount + 1);
      }

      if (mounted) {
        setState(() {
          _error = 'Lỗi kết nối: Vui lòng kiểm tra mạng và thử lại';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadPromotions() async {
    try {
      print('Loading promotions from API...');
      final response = await _apiService.getPromotions(limit: 20, active: true);
      print(
        'Promotions API Response: ${response.success}, Message: ${response.message}',
      );

      if (response.success && response.data != null) {
        print('Promotions loaded: ${response.data!.length}');
        if (mounted) {
          setState(() {
            _promotions = response.data!;
          });
        }
      } else {
        print('Promotions API Error: ${response.message}');
      }
    } catch (e) {
      print('Exception loading promotions: $e');
    }
  }

  void _performSearch() async {
    final searchQuery = _searchController.text.trim();
    final locationQuery = _locationController.text.trim();

    if (searchQuery.isEmpty &&
        locationQuery.isEmpty &&
        _checkInDate == null &&
        _checkOutDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng nhập từ khóa tìm kiếm hoặc chọn địa điểm/ngày',
          ),
        ),
      );
      return;
    }

    if (_checkInDate != null && _checkOutDate != null) {
      if (!_checkOutDate!.isAfter(_checkInDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ngày trả phòng phải sau ngày nhận phòng'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Determine what to search for
    String finalSearchQuery = '';
    if (locationQuery.isNotEmpty) {
      finalSearchQuery = locationQuery;
    } else if (searchQuery.isNotEmpty) {
      finalSearchQuery = searchQuery;
    } else {
      finalSearchQuery = 'Tất cả khách sạn';
    }

    // Navigate to SearchResultsScreen
    Navigator.pushNamed(
      context,
      '/search-results',
      arguments: {
        'location': finalSearchQuery,
        'checkInDate':
            _checkInDate ?? DateTime.now().add(const Duration(days: 1)),
        'checkOutDate':
            _checkOutDate ?? DateTime.now().add(const Duration(days: 2)),
        'guestCount': _guestCount,
        'roomCount': _roomCount,
      },
    );
  }

  Future<void> _handleRefresh() async {
    await _loadHotels();
  }

  // void _handleLogin() {
  //   Navigator.pushNamed(context, '/login');
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: _isLoading
            ? _buildLoadingState()
            : _error != null
            ? _buildErrorState()
            : _buildMainContent(),
      ),
    );
  }

  Widget _buildMainContent() {
    return CustomScrollView(
      slivers: [
        // Header with logo, notification, and avatar
        _buildHeader(),

        // Main Service Buttons (4 buttons)
        SliverToBoxAdapter(child: _buildMainServiceButtons()),

        // Today's Deals Card
        SliverToBoxAdapter(child: _buildTodaysDealsCard()),

        // Promotions Section
        SliverToBoxAdapter(child: _buildPromotionsSection()),

        // Service tabs (Khách sạn, Căn hộ)
        _buildServiceTabs(),

        // Additional content based on selected service
        _buildServiceContent(),

        // Bottom spacing for navigation bar
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      floating: true,
      pinned: false,
      elevation: 0,
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false,
      toolbarHeight: 70,
      flexibleSpace: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF003580), Color(0xFF0066CC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.hotel,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'triphotel',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),

              // Notification and Avatar
              Row(
                children: [
                  // Notification icon with badge
                  NotificationIcon(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen(),
                        ),
                      );
                    },
                    iconColor: Colors.black87,
                    iconSize: 28,
                  ),

                  const SizedBox(width: 8),

                  // Avatar
                  GestureDetector(
                    onTap: () {
                      // Handle avatar tap - navigate to login or profile
                      if (_isLoggedIn) {
                        // If logged in, show profile menu
                        _showProfileMenu();
                      } else {
                        // If not logged in, navigate to login screen
                        _navigateToLogin();
                      }
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _currentUser?.photoURL != null
                          ? NetworkImage(_currentUser!.photoURL!)
                          : null,
                      child: _currentUser?.photoURL == null
                          ? Icon(
                              Icons.person,
                              color: Colors.grey[600],
                              size: 24,
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainSearchBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tìm kiếm khách sạn',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Location field
          _buildSearchField(
            label: 'Địa điểm',
            hint: 'Chọn thành phố, quốc gia',
            icon: Icons.location_on,
            controller: _locationController,
            onTap: () => _showLocationPicker(),
          ),

          const SizedBox(height: 12),

          // Date fields
          Row(
            children: [
              Expanded(
                child: _buildSearchField(
                  label: 'Ngày nhận phòng',
                  hint: _checkInDate != null
                      ? DateFormat('dd/MM/yyyy').format(_checkInDate!)
                      : 'Chọn ngày',
                  icon: Icons.calendar_today,
                  onTap: () => _selectCheckInDate(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSearchField(
                  label: 'Ngày trả phòng',
                  hint: _checkOutDate != null
                      ? DateFormat('dd/MM/yyyy').format(_checkOutDate!)
                      : 'Chọn ngày',
                  icon: Icons.calendar_today,
                  onTap: () => _selectCheckOutDate(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Guest and room count
          Row(
            children: [
              Expanded(
                child: _buildSearchField(
                  label: 'Số khách',
                  hint: '$_guestCount khách',
                  icon: Icons.person,
                  onTap: () => _showGuestPicker(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSearchField(
                  label: 'Số phòng',
                  hint: '$_roomCount phòng',
                  icon: Icons.hotel,
                  onTap: () => _showRoomPicker(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Search button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _performSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Tìm kiếm',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField({
    required String label,
    required String hint,
    required IconData icon,
    TextEditingController? controller,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    controller?.text.isNotEmpty == true ? controller!.text : hint,
                    style: TextStyle(
                      fontSize: 14,
                      color: controller?.text.isNotEmpty == true
                          ? Colors.black87
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceTabs() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: TabBar(
          controller: _serviceTabController,
          indicatorColor: Colors.blue,
          indicatorWeight: 3,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          onTap: (index) {
            if (mounted) {
              setState(() {
                _selectedServiceIndex = index;
              });
            }
          },
          tabs: const [
            Tab(text: 'Khách sạn'),
            Tab(text: 'Căn hộ'),
          ],
        ),
      ),
    );
  }

  // Promotions Section with improved UI
  Widget _buildPromotionsSection() {
    if (_promotions.isEmpty) {
      return const SizedBox(height: 20);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Khuyến mại',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DealsScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Xem tất cả',
                    style: TextStyle(
                      color: Color(0xFF003580),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _promotions.length > 10 ? 10 : _promotions.length,
              itemBuilder: (context, index) {
                final promotion = _promotions[index];
                final imageUrl = promotion.image ?? promotion.hinhAnh;
                
                return GestureDetector(
                  onTap: () {
                    // Navigate to promotion detail or hotel list
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DealsScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Hotel Image
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: imageUrl?.isNotEmpty == true
                                ? Image.network(
                                    'http://10.0.2.2:5000/images/hotels/$imageUrl',
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) =>
                                        _buildPromotionPlaceholder(),
                                  )
                                : _buildPromotionPlaceholder(),
                          ),
                        ),
                        
                        // Gradient Overlay
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.7),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        
                        // Discount Badge
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '-${promotion.phanTramGiam.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        
                        // Category Badge (Du lịch)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF003580),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Du lịch',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Location Badge (bottom left)
                        if (promotion.location != null)
                          Positioned(
                            bottom: 60,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: Color(0xFF003580),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    promotion.location!,
                                    style: const TextStyle(
                                      color: Color(0xFF003580),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        
                        // Content
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  promotion.ten,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (promotion.moTa?.isNotEmpty == true) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    promotion.moTa!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text(
                                      'Áp dụng điều khoản',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF003580),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Xem ngay',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPromotionPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[300]!, Colors.blue[500]!],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer, color: Colors.white, size: 48),
            SizedBox(height: 8),
            Text(
              'Ưu đãi đặc biệt',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceContent() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedServiceIndex == 0
                  ? 'Khách sạn nổi bật'
                  : 'Căn hộ cho thuê',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedServiceIndex == 0)
              _buildHotelsList()
            else
              _buildApartmentsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHotelsList() {
    if (_hotels.isEmpty) {
      return const Center(
        child: Text(
          'Không có khách sạn nào',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final displayHotels = _hotels.length > 6 ? _hotels.sublist(0, 6) : _hotels;

    return Column(
      children: [
        SizedBox(
          height: 320,
          child: PageView.builder(
            controller: _hotelPageController,
            itemCount: displayHotels.length,
            onPageChanged: (index) {
              if (mounted) {
                setState(() {
                  _currentHotelPage = index;
                });
              }
            },
            itemBuilder: (context, index) {
              final hotel = displayHotels[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildHotelCard(hotel),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Page indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            displayHotels.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentHotelPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentHotelPage == index
                    ? const Color(0xFF2196F3)
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApartmentsList() {
    return const Center(
      child: Text(
        'Tính năng căn hộ đang được phát triển',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildHotelCard(Hotel hotel) {
    return HotelCardWithFavorite(
      hotel: hotel,
      width: double.infinity,
      height: 280,
      onTap: () => _viewHotelDetails(hotel),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
          ),
          SizedBox(height: 16),
          Text(
            'Đang tải khách sạn...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 64,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Không thể kết nối',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Đã xảy ra lỗi không xác định',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                if (mounted) {
                  setState(() {
                    _error = null;
                  });
                  _loadHotels();
                }
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for new design
  void _showLocationPicker() {
    final List<String> popularLocations = [
      'Hà Nội',
      'TP. Hồ Chí Minh',
      'Đà Nẵng',
      'Hội An',
      'Nha Trang',
      'Phú Quốc',
      'Đà Lạt',
      'Vũng Tàu',
      'Cần Thơ',
      'Huế',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chọn địa điểm',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm địa điểm...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      // TODO: Implement search functionality
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: popularLocations.length,
                itemBuilder: (context, index) {
                  final location = popularLocations[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.blue),
                    title: Text(location),
                    onTap: () {
                      if (mounted) {
                        setState(() {
                          _locationController.text = location;
                        });
                      }
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã chọn địa điểm: $location'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectCheckInDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _checkInDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      if (mounted) {
        setState(() {
          _checkInDate = picked;
          if (_checkOutDate != null && !_checkOutDate!.isAfter(picked)) {
            _checkOutDate = picked.add(const Duration(days: 1));
          }
        });
      }
    }
  }

  void _selectCheckOutDate() async {
    final DateTime firstDate =
        _checkInDate?.add(const Duration(days: 1)) ??
        DateTime.now().add(const Duration(days: 1));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _checkOutDate ?? firstDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      if (mounted) {
        setState(() {
          _checkOutDate = picked;
        });
      }
    }
  }

  void _showGuestPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          height: 300,
          child: Column(
            children: [
              const Text(
                'Chọn số khách',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Số khách'),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _guestCount > 1
                            ? () {
                                setModalState(() => _guestCount--);
                                if (mounted) setState(() {});
                              }
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text('$_guestCount'),
                      IconButton(
                        onPressed: () {
                          setModalState(() => _guestCount++);
                          if (mounted) setState(() {});
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRoomPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          height: 300,
          child: Column(
            children: [
              const Text(
                'Chọn số phòng',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Số phòng'),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _roomCount > 1
                            ? () {
                                setModalState(() => _roomCount--);
                                if (mounted) setState(() {});
                              }
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text('$_roomCount'),
                      IconButton(
                        onPressed: () {
                          setModalState(() => _roomCount++);
                          if (mounted) setState(() {});
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewHotelDetails(Hotel hotel) async {
    try {
      // Note: Firebase authentication is handled separately
      // Backend session sync can be implemented if needed

      // Lấy danh sách phòng của khách sạn
      final response = await _apiService.getRoomsByHotel(hotel.id);

      if (response.success &&
          response.data != null &&
          response.data!.isNotEmpty) {
        // Nếu có phòng, navigate đến chi tiết phòng đầu tiên
        final firstRoom = response.data!.first;
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  RoomDetailScreen(room: firstRoom, hotel: hotel),
            ),
          );
        }
      } else {
        // Nếu không có phòng, hiển thị thông báo
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Khách sạn ${hotel.ten} hiện không có phòng khả dụng',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải thông tin phòng: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Main Service Buttons (4 buttons with gradients)
  Widget _buildMainServiceButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildServiceButton(
                  title: 'Khách sạn',
                  icon: Icons.hotel,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B9D), Color(0xFFFFB3BA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HotelListScreen(
                          location: 'Tất cả khách sạn',
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildServiceButton(
                  title: 'Hoạt động',
                  icon: Icons.attractions,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFA500), Color(0xFFFFE4B5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tính năng hoạt động đang được phát triển'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceButton({
    required String title,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Today's Deals Card
  Widget _buildTodaysDealsCard() {
    final location = _locationController.text.isNotEmpty
        ? _locationController.text
        : 'hanoi';
    final checkIn = _checkInDate ?? DateTime.now().add(const Duration(days: 1));
    final checkOut = _checkOutDate ?? DateTime.now().add(const Duration(days: 2));
    final dateFormat = DateFormat('d MMM', 'vi');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Xem ưu đãi hôm nay',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _performSearch(),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF003580).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Color(0xFF003580),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_getDayName(checkIn)}, ${dateFormat.format(checkIn)} - ${_getDayName(checkOut)}, ${dateFormat.format(checkOut)} • $_roomCount Phòng $_guestCount Người lớn',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tìm kiếm nhanh',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionItem(
                  icon: Icons.location_city,
                  title: 'Khách sạn gần đây',
                  color: Colors.blue,
                  onTap: () async {
                    // Try to get current location for nearby hotels
                    try {
                      // For now, use a default location (Ho Chi Minh City)
                      // In a real app, you would use geolocation here
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HotelListScreen(
                            location: 'Thành phố Hồ Chí Minh',
                          ),
                        ),
                      );
                    } catch (e) {
                      // Fallback to all hotels if location fails
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HotelListScreen(
                            location: 'Tất cả khách sạn',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionItem(
                  icon: Icons.star,
                  title: 'Đánh giá cao',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HotelListScreen(
                          location: 'Khách sạn đánh giá cao',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showLoginRequiredDialog({String? message}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yêu cầu đăng nhập'),
        content: Text(message ?? 'Bạn cần đăng nhập để sử dụng chức năng này.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(context, '/login');
            },
            child: const Text('Đăng nhập'),
          ),
        ],
      ),
    );
  }

  void _navigateToLogin() async {
    final result = await Navigator.pushNamed(context, '/login');
    if (result == true) {
      // Refresh login status if login was successful
      _checkLoginStatus();
      // Notify parent about auth state change
      widget.onAuthStateChanged?.call();
    }
  }

  Widget _buildMenuSection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(20),
          children: [
            // User Info
            ListTile(
              leading: CircleAvatar(
                radius: 25,
                backgroundColor: Colors.blue,
                backgroundImage: _currentUser?.photoURL != null
                    ? NetworkImage(_currentUser!.photoURL!)
                    : null,
                child: _currentUser?.photoURL == null
                    ? Text(
                        _currentUser?.displayName?.isNotEmpty == true
                            ? _currentUser!.displayName![0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              title: Text(
                _currentUser?.displayName ?? 'Người dùng',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(_currentUser?.email ?? ''),
            ),

            const Divider(),

            // Authentication & Account Section
            if (!_isLoggedIn) ...[
              _buildMenuSection('Tài khoản'),
              ListTile(
                leading: const Icon(Icons.login, color: Colors.blue),
                title: const Text('Đăng nhập'),
                subtitle: const Text('Authentication feature'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToLogin();
                },
              ),
              const Divider(),
            ],

            // Hotel & Booking Section
            _buildMenuSection('Đặt phòng'),
            ListTile(
              leading: const Icon(Icons.hotel, color: Colors.blue),
              title: const Text('Khách sạn'),
              subtitle: const Text('Hotel booking feature'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HotelListScreen(
                      location: 'Tất cả khách sạn',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bed, color: Colors.green),
              title: const Text('Phòng'),
              subtitle: const Text('Room selection feature'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HotelListScreen(
                      location: 'Tất cả khách sạn',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.book_online, color: Colors.orange),
              title: const Text('Đặt phòng'),
              subtitle: const Text('Booking management feature'),
              onTap: () {
                Navigator.pop(context);
                if (_isLoggedIn) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HotelListScreen(
                        location: 'Tất cả khách sạn',
                      ),
                    ),
                  );
                } else {
                  _showLoginRequiredDialog(
                    message: 'Bạn cần đăng nhập để đặt phòng.',
                  );
                }
              },
            ),

            const Divider(),

            // Promotions Section
            _buildMenuSection('Ưu đãi'),
            ListTile(
              leading: const Icon(Icons.local_offer, color: Colors.red),
              title: const Text('Khuyến mãi'),
              subtitle: const Text('Promotions and deals feature'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DealsScreen(),
                  ),
                );
              },
            ),

            const Divider(),

            // Additional Features
            _buildMenuSection('Tính năng khác'),
            ListTile(
              leading: const Icon(Icons.tune, color: Colors.purple),
              title: const Text('Bộ lọc'),
              subtitle: const Text('Filter hotels'),
              onTap: () {
                Navigator.pop(context);
                _showFilterDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.map, color: Colors.teal),
              title: const Text('Bản đồ'),
              subtitle: const Text('Map view'),
              onTap: () {
                Navigator.pop(context);
                _showMapView();
              },
            ),
            ListTile(
              leading: const Icon(Icons.language, color: Colors.indigo),
              title: const Text('Ngôn ngữ'),
              subtitle: const Text('Language settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/language-demo');
              },
            ),
            ListTile(
              leading: const Icon(Icons.feedback_outlined, color: Colors.amber),
              title: const Text('Phản hồi'),
              subtitle: const Text('Send feedback'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/feedback');
              },
            ),

            if (_isLoggedIn) ...[
              const Divider(),
              _buildMenuSection('Tài khoản'),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Thông tin cá nhân'),
                onTap: () {
                  Navigator.pop(context);
                  _showPersonalInfo();
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.blue),
                title: const Text('Lịch sử đặt phòng'),
                subtitle: const Text('Xem các đặt phòng đã thực hiện'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BookingHistoryScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Cài đặt'),
                onTap: () {
                  Navigator.pop(context);
                  _showSettings();
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Đăng xuất',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutConfirmation();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper method to get day name in Vietnamese
  String _getDayName(DateTime date) {
    const days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    return days[date.weekday % 7];
  }

  void _showLogoutConfirmation() {
    // Lấy thông tin provider hiện tại
    List<String> providers = [];
    try {
      providers = _authService.getCurrentProviders();
      print('🔍 Current providers: $providers');
    } catch (e) {
      print('❌ Error getting providers: $e');
      providers = [];
    }
    
    final providerText = providers.isNotEmpty
        ? 'Bạn đang đăng nhập bằng ${providers.join(", ")}.\n\nBạn có chắc chắn muốn đăng xuất?'
        : 'Bạn có chắc chắn muốn đăng xuất?';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: Text(providerText),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // Chuyển về màn hình đăng nhập ngay lập tức
              print('🔄 Chuyển về màn hình đăng nhập ngay lập tức...');
              Navigator.pushReplacementNamed(context, '/login');
              
              // Notify parent about auth state change
              widget.onAuthStateChanged?.call();

              // Đăng xuất trong background (không chờ)
              _performLogoutInBackground(providers);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bộ lọc khách sạn',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Price Range
            const Text('Khoảng giá:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Từ',
                      hintText: '0',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Đến',
                      hintText: '1000000',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Star Rating
            const Text('Hạng sao:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () {
                    // Handle star rating selection
                  },
                  icon: Icon(
                    Icons.star,
                    color: index < 3 ? Colors.amber : Colors.grey,
                  ),
                );
              }),
            ),
            
            const SizedBox(height: 20),
            
            // Amenities
            const Text('Tiện ích:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                'WiFi', 'Parking', 'Pool', 'Gym', 'Spa', 'Restaurant'
              ].map((amenity) => FilterChip(
                label: Text(amenity),
                selected: false,
                onSelected: (selected) {
                  // Handle amenity selection
                },
              )).toList(),
            ),
            
            const SizedBox(height: 30),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã áp dụng bộ lọc'),
                        ),
                      );
                    },
                    child: const Text('Áp dụng'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMapView() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bản đồ khách sạn'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Bản đồ khách sạn',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Hiển thị vị trí các khách sạn trên bản đồ',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showPersonalInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, size: 28, color: Colors.blue),
                const SizedBox(width: 12),
                const Text(
                  'Thông tin cá nhân',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // User Info Display
            if (_currentUser != null) ...[
              _buildInfoRow('Tên', _currentUser!.displayName ?? 'Chưa cập nhật'),
              _buildInfoRow('Email', _currentUser!.email ?? 'Chưa cập nhật'),
              _buildInfoRow('Ảnh đại diện', _currentUser!.photoURL != null ? 'Đã có' : 'Chưa có'),
            ] else ...[
              const Center(
                child: Text(
                  'Không có thông tin người dùng',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
            
            const SizedBox(height: 20),
            
            // Edit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chức năng chỉnh sửa thông tin sẽ được bổ sung sớm'),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Chỉnh sửa thông tin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, size: 28, color: Colors.blue),
                const SizedBox(width: 12),
                const Text(
                  'Cài đặt',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Settings Options
            _buildSettingItem(
              Icons.notifications,
              'Thông báo',
              'Quản lý thông báo',
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cài đặt thông báo sẽ được bổ sung sớm'),
                  ),
                );
              },
            ),
            
            _buildSettingItem(
              Icons.privacy_tip,
              'Quyền riêng tư',
              'Cài đặt quyền riêng tư',
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cài đặt quyền riêng tư sẽ được bổ sung sớm'),
                  ),
                );
              },
            ),
            
            _buildSettingItem(
              Icons.security,
              'Bảo mật',
              'Cài đặt bảo mật tài khoản',
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cài đặt bảo mật sẽ được bổ sung sớm'),
                  ),
                );
              },
            ),
            
            _buildSettingItem(
              Icons.help,
              'Trợ giúp',
              'Hướng dẫn sử dụng',
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Trung tâm trợ giúp sẽ được bổ sung sớm'),
                  ),
                );
              },
            ),
            
            _buildSettingItem(
              Icons.info,
              'Về ứng dụng',
              'Thông tin phiên bản',
              () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Về ứng dụng'),
                    content: const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hotel Booking App'),
                        SizedBox(height: 8),
                        Text('Phiên bản: 1.0.0'),
                        SizedBox(height: 8),
                        Text('Phát triển bởi: Hotel Team'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Đóng'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  /// Thực hiện đăng xuất trong background (không chờ)
  void _performLogoutInBackground(List<String> providers) {
    // Chạy đăng xuất trong background với timeout
    _authService.signOut().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        print('⚠️ Logout timeout, but continuing...');
      },
    ).then((_) {
      print('✅ Đăng xuất thành công trong background');
    }).catchError((e) {
      print('❌ Lỗi đăng xuất trong background: $e');
      // Không cần xử lý lỗi vì đã chuyển màn hình rồi
    });
  }
}
