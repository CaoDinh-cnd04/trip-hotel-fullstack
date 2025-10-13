import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/models/hotel.dart';

class AmenitiesSection extends StatelessWidget {
  final Hotel hotel;

  const AmenitiesSection({super.key, required this.hotel});

  // Mock amenities data - in real app, this would come from the hotel model or API
  static const List<AmenityItem> _availableAmenities = [
    AmenityItem(icon: Icons.wifi, name: 'WiFi miễn phí', color: Colors.blue),
    AmenityItem(icon: Icons.pool, name: 'Hồ bơi', color: Colors.cyan),
    AmenityItem(icon: Icons.fitness_center, name: 'Gym', color: Colors.orange),
    AmenityItem(icon: Icons.restaurant, name: 'Nhà hàng', color: Colors.red),
    AmenityItem(icon: Icons.spa, name: 'Spa', color: Colors.pink),
    AmenityItem(
      icon: Icons.local_parking,
      name: 'Bãi đỗ xe',
      color: Colors.grey,
    ),
    AmenityItem(icon: Icons.pets, name: 'Thú cưng', color: Colors.brown),
    AmenityItem(
      icon: Icons.room_service,
      name: 'Dịch vụ phòng',
      color: Colors.purple,
    ),
    AmenityItem(
      icon: Icons.business_center,
      name: 'Trung tâm kinh doanh',
      color: Colors.indigo,
    ),
    AmenityItem(
      icon: Icons.child_friendly,
      name: 'Thân thiện với trẻ em',
      color: Colors.green,
    ),
    AmenityItem(icon: Icons.air, name: 'Điều hòa', color: Colors.lightBlue),
    AmenityItem(
      icon: Icons.local_laundry_service,
      name: 'Giặt là',
      color: Colors.teal,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // For demo, show random amenities. In real app, this would be based on hotel data
    final displayedAmenities = _availableAmenities.take(8).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tiện ích',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Horizontal scrollable amenities
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount:
                  displayedAmenities.length + 1, // +1 for "View all" button
              itemBuilder: (context, index) {
                if (index == displayedAmenities.length) {
                  return _buildViewAllAmenities(context);
                }

                final amenity = displayedAmenities[index];
                return _buildAmenityItem(amenity);
              },
            ),
          ),

          const SizedBox(height: 16),

          // Popular amenities chips
          const Text(
            'Tiện ích phổ biến',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: displayedAmenities.take(6).map((amenity) {
              return _buildAmenityChip(amenity);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityItem(AmenityItem amenity) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: amenity.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: amenity.color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(amenity.icon, color: amenity.color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            amenity.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildViewAllAmenities(BuildContext context) {
    return Container(
      width: 80,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showAllAmenities(context),
                borderRadius: BorderRadius.circular(16),
                child: const Icon(
                  Icons.more_horiz,
                  color: Colors.grey,
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Xem tất cả',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityChip(AmenityItem amenity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(amenity.icon, size: 16, color: amenity.color),
          const SizedBox(width: 6),
          Text(
            amenity.name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _showAllAmenities(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AllAmenitiesSheet(amenities: _availableAmenities),
    );
  }
}

class AmenityItem {
  final IconData icon;
  final String name;
  final Color color;

  const AmenityItem({
    required this.icon,
    required this.name,
    required this.color,
  });
}

class _AllAmenitiesSheet extends StatelessWidget {
  final List<AmenityItem> amenities;

  const _AllAmenitiesSheet({required this.amenities});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Tất cả tiện ích',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Amenities grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: amenities.length,
              itemBuilder: (context, index) {
                final amenity = amenities[index];
                return Container(
                  decoration: BoxDecoration(
                    color: amenity.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: amenity.color.withOpacity(0.2)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(amenity.icon, color: amenity.color, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        amenity.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
