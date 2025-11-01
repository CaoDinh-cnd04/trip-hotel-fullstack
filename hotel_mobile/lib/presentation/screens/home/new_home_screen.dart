import 'package:flutter/material.dart';
import '../../../data/models/hotel.dart';
import '../../../data/models/promotion.dart';
import '../../../data/models/destination.dart';
import '../../../data/models/country.dart';
import '../../../data/services/public_api_service.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../widgets/home/featured_hotels_section.dart';
import '../../widgets/home/featured_promotions_section.dart';
import '../../widgets/home/hot_destinations_section.dart';
import '../../widgets/home/popular_countries_section.dart';

class NewHomeScreen extends StatefulWidget {
  final bool isAuthenticated;
  final VoidCallback? onAuthStateChanged;

  const NewHomeScreen({
    Key? key,
    this.isAuthenticated = false,
    this.onAuthStateChanged,
  }) : super(key: key);

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen> {
  final PublicApiService _publicApiService = PublicApiService();
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
              ? ErrorStateWidget(
                  title: 'Có lỗi xảy ra',
                  message: _error,
                  onRetry: _loadHomePageData,
                )
              : RefreshIndicator(
                  onRefresh: _loadHomePageData,
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      // App Bar
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
                          IconButton(
                            icon: const Icon(Icons.search, color: Colors.white),
                            onPressed: () {
                              // TODO: Implement search
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.notifications, color: Colors.white),
                            onPressed: () {
                              // TODO: Implement notifications
                            },
                          ),
                        ],
                      ),
                      
                      // Content
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            
                            // Featured Hotels Section
                            if (_featuredHotels.isNotEmpty)
                              FeaturedHotelsSection(
                                hotels: _featuredHotels,
                                onViewAll: () {
                                  // TODO: Navigate to hotels list
                                },
                              ),
                            
                            const SizedBox(height: 24),
                            
                            // Featured Promotions Section
                            if (_featuredPromotions.isNotEmpty)
                              FeaturedPromotionsSection(
                                promotions: _featuredPromotions,
                                onViewAll: () {
                                  // TODO: Navigate to promotions list
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
                              ),
                            
                            const SizedBox(height: 24),
                            
                            // Popular Countries Section
                            if (_popularCountries.isNotEmpty)
                              PopularCountriesSection(
                                countries: _popularCountries,
                                onViewAll: () {
                                  // TODO: Navigate to countries list
                                },
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
