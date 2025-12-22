import 'package:flutter/material.dart';
import '../../data/models/room.dart';

class RoomAvailabilityBadge extends StatelessWidget {
  final Room room;
  final bool showIcon;
  final double fontSize;
  
  const RoomAvailabilityBadge({
    super.key,
    required this.room,
    this.showIcon = true,
    this.fontSize = 12,
  });
  
  /// Xác định màu sắc và text dựa trên số lượng phòng trống
  /// - Xanh: > 2 phòng
  /// - Cam: 1-2 phòng (Gần hết phòng)
  /// - Đỏ: 0 phòng (Hết phòng)
  /// 
  /// Ưu tiên availableCount hơn isAvailable để đảm bảo hiển thị chính xác
  Map<String, dynamic> _getAvailabilityInfo() {
    // Ưu tiên availableCount - nếu có giá trị thì dùng nó
    final availableCount = room.availableCount;
    
    // Nếu availableCount có giá trị, dùng nó để quyết định
    if (availableCount != null) {
      if (availableCount <= 0) {
        return {
          'color': Colors.red,
          'text': 'Hết phòng',
          'icon': Icons.close,
        };
      } else if (availableCount <= 2) {
        return {
          'color': Colors.orange,
          'text': 'Gần hết phòng ($availableCount)',
          'icon': Icons.warning,
        };
      } else {
        return {
          'color': Colors.green,
          'text': 'Còn trống ($availableCount)',
          'icon': Icons.check_circle,
        };
      }
    }
    
    // Nếu không có availableCount, fallback về isAvailable
    final isAvailable = room.isAvailable ?? true;
    if (!isAvailable) {
      return {
        'color': Colors.red,
        'text': 'Hết phòng',
        'icon': Icons.close,
      };
    } else {
      return {
        'color': Colors.green,
        'text': 'Còn phòng',
        'icon': Icons.check_circle,
      };
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final info = _getAvailabilityInfo();
    // Luôn sử dụng text từ _getAvailabilityInfo() để đảm bảo hiển thị đúng
    // Không sử dụng room.statusText vì có thể chứa "Đã đặt"
    final statusText = info['text'] as String;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: info['color'] as Color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              info['icon'] as IconData,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            statusText,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}