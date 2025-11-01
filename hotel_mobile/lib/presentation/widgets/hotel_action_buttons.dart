import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/hotel.dart';
import '../../data/services/saved_items_service.dart';
import '../../core/utils/currency_formatter.dart';

/// Nút Share cho khách sạn
class ShareHotelButton extends StatelessWidget {
  final Hotel hotel;
  final bool compact;

  const ShareHotelButton({
    Key? key,
    required this.hotel,
    this.compact = false,
  }) : super(key: key);

  Future<void> _shareHotel(BuildContext context) async {
    final shareText = '''
🏨 ${hotel.ten}

📍 ${hotel.diaChi ?? 'Địa chỉ: Chưa cập nhật'}
⭐ Đánh giá: ${hotel.diemDanhGiaTrungBinh ?? 4.0}/5
💰 Giá từ: ${hotel.yeuCauCoc?.toStringAsFixed(0) ?? '500,000'} VNĐ/đêm

📱 Đặt phòng ngay trên Hotel Booking App!
''';

    try {
      await Share.share(
        shareText,
        subject: 'Khách sạn ${hotel.ten}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chia sẻ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        icon: const Icon(Icons.share),
        onPressed: () => _shareHotel(context),
        iconSize: 20,
      );
    }

    return ElevatedButton.icon(
      onPressed: () => _shareHotel(context),
      icon: const Icon(Icons.share, size: 18),
      label: const Text('Chia sẻ'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
        side: const BorderSide(color: Colors.blue),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// Nút Save/Bookmark cho khách sạn
class SaveHotelButton extends StatefulWidget {
  final Hotel hotel;
  final bool compact;

  const SaveHotelButton({
    Key? key,
    required this.hotel,
    this.compact = false,
  }) : super(key: key);

  @override
  State<SaveHotelButton> createState() => _SaveHotelButtonState();
}

class _SaveHotelButtonState extends State<SaveHotelButton> {
  final SavedItemsService _savedItemsService = SavedItemsService();
  bool _isSaved = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkSavedStatus();
  }

  Future<void> _checkSavedStatus() async {
    try {
      final response = await _savedItemsService.isSaved(
        widget.hotel.id.toString(),
        'hotel',
      );
      
      if (mounted && response.success && response.data != null) {
        setState(() {
          _isSaved = response.data!;
        });
      }
    } catch (e) {
      print('Error checking saved status: $e');
    }
  }

  Future<void> _toggleSave() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isSaved) {
        // Remove from saved
        final response = await _savedItemsService.removeFromSavedByItemId(
          widget.hotel.id.toString(),
          'hotel',
        );
        
        // Update UI regardless of API result
        setState(() {
          _isSaved = false;
        });
        
        if (mounted && response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.heart_broken, color: Colors.white),
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
        } else if (!response.success) {
          print('⚠️ Xóa failed: ${response.message}');
        }
      } else {
        // Add to saved
        final response = await _savedItemsService.addToSaved(
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
        
        if (response.success) {
          setState(() {
            _isSaved = true;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.white),
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
        } else {
          throw Exception(response.message);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
    if (widget.compact) {
      return IconButton(
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                _isSaved ? Icons.favorite : Icons.favorite_border,
                color: _isSaved ? Colors.red : Colors.white,
              ),
        onPressed: _isLoading ? null : _toggleSave,
        iconSize: 24,
        tooltip: _isSaved ? 'Bỏ lưu' : 'Lưu khách sạn',
      );
    }

    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _toggleSave,
      icon: _isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              _isSaved ? Icons.favorite : Icons.favorite_border,
              size: 18,
            ),
      label: Text(_isSaved ? 'Đã lưu' : 'Lưu'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _isSaved ? Colors.red : Colors.white,
        foregroundColor: _isSaved ? Colors.white : Colors.red,
        side: const BorderSide(color: Colors.red),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// Row chứa cả 2 nút Share và Save
class HotelActionButtons extends StatelessWidget {
  final Hotel hotel;

  const HotelActionButtons({
    Key? key,
    required this.hotel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SaveHotelButton(hotel: hotel),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ShareHotelButton(hotel: hotel),
        ),
      ],
    );
  }
}

/// Floating action button cho Save và Share
class HotelFABActions extends StatelessWidget {
  final Hotel hotel;

  const HotelFABActions({
    Key? key,
    required this.hotel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'save',
          onPressed: () {},
          child: SaveHotelButton(hotel: hotel, compact: true),
          mini: true,
          backgroundColor: Colors.white,
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: 'share',
          onPressed: () {},
          child: ShareHotelButton(hotel: hotel, compact: true),
          mini: true,
          backgroundColor: Colors.white,
        ),
      ],
    );
  }
}

