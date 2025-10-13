import 'package:flutter/material.dart';
import '../../../data/models/filter_criteria.dart';
import 'widgets/price_range_filter.dart';
import 'widgets/star_rating_filter.dart';
import 'widgets/amenities_filter.dart';
import 'widgets/accommodation_type_filter.dart';
import 'widgets/filter_bottom_bar.dart';

class AdvancedFilterScreen extends StatefulWidget {
  final FilterCriteria? initialCriteria;

  const AdvancedFilterScreen({Key? key, this.initialCriteria})
    : super(key: key);

  @override
  State<AdvancedFilterScreen> createState() => _AdvancedFilterScreenState();
}

class _AdvancedFilterScreenState extends State<AdvancedFilterScreen> {
  late FilterCriteria filterCriteria;

  @override
  void initState() {
    super.initState();
    filterCriteria = widget.initialCriteria ?? FilterCriteria();
  }

  void _updateCriteria(FilterCriteria newCriteria) {
    setState(() {
      filterCriteria = newCriteria;
    });
  }

  void _clearAllFilters() {
    setState(() {
      filterCriteria.clear();
    });
  }

  void _applyFilters() {
    Navigator.pop(context, filterCriteria);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Lọc nâng cao',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price Range Filter
                  PriceRangeFilter(
                    minPrice: filterCriteria.minPrice,
                    maxPrice: filterCriteria.maxPrice,
                    onChanged: (min, max) {
                      _updateCriteria(
                        filterCriteria.copyWith(minPrice: min, maxPrice: max),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Star Rating Filter
                  StarRatingFilter(
                    selectedRatings: filterCriteria.selectedStarRatings,
                    onChanged: (ratings) {
                      _updateCriteria(
                        filterCriteria.copyWith(selectedStarRatings: ratings),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Amenities Filter
                  AmenitiesFilter(
                    selectedAmenities: filterCriteria.selectedAmenities,
                    onChanged: (amenities) {
                      _updateCriteria(
                        filterCriteria.copyWith(selectedAmenities: amenities),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Accommodation Type Filter
                  AccommodationTypeFilter(
                    selectedTypes: filterCriteria.selectedAccommodationTypes,
                    onChanged: (types) {
                      _updateCriteria(
                        filterCriteria.copyWith(
                          selectedAccommodationTypes: types,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 100), // Space for bottom bar
                ],
              ),
            ),
          ),

          // Fixed Bottom Bar
          FilterBottomBar(
            onClearAll: _clearAllFilters,
            onApply: _applyFilters,
            resultCount: filterCriteria.estimatedResultCount,
          ),
        ],
      ),
    );
  }
}
