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
  
  @override
  Widget build(BuildContext context) {
    final isAvailable = room.isAvailable ?? true;
    final statusText = room.statusText;
    final availableCount = room.availableCount;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            const Icon(
              Icons.check_circle,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            availableCount != null && availableCount > 0
                ? 'Còn trống ($availableCount)'
                : statusText,
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