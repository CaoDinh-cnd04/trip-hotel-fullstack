import 'package:flutter/material.dart';

/// Widget hiển thị banner khuyến mãi
/// Thiết kế theo phong cách Agoda: màu sắc đơn giản, không gradient
/// 
/// Tham số:
/// - onTap: Callback khi click vào banner
class PromotionBanner extends StatelessWidget {
  final VoidCallback? onTap;

  const PromotionBanner({super.key, this.onTap});

  /// ============================================
  /// HÀM BUILD CHÍNH
  /// ============================================
  /// Xây dựng banner khuyến mãi với màu xanh lá đơn giản (Agoda style)
  /// Layout: Icon bên trái, text ở giữa, nút action bên phải
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50), // Màu xanh lá solid (không gradient)
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05), // Đổ bóng nhẹ
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                /// Icon container: Container trắng với icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2), // Nền trắng trong suốt 20%
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.local_offer,
                    color: Colors.white,
                    size: 20,
                  ),
                ),

                const SizedBox(width: 16),

                /// Text section: Title và description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Được GIẢM thêm 10% chỉ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'trong vòng 60 phút nữa!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                /// Action button: Nút "Kích hoạt" với nền trắng
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Kích hoạt',
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
