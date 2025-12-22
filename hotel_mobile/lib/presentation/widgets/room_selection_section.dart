import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/models/room.dart';
import 'package:hotel_mobile/data/services/applied_promotion_service.dart';
import 'package:intl/intl.dart';
import 'room_availability_badge.dart';

/// Widget hiển thị danh sách phòng để người dùng lựa chọn
/// Thiết kế theo phong cách Agoda: layout ngang (hình ảnh bên trái, thông tin bên phải)
/// 
/// Tham số:
/// - rooms: Danh sách các phòng cần hiển thị
/// - onRoomSelected: Callback được gọi khi người dùng chọn phòng
/// - checkInDate: Ngày nhận phòng (optional)
/// - checkOutDate: Ngày trả phòng (optional)
/// - guestCount: Số lượng khách
class RoomSelectionSection extends StatefulWidget {
  final List<Room> rooms;
  final Function(Room) onRoomSelected;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final int guestCount;

  const RoomSelectionSection({
    super.key,
    required this.rooms,
    required this.onRoomSelected,
    this.checkInDate,
    this.checkOutDate,
    required this.guestCount,
  });

  @override
  State<RoomSelectionSection> createState() => _RoomSelectionSectionState();
}

class _RoomSelectionSectionState extends State<RoomSelectionSection> {
  /// Map lưu trạng thái expand/collapse của từng loại phòng
  /// Key: tenLoaiPhong (loại phòng)
  /// Value: true nếu đang expand, false nếu đang collapse
  final Map<String, bool> _expandedStates = {};
  
  /// Format tiền tệ theo định dạng Việt Nam (₫)
  /// Ví dụ: 1000000 -> 1.000.000 ₫
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
  
  /// Service để lấy promotion đang được áp dụng
  final AppliedPromotionService _promotionService = AppliedPromotionService();

  /// Lấy giá sau khi áp dụng promotion
  double _getPriceWithPromotion(double originalPrice, Room room) {
    return _promotionService.calculateDiscountedPrice(originalPrice, hotelId: room.khachSanId);
  }

  /// Tính số đêm từ check-in và check-out date
  /// 
  /// Trả về: Số đêm (int) hoặc null nếu không có đủ thông tin
  /// Ví dụ: Check-in 01/01, check-out 03/01 -> 2 đêm
  int? get _numberOfNights {
    if (widget.checkInDate != null && widget.checkOutDate != null) {
      return widget.checkOutDate!.difference(widget.checkInDate!).inDays;
    }
    return null;
  }

  /// ============================================
  /// HÀM: _getGroupedRooms
  /// ============================================
  /// Nhóm các phòng theo loại phòng (tenLoaiPhong)
  /// 
  /// Logic:
  /// 1. Nhóm tất cả phòng theo tenLoaiPhong
  /// 2. Lấy 1 phòng đầu tiên làm đại diện cho mỗi nhóm
  /// 3. Tính số phòng còn lại trong nhóm (trừ phòng đại diện)
  /// 
  /// Trả về: List<MapEntry<Room, int>>
  /// - Room: Phòng đại diện cho nhóm
  /// - int: Số phòng còn lại trong nhóm (ví dụ: nếu có 5 phòng, int = 4)
  /// 
  /// Ví dụ: Có 3 phòng "Deluxe" và 2 phòng "Standard"
  /// -> Trả về: [MapEntry(Deluxe_room1, 2), MapEntry(Standard_room1, 1)]
  List<MapEntry<Room, int>> _getGroupedRooms() {
    // Bước 1: Tạo Map để nhóm phòng theo loại
    final Map<String, List<Room>> grouped = {};
    
    // Bước 2: Duyệt qua tất cả phòng và nhóm chúng
    for (var room in widget.rooms) {
      final roomType = room.tenLoaiPhong ?? 'Phòng không tên'; // Nếu không có tên thì dùng mặc định
      if (!grouped.containsKey(roomType)) {
        grouped[roomType] = []; // Tạo list mới nếu chưa có
      }
      grouped[roomType]!.add(room); // Thêm phòng vào nhóm
    }

    // Bước 3: Lấy 1 phòng đầu tiên làm đại diện cho mỗi nhóm
    // và tính số phòng còn lại
    return grouped.entries.map((entry) {
      final representativeRoom = entry.value.first; // Phòng đầu tiên làm đại diện
      final remainingCount = entry.value.length - 1; // Số phòng còn lại (trừ phòng đại diện)
      return MapEntry(representativeRoom, remainingCount);
    }).toList();
  }

