import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/models/hotel.dart';
import 'package:hotel_mobile/data/services/saved_items_service.dart';
import 'package:hotel_mobile/core/utils/currency_formatter.dart';
import 'improved_image_widget.dart';

class HotelCardWithFavorite extends StatefulWidget {
  final Hotel hotel;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const HotelCardWithFavorite({
    super.key,
    required this.hotel,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  State<HotelCardWithFavorite> createState() => _HotelCardWithFavoriteState();
}

class _HotelCardWithFavoriteState extends State<HotelCardWithFavorite> {
  bool _isFavorite = false;
  bool _isLoading = false;
  final SavedItemsService _savedItemsService = SavedItemsService();

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final result = await _savedItemsService.isSaved(
        widget.hotel.id.toString(),
        'hotel',
      );
      if (mounted) {
        setState(() {
          _isFavorite = result.success && (result.data ?? false);
        });
      }
    } catch (e) {
      print('Error checking favorite status: $e');
      if (mounted) {
        setState(() {
          _isFavorite = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isFavorite) {
        // Remove from saved items
        final result = await _savedItemsService.removeFromSavedByItemId(
          widget.hotel.id.toString(),
          'hotel',
        );
        
        // Update UI regardless of API result
        if (mounted) {
          setState(() {
            _isFavorite = false;
          });
          
          if (result.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.heart_broken, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Đã xóa "${widget.hotel.ten}" khỏi danh sách'),
                    ),
                  ],
                ),
                backgroundColor: Colors.grey[700],
                duration: const Duration(seconds: 2),
              ),
            );
          } else {
            print('⚠️ Xóa failed: ${result.message}');
            // Don't show error to user, just update UI
          }
        }
      } else {
        // Add to saved items
        final result = await _savedItemsService.addToSaved(
          itemId: widget.hotel.id.toString(),
          type: 'hotel',
          name: widget.hotel.ten,
          location: widget.hotel.diaChi,
          price: widget.hotel.giaTb != null 
              ? CurrencyFormatter.formatVND(widget.hotel.giaTb!)
              : null,
          imageUrl: widget.hotel.hinhAnh,
          metadata: {
            'diemDanhGia': widget.hotel.diemDanhGiaTrungBinh,
            'soSao': widget.hotel.soSao,
          },
        );
        if (result.success && mounted) {
          setState(() {
            _isFavorite = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('❤️ Đã lưu "${widget.hotel.ten}"'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
              action: SnackBarAction(
                label: 'Xem',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.pushNamed(context, '/favorites');
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: widget.width,
          height: widget.height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hotel Image with Favorite Button
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: Container(
                      width: double.infinity,
                      height: 160,
                      child: HotelImageWidget(
                        imageUrl: widget.hotel.hinhAnh,
                        width: double.infinity,
                        height: 160,
                        onTap: widget.onTap,
                      ),
                    ),
                  ),
                  // Favorite Button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _toggleFavorite,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                ),
                              )
                            : Icon(
                                _isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: _isFavorite ? Colors.red : Colors.grey,
                                size: 20,
                              ),
                      ),
                    ),
                  ),
                  // Star Rating Badge (if available)
                  if (widget.hotel.soSao != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
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
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${widget.hotel.soSao}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              // Hotel Information
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hotel Name
                      Text(
                        widget.hotel.ten,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Location
                      if (widget.hotel.tenViTri != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.hotel.tenViTri!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      // Rating and Reviews
                      if (widget.hotel.diemDanhGiaTrungBinh != null)
                        Row(
                          children: [
                            ...List.generate(
                              5,
                              (index) => Icon(
                                index < (widget.hotel.soSao ?? 0)
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 12,
                                color: Colors.amber,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${widget.hotel.diemDanhGiaTrungBinh!.toStringAsFixed(1)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (widget.hotel.soLuotDanhGia != null)
                              Text(
                                ' (${widget.hotel.soLuotDanhGia})',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                              ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      // Description (if available)
                      if (widget.hotel.moTa != null)
                        Text(
                          widget.hotel.moTa!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
