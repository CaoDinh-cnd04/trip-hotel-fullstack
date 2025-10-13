import 'package:flutter/material.dart';
import '../../../../data/models/filter_criteria.dart';

class AmenitiesFilter extends StatelessWidget {
  final List<String> selectedAmenities;
  final Function(List<String>) onChanged;

  const AmenitiesFilter({
    Key? key,
    required this.selectedAmenities,
    required this.onChanged,
  }) : super(key: key);

  void _toggleAmenity(String amenity) {
    List<String> newAmenities = List.from(selectedAmenities);
    if (newAmenities.contains(amenity)) {
      newAmenities.remove(amenity);
    } else {
      newAmenities.add(amenity);
    }
    onChanged(newAmenities);
  }

  IconData _getAmenityIcon(String amenity) {
    switch (amenity) {
      case 'WiFi miễn phí':
        return Icons.wifi;
      case 'Bể bơi':
        return Icons.pool;
      case 'Phòng gym':
        return Icons.fitness_center;
      case 'Spa & Massage':
        return Icons.spa;
      case 'Nhà hàng':
        return Icons.restaurant;
      case 'Quầy bar':
        return Icons.local_bar;
      case 'Phòng họp':
        return Icons.meeting_room;
      case 'Dịch vụ phòng 24/7':
        return Icons.room_service;
      case 'Đỗ xe miễn phí':
        return Icons.local_parking;
      case 'Trung tâm thể dục':
        return Icons.sports_gymnastics;
      case 'Dịch vụ giặt ủi':
        return Icons.local_laundry_service;
      case 'Dịch vụ đưa đón sân bay':
        return Icons.airport_shuttle;
      case 'Phòng không hút thuốc':
        return Icons.smoke_free;
      case 'Thang máy':
        return Icons.elevator;
      case 'Điều hòa không khí':
        return Icons.ac_unit;
      case 'Ban công/Sân hiên':
        return Icons.balcony;
      default:
        return Icons.check_circle_outline;
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
                  Icon(Icons.local_offer, color: Colors.green[600], size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Tiện ích',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),

              // Select All / Deselect All
              GestureDetector(
                onTap: () {
                  if (selectedAmenities.length == CommonAmenities.all.length) {
                    onChanged([]);
                  } else {
                    onChanged(List.from(CommonAmenities.all));
                  }
                },
                child: Text(
                  selectedAmenities.length == CommonAmenities.all.length
                      ? 'Bỏ chọn tất cả'
                      : 'Chọn tất cả',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue[600],
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Amenities Grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CommonAmenities.all.map((amenity) {
              final isSelected = selectedAmenities.contains(amenity);

              return GestureDetector(
                onTap: () => _toggleAmenity(amenity),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue[50] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.blue[600]! : Colors.grey[200]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Checkbox
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue[600]
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue[600]!
                                : Colors.grey[400]!,
                            width: 1.5,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 10,
                              )
                            : null,
                      ),

                      const SizedBox(width: 8),

                      // Icon
                      Icon(
                        _getAmenityIcon(amenity),
                        color: isSelected ? Colors.blue[600] : Colors.grey[600],
                        size: 16,
                      ),

                      const SizedBox(width: 6),

                      // Text
                      Flexible(
                        child: Text(
                          amenity,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? Colors.blue[600]
                                : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          // Selected Count
          if (selectedAmenities.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green[600],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đã chọn ${selectedAmenities.length} tiện ích',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.green[600],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => onChanged([]),
                    child: Text(
                      'Xóa',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.green[600],
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Popular Amenities Quick Select
          if (selectedAmenities.isEmpty) ...[
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
              spacing: 6,
              runSpacing: 6,
              children:
                  [
                    'WiFi miễn phí',
                    'Bể bơi',
                    'Phòng gym',
                    'Spa & Massage',
                    'Nhà hàng',
                  ].map((amenity) {
                    return GestureDetector(
                      onTap: () => _toggleAmenity(amenity),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, color: Colors.blue[600], size: 12),
                            const SizedBox(width: 4),
                            Text(
                              amenity,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue[600],
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
