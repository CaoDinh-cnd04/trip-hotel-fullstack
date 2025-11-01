import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/models/hotel.dart';
import 'package:url_launcher/url_launcher.dart';

class PropertyInfoSection extends StatelessWidget {
  final Hotel hotel;

  const PropertyInfoSection({super.key, required this.hotel});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hotel name với gradient text effect - Sửa overflow hoàn toàn
            LayoutBuilder(
              builder: (context, constraints) {
                return ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Colors.purple[800]!,
                      Colors.pink[700]!,
                      Colors.orange[600]!,
                    ],
                  ).createShader(bounds),
                  child: SizedBox(
                    width: constraints.maxWidth,
                    child: Text(
                      hotel.ten,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.3,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Rating section với design hiện đại
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange[50]!,
                    Colors.amber[50]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.orange[200]!,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Star rating với animation effect
                  Flexible(
                    flex: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange[400]!,
                            Colors.orange[600]!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            child: Icon(
                              index < (hotel.soSao ?? 0) ? Icons.star : Icons.star_border,
                              color: Colors.white,
                              size: 16,
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Rating score với gradient background
                  if (hotel.diemDanhGiaTrungBinh != null)
                    Flexible(
                      flex: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.red[500]!,
                              Colors.orange[600]!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.emoji_events,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              hotel.diemDanhGiaTrungBinh!.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(width: 8),
                  
                  // Review count
                  if (hotel.soLuotDanhGia != null && hotel.soLuotDanhGia! > 0)
                    Expanded(
                      child: Text(
                        '${hotel.soLuotDanhGia} đánh giá',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Address section với design mới
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple[400]!,
                          Colors.purple[600]!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Địa chỉ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hotel.diaChi ?? 'Địa chỉ không có sẵn',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[900],
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // View on map button với gradient
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  _showOnMap(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ).copyWith(
                  backgroundColor: MaterialStateProperty.all(Colors.transparent),
                ),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue[600]!,
                        Colors.blue[800]!,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.map,
                        color: Colors.white,
                        size: 22,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Xem trên bản đồ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Check-in/Check-out times với design mới
            if (hotel.gioNhanPhong != null || hotel.gioTraPhong != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green[50]!,
                      Colors.teal[50]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.green[200]!,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (hotel.gioNhanPhong != null)
                      Expanded(
                        child: _buildModernTimeInfo(
                          'Nhận phòng',
                          'Từ ${hotel.gioNhanPhong}',
                          Icons.login_rounded,
                          Colors.green,
                        ),
                      ),
                    if (hotel.gioNhanPhong != null && hotel.gioTraPhong != null)
                      Container(
                        width: 1,
                        height: 50,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        color: Colors.grey[300]!,
                      ),
                    if (hotel.gioTraPhong != null)
                      Expanded(
                        child: _buildModernTimeInfo(
                          'Trả phòng',
                          'Trước ${hotel.gioTraPhong}',
                          Icons.logout_rounded,
                          Colors.teal,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModernTimeInfo(String title, String value, IconData icon, Color color) {
    // Helper để lấy các shade của màu
    Color getColorShade(Color baseColor, int shade) {
      if (baseColor == Colors.green) {
        return shade == 400 ? Colors.green[400]! : (shade == 600 ? Colors.green[600]! : Colors.green[800]!);
      }
      if (baseColor == Colors.teal) {
        return shade == 400 ? Colors.teal[400]! : (shade == 600 ? Colors.teal[600]! : Colors.teal[800]!);
      }
      // Fallback: tạo màu tương tự
      double factor = shade == 400 ? 0.7 : (shade == 600 ? 0.5 : 0.3);
      return Color.fromRGBO(
        (baseColor.red * (1 - factor) + 255 * factor).round(),
        (baseColor.green * (1 - factor) + 255 * factor).round(),
        (baseColor.blue * (1 - factor) + 255 * factor).round(),
        1.0,
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  getColorShade(color, 400),
                  getColorShade(color, 600),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: getColorShade(color, 800),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showOnMap(BuildContext context) async {
    try {
      String searchQuery = hotel.ten;
      
      List<String> addressParts = [];
      if (hotel.diaChi != null && hotel.diaChi!.isNotEmpty) {
        addressParts.add(hotel.diaChi!);
      }
      if (hotel.tenViTri != null && hotel.tenViTri!.isNotEmpty) {
        addressParts.add(hotel.tenViTri!);
      }
      if (hotel.tenTinhThanh != null && hotel.tenTinhThanh!.isNotEmpty) {
        addressParts.add(hotel.tenTinhThanh!);
      }
      if (hotel.tenQuocGia != null && hotel.tenQuocGia!.isNotEmpty) {
        addressParts.add(hotel.tenQuocGia!);
      }
      
      if (addressParts.isNotEmpty) {
        searchQuery += ', ${addressParts.join(', ')}';
      }
      
      if (searchQuery.isEmpty || searchQuery == hotel.ten) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không có địa chỉ để hiển thị trên bản đồ'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final encodedQuery = Uri.encodeComponent(searchQuery);
      final geoUri = Uri.parse('geo:0,0?q=$encodedQuery');
      final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedQuery');
      
      bool launched = false;
      
      try {
        if (await canLaunchUrl(geoUri)) {
          launched = await launchUrl(geoUri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        print('❌ Cannot launch geo: URI: $e');
      }
      
      if (!launched) {
        try {
          if (await canLaunchUrl(webUri)) {
            launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
          }
        } catch (e) {
          print('❌ Cannot launch web URI: $e');
        }
      }
      
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Không thể mở bản đồ. Vui lòng cài đặt Google Maps.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: () => _showOnMap(context),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi mở bản đồ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
