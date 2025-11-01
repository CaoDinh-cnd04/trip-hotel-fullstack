import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/models/hotel.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'favorite_button.dart';

class SearchResultCard extends StatelessWidget {
  final Hotel hotel;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guestCount;
  final int roomCount;
  final VoidCallback? onTap;

  const SearchResultCard({
    super.key,
    required this.hotel,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guestCount,
    required this.roomCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final nights = checkOutDate.difference(checkInDate).inDays;
    final basePrice = hotel.giaTb ?? 1500000.0;
    
    // Calculate discount (15-42% for demo, similar to screenshots)
    final random = math.Random(hotel.id);
    final discountPercent = 15 + random.nextInt(28); // 15-42%
    final originalPrice = basePrice / (1 - discountPercent / 100);
    final finalPrice = basePrice * nights;
    final originalTotalPrice = originalPrice * nights;

    return Card(
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with horizontal scroll
            _buildImageSection(discountPercent),

            // Hotel info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hotel type badge
                  _buildHotelTypeBadge(),

                  const SizedBox(height: 8),

                  // Hotel name and star rating
                  _buildHotelNameAndStars(),

                  const SizedBox(height: 8),

                  // Location
                  _buildLocation(),

                  const SizedBox(height: 12),

                  // Rating chip
                  _buildRatingChip(),

                  const SizedBox(height: 12),

                  // Amenities/Features
                  _buildFeatures(),

                  const SizedBox(height: 16),

                  // Price section
                  _buildPriceSection(
                    finalPrice: finalPrice,
                    originalPrice: originalTotalPrice,
                    nights: nights,
                    discountPercent: discountPercent,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(int discountPercent) {
    // Use hotel's full image URL
    final images = [
      hotel.fullImageUrl,
      'https://via.placeholder.com/300x200?text=Room+1',
      'https://via.placeholder.com/300x200?text=Room+2',
      'https://via.placeholder.com/300x200?text=Amenity',
    ];

    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: images.length,
            itemBuilder: (context, index) {
              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  image: DecorationImage(
                    image: NetworkImage(images[index]),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      // Handle image load error
                    },
                  ),
                ),
                child: images[index].contains('placeholder')
                    ? Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          color: Colors.grey[300],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.hotel,
                            size: 48,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : null,
              );
            },
          ),

          // Discount badge (top left corner)
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: const BoxDecoration(
                color: Color(0xFFE91E63),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Text(
                '-$discountPercent% HÔM NAY',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Favorite button
          Positioned(
            top: 12,
            right: 12,
            child: FavoriteButton(
              hotel: hotel,
              iconSize: 20,
              showBackground: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotelTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF003580).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.apartment,
            size: 14,
            color: const Color(0xFF003580),
          ),
          const SizedBox(width: 4),
          Text(
            'Căn hộ',
            style: TextStyle(
              color: const Color(0xFF003580),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotelNameAndStars() {
    return Row(
      children: [
        Expanded(
          child: Text(
            hotel.ten,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        const SizedBox(width: 8),

        // Star rating
        if (hotel.soSao != null && hotel.soSao! > 0)
          Row(
            children: List.generate(hotel.soSao!, (index) {
              return Icon(Icons.star, size: 16, color: Colors.amber[600]);
            }),
          ),
      ],
    );
  }

  Widget _buildLocation() {
    return Row(
      children: [
        Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            hotel.tenViTri ?? hotel.diaChi ?? 'Vị trí không xác định',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingChip() {
    final rating = hotel.diemDanhGiaTrungBinh ?? 0.0;
    final reviewCount = hotel.soLuotDanhGia ?? 0;

    if (rating == 0) return const SizedBox.shrink();

    String ratingText = 'Tốt';
    Color chipColor = Colors.green;

    if (rating >= 9.0) {
      ratingText = 'Tuyệt vời';
      chipColor = const Color(0xFF003580);
    } else if (rating >= 8.0) {
      ratingText = 'Rất tốt';
      chipColor = const Color(0xFF2196F3);
    } else if (rating >= 7.0) {
      ratingText = 'Tốt';
      chipColor = const Color(0xFF4CAF50);
    } else if (rating >= 6.0) {
      ratingText = 'Khá';
      chipColor = const Color(0xFFFF9800);
    } else {
      ratingText = 'Trung bình';
      chipColor = const Color(0xFFF44336);
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: chipColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          child: Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ratingText,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              if (reviewCount > 0)
                Text(
                  '$reviewCount nhận xét',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatures() {
    // Mock features - replace with actual hotel amenities
    final features = [
      'Hủy miễn phí',
      'Thanh toán tại khách sạn',
      'WiFi miễn phí',
      'Bể bơi',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: features.take(2).map((feature) {
        Color chipColor = Colors.grey[100]!;
        Color textColor = Colors.grey[700]!;

        if (feature == 'Hủy miễn phí') {
          chipColor = Colors.green[50]!;
          textColor = Colors.green[700]!;
        } else if (feature == 'Thanh toán tại khách sạn') {
          chipColor = Colors.blue[50]!;
          textColor = Colors.blue[700]!;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: chipColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: textColor.withOpacity(0.3)),
          ),
          child: Text(
            feature,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceSection({
    required double finalPrice,
    required double originalPrice,
    required int nights,
    required int discountPercent,
  }) {
    return Builder(
      builder: (context) {
        final currencyFormat = NumberFormat.currency(
          locale: 'vi_VN',
          symbol: 'đ',
          decimalDigits: 0,
        );

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Original price (strikethrough)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hủy miễn phí',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tổng $nights đêm',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(originalPrice),
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Colors.grey[500],
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFormat.format(finalPrice),
                            style: const TextStyle(
                              color: Color(0xFFE91E63),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Đã bao gồm thuế và phí',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
