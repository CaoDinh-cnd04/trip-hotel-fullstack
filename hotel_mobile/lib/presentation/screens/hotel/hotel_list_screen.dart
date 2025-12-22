import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/models/hotel.dart';
import 'package:hotel_mobile/data/services/api_service.dart';
import 'package:hotel_mobile/data/services/saved_items_service.dart';
import 'package:hotel_mobile/data/services/applied_promotion_service.dart';
import 'package:hotel_mobile/presentation/screens/property/property_detail_screen.dart';
import 'package:hotel_mobile/presentation/widgets/enhanced_filter_bottom_sheet.dart';
import 'package:hotel_mobile/core/utils/image_url_helper.dart';
import 'package:intl/intl.dart';

class HotelListScreen extends StatefulWidget {
  final String location;
  final String? title;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final int guestCount;
  final int roomCount;

  const HotelListScreen({
    super.key,
    required this.location,
    this.title,
    this.checkInDate,
    this.checkOutDate,
    this.guestCount = 1,
    this.roomCount = 1,
  });

  @override
  State<HotelListScreen> createState() => _HotelListScreenState();
}

class _HotelListScreenState extends State<HotelListScreen> {
  final ApiService _apiService = ApiService();
  final SavedItemsService _savedItemsService = SavedItemsService();
  final AppliedPromotionService _promotionService = AppliedPromotionService();
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  List<Hotel> _hotels = [];
  List<Hotel> _allHotels = [];
  bool _isLoading = true;
  String? _error;
  
  late DateTime _checkInDate;
  late DateTime _checkOutDate;
  
  Map<String, dynamic> _filters = {
    'starRating': <int>{},
    'priceRange': const RangeValues(0, 40000000),
    'guestReviewScore': null,
    'amenities': <String>{},
    'cancellationPolicy': false,
  };
  int _activeFilterCount = 0;
  
  // Favorite status tracking
  final Map<int, bool> _favoriteStatus = {};

  @override
  void initState() {
    super.initState();
    _checkInDate = widget.checkInDate ?? DateTime.now().add(const Duration(days: 1));
    _checkOutDate = widget.checkOutDate ?? DateTime.now().add(const Duration(days: 2));
    
    _apiService.initialize();
    _loadHotels();
    _updateActiveFilterCount();
  }
  
  void _updateActiveFilterCount() {
    int count = 0;
    if ((_filters['starRating'] as Set<int>).isNotEmpty) count++;
    final priceRange = _filters['priceRange'] as RangeValues;
    if (priceRange.start > 0 || priceRange.end < 40000000) count++;
    if (_filters['guestReviewScore'] != null) count++;
    if ((_filters['amenities'] as Set<String>).isNotEmpty) count++;
    if (_filters['cancellationPolicy'] == true) count++;
    setState(() {
      _activeFilterCount = count;
    });
  }

  Future<void> _loadHotels() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String searchQuery = widget.location;
      bool sortByRating = false;

      if (widget.location == 'Tất cả') {
        searchQuery = '';
      } else if (widget.location.contains('đánh giá cao') ||
          widget.location.contains('rating') ||
          widget.location.contains('Đánh giá cao')) {
        searchQuery = '';
        sortByRating = true;
      } else if (widget.location.contains('Gần bạn') ||
          widget.location.contains('gần đây')) {
        searchQuery = 'Thành phố Hồ Chí Minh';
      }

      print('🔍 Searching hotels with query: "$searchQuery"');

      final response = await _apiService.getHotels(
        search: searchQuery,
        limit: 50,
      );

      print('📊 API Response: success=${response.success}, count=${response.data?.length ?? 0}');

