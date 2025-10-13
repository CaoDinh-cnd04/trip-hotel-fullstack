import 'package:flutter/material.dart';

class StickyFilterBar extends StatelessWidget {
  final String sortBy;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onFilterTap;
  final VoidCallback onMapTap;

  const StickyFilterBar({
    super.key,
    required this.sortBy,
    required this.onSortChanged,
    required this.onFilterTap,
    required this.onMapTap,
  });

  @override
  Widget build(BuildContext context) {
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
            child: _buildActionButton(
              context: context,
              icon: Icons.sort,
              label: _getSortLabel(sortBy),
              onTap: () => _showSortBottomSheet(context),
            ),
          ),

          const SizedBox(width: 12),

          // Filter button
          Expanded(
            child: _buildActionButton(
              context: context,
              icon: Icons.tune,
              label: 'Lọc',
              onTap: onFilterTap,
            ),
          ),

          const SizedBox(width: 12),

          // Map button
          Expanded(
            child: _buildActionButton(
              context: context,
              icon: Icons.map,
              label: 'Bản đồ',
              onTap: onMapTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
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
      case 'distance':
        return 'Khoảng cách';
      default:
        return 'Phổ biến';
    }
  }

  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Sắp xếp theo',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            // Sort options
            ..._buildSortOptions(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSortOptions(BuildContext context) {
    final options = [
      {
        'value': 'popularity',
        'label': 'Phổ biến nhất',
        'desc': 'Được đặt nhiều nhất',
      },
      {
        'value': 'price_low',
        'label': 'Giá thấp nhất',
        'desc': 'Giá từ thấp đến cao',
      },
      {
        'value': 'price_high',
        'label': 'Giá cao nhất',
        'desc': 'Giá từ cao đến thấp',
      },
      {
        'value': 'rating',
        'label': 'Đánh giá cao',
        'desc': 'Điểm đánh giá từ cao đến thấp',
      },
      {
        'value': 'distance',
        'label': 'Khoảng cách',
        'desc': 'Gần trung tâm nhất',
      },
    ];

    return options.map((option) {
      final isSelected = sortBy == option['value'];

      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Radio<String>(
          value: option['value']!,
          groupValue: sortBy,
          onChanged: (value) {
            if (value != null) {
              onSortChanged(value);
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          option['label']!,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          option['desc']!,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        onTap: () {
          onSortChanged(option['value']!);
          Navigator.pop(context);
        },
      );
    }).toList();
  }
}
