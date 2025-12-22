import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:hotel_mobile/data/models/hotel.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:hotel_mobile/core/widgets/glass_card.dart';
import 'package:hotel_mobile/data/services/discount_service.dart';
import 'favorite_button.dart';

/// Widget hiển thị card khách sạn trong kết quả tìm kiếm
/// Thiết kế theo phong cách Agoda hiện đại: layout ngang (hình bên trái, thông tin bên phải)
/// 
/// Tham số:
/// - hotel: Đối tượng Hotel cần hiển thị
/// - checkInDate: Ngày nhận phòng
/// - checkOutDate: Ngày trả phòng
/// - guestCount: Số lượng khách
/// - roomCount: Số lượng phòng
/// - onTap: Callback khi click vào card
class SearchResultCard extends StatefulWidget {
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
  State<SearchResultCard> createState() => _SearchResultCardState();
}

class _SearchResultCardState extends State<SearchResultCard> {
  final DiscountService _discountService = DiscountService();
  List<Map<String, dynamic>> _availableDiscounts = [];
  bool _isLoadingDiscounts = false;
  Map<String, dynamic>? _bestDiscount;

  @override
  void initState() {
    super.initState();
    _loadAvailableDiscounts();
  }

  Future<void> _loadAvailableDiscounts() async {
    setState(() {
      _isLoadingDiscounts = true;
    });

    try {
      final discounts = await _discountService.getAvailableDiscounts();
      final basePrice = widget.hotel.giaTb ?? 1500000.0;
      final nights = widget.checkOutDate.difference(widget.checkInDate).inDays;
      final totalPrice = basePrice * nights;

      // Tìm mã giảm giá tốt nhất có thể áp dụng
      Map<String, dynamic>? bestDiscount;
      double maxDiscount = 0;

      for (var discount in discounts) {
        final minOrder = discount['minOrderValue']?.toDouble() ?? 0;
        if (totalPrice >= minOrder) {
          double discountAmount = 0;
          if (discount['discountType'] == 'phan_tram') {
            discountAmount = totalPrice * (discount['discountValue']?.toDouble() ?? 0) / 100;
            final maxDiscountValue = discount['maxDiscountValue']?.toDouble();
            if (maxDiscountValue != null && discountAmount > maxDiscountValue) {
              discountAmount = maxDiscountValue;
            }
          } else {
            discountAmount = discount['discountValue']?.toDouble() ?? 0;
          }

          if (discountAmount > maxDiscount) {
            maxDiscount = discountAmount;
            bestDiscount = discount;
            bestDiscount!['calculatedDiscount'] = discountAmount;
          }
        }
      }

      if (mounted) {
        setState(() {
          _availableDiscounts = discounts;
          _bestDiscount = bestDiscount;
          _isLoadingDiscounts = false;
        });
      }
    } catch (e) {
      print('❌ Error loading discounts: $e');
      if (mounted) {
        setState(() {
          _isLoadingDiscounts = false;
        });
      }
    }
  }

