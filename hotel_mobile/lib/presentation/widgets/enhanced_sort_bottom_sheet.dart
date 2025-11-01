import 'package:flutter/material.dart';

class EnhancedSortBottomSheet extends StatelessWidget {
  final String currentSort;
  final ValueChanged<String> onSortChanged;

  const EnhancedSortBottomSheet({
    super.key,
    required this.currentSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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

            const SizedBox(height: 20),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Sắp xếp theo:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Sort options
            ..._buildSortOptions(context),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSortOptions(BuildContext context) {
    final options = [
      {
        'value': 'most_suitable',
        'label': 'Phù hợp nhất',
        'icon': Icons.recommend,
      },
      {
        'value': 'price_low',
        'label': 'Giá thấp nhất',
        'icon': Icons.arrow_downward,
      },
      {
        'value': 'price_high',
        'label': 'Giá cao nhất',
        'icon': Icons.arrow_upward,
      },
      {
        'value': 'limited_promotion',
        'label': 'Khuyến mại có thời hạn',
        'icon': Icons.local_offer,
      },
      {
        'value': 'stars_high',
        'label': 'Sao (5 đến 0)',
        'icon': Icons.star,
      },
      {
        'value': 'rating',
        'label': 'Được đánh giá nhiều nhất',
        'icon': Icons.rate_review,
      },
    ];

    return options.map((option) {
      final isSelected = currentSort == option['value'];

      return InkWell(
        onTap: () {
          onSortChanged(option['value'] as String);
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF003580).withOpacity(0.1) : null,
            border: Border(
              left: BorderSide(
                color: isSelected ? const Color(0xFF003580) : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                option['icon'] as IconData,
                color: isSelected ? const Color(0xFF003580) : Colors.grey[600],
                size: 22,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  option['label'] as String,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? const Color(0xFF003580) : Colors.black87,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF003580),
                  size: 22,
                ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

