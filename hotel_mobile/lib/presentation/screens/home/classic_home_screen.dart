import 'package:flutter/material.dart';
import '../../../data/models/hotel.dart';
import '../../../data/models/promotion.dart';
import '../../../data/models/destination.dart';
import '../../../data/models/country.dart';
import '../../../data/services/public_api_service.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/home/featured_hotels_section.dart';
import '../../widgets/home/featured_promotions_section.dart';
import '../../widgets/home/hot_destinations_section.dart';
import '../../widgets/home/popular_countries_section.dart';
import '../hotel/hotel_list_screen.dart';
import '../login_screen.dart';
import '../profile/profile_screen.dart';

class ClassicHomeScreen extends StatefulWidget {
  final bool isAuthenticated;
  final VoidCallback? onAuthStateChanged;

  const ClassicHomeScreen({
    Key? key,
    this.isAuthenticated = false,
    this.onAuthStateChanged,
  }) : super(key: key);

  @override
  State<ClassicHomeScreen> createState() => _ClassicHomeScreenState();
}

class _ClassicHomeScreenState extends State<ClassicHomeScreen> {
  final PublicApiService _publicApiService = PublicApiService();
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Hotel> _featuredHotels = [];
  List<Promotion> _featuredPromotions = [];
  List<Destination> _hotDestinations = [];
  List<Country> _popularCountries = [];
  
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHomePageData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHomePageData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('🚀 Bắt đầu tải dữ liệu trang chủ...');
      
      // Load all data in parallel
      final results = await Future.wait([
        _publicApiService.getFeaturedHotels(limit: 6),
        _publicApiService.getFeaturedPromotions(limit: 4),
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

      print('✅ Tải dữ liệu trang chủ thành công');
    } catch (e) {
      print('❌ Lỗi tải dữ liệu trang chủ: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onDestinationTap(Destination destination) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HotelListScreen(
            location: destination.ten,
          ),
        ),
      );
  }

  void _onCountryTap(Country country) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HotelListScreen(
          location: country.ten,
        ),
      ),
    );
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HotelListScreen(
            location: query,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      // App Bar với tài khoản
                      SliverAppBar(
                        expandedHeight: 120,
                        floating: false,
                        pinned: true,
                        backgroundColor: Colors.blue[600],
                        flexibleSpace: FlexibleSpaceBar(
                          title: const Text(
                            'Hotel Booking',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          background: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.blue[600]!,
                                  Colors.blue[800]!,
                                ],
                              ),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(height: 40),
                                  Text(
                                    'Khám phá thế giới',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'Đặt phòng khách sạn tốt nhất',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        actions: [
                          // Tài khoản
                          IconButton(
                            icon: Icon(
                              widget.isAuthenticated ? Icons.account_circle : Icons.login,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: () {
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
                                    builder: (context) => LoginScreen(),
                                  ),
                                );
                              }
                            },
                          ),
                          // Thông báo
                          IconButton(
                            icon: const Icon(Icons.notifications, color: Colors.white),
                            onPressed: () {
                              // TODO: Navigate to notifications
                            },
                          ),
                        ],
                      ),
                      
                      // Search Bar
                      SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          child: Container(
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
                            child: TextField(
                              controller: _searchController,
                              onSubmitted: _onSearchSubmitted,
                              decoration: InputDecoration(
                                hintText: 'Tìm kiếm khách sạn, địa điểm...',
                                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.filter_list, color: Colors.grey),
                                  onPressed: () {
                                    // TODO: Show filter options
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Content
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            // Featured Promotions Section
                            if (_featuredPromotions.isNotEmpty)
                              FeaturedPromotionsSection(
                                promotions: _featuredPromotions,
                                onViewAll: () {
                                  // TODO: Navigate to promotions list
                                },
                              ),
                            
                            const SizedBox(height: 24),
                            
                            // Featured Hotels Section
                            if (_featuredHotels.isNotEmpty)
                              FeaturedHotelsSection(
                                hotels: _featuredHotels,
                                onViewAll: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HotelListScreen(
                                      location: 'Khách sạn nổi bật',
                                    ),
                                  ),
                                );
                                },
                              ),
                            
                            const SizedBox(height: 24),
                            
                            // Hot Destinations Section
                            if (_hotDestinations.isNotEmpty)
                              HotDestinationsSection(
                                destinations: _hotDestinations,
                                onViewAll: () {
                                  // TODO: Navigate to destinations list
                                },
                                onDestinationTap: _onDestinationTap,
                              ),
                            
                            const SizedBox(height: 24),
                            
                            // Popular Countries Section
                            if (_popularCountries.isNotEmpty)
                              PopularCountriesSection(
                                countries: _popularCountries,
                                onViewAll: () {
                                  // TODO: Navigate to countries list
                                },
                                onCountryTap: _onCountryTap,
                              ),
                            
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