  /// ============================================
  /// HÀM BUILD CHÍNH
  /// ============================================
  /// Xây dựng giao diện danh sách phòng với layout ngang (Agoda style)
  /// 
  /// Cấu trúc:
  /// 1. Section header: Tiêu đề và số lượng phòng
  /// 2. Danh sách phòng: Mỗi phòng hiển thị layout ngang (hình bên trái, info bên phải)
  @override
  Widget build(BuildContext context) {
    // Kiểm tra nếu không có phòng nào
    if (widget.rooms.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: const Center(
          child: Text(
            'Không có phòng nào khả dụng',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    // Nhóm phòng theo loại và lấy phòng đại diện
    final groupedRooms = _getGroupedRooms();
    final totalRooms = widget.rooms.length; // Tổng số phòng (không nhóm)

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      color: const Color(0xFFF5F5F5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ============================================
          /// PHẦN 1: SECTION HEADER
          /// ============================================
          /// Hiển thị tiêu đề và thông tin tổng quan về phòng
          /// Layout: Icon bên trái, text ở giữa, badge số đêm bên phải
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white, // Nền trắng
              borderRadius: BorderRadius.circular(12), // Bo góc 12px
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04), // Đổ bóng nhẹ
                  blurRadius: 8,
                  offset: const Offset(0, 2), // Đổ bóng xuống dưới 2px
                ),
              ],
            ),
            child: Row(
              children: [
                /// Icon container: Container xám nhẹ 48x48 với icon giường
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5), // Nền xám nhẹ
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.bed_outlined, // Icon giường
                    color: Color(0xFF1A1A1A),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16), // Khoảng cách giữa icon và text
                
                /// Phần text: Tiêu đề và mô tả
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tiêu đề chính
                      const Text(
                        'Lựa chọn phòng và giá',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700, // Font đậm
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -0.5, // Chữ gần nhau hơn
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Mô tả: Số loại phòng và tổng số phòng
                      Text(
                        'Đang hiển thị ${groupedRooms.length} loại phòng (Tổng ${totalRooms} phòng)',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF999999), // Màu xám nhẹ
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                
                /// Badge số đêm: Hiển thị số đêm đã chọn (nếu có)
                if (_numberOfNights != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A), // Màu đen
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bedtime_outlined, // Icon ban đêm
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$_numberOfNights đêm', // Ví dụ: "2 đêm"
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          /// ============================================
          /// PHẦN 2: DANH SÁCH PHÒNG
          /// ============================================
          /// Hiển thị danh sách phòng với layout ngang (Agoda style)
          /// Mỗi phòng được nhóm theo loại, chỉ hiển thị 1 phòng đại diện cho mỗi loại
          /// 
          /// Logic:
          /// - Sử dụng spread operator (...) để thêm các widget vào children list
          /// - Mỗi phòng được bọc trong Padding để có khoảng cách
          /// - remainingCount: Số phòng còn lại cùng loại (hiển thị badge "Còn X phòng")
          ...groupedRooms.map((roomEntry) {
            final room = roomEntry.key; // Phòng đại diện
            final remainingCount = roomEntry.value; // Số phòng còn lại
            final roomType = room.tenLoaiPhong ?? 'Phòng không tên';
            
            // Trả về card phòng với padding phía dưới
            return Padding(
              padding: const EdgeInsets.only(bottom: 16), // Khoảng cách giữa các card
              child: _buildRoomCard(room, roomType, remainingCount),
            );
          }),
        ],
      ),
    );
  }

  /// ============================================
  /// HÀM: _buildRoomCard
  /// ============================================
  /// Xây dựng card hiển thị thông tin phòng với layout dọc
  /// 
  /// Layout: Hình ảnh ở trên (full width), thông tin ở dưới
  /// 
  /// Tham số:
  /// - room: Đối tượng Room cần hiển thị
  /// - roomType: Loại phòng (dùng làm key cho expanded state)
  /// - remainingCount: Số phòng còn lại cùng loại (hiển thị badge)
  /// 
  /// Trả về: Container với Column layout dọc
  Widget _buildRoomCard(Room room, String roomType, int remainingCount) {
    final roomImages = room.hinhAnhPhong ?? []; // Lấy danh sách hình ảnh
    final isExpanded = _expandedStates[roomType] ?? false; // Kiểm tra trạng thái expand/collapse

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Nền trắng
        borderRadius: BorderRadius.circular(16), // Bo góc 16px
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06), // Đổ bóng nhẹ
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          /// ============================================
          /// PHẦN 1: HÌNH ẢNH PHÒNG (Ở TRÊN)
          /// ============================================
          /// Hiển thị hình ảnh đầu tiên của phòng
          /// Kích thước: full width, chiều cao 220px
          roomImages.isNotEmpty
              ? Container(
                  width: double.infinity, // Chiều rộng full
                  height: 220, // Chiều cao cố định
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    color: const Color(0xFFE8E8E8),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          roomImages.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFFE8E8E8),
                              child: const Icon(
                                Icons.bed,
                                size: 50,
                                color: Color(0xFF999999),
                              ),
                            );
                          },
                        ),
                        // Badge trạng thái phòng
                        Positioned(
                          top: 12,
                          right: 12,
                          child: RoomAvailabilityBadge(room: room),
                        ),
                      ],
                    ),
                  ),
                )
              : Container(
                  width: double.infinity,
                  height: 220,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    color: Color(0xFFE8E8E8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.bed,
                      size: 50,
                      color: Color(0xFF999999),
                    ),
                  ),
                ),

          /// ============================================
          /// PHẦN 2: THÔNG TIN PHÒNG (Ở DƯỚI)
          /// ============================================
          /// Padding và Column chứa tất cả thông tin
          Padding(
            padding: const EdgeInsets.all(16), // Padding 16px
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                /// ============================================
                /// THÔNG TIN 1: TÊN PHÒNG VÀ BADGE
                /// ============================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            room.tenLoaiPhong ?? 'Phòng không tên',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          // Hiển thị badge số lượng phòng với màu sắc theo số lượng
                          if (remainingCount >= 0) ...[
                            const SizedBox(height: 8),
                            _buildAvailabilityBadge(remainingCount),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                /// ============================================
                /// THÔNG TIN 2: SỨC CHỨA
                /// ============================================
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.people_outline,
                        size: 16,
                        color: Color(0xFF1A1A1A),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tối đa ${room.sucChua ?? 1} khách',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1A1A1A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                /// ============================================
                /// THÔNG TIN 3: MÔ TẢ
                /// ============================================
                if (room.moTa != null && room.moTa!.isNotEmpty)
                  Text(
                    room.moTa!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: isExpanded ? null : 2,
                    overflow: isExpanded ? null : TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 16),

                /// ============================================
                /// THÔNG TIN 4: GIÁ VÀ NÚT EXPAND
                /// ============================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Giá mỗi đêm',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF999999),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildPriceWithPromotion(room),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF003580),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _expandedStates[roomType] = !isExpanded;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                /// ============================================
                /// PHẦN MỞ RỘNG (EXPANDED CONTENT)
                /// ============================================
                if (isExpanded) ...[
                  const SizedBox(height: 20),
                  Container(
                    height: 1,
                    color: const Color(0xFFE8E8E8),
                  ),
                  const SizedBox(height: 20),

                  /// Gallery hình ảnh: Hiển thị tất cả hình ảnh của phòng (nếu có > 1 hình)
                  if (roomImages.length > 1) ...[
                    SizedBox(
                      height: 120, // Chiều cao cố định
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal, // Cuộn ngang
                        itemCount: roomImages.length, // Số lượng hình
                        itemBuilder: (context, imgIndex) {
                          return Container(
                            width: 160, // Chiều rộng mỗi hình
                            margin: const EdgeInsets.only(right: 12), // Khoảng cách giữa các hình
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: const Color(0xFFE8E8E8), // Nền xám khi load
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                roomImages[imgIndex],
                                fit: BoxFit.cover, // Phủ kín container
                                errorBuilder: (context, error, stackTrace) {
                                  // Icon thay thế nếu lỗi
                                  return const Icon(
                                    Icons.image_not_supported,
                                    color: Color(0xFF999999),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  /// Tiện ích phòng: Danh sách các tiện ích (WiFi, điều hòa, TV, etc.)
                  const Text(
                    'Tiện ích phòng',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Wrap để tự động xuống dòng khi hết chỗ
                  Wrap(
                    spacing: 8, // Khoảng cách ngang
                    runSpacing: 8, // Khoảng cách dọc
                    children: [
                      _buildFeatureChip(Icons.bed, 'Giường đôi'),
                      _buildFeatureChip(Icons.wifi, 'WiFi miễn phí'),
                      _buildFeatureChip(Icons.ac_unit, 'Điều hòa'),
                      _buildFeatureChip(Icons.tv, 'TV'),
                      _buildFeatureChip(Icons.local_parking, 'Bãi đỗ xe'),
                      _buildFeatureChip(Icons.restaurant, 'Nhà hàng'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  /// Tùy chọn giá: Hiển thị các gói giá khác nhau
                  const Text(
                    'Tùy chọn giá',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Option 1: Không hoàn tiền (giá gốc)
                  _buildPricingOption(
                    'Không hoàn tiền',
                    _getPriceWithPromotion(room.giaPhong ?? 0, room),
                    'Giá tốt nhất • Không thể hủy',
                    false, // Không được khuyến nghị
                    room,
                    0, // Index option
                  ),
                  const SizedBox(height: 12),
                  // Option 2: Kèm bữa sáng (giá cao hơn 200k)
                  _buildPricingOption(
                    'Kèm bữa sáng',
                    _getPriceWithPromotion((room.giaPhong ?? 0) + 200000, room), // Giá + 200k
                    'Hủy miễn phí • Bao gồm bữa sáng',
                    true, // Được khuyến nghị
                    room,
                    1, // Index option
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFE8E8E8),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1A1A1A)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF1A1A1A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// ============================================
  /// HÀM: _buildPricingOption
  /// ============================================
  /// Xây dựng card hiển thị một tùy chọn giá (ví dụ: "Không hoàn tiền", "Kèm bữa sáng")
  /// 
  /// Tham số:
  /// - title: Tên tùy chọn (ví dụ: "Không hoàn tiền")
  /// - price: Giá của tùy chọn này
  /// - description: Mô tả ngắn (ví dụ: "Giá tốt nhất • Không thể hủy")
  /// - recommended: true nếu được khuyến nghị (hiển thị badge)
  /// - room: Đối tượng Room
  /// - optionIndex: Index của option (0, 1, ...)
  /// 
  /// Trả về: Container card với thông tin giá và nút "Chọn"
  /// Nếu recommended = true: border đen dày hơn, có badge "Khuyến nghị"
  Widget _buildPricingOption(
    String title,
    double price,
    String description,
    bool recommended,
    Room room,
    int optionIndex,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          // Border đen dày nếu được khuyến nghị, xám mỏng nếu không
          color: recommended ? const Color(0xFF1A1A1A) : const Color(0xFFE8E8E8),
          width: recommended ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04), // Đổ bóng nhẹ
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Dòng 1: Title và badge "Khuyến nghị"
          /// Sử dụng Expanded để tránh overflow khi title dài
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 2, // Tối đa 2 dòng
                  overflow: TextOverflow.ellipsis, // Hiển thị ... nếu quá dài
                ),
              ),
              // Badge "Khuyến nghị" (chỉ hiển thị nếu recommended = true)
              if (recommended) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A), // Nền đen
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Khuyến nghị',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          /// Dòng 2: Mô tả (ví dụ: "Giá tốt nhất • Không thể hủy")
          /// Sử dụng Flexible để tránh overflow
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF666666), // Màu xám
              fontWeight: FontWeight.w400,
            ),
            maxLines: 2, // Tối đa 2 dòng
            overflow: TextOverflow.ellipsis, // Hiển thị ... nếu quá dài
          ),
          const SizedBox(height: 16),
          /// Dòng 3: Giá và nút "Chọn"
          /// Sử dụng Expanded để tránh overflow khi giá dài
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Giá bên trái, nút bên phải
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Giá phòng với promotion - Expanded để tránh overflow
              Expanded(
                child: _buildPriceWithPromotionForOption(price, room),
              ),
              const SizedBox(width: 12), // Khoảng cách giữa giá và nút
              // Nút "Chọn": Màu đen, khi click sẽ gọi onRoomSelected
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: () {
                    // Gọi callback để xử lý khi người dùng chọn phòng
                    widget.onRoomSelected(room);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A), // Màu đen
                    foregroundColor: Colors.white,
                    elevation: 0, // Không đổ bóng
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text(
                    'Chọn',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Hiển thị giá với promotion cho room card (collapsed view)
  Widget _buildPriceWithPromotion(Room room) {
    final originalPrice = room.giaPhong ?? 0;
    final promotion = _promotionService.getAppliedPromotion(hotelId: room.khachSanId);
    
    if (promotion != null && originalPrice > 0) {
      final discountedPrice = _promotionService.calculateDiscountedPrice(originalPrice, hotelId: room.khachSanId);
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Giá gốc (gạch ngang)
          Text(
            currencyFormat.format(originalPrice),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[400],
              decoration: TextDecoration.lineThrough,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          // Giá đã giảm
          Row(
            children: [
              Text(
                currencyFormat.format(discountedPrice),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF003580),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              // Badge promotion
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Text(
                  '-${promotion.phanTramGiam.toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }
    
    // Không có promotion, hiển thị giá bình thường
    return Text(
      currencyFormat.format(originalPrice),
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Color(0xFF003580),
        letterSpacing: -0.5,
      ),
    );
  }

  /// Hiển thị giá với promotion cho pricing option (expanded view)
  Widget _buildPriceWithPromotionForOption(double price, Room room) {
    final promotion = _promotionService.getAppliedPromotion(hotelId: room.khachSanId);
    
    if (promotion != null && price > 0) {
      final discountedPrice = _promotionService.calculateDiscountedPrice(price, hotelId: room.khachSanId);
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Giá gốc (gạch ngang)
          Text(
            '${currencyFormat.format(price)}/đêm',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[400],
              decoration: TextDecoration.lineThrough,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Giá đã giảm
          Row(
            children: [
              Flexible(
                child: Text(
                  '${currencyFormat.format(discountedPrice)}/đêm',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              // Badge promotion nhỏ
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Text(
                  '-${promotion.phanTramGiam.toInt()}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }
    
    // Không có promotion, hiển thị giá bình thường
    return Text(
      '${currencyFormat.format(price)}/đêm',
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A1A),
        letterSpacing: -0.5,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Xây dựng badge hiển thị số lượng phòng với màu sắc
  /// - Xanh: > 2 phòng (Còn trống)
  /// - Cam: 1-2 phòng (Gần hết phòng)
  /// - Đỏ: 0 phòng (Hết phòng)
  Widget _buildAvailabilityBadge(int availableCount) {
    Color badgeColor;
    Color textColor;
    String text;
    IconData icon;
    
    if (availableCount <= 0) {
      // Hết phòng - màu đỏ
      badgeColor = Colors.red[50]!;
      textColor = Colors.red[700]!;
      text = 'Hết phòng';
      icon = Icons.close;
    } else if (availableCount <= 2) {
      // Gần hết phòng - màu cam
      badgeColor = Colors.orange[50]!;
      textColor = Colors.orange[700]!;
      text = 'Gần hết phòng ($availableCount)';
      icon = Icons.warning;
    } else {
      // Còn nhiều phòng - màu xanh
      badgeColor = const Color(0xFFE8F5E9);
      textColor = const Color(0xFF2E7D32);
      text = 'Còn $availableCount phòng';
      icon = Icons.bed_outlined;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: textColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: textColor,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}