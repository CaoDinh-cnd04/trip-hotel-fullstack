import 'package:flutter/material.dart';
import '../../../core/widgets/empty_state_widget.dart';
import 'package:hotel_mobile/data/models/hotel.dart';
import 'package:hotel_mobile/data/services/api_service.dart';
import 'package:hotel_mobile/presentation/widgets/search_result_card.dart';
import 'package:hotel_mobile/presentation/widgets/sticky_filter_bar.dart';
import 'package:hotel_mobile/presentation/widgets/compact_search_header.dart';
import 'package:hotel_mobile/presentation/widgets/enhanced_filter_bottom_sheet.dart';
import 'package:hotel_mobile/presentation/widgets/enhanced_sort_bottom_sheet.dart';
import 'package:hotel_mobile/presentation/widgets/promotion_banner.dart';
import 'package:hotel_mobile/presentation/widgets/edit_search_modal.dart';

class SearchResultsScreen extends StatefulWidget {
  final String location;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guestCount;
  final int roomCount;

  const SearchResultsScreen({
    super.key,
    required this.location,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guestCount,
    required this.roomCount,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  List<Hotel> _hotels = [];
  List<Hotel> _allHotels = []; // Store all hotels for filtering
  bool _isLoading = true;
  String? _error;

  // Search parameters (mutable for editing)
  late String _location;
  late DateTime _checkInDate;
  late DateTime _checkOutDate;
  late int _guestCount;
  late int _roomCount;

  // Filter and sort states
  String _sortBy = 'most_suitable';
  Map<String, dynamic> _filters = {
    'priceRange': const RangeValues(0, 40000000),
    'starRating': <int>{},
    'guestReviewScore': null,
    'propertyTypes': <String>{},
    'areas': <String>{},
    'amenities': <String>{},
    'cancellationPolicy': false,
  };

  @override
  void initState() {
    super.initState();
    // Initialize mutable search parameters
    _location = widget.location;
    _checkInDate = widget.checkInDate;
    _checkOutDate = widget.checkOutDate;
    _guestCount = widget.guestCount;
    _roomCount = widget.roomCount;
    
    _loadSearchResults();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSearchResults() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Simulate API call with search parameters
      await Future.delayed(const Duration(milliseconds: 800));

      // Call API with location search parameter
      final response = await _apiService.getHotels(
        search: _location,
        limit: 100,
      );

      setState(() {
        _allHotels = response.data ?? [];
        _applyFiltersAndSort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFiltersAndSort() {
    // Start with all hotels
    List<Hotel> filtered = List.from(_allHotels);

    // Apply star rating filter
    final starRating = _filters['starRating'] as Set<int>;
    if (starRating.isNotEmpty) {
      filtered = filtered.where((hotel) {
        return hotel.soSao != null && starRating.contains(hotel.soSao!);
      }).toList();
    }

    // Apply price range filter
    final priceRange = _filters['priceRange'] as RangeValues;
    filtered = filtered.where((hotel) {
      final price = hotel.giaTb ?? 1000000;
      return price >= priceRange.start && price <= priceRange.end;
    }).toList();

    // Apply guest review score filter
    final guestReview = _filters['guestReviewScore'];
    if (guestReview != null) {
      filtered = filtered.where((hotel) {
        final rating = hotel.diemDanhGiaTrungBinh ?? 0;
        return rating >= guestReview;
      }).toList();
    }

    // Apply cancellation policy filter
    if (_filters['cancellationPolicy'] == true) {
      // Filter hotels with free cancellation (would need backend support)
      // For now, keep all
    }

    // Apply sorting
    _sortHotels(filtered);

    setState(() {
      _hotels = filtered;
    });
  }

  void _onSortChanged(String sortBy) {
    setState(() {
      _sortBy = sortBy;
      _applyFiltersAndSort();
    });
  }

  void _onFiltersChanged(Map<String, dynamic> filters) {
    setState(() {
      _filters = filters;
      _applyFiltersAndSort();
    });
  }

  void _sortHotels(List<Hotel> hotels) {
    switch (_sortBy) {
      case 'price_low':
        hotels.sort((a, b) => (a.giaTb ?? 0).compareTo(b.giaTb ?? 0));
        break;
      case 'price_high':
        hotels.sort((a, b) => (b.giaTb ?? 0).compareTo(a.giaTb ?? 0));
        break;
      case 'rating':
      case 'most_suitable':
        hotels.sort(
          (a, b) => (b.diemDanhGiaTrungBinh ?? 0).compareTo(
            a.diemDanhGiaTrungBinh ?? 0,
          ),
        );
        break;
      case 'stars_high':
        hotels.sort((a, b) => (b.soSao ?? 0).compareTo(a.soSao ?? 0));
        break;
      case 'limited_promotion':
        // Sort by hotels with promotions (would need backend support)
        // For now, use rating
        hotels.sort(
          (a, b) => (b.diemDanhGiaTrungBinh ?? 0).compareTo(
            a.diemDanhGiaTrungBinh ?? 0,
          ),
        );
        break;
      default:
        // Keep original order
        break;
    }
  }

  void _onSearchUpdated({
    required String location,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required int guestCount,
    required int roomCount,
  }) {
    setState(() {
      _location = location;
      _checkInDate = checkInDate;
      _checkOutDate = checkOutDate;
      _guestCount = guestCount;
      _roomCount = roomCount;
    });
    _loadSearchResults();
  }

  void _showMapView() {
    // Navigate to map view
    Navigator.pushNamed(
      context,
      '/map-view',
      arguments: {
        'hotels': _hotels,
        'location': widget.location,
        'checkInDate': widget.checkInDate,
        'checkOutDate': widget.checkOutDate,
        'guestCount': widget.guestCount,
        'roomCount': widget.roomCount,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Compact Search Header
          CompactSearchHeader(
            location: _location,
            checkInDate: _checkInDate,
            checkOutDate: _checkOutDate,
            guestCount: _guestCount,
            roomCount: _roomCount,
            onTap: _showEditSearchModal,
          ),

          // Sticky Filter Bar
          _buildEnhancedFilterBar(),

          // Results List
          Expanded(child: _buildResultsList()),
        ],
      ),
    );
  }

  Widget _buildEnhancedFilterBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Sort button
          Expanded(
            child: _buildFilterBarButton(
              context: context,
              icon: Icons.sort,
              label: _getSortLabel(_sortBy),
              onTap: _showSortBottomSheet,
            ),
          ),

          const SizedBox(width: 12),

          // Filter button (with badge if filters applied)
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _buildFilterBarButton(
                  context: context,
                  icon: Icons.tune,
                  label: 'Bộ lọc',
                  onTap: _showFilterBottomSheet,
                ),
                if (_hasActiveFilters())
                  Positioned(
                    top: -4,
                    right: -4,
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
                        '${_getActiveFilterCount()}',
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
          ),

          const SizedBox(width: 12),

          // Map button
          Expanded(
            child: _buildFilterBarButton(
              context: context,
              icon: Icons.map,
              label: 'Bản đồ',
              onTap: _showMapView,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBarButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: Colors.grey[700]),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'price_low':
        return 'Giá thấp';
      case 'price_high':
        return 'Giá cao';
      case 'rating':
        return 'Đánh giá';
      case 'stars_high':
        return 'Sao 5-0';
      case 'limited_promotion':
        return 'Khuyến mãi';
      case 'most_suitable':
      default:
        return 'Phù hợp';
    }
  }

  bool _hasActiveFilters() {
    final starRating = _filters['starRating'] as Set<int>;
    final areas = _filters['areas'] as Set<String>;
    final propertyTypes = _filters['propertyTypes'] as Set<String>;
    final amenities = _filters['amenities'] as Set<String>;
    final guestReview = _filters['guestReviewScore'];
    final cancellation = _filters['cancellationPolicy'];

    return starRating.isNotEmpty ||
        areas.isNotEmpty ||
        propertyTypes.isNotEmpty ||
        amenities.isNotEmpty ||
        guestReview != null ||
        cancellation == true;
  }

  int _getActiveFilterCount() {
    int count = 0;
    final starRating = _filters['starRating'] as Set<int>;
    final areas = _filters['areas'] as Set<String>;
    final propertyTypes = _filters['propertyTypes'] as Set<String>;
    final amenities = _filters['amenities'] as Set<String>;
    
    if (starRating.isNotEmpty) count++;
    if (areas.isNotEmpty) count++;
    if (propertyTypes.isNotEmpty) count++;
    if (amenities.isNotEmpty) count++;
    if (_filters['guestReviewScore'] != null) count++;
    if (_filters['cancellationPolicy'] == true) count++;
    
    return count;
  }

  Widget _buildResultsList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF003580)),
            ),
            SizedBox(height: 16),
            Text('Đang tìm kiếm khách sạn...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Có lỗi xảy ra',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSearchResults,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003580),
              ),
              child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_hotels.isEmpty) {
      return EmptySearchResultsWidget(
        onClearFilter: () {
          setState(() {
            _filters = {
              'priceRange': const RangeValues(0, 40000000),
              'starRating': <int>{},
              'guestReviewScore': null,
              'propertyTypes': <String>{},
              'areas': <String>{},
              'amenities': <String>{},
              'cancellationPolicy': false,
            };
            _applyFiltersAndSort();
          });
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSearchResults,
      color: const Color(0xFF003580),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Promotion Banner
          SliverToBoxAdapter(
            child: PromotionBanner(
              onTap: () {
                // Handle promotion activation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Khuyến mãi đã được kích hoạt!'),
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                );
              },
            ),
          ),

          // Results count
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                '$_location (${_hotels.length} khách sạn)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Hotel list
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final hotel = _hotels[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SearchResultCard(
                      hotel: hotel,
                      checkInDate: _checkInDate,
                      checkOutDate: _checkOutDate,
                      guestCount: _guestCount,
                      roomCount: _roomCount,
                      onTap: () => _navigateToHotelDetail(hotel),
                    ),
                  );
                },
                childCount: _hotels.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    // Calculate max price from hotels
    double maxPrice = 40000000;
    if (_allHotels.isNotEmpty) {
      final prices = _allHotels
          .map((h) => h.giaTb ?? 0)
          .where((p) => p > 0)
          .toList();
      if (prices.isNotEmpty) {
        maxPrice = prices.reduce((a, b) => a > b ? a : b);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EnhancedFilterBottomSheet(
        filters: _filters,
        onFiltersChanged: _onFiltersChanged,
        maxPrice: maxPrice,
        totalResults: _hotels.length,
      ),
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => EnhancedSortBottomSheet(
        currentSort: _sortBy,
        onSortChanged: _onSortChanged,
      ),
    );
  }

  void _showEditSearchModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditSearchModal(
        location: _location,
        checkInDate: _checkInDate,
        checkOutDate: _checkOutDate,
        guestCount: _guestCount,
        roomCount: _roomCount,
        onSearchUpdated: _onSearchUpdated,
      ),
    );
  }

  void _navigateToHotelDetail(Hotel hotel) {
    Navigator.pushNamed(
      context,
      '/property-detail',
      arguments: {
        'hotel': hotel,
        'checkInDate': _checkInDate,
        'checkOutDate': _checkOutDate,
        'guestCount': _guestCount,
        'roomCount': _roomCount,
      },
    );
  }
}

