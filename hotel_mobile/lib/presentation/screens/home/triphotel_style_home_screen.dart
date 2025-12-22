import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:ui';
import '../../../data/models/hotel.dart';
import '../../../data/models/promotion.dart';
import '../../../data/models/destination.dart';
import '../../../data/models/country.dart';
import '../../../data/services/public_api_service.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/search_history_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/user_profile_service.dart';
import '../../../data/models/notification.dart';
import '../../../data/models/user.dart';
import '../../../core/widgets/glass_card.dart';
import '../hotel/hotel_list_screen.dart';
import '../login_screen.dart';
import '../auth/triphotel_style_login_screen.dart';
import '../profile/profile_screen.dart';
import '../search/hotel_search_screen.dart';
import '../search/activity_search_screen.dart';
import '../booking/enhanced_booking_screen.dart';
import '../property/property_detail_screen.dart';
import '../../widgets/notification_bell_button.dart';
import '../../../data/services/applied_promotion_service.dart';

class TriphotelStyleHomeScreen extends StatefulWidget {
  final bool isAuthenticated;
  final VoidCallback? onAuthStateChanged;

  const TriphotelStyleHomeScreen({
    Key? key,
    this.isAuthenticated = false,
    this.onAuthStateChanged,
  }) : super(key: key);

  @override
  State<TriphotelStyleHomeScreen> createState() => _TriphotelStyleHomeScreenState();
}

class _TriphotelStyleHomeScreenState extends State<TriphotelStyleHomeScreen> with TickerProviderStateMixin {
  final PublicApiService _publicApiService = PublicApiService();
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  final UserProfileService _userProfileService = UserProfileService();
  
  List<Hotel> _featuredHotels = [];
  List<Promotion> _featuredPromotions = [];
  List<Destination> _hotDestinations = [];
  List<Country> _popularCountries = [];
  
  bool _isLoading = true;
  String? _error;
  
  // User data and notifications
  User? _currentUser;
  List<NotificationModel> _notifications = [];
  int _unreadNotificationCount = 0;
  
  // Thông tin tìm kiếm gần nhất
  String _lastSearchLocation = 'Vũng Tàu';
  DateTime _lastCheckInDate = DateTime.now().add(const Duration(days: 1));
  DateTime _lastCheckOutDate = DateTime.now().add(const Duration(days: 3));
  int _lastRooms = 1;
  int _lastAdults = 2;
  int _lastChildren = 0;
  
  // 🎬 Agoda-style Animation Controllers
  late PageController _hotelsPageController;
  late PageController _promotionsPageController;
  late PageController _destinationsPageController;
  late PageController _countriesPageController;
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  Timer? _hotelsAutoScrollTimer;
  Timer? _promotionsAutoScrollTimer;
  Timer? _destinationsAutoScrollTimer;
  Timer? _countriesAutoScrollTimer;
  
  int _currentHotelPage = 0;
  int _currentPromotionPage = 0;
  int _currentDestinationPage = 0;
  int _currentCountryPage = 0;
  
