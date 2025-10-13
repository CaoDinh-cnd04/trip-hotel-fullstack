import 'package:flutter/material.dart';

class BottomCTABar extends StatelessWidget {
  final double? lowestPrice;
  final VoidCallback onSelectRoom;

  const BottomCTABar({super.key, this.lowestPrice, required this.onSelectRoom});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: 16 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          // Price display
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (lowestPrice != null) ...[
                  Row(
                    children: [
                      Text(
                        'Từ ',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        _formatPrice(lowestPrice!),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        '/đêm',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Đã bao gồm thuế và phí',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                ] else ...[
                  Text(
                    'Giá đang cập nhật',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Select room button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: onSelectRoom,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                elevation: 2,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hotel, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Chọn Phòng',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M VND';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K VND';
    }
    return '${price.toStringAsFixed(0)} VND';
  }
}
