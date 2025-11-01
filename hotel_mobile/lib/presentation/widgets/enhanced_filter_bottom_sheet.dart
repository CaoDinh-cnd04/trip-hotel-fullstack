import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EnhancedFilterBottomSheet extends StatefulWidget {
  final Map<String, dynamic> filters;
  final ValueChanged<Map<String, dynamic>> onFiltersChanged;
  final double? maxPrice;
  final int totalResults;

  const EnhancedFilterBottomSheet({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
    this.maxPrice,
    this.totalResults = 0,
  });

  @override
  State<EnhancedFilterBottomSheet> createState() =>
      _EnhancedFilterBottomSheetState();
}

class _EnhancedFilterBottomSheetState extends State<EnhancedFilterBottomSheet> {
  late Map<String, dynamic> _tempFilters;
  final currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _tempFilters = Map.from(widget.filters);
    
    final maxPrice = widget.maxPrice ?? 40000000;
    
    // Initialize filters if not exist
    _tempFilters.putIfAbsent('starRating', () => <int>{});
    
    // Fix priceRange to ensure it's within valid bounds
    final existingPriceRange = _tempFilters['priceRange'] as RangeValues?;
    if (existingPriceRange == null) {
      _tempFilters['priceRange'] = RangeValues(0, maxPrice);
    } else {
      // Clamp existing range to valid bounds
      final clampedStart = existingPriceRange.start.clamp(0.0, maxPrice);
      final clampedEnd = existingPriceRange.end.clamp(0.0, maxPrice);
      // Ensure end >= start
      final finalEnd = clampedEnd >= clampedStart ? clampedEnd : maxPrice;
      _tempFilters['priceRange'] = RangeValues(clampedStart, finalEnd);
    }
    