  /// ============================================
  /// HÀM BUILD CHÍNH
  /// ============================================
  /// Xây dựng card khách sạn với layout ngang (Agoda style)
  /// Layout: Hình ảnh bên trái (40%), thông tin bên phải (60%)
  @override
  Widget build(BuildContext context) {
    final nights = widget.checkOutDate.difference(widget.checkInDate).inDays;
    final basePrice = widget.hotel.giaTb ?? 1500000.0;
    final totalPrice = basePrice * nights;
    
    // Tính toán giá với discount từ API
    double discountAmount = 0;
    double finalPrice = totalPrice;
    double originalPrice = totalPrice;
    
    if (_bestDiscount != null) {
      discountAmount = _bestDiscount!['calculatedDiscount']?.toDouble() ?? 0;
      finalPrice = totalPrice - discountAmount;
      originalPrice = totalPrice;
    } else {
      // Nếu không có discount từ API, tính discount dựa trên rating
      final rating = widget.hotel.diemDanhGiaTrungBinh ?? 0;
      if (rating >= 8.0) {
        final discountPercent = 10 + (rating - 8.0) * 5; // 10-20%
        discountAmount = totalPrice * discountPercent / 100;
        finalPrice = totalPrice - discountAmount;
        originalPrice = totalPrice;
      }
    }
    
    final discountPercent = originalPrice > 0 
        ? ((discountAmount / originalPrice) * 100).round()
        : 0;

    return GlassCard(
      blur: 15,
      opacity: 0.25,
      borderRadius: 16,
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Tag "Đang được đặt nhiều" hoặc "Agoda Preferred"
              _buildHeaderTag(),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// ============================================
                  /// PHẦN 1: HÌNH ẢNH (BÊN TRÁI) - 40%
                  /// ============================================
                  _buildImageSection(context, discountPercent),

                  /// ============================================
                  /// PHẦN 2: THÔNG TIN (BÊN PHẢI) - 60%
                  /// ============================================
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          /// Tên khách sạn
                          _buildHotelName(),
                          const SizedBox(height: 8),

                          /// Địa chỉ và khoảng cách
                          _buildLocationWithDistance(),
                          const SizedBox(height: 12),

                          /// Rating và đánh giá
                          _buildRatingSection(),
                          const SizedBox(height: 12),

                          /// Discount voucher info (nếu có)
                          if (_bestDiscount != null) ...[
                            _buildDiscountVoucherInfo(discountAmount),
                            const SizedBox(height: 8),
                          ],

                          /// Giá cả - nổi bật
                          _buildPriceSection(
                            finalPrice: finalPrice,
                            originalPrice: originalPrice,
                            discountPercent: discountPercent,
                          ),
                          const SizedBox(height: 12),

                          /// Tags: Bán chạy nhất, Mới sửa sang, etc.
                          _buildFeatureTags(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ============================================
  /// HÀM: _buildHeaderTag
  /// ============================================
  /// Hiển thị tag "Đang được đặt nhiều" hoặc "Agoda Preferred"
  Widget _buildHeaderTag() {
    final isPopular = (widget.hotel.soLuotDanhGia ?? 0) > 100;
    final isHighRating = (widget.hotel.diemDanhGiaTrungBinh ?? 0) >= 8.5;
    
    if (!isPopular && !isHighRating) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isHighRating 
              ? const Color(0xFF003580) // Agoda Preferred
              : Colors.grey.shade200, // Đang được đặt nhiều
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isHighRating)
              const Icon(
                Icons.star,
                size: 12,
                color: Colors.white,
              ),
            if (isHighRating) const SizedBox(width: 4),
            Text(
              isHighRating 
                  ? 'Agoda Preferred'
                  : 'Đang được đặt nhiều',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isHighRating 
                    ? Colors.white
                    : const Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ============================================
  /// HÀM: _buildImageSection
  /// ============================================
  /// Xây dựng phần hình ảnh bên trái với badge số sao và ưu đãi
  Widget _buildImageSection(BuildContext context, int discountPercent) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.4, // 40% chiều rộng
      height: 240, // Chiều cao tối ưu
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        color: const Color(0xFFE8E8E8),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Hình ảnh khách sạn
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: Image.network(
              widget.hotel.fullImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFE8E8E8),
                  child: const Icon(
                    Icons.hotel,
                    size: 48,
                    color: Color(0xFF999999),
                  ),
                );
              },
            ),
          ),

