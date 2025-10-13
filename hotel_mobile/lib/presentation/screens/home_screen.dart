import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/models/hotel.dart';
import 'package:hotel_mobile/data/models/promotion.dart';
import 'package:hotel_mobile/data/services/api_service.dart';
import 'package:hotel_mobile/core/services/firebase_auth_service.dart';
import 'package:hotel_mobile/presentation/screens/room/room_detail_screen.dart';
import 'package:hotel_mobile/presentation/screens/hotel/hotel_list_screen.dart';
import 'package:hotel_mobile/presentation/screens/main_navigation_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final PageController _promotionPageController = PageController();
  late TabController _serviceTabController;

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
    _checkLoginStatus();
    _loadHotels();
    _loadPromotions();
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
      } else {
        _currentUser = _authService.currentUser;
        _isLoggedIn = _currentUser != null;
      }
    } catch (e) {
      print('Error checking login status: $e');
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
    _promotionPageController.dispose();
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
        print('Hotels loaded: ${response.data!.length}');
        for (var hotel in response.data!) {
          print(
            'Hotel: ${hotel.ten}, Stars: ${hotel.soSao}, Image: ${hotel.hinhAnh}',
          );
        }

        setState(() {
          _hotels = response.data!;
          _promotionHotels = _hotels
              .where((hotel) => (hotel.soSao ?? 0) >= 4)
              .toList();
          _isLoading = false;
        });
        print('Promotion hotels: ${_promotionHotels.length}');
      } else {
        print('API Error: ${response.message}');
        setState(() {
          _error = response.message.isNotEmpty
              ? response.message
              : 'Không thể tải danh sách khách sạn';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Exception loading hotels: $e');

      if (!mounted) return;

      // Auto retry once for network errors
      if (retryCount < 1 && e.toString().contains('Connection')) {
        await Future.delayed(const Duration(seconds: 2));
        return _loadHotels(retryCount: retryCount + 1);
      }

      setState(() {
        _error = 'Lỗi kết nối: Vui lòng kiểm tra mạng và thử lại';
        _isLoading = false;
      });
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

        // Main search box
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildMainSearchBox(),
          ),
        ),

        // Quick Actions
        SliverToBoxAdapter(child: _buildQuickActions()),

        // Service tabs (Khách sạn, Căn hộ)
        _buildServiceTabs(),

        // Promotions carousel
        SliverToBoxAdapter(child: _buildPromotionsCarousel()),

        // Additional content based on selected service
        _buildServiceContent(),
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
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.hotel,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Hotel App',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),

              // Notification and Avatar
              Row(
                children: [
                  // Notification icon
                  Stack(
                    children: [
                      IconButton(
                        onPressed: () {
                          // Handle notification tap
                        },
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.black87,
                          size: 28,
                        ),
                      ),
                      // Notification badge
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Filter Demo Button
                  IconButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/filter-demo');
                    },
                    icon: const Icon(
                      Icons.tune,
                      color: Colors.black87,
                      size: 28,
                    ),
                    tooltip: 'Filter Demo',
                  ),

                  // Map Demo Button
                  IconButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/map-demo');
                    },
                    icon: const Icon(
                      Icons.map,
                      color: Colors.black87,
                      size: 28,
                    ),
                    tooltip: 'Map Demo',
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
            color: Colors.black.withOpacity(0.1),
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
                    hint,
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
            setState(() {
              _selectedServiceIndex = index;
            });
          },
          tabs: const [
            Tab(text: 'Khách sạn'),
            Tab(text: 'Căn hộ'),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionsCarousel() {
    if (_promotions.isEmpty) {
      return const SizedBox(height: 20);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Ưu đãi đặc biệt',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: PageView.builder(
              controller: _promotionPageController,
              itemCount: _promotions.length,
              itemBuilder: (context, index) {
                final promotion = _promotions[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withOpacity(0.8),
                        Colors.purple.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: promotion.hinhAnh?.isNotEmpty == true
                              ? Image.network(
                                  promotion.hinhAnh!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(color: Colors.grey[300]),
                                )
                              : Container(color: Colors.grey[300]),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.3),
                              Colors.transparent,
                              Colors.black.withOpacity(0.5),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              promotion.ten,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (promotion.moTa?.isNotEmpty == true) ...[
                              const SizedBox(height: 4),
                              Text(
                                promotion.moTa!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
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

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _hotels.length > 5 ? 5 : _hotels.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final hotel = _hotels[index];
        return _buildHotelCard(hotel);
      },
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: hotel.hinhAnh?.isNotEmpty == true
                  ? Image.network(
                      hotel.hinhAnh!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.hotel, size: 50),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.hotel, size: 50),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hotel.ten,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hotel.diaChi?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          hotel.diaChi!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        ...List.generate(5, (starIndex) {
                          return Icon(
                            starIndex < (hotel.soSao ?? 0)
                                ? Icons.star
                                : Icons.star_border,
                            size: 16,
                            color: Colors.amber,
                          );
                        }),
                        const SizedBox(width: 4),
                        Text(
                          '${hotel.soSao ?? 0}/5',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => _viewHotelDetails(hotel),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        'Xem chi tiết',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
                setState(() {
                  _error = null;
                });
                _loadHotels();
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
                      setState(() {
                        _locationController.text = location;
                      });
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
      setState(() {
        _checkInDate = picked;
        if (_checkOutDate != null && !_checkOutDate!.isAfter(picked)) {
          _checkOutDate = picked.add(const Duration(days: 1));
        }
      });
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
      setState(() {
        _checkOutDate = picked;
      });
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
                                setState(() {});
                              }
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text('$_guestCount'),
                      IconButton(
                        onPressed: () {
                          setModalState(() => _guestCount++);
                          setState(() {});
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
                                setState(() {});
                              }
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text('$_roomCount'),
                      IconButton(
                        onPressed: () {
                          setModalState(() => _roomCount++);
                          setState(() {});
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

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chức năng nhanh',
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const HotelListScreen(location: 'Gần bạn'),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionItem(
                  icon: Icons.local_offer,
                  title: 'Khuyến mãi hot',
                  color: Colors.orange,
                  onTap: () {
                    // Navigate to Promotions tab
                    final navigator = Navigator.of(context);
                    navigator.popUntil((route) => route.isFirst);
                    // This will trigger the MainNavigationScreen to switch to Promotions tab
                    // We need to access the parent state somehow
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Chuyển đến tab Khuyến mãi'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionItem(
                  icon: Icons.book_online,
                  title: 'Đặt phòng nhanh',
                  color: Colors.green,
                  onTap: () {
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
                      _showLoginRequiredDialog();
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
                        builder: (context) =>
                            const HotelListScreen(location: 'Đánh giá cao'),
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
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
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

  void _showLoginRequiredDialog() {
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
    }
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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

            // Menu items
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Thông tin cá nhân'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chức năng đang được phát triển'),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.book_online),
              title: const Text('Lịch sử đặt phòng'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to booking management (tab index 2)
                if (context
                        .findAncestorWidgetOfExactType<
                          MainNavigationScreen
                        >() !=
                    null) {
                  // This will be handled by the navigation
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chuyển đến tab Đặt phòng')),
                  );
                }
              },
            ),

            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Cài đặt'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chức năng đang được phát triển'),
                  ),
                );
              },
            ),

            const Divider(),

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
        ),
      ),
    );
  }

  void _showLogoutConfirmation() {
    // Lấy thông tin provider hiện tại
    final providers = _authService.getCurrentProviders();
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

              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );

              // Sign out
              await _authService.signOut();

              // Close loading and refresh state
              Navigator.of(context).pop();
              _checkLoginStatus();

              final successMessage = providers.isNotEmpty
                  ? 'Đã đăng xuất thành công khỏi ${providers.join(", ")}'
                  : 'Đã đăng xuất thành công';

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(successMessage)));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}
