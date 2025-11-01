import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/models/promotion.dart';
import 'package:hotel_mobile/data/services/api_service.dart';
import 'package:hotel_mobile/data/services/promotion_notification_service.dart';
import 'package:hotel_mobile/presentation/widgets/deals_header.dart';
import 'package:hotel_mobile/presentation/widgets/personal_offers_card.dart';
import 'package:hotel_mobile/presentation/widgets/deals_tab_bar.dart';
import 'package:hotel_mobile/presentation/widgets/promotion_card.dart';
import 'package:hotel_mobile/presentation/widgets/promo_carousel.dart';
import 'package:hotel_mobile/presentation/screens/property/property_detail_screen.dart';
import 'package:hotel_mobile/presentation/screens/hotel/hotel_list_screen.dart';

class DealsScreen extends StatefulWidget {
  const DealsScreen({super.key});

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final PromotionNotificationService _notificationService = PromotionNotificationService();
  late TabController _tabController;

  List<Promotion> _allPromotions = [];
  List<Promotion> _filteredPromotions = [];
  bool _isLoading = true;
  String? _error;
  int _selectedTabIndex = 0;

  // User's actual data
  int _personalPoints = 0;
  String _personalPromoCode = '';
  
  // New promotions notification
  int _newPromotionsCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1); // Start with "Gần tôi" tab
    _selectedTabIndex = 1; // Set initial selected tab to "Gần tôi"
    _tabController.addListener(_handleTabSelection);
    _loadPromotions();
    _loadUserData();
    _checkForNewPromotions();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
      _filterPromotions();
    }
  }

  Future<void> _loadPromotions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Tăng limit lên 50 để lấy hết tất cả khuyến mãi
      final response = await _apiService.getPromotions(active: true, limit: 50);

      print('🎁 Promotions API Response:');
      print('   Success: ${response.success}');
      print('   Data count: ${response.data?.length ?? 0}');
      print('   Message: ${response.message}');

      if (response.success) {
        setState(() {
          _allPromotions = response.data ?? [];
          print('   ✅ All promotions loaded: ${_allPromotions.length}');
          _filterPromotions();
          print('   ✅ Filtered promotions: ${_filteredPromotions.length}');
          _isLoading = false;
        });
      } else {
        print('   ❌ Error: ${response.message}');
        setState(() {
          _error = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('   ❌ Exception: $e');
      setState(() {
        _error = 'Không thể kết nối với máy chủ';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    try {
      // In a real app, you would load user's actual points and promo codes
      // For now, we'll set default values
      setState(() {
        _personalPoints = 0; // Load from user profile
        _personalPromoCode = ''; // Load from user's active promo codes
      });
    } catch (e) {
      // Handle error silently for user data
      print('Error loading user data: $e');
    }
  }

  Future<void> _checkForNewPromotions() async {
    try {
      // Check if we should check for new promotions
      final shouldCheck = await _notificationService.shouldCheckForNewPromotions();
      
      if (!shouldCheck) {
        print('⏭️ Skipping promotion check (checked recently)');
        return;
      }

      print('🔍 Checking for new promotions...');
      final newPromotions = await _notificationService.checkForNewPromotions();
      
      if (newPromotions.isNotEmpty && mounted) {
        setState(() {
          _newPromotionsCount = newPromotions.length;
        });

        // Show notification snackbar
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.celebration, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '🎉 Có ${newPromotions.length} ưu đãi mới! Xem ngay!',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'XEM',
              textColor: Colors.white,
              onPressed: () {
                // Scroll to top to see new promotions
                setState(() {
                  _newPromotionsCount = 0;
                });
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error checking for new promotions: $e');
    }
  }

  void _filterPromotions() {
    final now = DateTime.now();

    setState(() {
      switch (_selectedTabIndex) {
        case 0: // Giờ chót
          _filteredPromotions = _allPromotions.where((promotion) {
            // Filter for promotions ending within 48 hours
            final hoursLeft = promotion.ngayKetThuc.difference(now).inHours;
            return hoursLeft <= 48 && hoursLeft > 0 && promotion.isActive;
          }).toList();
          break;
        case 1: // Gần tôi
          _filteredPromotions = _allPromotions.where((promotion) {
            // Show all active promotions (in real app, filter by location)
            return promotion.isActive && promotion.ngayKetThuc.isAfter(now);
          }).toList();
          break;
        case 2: // Theo điểm đến
          _filteredPromotions = _allPromotions.where((promotion) {
            // Show all active promotions with any discount
            return promotion.isActive && promotion.phanTramGiam > 0;
          }).toList();
          break;
        default:
          _filteredPromotions = _allPromotions.where((p) => p.isActive).toList();
      }

      // Sort by discount percentage (highest first)
      _filteredPromotions.sort(
        (a, b) => b.phanTramGiam.compareTo(a.phanTramGiam),
      );
    });
  }

  String _getTimeLeft(DateTime endDate) {
    final now = DateTime.now();
    final difference = endDate.difference(now);

    if (difference.isNegative) {
      return 'Đã hết hạn';
    }

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;

    if (days > 0) {
      return 'Còn lại: ${days}d ${hours}h';
    } else if (hours > 0) {
      return 'Còn lại: ${hours}h ${minutes}m';
    } else {
      return 'Còn lại: ${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Compact Header
            const DealsHeader(),

            // Scrollable Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadPromotions,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Personal Offers Card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: PersonalOffersCard(
                          points: _personalPoints,
                          promoCode: _personalPromoCode,
                        ),
                      ),
                    ),

                    // Tab Bar
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _StickyTabBarDelegate(
                        child: Container(
                          color: Colors.grey[50],
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: DealsTabBar(
                            tabController: _tabController,
                            tabs: const ['Giờ chót', 'Gần tôi', 'Theo điểm đến'],
                          ),
                        ),
                      ),
                    ),

                    // Content
                    _buildSliverContent(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverContent() {
    if (_isLoading) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF003580)),
              ),
              const SizedBox(height: 16),
              Text(
                'Đang tải ưu đãi...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[400],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Oops! Có lỗi xảy ra',
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadPromotions,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003580),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_filteredPromotions.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_offer_outlined,
                    size: 64,
                    color: Colors.blue[400],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Chưa có ưu đãi nào',
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Hãy quay lại sau để xem ưu đãi mới nhất!',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: _loadPromotions,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Làm mới'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF003580),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        const SizedBox(height: 8),
        
        // Auto-scroll Carousel
        PromoCarousel(
          promotions: _filteredPromotions,
          onPromotionTap: _handlePromotionTap,
        ),
        
        const SizedBox(height: 24),
        
        // All Promotions List
        if (_filteredPromotions.length > 3) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tất cả ưu đãi',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${_filteredPromotions.length} ưu đãi',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            _filteredPromotions.length,
            (index) {
              final promotion = _filteredPromotions[index];
              return Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: PromotionCard(
                  promotion: promotion,
                  timeLeft: _getTimeLeft(promotion.ngayKetThuc),
                  onTap: () => _handlePromotionTap(promotion),
                ),
              );
            },
          ),
        ],
        
        const SizedBox(height: 24),
      ]),
    );
  }

  /// Áp dụng promotion và chuyển sang màn hình khách sạn
  Future<void> _applyPromotion(Promotion promotion) async {
    // Nếu có khachSanId, fetch hotel details và navigate
    if (promotion.khachSanId != null) {
      try {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // Fetch hotel details
        final hotelResponse = await _apiService.getHotelById(promotion.khachSanId!);

        if (mounted) {
          Navigator.pop(context); // Close loading

          if (hotelResponse.success && hotelResponse.data != null) {
            final hotel = hotelResponse.data!;
            
            // Navigate to PropertyDetailScreen để chọn phòng
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

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã áp dụng ưu đãi ${promotion.ten}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          } else {
            // Nếu không tìm thấy hotel, navigate to hotel list với location
            _navigateToHotelListByLocation(promotion);
          }
        }
      } catch (e) {
        print('❌ Error fetching hotel: $e');
        if (mounted) {
          Navigator.pop(context); // Close loading if still open
          _navigateToHotelListByLocation(promotion);
        }
      }
    } else {
      // Không có khachSanId, navigate to hotel list với location
      _navigateToHotelListByLocation(promotion);
    }
  }

  /// Navigate to hotel list với location từ promotion
  void _navigateToHotelListByLocation(Promotion promotion) {
    if (promotion.location != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HotelListScreen(
            location: promotion.location!,
            title: 'Khách sạn tại ${promotion.location}',
          ),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã áp dụng ưu đãi ${promotion.ten}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // Nếu không có location, chỉ show message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã áp dụng ưu đãi ${promotion.ten}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _handlePromotionTap(Promotion promotion) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image Header
              if (promotion.image != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    'http://10.0.2.2:5000/images/hotels/${promotion.image}',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.blue,
                      child: const Center(
                        child: Icon(Icons.local_offer, size: 64, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      promotion.ten,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Location
                    if (promotion.location != null) ...[
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            promotion.location!,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    // Description
                    if (promotion.moTa != null) ...[
                      Text(
                        promotion.moTa!,
                        style: TextStyle(
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Discount Badge
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green[400]!, Colors.green[600]!],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_offer, color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            'Giảm ${promotion.phanTramGiam.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Expiry Date
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Có hiệu lực đến: ${promotion.ngayKetThuc.day}/${promotion.ngayKetThuc.month}/${promotion.ngayKetThuc.year}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Đóng'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              // Đóng dialog trước
                              Navigator.of(context).pop();
                              
                              // Áp dụng promotion và chuyển sang màn hình khách sạn
                              await _applyPromotion(promotion);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF003580),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Áp dụng',
                              style: TextStyle(color: Colors.white),
                            ),
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
}

// Sticky Tab Bar Delegate
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyTabBarDelegate({required this.child});

  @override
  double get minExtent => 60;

  @override
  double get maxExtent => 60;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false;
  }
}