// Old FilterBottomSheet removed - now using EnhancedFilterBottomSheet

// Keep old implementation for backwards compatibility (can be removed later)
class FilterBottomSheet extends StatefulWidget {
  final Map<String, dynamic> filters;
  final ValueChanged<Map<String, dynamic>> onFiltersChanged;

  const FilterBottomSheet({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late Map<String, dynamic> _tempFilters;

  @override
  void initState() {
    super.initState();
    _tempFilters = Map.from(widget.filters);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                Text(
                  'Bộ lọc',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: _applyFilters,
                  child: const Text('Áp dụng'),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Filter Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPriceRangeFilter(),
                  const SizedBox(height: 24),
                  _buildStarRatingFilter(),
                  const SizedBox(height: 24),
                  _buildAmenitiesFilter(),
                  const SizedBox(height: 24),
                  _buildCancellationFilter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Khoảng giá',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        RangeSlider(
          values: _tempFilters['priceRange'],
          min: 0,
          max: 5000000,
          divisions: 50,
          labels: RangeLabels(
            '${(_tempFilters['priceRange'].start / 1000).round()}k',
            '${(_tempFilters['priceRange'].end / 1000).round()}k',
          ),
          onChanged: (values) {
            setState(() {
              _tempFilters['priceRange'] = values;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${(_tempFilters['priceRange'].start / 1000).round()}k VNĐ'),
            Text('${(_tempFilters['priceRange'].end / 1000).round()}k VNĐ'),
          ],
        ),
      ],
    );
  }

  Widget _buildStarRatingFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Xếp hạng sao',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [1, 2, 3, 4, 5].map((star) {
            final isSelected = (_tempFilters['starRating'] as Set<int>)
                .contains(star);
            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [Text('$star'), const Icon(Icons.star, size: 16)],
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final starRating = _tempFilters['starRating'] as Set<int>;
                  if (selected) {
                    starRating.add(star);
                  } else {
                    starRating.remove(star);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAmenitiesFilter() {
    final amenities = [
      'WiFi miễn phí',
      'Bể bơi',
      'Phòng gym',
      'Spa',
      'Nhà hàng',
      'Chỗ đậu xe',
      'Máy lạnh',
      'Dịch vụ phòng',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tiện nghi',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: amenities.map((amenity) {
            final isSelected = (_tempFilters['amenities'] as Set<String>)
                .contains(amenity);
            return FilterChip(
              label: Text(amenity),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final amenitiesSet = _tempFilters['amenities'] as Set<String>;
                  if (selected) {
                    amenitiesSet.add(amenity);
                  } else {
                    amenitiesSet.remove(amenity);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCancellationFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chính sách hủy',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          title: const Text('Hủy miễn phí'),
          value: _tempFilters['cancellationPolicy'],
          onChanged: (value) {
            setState(() {
              _tempFilters['cancellationPolicy'] = value ?? false;
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  void _applyFilters() {
    widget.onFiltersChanged(_tempFilters);
    Navigator.pop(context);
  }
}