    _tempFilters.putIfAbsent('guestReviewScore', () => null);
    _tempFilters.putIfAbsent('propertyTypes', () => <String>{});
    _tempFilters.putIfAbsent('areas', () => <String>{});
    _tempFilters.putIfAbsent('amenities', () => <String>{});
    _tempFilters.putIfAbsent('cancellationPolicy', () => false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                  ),
                ),
                const Text(
                  'Chọn lọc',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text('Xóa'),
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
                  _buildStarRatingFilter(),
                  const SizedBox(height: 24),
                  _buildPriceRangeFilter(),
                  const SizedBox(height: 24),
                  _buildGuestReviewFilter(),
                  const SizedBox(height: 24),
                  _buildAreaFilter(),
                  const SizedBox(height: 24),
                  _buildPropertyTypeFilter(),
                  const SizedBox(height: 24),
                  _buildAmenitiesFilter(),
                  const SizedBox(height: 24),
                  _buildCancellationFilter(),
                  const SizedBox(height: 80), // Space for bottom button
                ],
              ),
            ),
          ),

          // Bottom Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003580),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Xem ${widget.totalResults} kết quả',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRatingFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Xếp hạng sao',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [1, 2, 3, 4, 5].map((star) {
            final isSelected =
                (_tempFilters['starRating'] as Set<int>).contains(star);
            return InkWell(
              onTap: () {
                setState(() {
                  final starRating = _tempFilters['starRating'] as Set<int>;
                  if (isSelected) {
                    starRating.remove(star);
                  } else {
                    starRating.add(star);
                  }
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF003580) : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF003580)
                        : Colors.grey[300]!,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$star',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.star,
                      size: 16,
                      color: isSelected ? Colors.white : Colors.amber,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceRangeFilter() {
    final maxPrice = widget.maxPrice ?? 40000000;
    var currentRange = _tempFilters['priceRange'] as RangeValues;
    
    // Ensure range is within valid bounds
    currentRange = RangeValues(
      currentRange.start.clamp(0.0, maxPrice),
      currentRange.end.clamp(0.0, maxPrice),
    );
    
    // Ensure end >= start
    if (currentRange.end < currentRange.start) {
      currentRange = RangeValues(currentRange.start, maxPrice);
    }
    
    // Update tempFilters with clamped values
    _tempFilters['priceRange'] = currentRange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Giá tiền',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${currencyFormat.format(currentRange.start)} - ${currencyFormat.format(currentRange.end)}',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        RangeSlider(
          values: currentRange,
          min: 0,
          max: maxPrice,
          divisions: maxPrice > 0 ? (maxPrice ~/ 100000).clamp(10, 100) : 100, // Đảm bảo divisions hợp lý
          activeColor: const Color(0xFF003580),
          onChanged: (values) {
            setState(() {
              // Clamp values to ensure they stay within bounds
              final clampedValues = RangeValues(
                values.start.clamp(0.0, maxPrice),
                values.end.clamp(0.0, maxPrice),
              );
              // Ensure end >= start
              final finalValues = clampedValues.end >= clampedValues.start 
                  ? clampedValues 
                  : RangeValues(clampedValues.start, maxPrice);
              _tempFilters['priceRange'] = finalValues;
            });
          },
        ),
      ],
    );
  }

  Widget _buildGuestReviewFilter() {
    final reviewScores = [
      {'value': 9.0, 'label': '9+', 'desc': 'Tuyệt vời'},
      {'value': 8.0, 'label': '8+', 'desc': 'Rất tốt'},
      {'value': 7.0, 'label': '7+', 'desc': 'Tốt'},
      {'value': 6.0, 'label': '6+', 'desc': 'Hài lòng'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Đánh giá của khách: Tất cả số điểm',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: reviewScores.map((score) {
            final isSelected =
                _tempFilters['guestReviewScore'] == score['value'];
            return InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _tempFilters['guestReviewScore'] = null;
                  } else {
                    _tempFilters['guestReviewScore'] = score['value'];
                  }
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF003580) : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF003580)
                        : Colors.grey[300]!,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      score['label'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      score['desc'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAreaFilter() {
    final areas = [
      'Trung tâm thành phố',
      'Gần sân bay',
      'Khu du lịch',
      'Bãi biển',
      'Khu phố cổ',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Khu vực',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: areas.map((area) {
            final isSelected =
                (_tempFilters['areas'] as Set<String>).contains(area);
            return CheckboxListTile(
              title: Text(area),
              value: isSelected,
              activeColor: const Color(0xFF003580),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (value) {
                setState(() {
                  final areasSet = _tempFilters['areas'] as Set<String>;
                  if (value == true) {
                    areasSet.add(area);
                  } else {
                    areasSet.remove(area);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPropertyTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Loại hình nơi ở',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(Icons.expand_more, color: Colors.grey[600]),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Khách sạn, resort và các nơi ở khác',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        const Divider(),
        CheckboxListTile(
          title: const Text('Khách sạn'),
          value: (_tempFilters['propertyTypes'] as Set<String>).contains('hotel'),
          activeColor: const Color(0xFF003580),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: (value) {
            setState(() {
              final types = _tempFilters['propertyTypes'] as Set<String>;
              if (value == true) {
                types.add('hotel');
              } else {
                types.remove('hotel');
              }
            });
          },
        ),
        CheckboxListTile(
          title: const Text('Biệt thự nghỉ dưỡng'),
          value: (_tempFilters['propertyTypes'] as Set<String>).contains('villa'),
          activeColor: const Color(0xFF003580),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: (value) {
            setState(() {
              final types = _tempFilters['propertyTypes'] as Set<String>;
              if (value == true) {
                types.add('villa');
              } else {
                types.remove('villa');
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildAmenitiesFilter() {
    final amenities = [
      {'icon': Icons.wifi, 'label': 'WiFi miễn phí'},
      {'icon': Icons.pool, 'label': 'Bể bơi'},
      {'icon': Icons.fitness_center, 'label': 'Phòng gym'},
      {'icon': Icons.spa, 'label': 'Spa'},
      {'icon': Icons.restaurant, 'label': 'Nhà hàng'},
      {'icon': Icons.local_parking, 'label': 'Chỗ đậu xe'},
      {'icon': Icons.ac_unit, 'label': 'Máy lạnh'},
      {'icon': Icons.room_service, 'label': 'Dịch vụ phòng'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tiện nghi',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: amenities.map((amenity) {
            final label = amenity['label'] as String;
            final icon = amenity['icon'] as IconData;
            final isSelected =
                (_tempFilters['amenities'] as Set<String>).contains(label);
            return InkWell(
              onTap: () {
                setState(() {
                  final amenitiesSet = _tempFilters['amenities'] as Set<String>;
                  if (isSelected) {
                    amenitiesSet.remove(label);
                  } else {
                    amenitiesSet.add(label);
                  }
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF003580) : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF003580)
                        : Colors.grey[300]!,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
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
        const Text(
          'Chính sách hủy phòng',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('Hủy miễn phí'),
          subtitle: const Text(
            'Các nơi nghỉ cho phép bạn hủy miễn phí',
            style: TextStyle(fontSize: 12),
          ),
          value: _tempFilters['cancellationPolicy'],
          activeColor: const Color(0xFF003580),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: (value) {
            setState(() {
              _tempFilters['cancellationPolicy'] = value ?? false;
            });
          },
        ),
      ],
    );
  }

  void _resetFilters() {
    final maxPrice = widget.maxPrice ?? 40000000;
    setState(() {
      _tempFilters = {
        'starRating': <int>{},
        'priceRange': RangeValues(0, maxPrice),
        'guestReviewScore': null,
        'propertyTypes': <String>{},
        'areas': <String>{},
        'amenities': <String>{},
        'cancellationPolicy': false,
      };
    });
  }

  void _applyFilters() {
    widget.onFiltersChanged(_tempFilters);
    Navigator.pop(context);
  }
}

