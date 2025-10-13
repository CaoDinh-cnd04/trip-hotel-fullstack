import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/models/hotel.dart';
import 'package:intl/intl.dart';

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
    final basePrice =
        1500000.0; // Mock price - replace with actual pricing logic
    final originalPrice = basePrice * 1.2; // Mock original price
    final finalPrice = basePrice * nights;
    final originalTotalPrice = originalPrice * nights;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with horizontal scroll
            _buildImageSection(),

            // Hotel info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    // Mock images - replace with actual hotel images
    final images = [
      hotel.hinhAnh ?? 'https://via.placeholder.com/300x200?text=Hotel+Image',
      'https://via.placeholder.com/300x200?text=Room+1',
      'https://via.placeholder.com/300x200?text=Room+2',
      'https://via.placeholder.com/300x200?text=Amenity',
    ];

    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Stack(
            children: [
              // Image
              Container(
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
              ),

              // Image counter
              if (images.length > 1)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${index + 1}/${images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

              // Favorite button
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.favorite_border),
                    iconSize: 20,
                    onPressed: () {
                      // Handle favorite toggle
                    },
                  ),
                ),
              ),
            ],
          );
        },
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
      chipColor = Colors.blue[700]!;
    } else if (rating >= 8.0) {
      ratingText = 'Rất tốt';
      chipColor = Colors.green[600]!;
    } else if (rating >= 7.0) {
      ratingText = 'Tốt';
      chipColor = Colors.green;
    } else if (rating >= 6.0) {
      ratingText = 'Khá';
      chipColor = Colors.orange;
    } else {
      ratingText = 'Trung bình';
      chipColor = Colors.red;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: chipColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                ratingText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        if (reviewCount > 0)
          Text(
            '($reviewCount đánh giá)',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
  }) {
    return Builder(
      builder: (context) {
        final currencyFormat = NumberFormat.currency(
          locale: 'vi_VN',
          symbol: 'VNĐ',
          decimalDigits: 0,
        );

        final hasDiscount = originalPrice > finalPrice;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Original price (strikethrough)
            if (hasDiscount)
              Text(
                currencyFormat.format(originalPrice),
                style: TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),

            // Final price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng $nights đêm',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      'Đã bao gồm thuế',
                      style: TextStyle(color: Colors.grey[500], fontSize: 10),
                    ),
                  ],
                ),

                Text(
                  currencyFormat.format(finalPrice),
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
