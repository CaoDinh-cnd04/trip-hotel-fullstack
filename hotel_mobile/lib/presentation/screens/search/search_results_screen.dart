import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/models/hotel.dart';
import 'package:hotel_mobile/data/services/api_service.dart';
import 'package:hotel_mobile/presentation/widgets/search_result_card.dart';
import 'package:hotel_mobile/presentation/widgets/sticky_filter_bar.dart';
import 'package:hotel_mobile/presentation/widgets/compact_search_header.dart';

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
  bool _isLoading = true;
  String? _error;

  // Filter and sort states
  String _sortBy = 'popularity'; // popularity, price_low, price_high, rating
  Map<String, dynamic> _filters = {
    'priceRange': RangeValues(0, 5000000),
    'starRating': <int>{},
    'amenities': <String>{},
    'cancellationPolicy': false,
  };

  @override
  void initState() {
    super.initState();
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

      // Mock data - replace with actual API call
      final response = await _apiService.getHotels();

      setState(() {
        _hotels = response.data ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSortChanged(String sortBy) {
    setState(() {
      _sortBy = sortBy;
      _sortHotels();
    });
  }

  void _onFiltersChanged(Map<String, dynamic> filters) {
    setState(() {
      _filters = filters;
      _applyFilters();
    });
  }

  void _sortHotels() {
    switch (_sortBy) {
      case 'price_low':
        // Mock sorting by price - replace with actual price field when available
        _hotels.sort((a, b) => a.id.compareTo(b.id));
        break;
      case 'price_high':
        // Mock sorting by price - replace with actual price field when available
        _hotels.sort((a, b) => b.id.compareTo(a.id));
        break;
      case 'rating':
        _hotels.sort(
          (a, b) => (b.diemDanhGiaTrungBinh ?? 0).compareTo(
            a.diemDanhGiaTrungBinh ?? 0,
          ),
        );
        break;
      default: // popularity
        // Keep original order or implement popularity logic
        break;
    }
  }

  void _applyFilters() {
    // Implement filter logic here
    // This would typically involve calling the API with filter parameters
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
            location: widget.location,
            checkInDate: widget.checkInDate,
            checkOutDate: widget.checkOutDate,
            guestCount: widget.guestCount,
            roomCount: widget.roomCount,
            onTap: () => Navigator.pop(context),
          ),

          // Sticky Filter Bar
          StickyFilterBar(
            sortBy: _sortBy,
            onSortChanged: _onSortChanged,
            onFilterTap: () => _showFilterBottomSheet(),
            onMapTap: _showMapView,
          ),

          // Results List
          Expanded(child: _buildResultsList()),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
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
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_hotels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy khách sạn',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Thử thay đổi tiêu chí tìm kiếm',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSearchResults,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _hotels.length,
        itemBuilder: (context, index) {
          final hotel = _hotels[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SearchResultCard(
              hotel: hotel,
              checkInDate: widget.checkInDate,
              checkOutDate: widget.checkOutDate,
              guestCount: widget.guestCount,
              roomCount: widget.roomCount,
              onTap: () => _navigateToHotelDetail(hotel),
            ),
          );
        },
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        filters: _filters,
        onFiltersChanged: _onFiltersChanged,
      ),
    );
  }

  void _navigateToHotelDetail(Hotel hotel) {
    Navigator.pushNamed(
      context,
      '/property-detail',
      arguments: {
        'hotel': hotel,
        'checkInDate': widget.checkInDate,
        'checkOutDate': widget.checkOutDate,
        'guestCount': widget.guestCount,
        'roomCount': widget.roomCount,
      },
    );
  }
}

// Filter Bottom Sheet Widget
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
