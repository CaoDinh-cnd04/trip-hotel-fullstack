import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/models/hotel.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget hiển thị thông tin chi tiết của khách sạn
/// Thiết kế theo phong cách Agoda: đơn giản, màu sắc tối giản, không gradient
/// 
/// Tham số:
/// - hotel: Đối tượng Hotel chứa thông tin khách sạn cần hiển thị
class PropertyInfoSection extends StatelessWidget {
  final Hotel hotel;

  const PropertyInfoSection({super.key, required this.hotel});

  /// Hàm build chính - xây dựng giao diện hiển thị thông tin khách sạn
  /// 
  /// Trả về: Container chứa Column với các thông tin:
  /// - Tên khách sạn
  /// - Rating và số sao
  /// - Địa chỉ
  /// - Nút xem trên bản đồ
  /// - Giờ check-in/check-out
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ============================================
          /// PHẦN 1: TÊN KHÁCH SẠN
          /// ============================================
          /// Hiển thị tên khách sạn với typography lớn, đơn giản
          /// - Font size: 28px
          /// - Font weight: 700 (bold)
          /// - Màu: #1A1A1A (đen nhẹ)
          /// - Tối đa 2 dòng, nếu dài sẽ cắt bằng dấu ...
          Text(
            hotel.ten,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
              height: 1.3, // Khoảng cách giữa các dòng
              letterSpacing: -0.5, // Khoảng cách giữa các ký tự (âm để chữ gần nhau hơn)
            ),
            maxLines: 2, // Giới hạn tối đa 2 dòng
            overflow: TextOverflow.ellipsis, // Nếu quá dài sẽ hiển thị ...
          ),
          
          const SizedBox(height: 16),
          
          /// ============================================
          /// PHẦN 2: RATING VÀ ĐÁNH GIÁ
          /// ============================================
          /// Hiển thị rating theo phong cách Agoda: đơn giản, không gradient
          /// Bao gồm: sao vàng, điểm số, số lượng đánh giá
          Row(
            children: [
              /// Hiển thị 5 sao: sao vàng (#FFB800) cho sao đã đánh giá, xám nhẹ cho sao chưa đánh giá
              /// Logic: So sánh index với số sao (soSao) để quyết định màu sắc
              if (hotel.soSao != null && hotel.soSao! > 0)
                Row(
                  mainAxisSize: MainAxisSize.min, // Chỉ chiếm không gian cần thiết
                  children: List.generate(5, (index) {
                    // Tạo 5 icon sao
                    return Icon(
                      // Nếu index < số sao thì hiển thị sao đầy, ngược lại hiển thị sao rỗng
                      index < hotel.soSao! ? Icons.star : Icons.star_border,
                      color: index < hotel.soSao! 
                          ? const Color(0xFFFFB800) // Vàng cho sao đã đánh giá
                          : const Color(0xFFE0E0E0), // Xám nhẹ cho sao chưa đánh giá
                      size: 18,
                    );
                  }),
                ),
              
              const SizedBox(width: 8),
              
              /// Hiển thị điểm đánh giá trung bình trong badge vàng
              /// Ví dụ: 8.5, 9.0, etc.
              if (hotel.diemDanhGiaTrungBinh != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB800), // Màu vàng giống Agoda
                    borderRadius: BorderRadius.circular(4), // Bo góc nhẹ
                  ),
                  child: Text(
                    // Format điểm số với 1 chữ số thập phân
                    hotel.diemDanhGiaTrungBinh!.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              
              /// Hiển thị số lượng đánh giá (ví dụ: "150 đánh giá")
              if (hotel.soLuotDanhGia != null && hotel.soLuotDanhGia! > 0)
                Text(
                  '${hotel.soLuotDanhGia} đánh giá',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF666666), // Màu xám
                    fontWeight: FontWeight.w400,
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          /// ============================================
          /// PHẦN 3: ĐỊA CHỈ KHÁCH SẠN
          /// ============================================
          /// Hiển thị địa chỉ trong card xám nhẹ với icon location
          /// Layout: Icon bên trái, địa chỉ bên phải
          Container(
            padding: const EdgeInsets.all(18), // Padding bên trong card
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5), // Nền xám nhẹ
              borderRadius: BorderRadius.circular(12), // Bo góc 12px
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start, // Căn trên cùng
              children: [
                /// Icon container: Container trắng 40x40 với icon location
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white, // Nền trắng cho icon
                    borderRadius: BorderRadius.circular(10), // Bo góc
                  ),
                  child: const Icon(
                    Icons.location_on_outlined, // Icon vị trí
                    color: Color(0xFF1A1A1A),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16), // Khoảng cách giữa icon và text
                
                /// Phần text địa chỉ: Expanded để chiếm hết không gian còn lại
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Label "Địa chỉ"
                      const Text(
                        'Địa chỉ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF999999), // Màu xám nhẹ cho label
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Nội dung địa chỉ
                      Text(
                        hotel.diaChi ?? 'Địa chỉ không có sẵn', // Nếu null thì hiển thị text mặc định
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF1A1A1A), // Màu đen nhẹ
                          fontWeight: FontWeight.w500,
                          height: 1.4, // Khoảng cách giữa các dòng
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          /// ============================================
          /// PHẦN 4: NÚT XEM TRÊN BẢN ĐỒ
          /// ============================================
          /// Nút màu đen (#1A1A1A) để mở Google Maps với địa chỉ khách sạn
          /// Khi click sẽ gọi hàm _showOnMap() để mở ứng dụng bản đồ
          SizedBox(
            width: double.infinity, // Chiếm toàn bộ chiều rộng
            height: 50, // Chiều cao cố định
            child: ElevatedButton(
              onPressed: () {
                // Gọi hàm mở bản đồ khi click
                _showOnMap(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A), // Màu đen nhẹ
                foregroundColor: Colors.white, // Màu chữ trắng
                elevation: 0, // Không có đổ bóng
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Bo góc 12px
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center, // Căn giữa icon và text
                children: [
                  Icon(
                    Icons.map_outlined, // Icon bản đồ
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8), // Khoảng cách giữa icon và text
                  Text(
                    'Xem trên bản đồ',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// ============================================
          /// PHẦN 5: GIỜ CHECK-IN/CHECK-OUT
          /// ============================================
          /// Hiển thị giờ nhận phòng và trả phòng (nếu có)
          /// Sử dụng spread operator (...) để chỉ hiển thị khi có dữ liệu
          /// Layout: 2 cột bằng nhau (Expanded) với divider ở giữa
          if (hotel.gioNhanPhong != null || hotel.gioTraPhong != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5), // Nền xám nhẹ
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  /// Cột 1: Giờ nhận phòng (nếu có)
                  if (hotel.gioNhanPhong != null)
                    Expanded(
                      // Expanded để chia đều không gian với cột 2
                      child: _buildSimpleTimeInfo(
                        'Nhận phòng', // Label
                        'Từ ${hotel.gioNhanPhong}', // Giá trị (ví dụ: "Từ 14:00")
                        Icons.login_outlined, // Icon
                      ),
                    ),
                  /// Divider: Đường phân cách giữa 2 cột (chỉ hiển thị khi có cả 2 thông tin)
                  if (hotel.gioNhanPhong != null && hotel.gioTraPhong != null)
                    Container(
                      width: 1, // Độ dày 1px
                      height: 50,
                      margin: const EdgeInsets.symmetric(horizontal: 12), // Margin trái phải
                      color: const Color(0xFFE8E8E8), // Màu xám nhẹ
                    ),
                  /// Cột 2: Giờ trả phòng (nếu có)
                  if (hotel.gioTraPhong != null)
                    Expanded(
                      child: _buildSimpleTimeInfo(
                        'Trả phòng',
                        'Trước ${hotel.gioTraPhong}', // Ví dụ: "Trước 12:00"
                        Icons.logout_outlined,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// ============================================
  /// HÀM HELPER: _buildSimpleTimeInfo
  /// ============================================
  /// Xây dựng widget hiển thị thông tin giờ (check-in/check-out)
  /// 
  /// Tham số:
  /// - title: Tiêu đề (ví dụ: "Nhận phòng", "Trả phòng")
  /// - value: Giá trị hiển thị (ví dụ: "Từ 14:00")
  /// - icon: Icon hiển thị phía trên (Icons.login_outlined hoặc logout_outlined)
  /// 
  /// Trả về: Column chứa icon, title và value theo chiều dọc
  /// Layout: Icon ở trên, title ở giữa, value ở dưới
  Widget _buildSimpleTimeInfo(String title, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min, // Chỉ chiếm không gian cần thiết
      children: [
        // Icon ở trên cùng
        Icon(
          icon,
          color: const Color(0xFF1A1A1A), // Màu đen nhẹ
          size: 20,
        ),
        const SizedBox(height: 8), // Khoảng cách giữa icon và title
        // Title (label): Màu xám nhẹ, font nhỏ
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF999999), // Màu xám nhẹ
            fontWeight: FontWeight.w400, // Font thường
          ),
        ),
        const SizedBox(height: 4), // Khoảng cách giữa title và value
        // Value (nội dung): Màu đen, font đậm hơn
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600, // Font đậm
            color: Color(0xFF1A1A1A), // Màu đen nhẹ
          ),
          textAlign: TextAlign.center, // Căn giữa
          maxLines: 2, // Tối đa 2 dòng
          overflow: TextOverflow.ellipsis, // Nếu quá dài sẽ hiển thị ...
        ),
      ],
    );
  }

  /// ============================================
  /// HÀM: _showOnMap
  /// ============================================
  /// Mở Google Maps với địa chỉ khách sạn
  /// 
  /// Logic hoạt động:
  /// 1. Thu thập thông tin địa chỉ từ hotel object
  /// 2. Tạo query string từ tên khách sạn + địa chỉ
  /// 3. Thử mở ứng dụng Google Maps (geo URI)
  /// 4. Nếu không được, thử mở trình duyệt với Google Maps web
  /// 5. Hiển thị thông báo lỗi nếu không mở được
  /// 
  /// Tham số:
  /// - context: BuildContext để hiển thị SnackBar
  void _showOnMap(BuildContext context) async {
    try {
      // Bước 1: Bắt đầu với tên khách sạn
      String searchQuery = hotel.ten;
      
      // Bước 2: Thu thập các phần địa chỉ (nếu có)
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
      
      // Bước 3: Ghép các phần địa chỉ vào query
      // Ví dụ: "Khách sạn ABC, 123 Đường XYZ, Quận 1, TP.HCM"
      if (addressParts.isNotEmpty) {
        searchQuery += ', ${addressParts.join(', ')}';
      }
      
      // Bước 4: Kiểm tra nếu không có địa chỉ
      if (searchQuery.isEmpty || searchQuery == hotel.ten) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không có địa chỉ để hiển thị trên bản đồ'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return; // Dừng hàm nếu không có địa chỉ
      }

      // Bước 5: Encode query để dùng trong URL
      final encodedQuery = Uri.encodeComponent(searchQuery);
      
      // Tạo 2 loại URI:
      // - geoUri: Dành cho ứng dụng Google Maps trên điện thoại
      // - webUri: Dành cho trình duyệt web
      final geoUri = Uri.parse('geo:0,0?q=$encodedQuery');
      final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedQuery');
      
      bool launched = false; // Flag để kiểm tra đã mở được chưa
      
      // Bước 6: Thử mở ứng dụng Google Maps (nếu có)
      try {
        if (await canLaunchUrl(geoUri)) {
          launched = await launchUrl(geoUri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        print('❌ Cannot launch geo: URI: $e');
      }
      
      // Bước 7: Nếu không mở được app, thử mở trình duyệt web
      if (!launched) {
        try {
          if (await canLaunchUrl(webUri)) {
            launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
          }
        } catch (e) {
          print('❌ Cannot launch web URI: $e');
        }
      }
      
      // Bước 8: Hiển thị thông báo lỗi nếu không mở được
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Không thể mở bản đồ. Vui lòng cài đặt Google Maps.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: () => _showOnMap(context), // Cho phép thử lại
            ),
          ),
        );
      }
    } catch (e) {
      // Xử lý lỗi chung
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
