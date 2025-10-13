import 'package:flutter/material.dart';
import '../../../../data/models/filter_criteria.dart';

class AccommodationTypeFilter extends StatelessWidget {
  final List<String> selectedTypes;
  final Function(List<String>) onChanged;

  const AccommodationTypeFilter({
    Key? key,
    required this.selectedTypes,
    required this.onChanged,
  }) : super(key: key);

  void _toggleType(String type) {
    List<String> newTypes = List.from(selectedTypes);
    if (newTypes.contains(type)) {
      newTypes.remove(type);
    } else {
      newTypes.add(type);
    }
    onChanged(newTypes);
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Khách sạn':
        return Icons.hotel;
      case 'Resort':
        return Icons.beach_access;
      case 'Villa':
        return Icons.villa;
      case 'Homestay':
        return Icons.home;
      case 'Hostel':
        return Icons.single_bed;
      case 'Căn hộ dịch vụ':
        return Icons.apartment;
      case 'Nhà nghỉ':
        return Icons.bed;
      case 'Motel':
        return Icons.local_hotel;
      case 'Biệt thự':
        return Icons.house;
      case 'Nhà riêng':
        return Icons.home_work;
      default:
        return Icons.location_city;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Khách sạn':
        return Colors.blue;
      case 'Resort':
        return Colors.teal;
      case 'Villa':
        return Colors.purple;
      case 'Homestay':
        return Colors.orange;
      case 'Hostel':
        return Colors.green;
      case 'Căn hộ dịch vụ':
        return Colors.indigo;
      case 'Nhà nghỉ':
        return Colors.pink;
      case 'Motel':
        return Colors.brown;
      case 'Biệt thự':
        return Colors.deepPurple;
      case 'Nhà riêng':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  int _getMockCount(String type) {
    // Mock data - trong thực tế sẽ lấy từ API
    switch (type) {
      case 'Khách sạn':
        return 85;
      case 'Resort':
        return 32;
      case 'Villa':
        return 18;
      case 'Homestay':
        return 24;
      case 'Hostel':
        return 15;
      case 'Căn hộ dịch vụ':
        return 12;
      case 'Nhà nghỉ':
        return 28;
      case 'Motel':
        return 22;
      case 'Biệt thự':
        return 8;
      case 'Nhà riêng':
        return 6;
      default:
        return 0;
    }
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_city,
                    color: Colors.purple[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Loại hình chỗ ở',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),

              // Clear Selection
              if (selectedTypes.isNotEmpty)
                GestureDetector(
                  onTap: () => onChanged([]),
                  child: Text(
                    'Xóa tất cả',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.purple[600],
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Accommodation Types List
          Column(
            children: AccommodationTypes.all.map((type) {
              final isSelected = selectedTypes.contains(type);
              final typeColor = _getTypeColor(type);
              final count = _getMockCount(type);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _toggleType(type),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? typeColor.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? typeColor : Colors.grey[200]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Checkbox
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isSelected ? typeColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isSelected ? typeColor : Colors.grey[400]!,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 14,
                                )
                              : null,
                        ),

                        const SizedBox(width: 12),

                        // Icon with background
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? typeColor.withOpacity(0.2)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getTypeIcon(type),
                            color: isSelected ? typeColor : Colors.grey[600],
                            size: 20,
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Type Name
                        Expanded(
                          child: Text(
                            type,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected ? typeColor : Colors.black87,
                            ),
                          ),
                        ),

                        // Count
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? typeColor.withOpacity(0.2)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? typeColor : Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          // Selected Summary
          if (selectedTypes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.purple[600],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đã chọn ${selectedTypes.length} loại hình chỗ ở',
                      style: TextStyle(fontSize: 12, color: Colors.purple[600]),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Popular Types Quick Select
          if (selectedTypes.isEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Phổ biến:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: ['Khách sạn', 'Resort', 'Villa', 'Homestay'].map((
                type,
              ) {
                final typeColor = _getTypeColor(type);

                return GestureDetector(
                  onTap: () => _toggleType(type),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: typeColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getTypeIcon(type), color: typeColor, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          type,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: typeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
