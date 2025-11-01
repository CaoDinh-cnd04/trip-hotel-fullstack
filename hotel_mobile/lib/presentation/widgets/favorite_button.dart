/**
 * Favorite Button Widget
 * 
 * Nút tim để thêm/xóa khách sạn yêu thích
 * Có thể dùng ở bất kỳ đâu: Home, Search, Hotel Detail, etc.
 */

import 'package:flutter/material.dart';
import '../../data/models/hotel.dart';
import '../../data/services/saved_items_service.dart';
import '../../core/utils/currency_formatter.dart';

class FavoriteButton extends StatefulWidget {
  final Hotel hotel;
  final Color? iconColor;
  final Color? activeColor;
  final double? iconSize;
  final bool showBackground;
  final VoidCallback? onToggle;

  const FavoriteButton({
    Key? key,
    required this.hotel,
    this.iconColor,
    this.activeColor,
    this.iconSize = 20,
    this.showBackground = true,
    this.onToggle,
  }) : super(key: key);

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> 
    with SingleTickerProviderStateMixin {
  final SavedItemsService _savedItemsService = SavedItemsService();
  bool _isFavorite = false;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _checkFavoriteStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking favorite status: $e');
      if (mounted) {
        setState(() {
          _isFavorite = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // Animation
    await _animationController.forward();
    await _animationController.reverse();

    try {
      final result = _isFavorite
          ? await _savedItemsService.removeFromSavedByItemId(
              widget.hotel.id.toString(), 
              'hotel',
            )
          : await _savedItemsService.addToSaved(
              itemId: widget.hotel.id.toString(),
              type: 'hotel',
              name: widget.hotel.ten,
              location: widget.hotel.diaChi,
              price: widget.hotel.giaTb != null 
                  ? CurrencyFormatter.formatVND(widget.hotel.giaTb!)
                  : null,
              imageUrl: widget.hotel.hinhAnh,
              metadata: {
                'soSao': widget.hotel.soSao,
                'diemDanhGia': widget.hotel.diemDanhGiaTrungBinh,
              },
            );

      if (mounted) {
        // Update UI regardless of API result for better UX
        final wasRemove = _isFavorite;
        setState(() {
          if (result.success) {
            _isFavorite = !_isFavorite;
          }
          _isLoading = false;
        });

        // Show snackbar only on success
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isFavorite 
                    ? '❤️ Đã lưu "${widget.hotel.ten}"'
                    : 'Đã xóa "${widget.hotel.ten}" khỏi danh sách',
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: _isFavorite ? Colors.pink : Colors.grey[700],
              behavior: SnackBarBehavior.floating,
              action: _isFavorite
                  ? SnackBarAction(
                      label: 'Xem',
                      textColor: Colors.white,
                      onPressed: () {
                        Navigator.pushNamed(context, '/favorites');
                      },
                    )
                  : null,
            ),
          );
          
          // Call callback nếu có
          widget.onToggle?.call();
        } else {
          // Log error but don't show to user
          print('⚠️ ${wasRemove ? "Xóa" : "Lưu"} failed: ${result.message}');
        }
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.iconSize! + 16,
        height: widget.iconSize! + 16,
        child: Center(
          child: SizedBox(
            width: widget.iconSize,
            height: widget.iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: widget.iconColor ?? Colors.black87,
            ),
          ),
        ),
      );
    }

    final button = ScaleTransition(
      scale: _scaleAnimation,
      child: IconButton(
        icon: Icon(
          _isFavorite ? Icons.favorite : Icons.favorite_border,
          color: _isFavorite 
              ? (widget.activeColor ?? Colors.pink) 
              : (widget.iconColor ?? Colors.black87),
          size: widget.iconSize,
        ),
        onPressed: _toggleFavorite,
        padding: EdgeInsets.all(8),
        constraints: const BoxConstraints(),
        tooltip: _isFavorite ? 'Bỏ yêu thích' : 'Thêm vào yêu thích',
      ),
    );

    if (!widget.showBackground) {
      return button;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: button,
    );
  }
}

