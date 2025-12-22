import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:hotel_mobile/core/widgets/glass_card.dart';

/// Widget header hiển thị thông tin tìm kiếm có thể chỉnh sửa
/// Thiết kế theo phong cách Agoda: header màu xanh, các input field riêng biệt
/// 
/// Tham số:
/// - location: Địa điểm tìm kiếm
/// - checkInDate: Ngày nhận phòng
/// - checkOutDate: Ngày trả phòng
/// - guestCount: Số lượng khách
/// - roomCount: Số lượng phòng
/// - onTap: Callback khi click để chỉnh sửa tìm kiếm
class CompactSearchHeader extends StatelessWidget {
  final String location;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guestCount;
  final int roomCount;
  final VoidCallback? onTap;

  const CompactSearchHeader({
    super.key,
    required this.location,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guestCount,
    required this.roomCount,
    this.onTap,
  });

  /// ============================================
  /// HÀM BUILD CHÍNH
  /// ============================================
  /// Xây dựng header với màu xanh Agoda (#003580) và các input field riêng biệt
  /// Layout:
  /// - AppBar: Màu xanh, nút back, title, icon notification
  /// - Search Section: 3 input fields (Location, Date, Guests) trong card trắng
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM');
    final nights = checkOutDate.difference(checkInDate).inDays;

    return Container(
      color: const Color(0xFF003580), // Màu xanh đậm Agoda
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            /// ============================================
            /// PHẦN 1: APP BAR
            /// ============================================
            /// App bar với nút back, title, và notification icon
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Nút back: Màu trắng
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 18,
                      color: Colors.white,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  
                  // Title: "Khách sạn tại [Location]"
                  Expanded(
                    child: Text(
                      'Khách sạn tại $location',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Notification icon (có thể có badge số)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        // Badge số (nếu có notification)
                        // Positioned(
                        //   top: -4,
                        //   right: -4,
                        //   child: Container(
                        //     width: 16,
                        //     height: 16,
                        //     decoration: const BoxDecoration(
                        //       color: Colors.red,
                        //       shape: BoxShape.circle,
                        //     ),
                        //     child: const Center(
                        //       child: Text(
                        //         '1',
                        //         style: TextStyle(
                        //           color: Colors.white,
                        //           fontSize: 10,
                        //           fontWeight: FontWeight.bold,
                        //         ),
                        //       ),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// ============================================
            /// PHẦN 2: SEARCH INPUT FIELDS (Glass morphism)
            /// ============================================
            /// Container với glass effect và các input field riêng biệt
            /// Layout: Location (full width), Date và Guests (2 cột)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: GlassCard(
                blur: 20,
                opacity: 0.3,
                borderRadius: 16,
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                onTap: onTap, // Click để chỉnh sửa
                child: Column(
                  children: [
                    /// Input 1: Location (full width)
                    _buildInputField(
                      icon: Icons.location_on_outlined,
                      title: 'Địa điểm',
                      value: location,
                      iconColor: const Color(0xFF003580),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    /// Input 2 & 3: Date và Guests (2 cột)
                    Row(
                      children: [
                        // Date input (chiếm 2/3 chiều rộng)
                        Expanded(
                          flex: 2,
                          child: _buildInputField(
                            icon: Icons.calendar_today_outlined,
                            title: 'Nhận phòng - Trả phòng',
                            value: '${dateFormat.format(checkInDate)} - ${dateFormat.format(checkOutDate)} • $nights đêm',
                            iconColor: const Color(0xFF003580),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Guests input (chiếm 1/3 chiều rộng)
                        Expanded(
                          flex: 1,
                          child: _buildInputField(
                            icon: Icons.people_outline,
                            title: 'Khách',
                            value: '$guestCount khách • $roomCount phòng',
                            iconColor: const Color(0xFF003580),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ============================================
  /// HÀM HELPER: _buildInputField
  /// ============================================
  /// Xây dựng một input field với icon, title và value
  /// 
  /// Tham số:
  /// - icon: Icon hiển thị bên trái
  /// - title: Label phía trên
  /// - value: Giá trị hiển thị
  /// - iconColor: Màu của icon
  /// 
  /// Trả về: Container với Row chứa icon và Column chứa title + value
  Widget _buildInputField({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF), // Nền xanh nhạt (Agoda style)
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFE0E8F0), // Viền xanh nhạt
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon container
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 12),
          // Title và value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title (label)
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Value
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Icon edit (pencil)
          const Icon(
            Icons.edit_outlined,
            size: 16,
            color: Color(0xFF999999),
          ),
        ],
      ),
    );
  }
}
