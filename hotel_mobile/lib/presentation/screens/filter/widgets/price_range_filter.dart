import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PriceRangeFilter extends StatelessWidget {
  final double minPrice;
  final double maxPrice;
  final Function(double, double) onChanged;

  const PriceRangeFilter({
    Key? key,
    required this.minPrice,
    required this.maxPrice,
    required this.onChanged,
  }) : super(key: key);

  String _formatPrice(double price) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '',
      decimalDigits: 0,
    );
    return '${formatter.format(price)} VND';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Icon(Icons.attach_money, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Phạm vi giá',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Price Range Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatPrice(minPrice),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(height: 2, width: 20, color: Colors.grey[300]),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatPrice(maxPrice),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Range Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.blue[600],
              inactiveTrackColor: Colors.grey[300],
              thumbColor: Colors.blue[600],
              overlayColor: Colors.blue[600]?.withOpacity(0.1),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            ),
            child: RangeSlider(
              values: RangeValues(minPrice, maxPrice),
              min: 0,
              max: 10000000,
              divisions: 100,
              onChanged: (values) {
                onChanged(values.start, values.end);
              },
            ),
          ),

          const SizedBox(height: 8),

          // Quick Price Options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PriceQuickOption(
                label: 'Dưới 1 triệu',
                isSelected: minPrice == 0 && maxPrice <= 1000000,
                onTap: () => onChanged(0, 1000000),
              ),
              _PriceQuickOption(
                label: '1-3 triệu',
                isSelected: minPrice >= 1000000 && maxPrice <= 3000000,
                onTap: () => onChanged(1000000, 3000000),
              ),
              _PriceQuickOption(
                label: 'Trên 3 triệu',
                isSelected: minPrice >= 3000000 && maxPrice == 10000000,
                onTap: () => onChanged(3000000, 10000000),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceQuickOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PriceQuickOption({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[600] : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}