          /// Badge số sao: Góc trên trái (giống Agoda)
          if (widget.hotel.soSao != null && widget.hotel.soSao! > 0)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB800), // Màu vàng Agoda
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.hotel.soSao}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          /// Badge ưu đãi: Góc trên trái (nếu có số sao thì ở dưới)
          Positioned(
            top: widget.hotel.soSao != null && widget.hotel.soSao! > 0 ? 60 : 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE91E63), // Màu hồng đỏ Agoda
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '-$discountPercent%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          /// Nút yêu thích: Góc trên phải
          Positioned(
            top: 12,
            right: 12,
            child: FavoriteButton(
              hotel: widget.hotel,
              iconSize: 20,
              showBackground: true,
            ),
          ),
        ],
      ),
    );
  }

  /// ============================================
  /// HÀM: _buildHotelName
  /// ============================================
  /// Hiển thị tên khách sạn
  Widget _buildHotelName() {
    return Text(
      widget.hotel.ten.toUpperCase(),
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A1A),
        height: 1.3,
        letterSpacing: -0.3,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// ============================================
  /// HÀM: _buildLocationWithDistance
  /// ============================================
  /// Hiển thị địa chỉ khách sạn với khoảng cách (nếu có)
  Widget _buildLocationWithDistance() {
    final location = widget.hotel.tenViTri ?? widget.hotel.diaChi ?? 'Vị trí không xác định';
    // Tính khoảng cách giả lập dựa trên ID (có thể lấy từ API thật)
    final distance = (widget.hotel.id ?? 0) % 10 + 1.5; // 1.5 - 10.5 km
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 14,
              color: Color(0xFF666666),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                location,
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'cách bạn ${distance.toStringAsFixed(1)} km',
          style: const TextStyle(
            color: Color(0xFF999999),
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  /// ============================================
  /// HÀM: _buildRatingSection
  /// ============================================
  /// Hiển thị rating với số sao và text đánh giá
  Widget _buildRatingSection() {
    final rating = widget.hotel.diemDanhGiaTrungBinh ?? 0.0;
    final reviewCount = widget.hotel.soLuotDanhGia ?? 0;

    if (rating == 0) return const SizedBox.shrink();

    String ratingText = 'Tốt';
    if (rating >= 9.0) {
      ratingText = 'Tuyệt vời';
    } else if (rating >= 8.0) {
      ratingText = 'Tuyệt vời';
    } else if (rating >= 7.0) {
      ratingText = 'Tốt';
    } else if (rating >= 6.0) {
      ratingText = 'Khá';
    } else {
      ratingText = 'Trung bình';
    }

    return Row(
      children: [
        // Số sao
        ...List.generate(5, (index) {
          return Icon(
            index < (rating / 2).floor() 
                ? Icons.star 
                : Icons.star_border,
            size: 16,
            color: Colors.orange,
          );
        }),
        const SizedBox(width: 8),
        // Rating số và text
        Text(
          '${rating.toStringAsFixed(1)} $ratingText',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(width: 8),
        // Số review
        if (reviewCount > 0)
          Text(
            '$reviewCount nhận xét',
            style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
      ],
    );
  }

  /// ============================================
  /// HÀM: _buildDiscountVoucherInfo
  /// ============================================
  /// Hiển thị thông tin mã giảm giá đã áp dụng
  Widget _buildDiscountVoucherInfo(double discountAmount) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFF4CAF50),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_offer,
            size: 14,
            color: Color(0xFF4CAF50),
          ),
          const SizedBox(width: 6),
          Text(
            'Đã áp dụng ${currencyFormat.format(discountAmount)}',
            style: const TextStyle(
              color: Color(0xFF2E7D32),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// ============================================
  /// HÀM: _buildFeatureTags
  /// ============================================
  /// Hiển thị các tag như "Bán chạy nhất", "Mới sửa sang", "Đánh giá hàng đầu"
  Widget _buildFeatureTags() {
    final tags = <String>[];
    
    // Logic để xác định tags dựa trên dữ liệu thật
    final reviewCount = widget.hotel.soLuotDanhGia ?? 0;
    final rating = widget.hotel.diemDanhGiaTrungBinh ?? 0;
    
    if (reviewCount > 50) {
      tags.add('Bán chạy nhất');
    }
    if (rating >= 8.5) {
      tags.add('Đánh giá hàng đầu');
    }
    if ((widget.hotel.id ?? 0) % 3 == 0) {
      tags.add('Mới sửa sang');
    }

    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: tags.map((tag) {
        Color bgColor = const Color(0xFF003580);
        if (tag == 'Bán chạy nhất') {
          bgColor = const Color(0xFF003580);
        } else if (tag == 'Đánh giá hàng đầu') {
          bgColor = const Color(0xFF2196F3);
        } else {
          bgColor = const Color(0xFF4CAF50);
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            tag,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// ============================================
  /// HÀM: _buildPriceSection
  /// ============================================
  /// Hiển thị phần giá với ưu đãi (Agoda style)
  Widget _buildPriceSection({
    required double finalPrice,
    required double originalPrice,
    required int discountPercent,
  }) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row: Giá gốc (gạch ngang) và % giảm
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Giá gốc (gạch ngang)
            Text(
              currencyFormat.format(originalPrice),
              style: const TextStyle(
                decoration: TextDecoration.lineThrough,
                decorationColor: Color(0xFF999999),
                color: Color(0xFF999999),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            // % giảm
            if (discountPercent > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '-$discountPercent%',
                  style: const TextStyle(
                    color: Color(0xFFE91E63),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Giá cuối - nổi bật (màu đỏ)
        Text(
          currencyFormat.format(finalPrice),
          style: const TextStyle(
            color: Color(0xFFE91E63), // Màu đỏ Agoda
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            height: 1.0,
          ),
        ),
        // Thông tin mã giảm giá có thể áp dụng
        if (_availableDiscounts.isNotEmpty && _bestDiscount == null) ...[
          const SizedBox(height: 8),
          _buildAvailableDiscountsInfo(),
        ],
      ],
    );
  }

  /// ============================================
  /// HÀM: _buildAvailableDiscountsInfo
  /// ============================================
  /// Hiển thị thông tin các mã giảm giá có thể áp dụng
  Widget _buildAvailableDiscountsInfo() {
    if (_availableDiscounts.isEmpty) return const SizedBox.shrink();

    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    // Lấy mã giảm giá tốt nhất (chưa áp dụng)
    final bestDiscount = _availableDiscounts.first;
    final discountValue = bestDiscount['discountValue']?.toDouble() ?? 0;
    final discountType = bestDiscount['discountType'] ?? 'phan_tram';
    
    String discountText = '';
    if (discountType == 'phan_tram') {
      discountText = 'GIẢM ${(discountValue * 100).toInt()}%';
    } else {
      discountText = 'GIẢM ${currencyFormat.format(discountValue)}';
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFE8E8E8),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_offer_outlined,
            size: 16,
            color: Color(0xFF1A1A1A),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Đã áp dụng Phiếu giảm giá đặc biệt:',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  discountText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