      if (response.success && response.data != null && response.data!.isNotEmpty) {
        List<Hotel> hotels = response.data!;

        if (sortByRating) {
          hotels.sort(
            (a, b) => (b.diemDanhGiaTrungBinh ?? 0.0).compareTo(
              a.diemDanhGiaTrungBinh ?? 0.0,
            ),
          );
        }

        double maxPrice = 40000000;
        if (hotels.isNotEmpty) {
          final prices = hotels.map((h) => h.giaTb ?? 0).where((p) => p > 0).toList();
          if (prices.isNotEmpty) {
            maxPrice = prices.reduce((a, b) => a > b ? a : b).toDouble();
          }
          if (maxPrice < 1000000) maxPrice = 40000000;
          
          final currentPriceRange = _filters['priceRange'] as RangeValues;
          if (currentPriceRange.end > maxPrice) {
            _filters['priceRange'] = RangeValues(
              currentPriceRange.start.clamp(0.0, maxPrice),
              maxPrice,
            );
          }
        }
        
        // Load favorite status for all hotels
        await _loadFavoriteStatus(hotels);
        
        setState(() {
          _allHotels = hotels;
          _applyFilters();
          _isLoading = false;
        });
        print('✅ Loaded ${hotels.length} hotels from backend API');
      } else {
        print('⚠️ API returned no data');
        setState(() {
          _allHotels = [];
          _hotels = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading hotels: $e');
        setState(() {
        _error = e.toString();
          _isLoading = false;
      });
    }
  }
  
  Future<void> _loadFavoriteStatus(List<Hotel> hotels) async {
    for (var hotel in hotels) {
      try {
        final result = await _savedItemsService.isSaved(
          hotel.id.toString(),
          'hotel',
        );
        _favoriteStatus[hotel.id] = result.success && (result.data ?? false);
      } catch (e) {
        _favoriteStatus[hotel.id] = false;
      }
    }
  }

  void _applyFilters() {
    List<Hotel> filtered = List.from(_allHotels);
    
    final starRating = _filters['starRating'] as Set<int>;
    if (starRating.isNotEmpty) {
      filtered = filtered.where((hotel) {
        return hotel.soSao != null && starRating.contains(hotel.soSao!);
      }).toList();
    }
    
    final priceRange = _filters['priceRange'] as RangeValues;
    filtered = filtered.where((hotel) {
      final price = hotel.giaTb ?? 1000000;
      return price >= priceRange.start && price <= priceRange.end;
    }).toList();
    
    final guestReview = _filters['guestReviewScore'];
    if (guestReview != null) {
      filtered = filtered.where((hotel) {
        final rating = hotel.diemDanhGiaTrungBinh ?? 0;
        return rating >= guestReview;
      }).toList();
    }
    
    setState(() {
      _hotels = filtered;
    });
    _updateActiveFilterCount();
  }
  
  void _showFilterBottomSheet() {
    double maxPrice = 40000000;
    if (_allHotels.isNotEmpty) {
      final prices = _allHotels.map((h) => h.giaTb ?? 0).where((p) => p > 0).toList();
      if (prices.isNotEmpty) {
        maxPrice = prices.reduce((a, b) => a > b ? a : b).toDouble();
      }
      if (maxPrice < 1000000) maxPrice = 40000000;
    }
    
    final currentPriceRange = _filters['priceRange'] as RangeValues;
    if (currentPriceRange.end > maxPrice) {
      _filters['priceRange'] = RangeValues(
        currentPriceRange.start.clamp(0.0, maxPrice),
        maxPrice,
      );
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EnhancedFilterBottomSheet(
        filters: _filters,
        maxPrice: maxPrice,
        totalResults: _allHotels.length,
        onFiltersChanged: (newFilters) {
          setState(() {
            _filters = newFilters;
            _applyFilters();
          });
        },
      ),
    );
  }

  Future<void> _viewHotelRooms(Hotel hotel) async {
    try {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PropertyDetailScreen(
              hotel: hotel,
              checkInDate: _checkInDate,
              checkOutDate: _checkOutDate,
              guestCount: widget.guestCount,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi mở trang đặt phòng: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _toggleFavorite(Hotel hotel) async {
    final isCurrentlyFavorite = _favoriteStatus[hotel.id] ?? false;
    
    setState(() {
      _favoriteStatus[hotel.id] = !isCurrentlyFavorite;
    });
    
    try {
      if (isCurrentlyFavorite) {
        await _savedItemsService.removeFromSavedByItemId(
          hotel.id.toString(),
          'hotel',
        );
      } else {
        await _savedItemsService.addToSaved(
          itemId: hotel.id.toString(),
          type: 'hotel',
          name: hotel.ten,
          location: hotel.diaChi ?? hotel.tenViTri ?? '',
          price: hotel.giaTb != null 
              ? currencyFormat.format(hotel.giaTb)
              : null,
          imageUrl: hotel.hinhAnh,
          metadata: {
            'diemDanhGia': hotel.diemDanhGiaTrungBinh,
            'soSao': hotel.soSao,
          },
        );
      }
    } catch (e) {
      // Revert on error
      setState(() {
        _favoriteStatus[hotel.id] = isCurrentlyFavorite;
      });
    }
  }

  String _getAppBarTitle() {
    if (widget.title != null) {
      return widget.title!;
    }
    if (widget.location.contains('đánh giá cao') ||
        widget.location.contains('Đánh giá cao')) {
      return 'Khách sạn đánh giá cao';
    } else if (widget.location.contains('Gần bạn') ||
        widget.location.contains('gần đây')) {
      return 'Khách sạn gần đây';
    } else if (widget.location == 'Tất cả khách sạn') {
      return 'Tất cả khách sạn';
    } else {
      return 'Khách sạn tại ${widget.location}';
    }
  }

  void _editLocation() {
    final TextEditingController controller = TextEditingController(text: widget.location);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.location_on, color: Color(0xFF003580)),
            SizedBox(width: 8),
            Text('Thay đổi địa điểm'),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nhập tên địa điểm',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (controller.text.isNotEmpty && controller.text != widget.location) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HotelListScreen(
                      location: controller.text,
                      checkInDate: widget.checkInDate,
                      checkOutDate: widget.checkOutDate,
                      guestCount: widget.guestCount,
                      roomCount: widget.roomCount,
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003580),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Tìm kiếm'),
          ),
        ],
      ),
    );
  }

  void _editDates() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _checkInDate, end: _checkOutDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF003580),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _checkInDate = picked.start;
        _checkOutDate = picked.end;
      });
    }
  }

  void _editGuests() {
    int tempGuestCount = widget.guestCount;
    int tempRoomCount = widget.roomCount;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.people, color: Color(0xFF003580)),
              SizedBox(width: 8),
              Text('Số khách & phòng'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Số khách', style: TextStyle(fontSize: 16)),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (tempGuestCount > 1) {
                            setDialogState(() => tempGuestCount--);
                          }
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                        color: const Color(0xFF003580),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$tempGuestCount',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (tempGuestCount < 10) {
                            setDialogState(() => tempGuestCount++);
                          }
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        color: const Color(0xFF003580),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Số phòng', style: TextStyle(fontSize: 16)),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (tempRoomCount > 1) {
                            setDialogState(() => tempRoomCount--);
                          }
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                        color: const Color(0xFF003580),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$tempRoomCount',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (tempRoomCount < 5) {
                            setDialogState(() => tempRoomCount++);
                          }
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        color: const Color(0xFF003580),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (tempGuestCount != widget.guestCount || tempRoomCount != widget.roomCount) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HotelListScreen(
                        location: widget.location,
                        checkInDate: widget.checkInDate,
                        checkOutDate: widget.checkOutDate,
                        guestCount: tempGuestCount,
                        roomCount: tempRoomCount,
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003580),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Áp dụng'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF003580), // Agoda blue
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.tune, color: Colors.white),
                tooltip: 'Bộ lọc',
                onPressed: _showFilterBottomSheet,
              ),
              if (_activeFilterCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_activeFilterCount',
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
        ],
      ),
      body: Column(
        children: [
          // Agoda-style Search Inputs Section
          Container(
            color: const Color(0xFF003580),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                // Location Input
                _buildSearchInput(
                  icon: Icons.location_on,
                  label: widget.location,
                        onTap: _editLocation,
                ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                    // Date Input
                          Expanded(
                      child: _buildSearchInput(
                        icon: Icons.calendar_today,
                        label: '${DateFormat('dd/MM').format(_checkInDate)} - ${DateFormat('dd/MM').format(_checkOutDate)}',
                        subtitle: '${_checkOutDate.difference(_checkInDate).inDays} đêm',
                              onTap: _editDates,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Guests Input
                    Expanded(
                      child: _buildSearchInput(
                        icon: Icons.people,
                        label: '${widget.roomCount}K • ${widget.guestCount}P',
                            onTap: _editGuests,
                      ),
                    ),
                  ],
                      ),
                    ],
                  ),
                ),
                
          // Results Summary
                Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                  _isLoading 
                      ? 'Đang tìm kiếm...' 
                      : 'Tìm thấy ${_hotels.length} khách sạn',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                if (_activeFilterCount > 0 && !_isLoading)
                  InkWell(
                    onTap: _showFilterBottomSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                        color: const Color(0xFF003580),
                        borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                          const Icon(Icons.filter_alt, size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                '$_activeFilterCount bộ lọc',
                                style: const TextStyle(
                                  color: Colors.white,
                              fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),

          // Hotels List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF003580)),
                        SizedBox(height: 16),
                        Text('Đang tìm kiếm khách sạn...'),
                      ],
                    ),
                  )
                : _error != null
                ? _buildErrorState()
                : _hotels.isEmpty
                ? _buildEmptyState()
                : _buildHotelsList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchInput({
    required IconData icon,
    required String label,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF003580), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.edit, color: Colors.grey[400], size: 18),
          ],
        ),
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
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline, 
                size: 64, 
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Đã xảy ra lỗi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Không thể tải dữ liệu',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadHotels,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003580),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.hotel_outlined, 
                size: 64, 
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Không tìm thấy khách sạn',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hiện chưa có khách sạn nào tại ${widget.location}',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadHotels,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                  style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003580),
                    foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotelsList() {
    return RefreshIndicator(
      onRefresh: _loadHotels,
      color: const Color(0xFF003580),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _hotels.length,
        itemBuilder: (context, index) {
          final hotel = _hotels[index];
          return _buildAgodaStyleHotelCard(hotel);
        },
      ),
    );
  }

  Widget _buildAgodaStyleHotelCard(Hotel hotel) {
    final isFavorite = _favoriteStatus[hotel.id] ?? false;
    final imageUrl = hotel.fullImageUrl;
    final nights = _checkOutDate.difference(_checkInDate).inDays;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _viewHotelRooms(hotel),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / 
                                        loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: const Color(0xFF003580),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.hotel,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.hotel,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
                
                // Star Rating Badge (Top Left)
                if (hotel.soSao != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber[700],
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${hotel.soSao}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Favorite Button (Top Right)
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => _toggleFavorite(hotel),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey[600],
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Content Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hotel Name
                  Text(
                    hotel.ten,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          hotel.diaChi ?? hotel.tenViTri ?? 'Địa chỉ không xác định',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Rating and Reviews
                  if (hotel.diemDanhGiaTrungBinh != null)
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (index) => Icon(
                            index < (hotel.soSao ?? 0)
                                ? Icons.star
                                : Icons.star_border,
                            size: 16,
                            color: Colors.amber[700],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${hotel.diemDanhGiaTrungBinh!.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (hotel.soLuotDanhGia != null && hotel.soLuotDanhGia! > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${hotel.soLuotDanhGia})',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  
                  const SizedBox(height: 8),
                  
                  // Description/Tagline
                  if (hotel.moTa != null && hotel.moTa!.isNotEmpty)
                    Text(
                      hotel.moTa!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  
                  const SizedBox(height: 12),
                  
                  // Price and CTA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildPriceWithPromotion(hotel, nights),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF003580),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Xem phòng',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
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
    );
  }

  /// Hiển thị giá với promotion cho hotel card
  Widget _buildPriceWithPromotion(Hotel hotel, int nights) {
    final originalPrice = hotel.giaTb;
    if (originalPrice == null) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Liên hệ để biết giá',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      );
    }

    final promotion = _promotionService.getAppliedPromotion(hotelId: hotel.id);
    final hasPromotion = promotion != null;
    
    if (hasPromotion) {
      final discountedPrice = _promotionService.calculateDiscountedPrice(originalPrice, hotelId: hotel.id);
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Giá gốc (gạch ngang)
          Text(
            'Từ ${currencyFormat.format(originalPrice)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(height: 2),
          // Giá đã giảm
          Row(
            children: [
              Text(
                'Từ ${currencyFormat.format(discountedPrice)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003580),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Text(
                  '-${promotion!.phanTramGiam.toInt()}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
          Text(
            'cho $nights đêm',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      );
    }
    
    // Không có promotion
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Từ ${currencyFormat.format(originalPrice)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF003580),
          ),
        ),
        Text(
          'cho $nights đêm',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