  static const Duration _autoScrollDuration = Duration(seconds: 5);
  static const Duration _scrollAnimationDuration = Duration(milliseconds: 800);
  static const Curve _scrollCurve = Curves.easeInOutCubic;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadHomePageData();
    if (widget.isAuthenticated) {
      _loadUserData();
    }
  }
  
  void _initializeAnimations() {
    // Initialize PageControllers with smooth physics
    _hotelsPageController = PageController(
      viewportFraction: 0.85, // Agoda-style card peek
      initialPage: 0,
    );
    _promotionsPageController = PageController(
      viewportFraction: 0.88, // Show promotion cards with peek
      initialPage: 0,
    );
    _destinationsPageController = PageController(
      viewportFraction: 0.88,
      initialPage: 0,
    );
    _countriesPageController = PageController(
      viewportFraction: 0.42, // Show multiple cards
      initialPage: 0,
    );
    
    // Initialize fade animation controller
    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeOut,
    );
    
    // Initialize slide animation controller
    _slideAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));
  }
  
  void _startAutoScroll() {
    // Auto-scroll for hotels
    _hotelsAutoScrollTimer = Timer.periodic(_autoScrollDuration, (timer) {
      if (_featuredHotels.isNotEmpty && mounted && 
          _hotelsPageController.hasClients && 
          _hotelsPageController.positions.isNotEmpty) {
        _currentHotelPage = (_currentHotelPage + 1) % _featuredHotels.length;
        _hotelsPageController.animateToPage(
          _currentHotelPage,
          duration: _scrollAnimationDuration,
          curve: _scrollCurve,
        );
      }
    });
    
    // Auto-scroll for promotions
    _promotionsAutoScrollTimer = Timer.periodic(_autoScrollDuration, (timer) {
      if (_featuredPromotions.isNotEmpty && mounted &&
          _promotionsPageController.hasClients &&
          _promotionsPageController.positions.isNotEmpty) {
        _currentPromotionPage = (_currentPromotionPage + 1) % _featuredPromotions.length;
        _promotionsPageController.animateToPage(
          _currentPromotionPage,
          duration: _scrollAnimationDuration,
          curve: _scrollCurve,
        );
      }
    });
    
    // Auto-scroll for destinations
    _destinationsAutoScrollTimer = Timer.periodic(_autoScrollDuration, (timer) {
      if (_hotDestinations.isNotEmpty && mounted &&
          _destinationsPageController.hasClients &&
          _destinationsPageController.positions.isNotEmpty) {
        _currentDestinationPage = (_currentDestinationPage + 1) % _hotDestinations.length;
        _destinationsPageController.animateToPage(
          _currentDestinationPage,
          duration: _scrollAnimationDuration,
          curve: _scrollCurve,
        );
      }
    });
    
    // Auto-scroll for countries
    _countriesAutoScrollTimer = Timer.periodic(_autoScrollDuration, (timer) {
      if (_popularCountries.isNotEmpty && mounted &&
          _countriesPageController.hasClients &&
          _countriesPageController.positions.isNotEmpty) {
        _currentCountryPage = (_currentCountryPage + 1) % _popularCountries.length;
        _countriesPageController.animateToPage(
          _currentCountryPage,
          duration: _scrollAnimationDuration,
          curve: _scrollCurve,
        );
      }
    });
  }
  
  @override
  void dispose() {
    _hotelsPageController.dispose();
    _promotionsPageController.dispose();
    _destinationsPageController.dispose();
    _countriesPageController.dispose();
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _hotelsAutoScrollTimer?.cancel();
    _promotionsAutoScrollTimer?.cancel();
    _destinationsAutoScrollTimer?.cancel();
    _countriesAutoScrollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadHomePageData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('🚀 Bắt đầu tải dữ liệu trang chủ Triphotel-style...');
      
      // Load lịch sử tìm kiếm gần nhất
      await _loadLastSearchData();
      
      // Load all data in parallel
      final results = await Future.wait([
        _publicApiService.getFeaturedHotels(limit: 6),
        _loadActivePromotions(), // Load from API v2 (SQL Server)
        _publicApiService.getHotDestinations(limit: 8),
        _publicApiService.getPopularCountries(limit: 6),
      ]);

      setState(() {
        _featuredHotels = results[0] as List<Hotel>;
        _featuredPromotions = results[1] as List<Promotion>;
        _hotDestinations = results[2] as List<Destination>;
        _popularCountries = results[3] as List<Country>;
        _isLoading = false;
      });

      print('✅ Tải dữ liệu trang chủ Triphotel-style thành công');
      print('📊 Loaded ${_featuredPromotions.length} active promotions from SQL Server');
      
      // 🎬 Start Agoda-style animations
      _fadeAnimationController.forward();
      _slideAnimationController.forward();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _startAutoScroll();
        }
      });
    } catch (e) {
      print('❌ Lỗi tải dữ liệu trang chủ: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Load active promotions from SQL Server via API v2
  Future<List<Promotion>> _loadActivePromotions() async {
    try {
      print('🚀 Loading active promotions from API v2...');
      final response = await _apiService.getPromotions(
        active: true, // Chỉ lấy khuyến mãi đang active
        limit: 10,
      );

      if (response.success && response.data != null) {
        print('✅ Loaded ${response.data!.length} active promotions from SQL Server');
        return response.data!.take(4).toList(); // Chỉ lấy 4 cái đầu để hiển thị
      } else {
        print('⚠️ No promotions found or API error: ${response.message}');
        return [];
      }
    } catch (e) {
      print('❌ Error loading active promotions: $e');
      return [];
    }
  }

  Future<void> _loadLastSearchData() async {
    try {
      final lastSearch = await SearchHistoryService.getLastSearch();
      if (lastSearch != null) {
        setState(() {
          _lastSearchLocation = lastSearch['location'] ?? 'Vũng Tàu';
          _lastCheckInDate = DateTime.parse(lastSearch['checkInDate']);
          _lastCheckOutDate = DateTime.parse(lastSearch['checkOutDate']);
          _lastRooms = lastSearch['rooms'] ?? 1;
          _lastAdults = lastSearch['adults'] ?? 2;
          _lastChildren = lastSearch['children'] ?? 0;
        });
        print('✅ Đã load thông tin tìm kiếm gần nhất: $_lastSearchLocation');
      }
    } catch (e) {
      print('❌ Lỗi load lịch sử tìm kiếm: $e');
    }
  }

  Future<void> _loadUserData() async {
    try {
      // Load user profile
      final userResponse = await _userProfileService.getUserProfile();
      if (userResponse.success && userResponse.data != null) {
        setState(() {
          _currentUser = userResponse.data!;
        });
      } else {
        // Use fallback user data
        _loadFallbackUserData();
      }

      // Load notifications
      final notificationResponse = await _notificationService.getNotifications();
      if (notificationResponse.success && notificationResponse.data != null) {
        setState(() {
          _notifications = notificationResponse.data!;
          _unreadNotificationCount = _notifications.where((n) => !n.isRead).length;
        });
      } else {
        // Use fallback notification data
        _loadFallbackNotificationData();
      }
    } catch (e) {
      print('❌ Lỗi load user data: $e');
      // Use fallback data when API fails
      _loadFallbackUserData();
      _loadFallbackNotificationData();
    }
  }

  void _loadFallbackUserData() {
    setState(() {
      _currentUser = User(
        id: 1,
        hoTen: 'Nguyễn Văn A',
        email: 'user@example.com',
        sdt: '0123456789',
        anhDaiDien: null, // No profile image for fallback
        diaChi: 'Hà Nội, Việt Nam',
        ngaySinh: '1990-01-01',
        gioiTinh: 'Nam',
        trangThai: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });
  }

  void _loadFallbackNotificationData() {
    setState(() {
      _notifications = [
        NotificationModel(
          id: 1,
          title: 'Chào mừng đến với Triphotel!',
          content: 'Cảm ơn bạn đã đăng ký tài khoản. Hãy khám phá những khách sạn tuyệt vời.',
          type: 'welcome',
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        NotificationModel(
          id: 2,
          title: 'Ưu đãi đặc biệt cuối tuần',
          content: 'Giảm giá 30% cho tất cả khách sạn tại Hà Nội. Áp dụng đến hết tuần này.',
          type: 'promotion',
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        NotificationModel(
          id: 3,
          title: 'Xác nhận đặt phòng',
          content: 'Đặt phòng tại Grand Hotel Hanoi đã được xác nhận. Mã đặt phòng: #12345',
          type: 'booking',
          isRead: true,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ];
      _unreadNotificationCount = _notifications.where((n) => !n.isRead).length;
    });
  }

  void _onServiceTap(String service) {
    switch (service) {
      case 'hotel':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HotelSearchScreen(),
          ),
        );
        break;
      case 'activity':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ActivitySearchScreen(),
          ),
        );
        break;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tải dữ liệu...'),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Có lỗi xảy ra',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadHomePageData,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHomePageData,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Header với logo Triphotel
                        _buildHeader(),
                        
                        // Main Service Categories
                        _buildMainServices(),
                        
                        // Today's Deals
                        _buildTodaysDeals(),
                        
                        // Promotions Section
                        _buildPromotionsSection(),
                        
                        // Featured Hotels Section
                        _buildFeaturedHotelsSection(),
                        
                        // Featured Destinations Section
                        _buildFeaturedDestinationsSection(),
                        
                        const SizedBox(height: 100), // Space for bottom nav
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo Triphotel
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.hotel,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'triphotel',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          
          // Notification and Profile
          Row(
            children: [
              // Notification Bell (only for authenticated users)
              if (widget.isAuthenticated)
                const NotificationBellButton()
              else
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, size: 28),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TriphotelStyleLoginScreen(),
                      ),
                    );
                  },
                ),
              // Remove old notification badge code
              if (false)
                Stack(
                  children: [
                    Container(),
                    if (_unreadNotificationCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                        child: Text(
                          '$_unreadNotificationCount',
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
              ),
              
              // Profile Icon with User Image
              GestureDetector(
                onTap: () {
                  if (widget.isAuthenticated) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TriphotelStyleLoginScreen(),
                      ),
                    );
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: ClipOval(
                    child: _currentUser?.anhDaiDien != null && _currentUser!.anhDaiDien!.isNotEmpty
                        ? Image.network(
                            _currentUser!.anhDaiDien!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                widget.isAuthenticated ? Icons.account_circle : Icons.person_outline,
                                size: 28,
                                color: Colors.grey.shade600,
                              );
                            },
                          )
                        : Icon(
                            widget.isAuthenticated ? Icons.account_circle : Icons.person_outline,
                            size: 28,
                            color: Colors.grey.shade600,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildMainServices() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
        children: [
          // Main services: Khách sạn và Hoạt động
          Row(
            children: [
              Expanded(
                child: _buildServiceCard(
                  title: 'Khách sạn',
                  icon: Icons.hotel,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B9D), Color(0xFFFFB3BA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => _onServiceTap('hotel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildServiceCard(
                  title: 'Hoạt động',
                  icon: Icons.attractions,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFA500), Color(0xFFFFE4B5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => _onServiceTap('activity'),
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

  Widget _buildServiceCard({
    required String title,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        blur: 8,
        opacity: 0.3,
        borderRadius: 20,
        padding: EdgeInsets.zero,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildTodaysDeals() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HotelSearchScreen(
                    initialLocation: _lastSearchLocation,
                    initialCheckInDate: _lastCheckInDate,
                    initialCheckOutDate: _lastCheckOutDate,
                    initialRooms: _lastRooms,
                    initialAdults: _lastAdults,
                    initialChildren: _lastChildren,
                  ),
                ),
              );
            },
            child: GlassCard(
              blur: 10,
              opacity: 0.25,
              borderRadius: 16,
              padding: const EdgeInsets.all(16),
              child: Container(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: Colors.blue[600],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _lastSearchLocation,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${SearchHistoryService.formatDateRange(_lastCheckInDate, _lastCheckOutDate)} • ${SearchHistoryService.formatGuestInfo(_lastRooms, _lastAdults, _lastChildren)}',
                        style: TextStyle(
                          fontSize: 14,
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
          ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromotionsSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                if (_featuredPromotions.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      // Navigate to deals screen
                      Navigator.pushNamed(context, '/deals');
                    },
                    child: const Text(
                      'Xem tất cả',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2196F3),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: _featuredPromotions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_offer_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Không có khuyến mãi nào',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : PageView.builder(
                      controller: _promotionsPageController,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _featuredPromotions.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPromotionPage = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final promotion = _featuredPromotions[index];
                        // Display hotel name and location
                        final subtitle = promotion.hotelName != null 
                          ? promotion.hotelName! 
                          : (promotion.moTa?.isNotEmpty == true 
                            ? promotion.moTa! 
                            : 'Đi nhiều hơn, chi ít hơn!');
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _buildPromotionCard(
                            promotion: promotion,
                            title: promotion.ten,
                            discount: '${promotion.phanTramGiam.isFinite && !promotion.phanTramGiam.isNaN ? promotion.phanTramGiam.toInt() : 0}%',
                            subtitle: subtitle,
                            imageUrl: promotion.image ?? promotion.hinhAnh ?? '',
                            isFirst: index == 0,
                            location: promotion.location,
                          ),
                        );
                      },
                    ),
            ),
            
            // Page Indicators (Dots)
            if (_featuredPromotions.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _featuredPromotions.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPromotionPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPromotionPage == index
                            ? const Color(0xFF2196F3)
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionCard({
    required Promotion promotion,
    required String title,
    required String discount,
    required String subtitle,
    required String imageUrl,
    required bool isFirst,
    String? location,
  }) {
    return GestureDetector(
      onTap: () {
        // Navigate to hotel list with promotion location
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HotelListScreen(
              location: location ?? _lastSearchLocation,
              title: 'Khách sạn tại ${location ?? _lastSearchLocation}',
            ),
          ),
        );
      },
      child: GlassCard(
        blur: 12,
        opacity: 0.3,
        borderRadius: 20,
        padding: EdgeInsets.zero,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section with Badges
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                color: Colors.grey[200],
              ),
              child: Stack(
                children: [
                  // Hotel Image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            'http://10.0.2.2:5000/images/hotels/$imageUrl',
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildPromotionPlaceholder(isFirst),
                          )
                        : _buildPromotionPlaceholder(isFirst),
                  ),
                  
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                  
                  // Discount Badge (Top Left)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '-$discount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),

                  // Location Badge (Bottom Left)
                  if (location != null)
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
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
                              location,
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

                  // "Du lịch" Badge (Top Right)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isFirst ? const Color(0xFF4CAF50) : const Color(0xFF2196F3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.yellow[300],
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Du lịch',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Hotel Name (Subtitle)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Áp dụng điều khoản',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                      Row(
                        children: [
                          // Apply Button
                          InkWell(
                            onTap: () => _applyPromotionFromHome(promotion),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                'Áp dụng',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // View Button
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'Xem ngay',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  /// Áp dụng promotion từ màn hình chính
  void _applyPromotionFromHome(Promotion promotion) {
    // Áp dụng promotion vào service
    final appliedPromotionService = AppliedPromotionService();
    appliedPromotionService.applyPromotion(promotion, hotelId: promotion.khachSanId);
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Đã áp dụng ưu đãi: ${promotion.ten} (Giảm ${promotion.phanTramGiam.toStringAsFixed(0)}%)',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: promotion.khachSanId != null
            ? SnackBarAction(
                label: 'Xem khách sạn',
                textColor: Colors.white,
                onPressed: () async {
                  // Fetch hotel data and navigate
                  try {
                    final hotelResponse = await _apiService.getHotelById(promotion.khachSanId!);
                    if (mounted && hotelResponse.success && hotelResponse.data != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PropertyDetailScreen(
                            hotel: hotelResponse.data!,
                            checkInDate: DateTime.now().add(const Duration(days: 1)),
                            checkOutDate: DateTime.now().add(const Duration(days: 2)),
                            guestCount: 1,
                          ),
                        ),
                      );
                    } else {
                      // Fallback: navigate to hotel list
                      if (promotion.location != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HotelListScreen(
                              location: promotion.location!,
                              title: 'Khách sạn ${promotion.location}',
                            ),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    // Fallback: navigate to hotel list
                    if (mounted && promotion.location != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HotelListScreen(
                            location: promotion.location!,
                            title: 'Khách sạn ${promotion.location}',
                          ),
                        ),
                      );
                    }
                  }
                },
              )
            : null,
      ),
    );
  }

  Widget _buildPromotionPlaceholder(bool isFirst) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isFirst 
              ? [const Color(0xFF4CAF50), const Color(0xFF2E7D32)]
              : [const Color(0xFF2196F3), const Color(0xFF1565C0)],
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer, color: Colors.white, size: 32),
          SizedBox(height: 6),
          Text(
            'Ưu đãi đặc biệt',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedHotelsSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    'Một số khách sạn nổi bật',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HotelListScreen(
                            location: 'Tất cả',
                            title: 'Tất cả khách sạn',
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Xem tất cả',
                      style: TextStyle(
                        color: Color(0xFF8B4513),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 🎬 Agoda-style PageView Carousel
            SizedBox(
              height: 220,
              child: _featuredHotels.isEmpty
                  ? _buildShimmerHotels()
                  : PageView.builder(
                      controller: _hotelsPageController,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() {
                          _currentHotelPage = index;
                        });
                      },
                      itemCount: _featuredHotels.length,
                      itemBuilder: (context, index) {
                        return AnimatedBuilder(
                          animation: _hotelsPageController,
                          builder: (context, child) {
                            double value = 1.0;
                            if (_hotelsPageController.hasClients &&
                                _hotelsPageController.positions.isNotEmpty &&
                                _hotelsPageController.position.haveDimensions) {
                              value = _hotelsPageController.page! - index;
                              value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                            }
                            return Center(
                              child: SizedBox(
                                height: Curves.easeOut.transform(value) * 220,
                                child: child,
                              ),
                            );
                          },
                          child: _buildFeaturedHotelCard(_featuredHotels[index]),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            // Page Dots Indicator
            if (_featuredHotels.isNotEmpty)
              _buildPageIndicator(_currentHotelPage, _featuredHotels.length),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedHotelCard(Hotel hotel) {
    return GestureDetector(
      onTap: () => _navigateToBooking(hotel),
      child: GlassCard(
        blur: 10,
        opacity: 0.25,
        borderRadius: 16,
        padding: EdgeInsets.zero,
        child: Container(
          width: 260,
          height: 200,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hotel Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                height: 120,
                width: double.infinity,
                child: hotel.hinhAnh != null
                    ? Image.network(
                        hotel.fullImageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print('❌ Error loading hotel image: ${hotel.fullImageUrl}');
                          print('   Error: $error');
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.hotel, size: 32, color: Colors.grey),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.hotel, size: 32, color: Colors.grey),
                      ),
              ),
            ),
            
            // Hotel Info
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hotel.ten,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 2),
                  
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            hotel.diaChi ?? 'Địa chỉ không xác định',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Row(
                    children: [
                      // Rating
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < (hotel.soSao ?? 4) ? Icons.star : Icons.star_border,
                              size: 10,
                              color: Colors.amber,
                            );
                          }),
                          const SizedBox(width: 2),
                          Text(
                            '${hotel.diemDanhGiaTrungBinh?.toStringAsFixed(1) ?? "4.5"}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      
                      const Spacer(),
                      
                      // Price
                      Text(
                        'Từ ${hotel.giaTb?.toStringAsFixed(0) ?? "500,000"} ₫',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackHotelCard(int index) {
    final hotels = [
      {
        'name': 'Grand Hotel Saigon', 
        'location': 'Quận 1, TP.HCM', 
        'price': '1,200,000',
        'image': 'http://localhost:5000/images/hotels/saigon_star.jpg'
      },
      {
        'name': 'Hanoi Heritage Hotel', 
        'location': 'Hoàn Kiếm, Hà Nội', 
        'price': '800,000',
        'image': 'http://localhost:5000/images/hotels/hanoi_heritage.jpg'
      },
      {
        'name': 'Da Nang Beach Resort', 
        'location': 'Sơn Trà, Đà Nẵng', 
        'price': '1,500,000',
        'image': 'http://localhost:5000/images/hotels/marble_mountain.jpg'
      },
    ];
    
    final hotel = hotels[index % hotels.length];
    
    return GestureDetector(
      onTap: () => _navigateToFallbackBooking(hotel),
      child: Container(
        width: 260,
        height: 200,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hotel Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                height: 120,
                width: double.infinity,
                child: Image.network(
                  hotel['image'] as String,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.hotel, size: 32, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
            
            // Hotel Info
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hotel['name']!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 2),
                  
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          hotel['location']!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Row(
                    children: [
                      // Rating
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < 4 ? Icons.star : Icons.star_border,
                              size: 10,
                              color: Colors.amber,
                            );
                          }),
                          const SizedBox(width: 2),
                          Text(
                            '4.5',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      
                      const Spacer(),
                      
                      // Price
                      Text(
                        'Từ ${hotel['price']} ₫',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedDestinationsSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    'Địa điểm nổi bật',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HotelSearchScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Xem tất cả',
                      style: TextStyle(
                        color: Color(0xFF8B4513),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 🎬 Agoda-style PageView Carousel for Destinations
            SizedBox(
              height: 220,
              child: _hotDestinations.isEmpty
                  ? _buildShimmerDestinations()
                  : PageView.builder(
                      controller: _destinationsPageController,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() {
                          _currentDestinationPage = index;
                        });
                      },
                      itemCount: _hotDestinations.length,
                      itemBuilder: (context, index) {
                        return AnimatedBuilder(
                          animation: _destinationsPageController,
                          builder: (context, child) {
                            double value = 1.0;
                            if (_destinationsPageController.hasClients &&
                                _destinationsPageController.positions.isNotEmpty &&
                                _destinationsPageController.position.haveDimensions) {
                              value = _destinationsPageController.page! - index;
                              value = (1 - (value.abs() * 0.25)).clamp(0.0, 1.0);
                            }
                            return Center(
                              child: SizedBox(
                                height: Curves.easeOut.transform(value) * 220,
                                width: double.infinity,
                                child: child,
                              ),
                            );
                          },
                          child: _buildFeaturedDestinationCard(_hotDestinations[index]),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            // Page Dots Indicator
            if (_hotDestinations.isNotEmpty)
              _buildPageIndicator(_currentDestinationPage, _hotDestinations.length),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedDestinationCard(Destination destination) {
    return GestureDetector(
      onTap: () => _navigateToDestinationHotels(destination),
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Background Image
              AspectRatio(
                aspectRatio: 16 / 9,
                child: destination.hinhAnh != null
                    ? Image.network(
                        destination.fullImageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print('❌ Error loading destination image: ${destination.fullImageUrl}');
                          print('   Error: $error');
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.location_on, size: 48, color: Colors.grey),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.location_on, size: 48, color: Colors.grey),
                      ),
              ),
              
              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        destination.ten,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 2),
                      
                      Text(
                        destination.quocGia,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Row(
                        children: [
                          Icon(
                            Icons.hotel,
                            size: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${destination.soKhachSan} khách sạn',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 11,
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
      ),
    );
  }

  Widget _buildFallbackDestinationCard(int index) {
    final destinations = [
      {
        'name': 'Hà Nội', 
        'country': 'Việt Nam', 
        'hotels': 150,
        'image': 'http://localhost:5000/images/locations/hoankiem.jpg'
      },
      {
        'name': 'TP. Hồ Chí Minh', 
        'country': 'Việt Nam', 
        'hotels': 200,
        'image': 'http://localhost:5000/images/locations/district1.jpg'
      },
      {
        'name': 'Đà Nẵng', 
        'country': 'Việt Nam', 
        'hotels': 80,
        'image': 'http://localhost:5000/images/locations/sontra.jpg'
      },
      {
        'name': 'Bangkok', 
        'country': 'Thái Lan', 
        'hotels': 300,
        'image': 'http://localhost:5000/images/locations/silom.jpg'
      },
    ];
    
    final destination = destinations[index % destinations.length];
    
    return GestureDetector(
      onTap: () => _navigateToFallbackDestination(destination),
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Background Image
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  destination['image'] as String,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.location_on, size: 48, color: Colors.grey),
                    );
                  },
                ),
              ),
              
              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        destination['name'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 2),
                      
                      Text(
                        destination['country'] as String,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Row(
                        children: [
                          Icon(
                            Icons.hotel,
                            size: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${destination['hotels']} khách sạn',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 11,
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
      ),
    );
  }

  void _navigateToBooking(Hotel hotel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PropertyDetailScreen(
          hotel: hotel,
          checkInDate: DateTime.now().add(const Duration(days: 1)),
          checkOutDate: DateTime.now().add(const Duration(days: 2)),
          guestCount: 1,
        ),
      ),
    );
  }

  void _navigateToFallbackBooking(Map<String, String> hotel) {
    // Parse price from string to double
    final priceString = hotel['price']!.replaceAll(',', '');
    final price = double.tryParse(priceString) ?? 500000;
    
    // Create a mock hotel object for fallback
    final mockHotel = Hotel(
      id: 999, // Mock ID
      ten: hotel['name']!,
      diaChi: hotel['location']!,
      giaTb: price,
      soSao: 4,
      diemDanhGiaTrungBinh: 4.5,
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedBookingScreen(hotel: mockHotel),
      ),
    );
  }

  void _navigateToDestinationHotels(Destination destination) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HotelListScreen(
          location: destination.ten,
          title: 'Khách sạn tại ${destination.ten}',
        ),
      ),
    );
  }

  void _navigateToFallbackDestination(Map<String, dynamic> destination) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HotelListScreen(
          location: destination['name']!,
          title: 'Khách sạn tại ${destination['name']}',
        ),
      ),
    );
  }
  
  // 🎬 Agoda-style Page Indicator (Dots)
  Widget _buildPageIndicator(int currentPage, int itemCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: currentPage == index ? 24 : 8,
          decoration: BoxDecoration(
            color: currentPage == index
                ? const Color(0xFF8B4513)
                : Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
  
  // 🌈 Shimmer Loading Effect
  Widget _buildShimmerHotels() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          width: 260,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              // Shimmer animation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: -1.0, end: 2.0),
                duration: const Duration(milliseconds: 1500),
                builder: (context, value, child) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment(value - 1, 0),
                        end: Alignment(value, 0),
                        colors: [
                          Colors.grey[300]!,
                          Colors.grey[100]!,
                          Colors.grey[300]!,
                        ],
                      ),
                    ),
                  );
                },
                onEnd: () {
                  // Loop animation
                  if (mounted) {
                    setState(() {});
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildShimmerDestinations() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          width: 280,
          height: 180,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: -1.0, end: 2.0),
            duration: const Duration(milliseconds: 1500),
            builder: (context, value, child) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment(value - 1, 0),
                    end: Alignment(value, 0),
                    colors: [
                      Colors.grey[300]!,
                      Colors.grey[100]!,
                      Colors.grey[300]!,
                    ],
                  ),
                ),
              );
            },
            onEnd: () {
              if (mounted) setState(() {});
            },
          ),
        );
      },
    );
  }

}
