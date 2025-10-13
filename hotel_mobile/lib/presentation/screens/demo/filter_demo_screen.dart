import 'package:flutter/material.dart';
import '../../../data/models/filter_criteria.dart';
import '../filter/advanced_filter_screen.dart';

class FilterDemoScreen extends StatefulWidget {
  const FilterDemoScreen({Key? key}) : super(key: key);

  @override
  State<FilterDemoScreen> createState() => _FilterDemoScreenState();
}

class _FilterDemoScreenState extends State<FilterDemoScreen> {
  FilterCriteria? appliedFilters;

  void _openAdvancedFilter() async {
    final result = await Navigator.push<FilterCriteria>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AdvancedFilterScreen(initialCriteria: appliedFilters),
      ),
    );

    if (result != null) {
      setState(() {
        appliedFilters = result;
      });

      // Show snackbar with applied filters
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              appliedFilters!.hasActiveFilters
                  ? 'Đã áp dụng ${_getFilterSummary()}'
                  : 'Đã xóa tất cả bộ lọc',
            ),
            backgroundColor: appliedFilters!.hasActiveFilters
                ? Colors.green[600]
                : Colors.grey[600],
          ),
        );
      }
    }
  }

  String _getFilterSummary() {
    if (appliedFilters == null || !appliedFilters!.hasActiveFilters) {
      return 'bộ lọc';
    }

    List<String> parts = [];

    if (appliedFilters!.minPrice > 0 || appliedFilters!.maxPrice < 10000000) {
      parts.add('phạm vi giá');
    }

    if (appliedFilters!.selectedStarRatings.isNotEmpty) {
      parts.add('${appliedFilters!.selectedStarRatings.length} xếp hạng sao');
    }

    if (appliedFilters!.selectedAmenities.isNotEmpty) {
      parts.add('${appliedFilters!.selectedAmenities.length} tiện ích');
    }

    if (appliedFilters!.selectedAccommodationTypes.isNotEmpty) {
      parts.add(
        '${appliedFilters!.selectedAccommodationTypes.length} loại hình',
      );
    }

    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Demo Filter Screen',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[600]!, Colors.blue[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trang Lọc Nâng Cao',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tìm kiếm chỗ nghỉ phù hợp với tiêu chí của bạn',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Current Filters
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.filter_list,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Bộ lọc hiện tại',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  if (appliedFilters == null ||
                      !appliedFilters!.hasActiveFilters)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.grey[600],
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Chưa áp dụng bộ lọc nào',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    _buildFilterSummary(),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Filter Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _openAdvancedFilter,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.tune, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Mở Bộ Lọc Nâng Cao',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Mock Search Results
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.search, color: Colors.green[600], size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Kết quả tìm kiếm',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green[600],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tìm thấy ${appliedFilters?.estimatedResultCount ?? 150} chỗ nghỉ phù hợp',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (appliedFilters!.minPrice > 0 ||
            appliedFilters!.maxPrice < 10000000) ...[
          _buildFilterItem(
            'Phạm vi giá',
            '${(appliedFilters!.minPrice / 1000000).toStringAsFixed(1)}M - ${(appliedFilters!.maxPrice / 1000000).toStringAsFixed(1)}M VND',
            Icons.attach_money,
            Colors.blue,
          ),
          const SizedBox(height: 8),
        ],

        if (appliedFilters!.selectedStarRatings.isNotEmpty) ...[
          _buildFilterItem(
            'Xếp hạng sao',
            appliedFilters!.selectedStarRatings.map((r) => '${r}★').join(', '),
            Icons.star,
            Colors.amber,
          ),
          const SizedBox(height: 8),
        ],

        if (appliedFilters!.selectedAmenities.isNotEmpty) ...[
          _buildFilterItem(
            'Tiện ích',
            '${appliedFilters!.selectedAmenities.length} tiện ích được chọn',
            Icons.local_offer,
            Colors.green,
          ),
          const SizedBox(height: 8),
        ],

        if (appliedFilters!.selectedAccommodationTypes.isNotEmpty) ...[
          _buildFilterItem(
            'Loại hình chỗ ở',
            appliedFilters!.selectedAccommodationTypes.take(2).join(', ') +
                (appliedFilters!.selectedAccommodationTypes.length > 2
                    ? '...'
                    : ''),
            Icons.location_city,
            Colors.purple,
          ),
        ],
      ],
    );
  }

  Widget _buildFilterItem(
    String title,
    String value,
    IconData icon,
    MaterialColor color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color[600], size: 16),
        const SizedBox(width: 8),
        Text(
          '$title: ',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color[600],
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
