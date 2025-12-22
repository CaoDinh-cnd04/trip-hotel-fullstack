/// Model đại diện cho lịch sử tìm kiếm của người dùng
/// 
/// Chứa thông tin:
/// - Thông tin tìm kiếm: location, checkInDate, checkOutDate, guestCount, roomCount
/// - Kết quả: resultCount, locationDisplayName
/// - Lọc: minPrice, maxPrice, selectedFilters
/// - Thời gian: searchDate
class SearchHistory {
  final String id;
  final String location;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guestCount;
  final int roomCount;
  final DateTime searchDate;
  final int? resultCount;
  final String? locationDisplayName;
  final double? minPrice;
  final double? maxPrice;
  final List<String>? selectedFilters;

  SearchHistory({
    required this.id,
    required this.location,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guestCount,
    required this.roomCount,
    required this.searchDate,
    this.resultCount,
    this.locationDisplayName,
    this.minPrice,
    this.maxPrice,
    this.selectedFilters,
  });

  /// Tạo đối tượng SearchHistory từ JSON
  /// 
  /// [json] - Map chứa dữ liệu JSON từ API
  /// 
  /// Parse các trường từ snake_case sang camelCase
  /// Chuyển đổi an toàn các kiểu dữ liệu số
  factory SearchHistory.fromJson(Map<String, dynamic> json) {
    return SearchHistory(
      id: json['id'].toString(),
      location: json['location'] ?? '',
      checkInDate: DateTime.parse(json['check_in_date']),
      checkOutDate: DateTime.parse(json['check_out_date']),
      guestCount: _safeToInt(json['guest_count']) ?? 1,
      roomCount: _safeToInt(json['room_count']) ?? 1,
      searchDate: DateTime.parse(json['search_date']),
      resultCount: _safeToInt(json['result_count']),
      locationDisplayName: json['location_display_name'],
      minPrice: _safeToDouble(json['min_price']),
      maxPrice: _safeToDouble(json['max_price']),
      selectedFilters: json['selected_filters']?.cast<String>(),
    );
  }

  /// Chuyển đổi đối tượng SearchHistory sang JSON
  /// 
  /// Trả về Map chứa tất cả các trường dưới dạng JSON (snake_case)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location': location,
      'check_in_date': checkInDate.toIso8601String(),
      'check_out_date': checkOutDate.toIso8601String(),
      'guest_count': guestCount,
      'room_count': roomCount,
      'search_date': searchDate.toIso8601String(),
      'result_count': resultCount,
      'location_display_name': locationDisplayName,
      'min_price': minPrice,
      'max_price': maxPrice,
      'selected_filters': selectedFilters,
    };
  }

  /// Tính số đêm từ ngày check-in đến check-out
  /// 
  /// Trả về số ngày chênh lệch giữa checkOutDate và checkInDate
  int get nights {
    return checkOutDate.difference(checkInDate).inDays;
  }

  /// Lấy chuỗi hiển thị khoảng thời gian đặt phòng
  /// 
  /// Ví dụ: "15/12 - 18/12"
  String get dateRangeString {
    return '${checkInDate.day}/${checkInDate.month} - ${checkOutDate.day}/${checkOutDate.month}';
  }

  /// Lấy chuỗi hiển thị số khách và số phòng
  /// 
  /// Ví dụ: "2 khách, 1 phòng"
  String get guestRoomString {
    return '$guestCount khách, $roomCount phòng';
  }

  /// Lấy tên địa điểm để hiển thị
  /// 
  /// Trả về locationDisplayName nếu có, nếu không trả về location
  String get displayLocation {
    return locationDisplayName ?? location;
  }

  /// Chuyển đổi giá trị sang double một cách an toàn
  /// 
  /// [value] - Giá trị có thể là double, int, String, hoặc null
  /// 
  /// Trả về double nếu chuyển đổi thành công, null nếu không
  static double? _safeToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed;
    }
    return null;
  }

  /// Chuyển đổi giá trị sang int một cách an toàn
  /// 
  /// [value] - Giá trị có thể là int, double, String, hoặc null
  /// 
  /// Trả về int nếu chuyển đổi thành công, null nếu không
  static int? _safeToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed;
    }
    return null;
  }

  /// Tạo Map chứa các tham số tìm kiếm để tái sử dụng
  /// 
  /// Trả về Map với các thông tin: location, checkInDate, checkOutDate, guestCount, roomCount
  Map<String, dynamic> get searchParams {
    return {
      'location': location,
      'checkInDate': checkInDate,
      'checkOutDate': checkOutDate,
      'guestCount': guestCount,
      'roomCount': roomCount,
    };
  }

  /// Kiểm tra xem lịch sử tìm kiếm có gần đây không (trong vòng 30 ngày)
  /// 
  /// Trả về true nếu searchDate cách hiện tại <= 30 ngày
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(searchDate);
    return difference.inDays <= 30; // Considered recent if within 30 days
  }

  /// Tạo bản sao của SearchHistory với các trường được cập nhật
  /// 
  /// Cho phép cập nhật từng trường riêng lẻ mà không cần tạo mới toàn bộ object
  /// 
  /// Tất cả các tham số đều tùy chọn, nếu không cung cấp sẽ giữ nguyên giá trị cũ
  SearchHistory copyWith({
    String? id,
    String? location,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    int? guestCount,
    int? roomCount,
    DateTime? searchDate,
    int? resultCount,
    String? locationDisplayName,
    double? minPrice,
    double? maxPrice,
    List<String>? selectedFilters,
  }) {
    return SearchHistory(
      id: id ?? this.id,
      location: location ?? this.location,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      guestCount: guestCount ?? this.guestCount,
      roomCount: roomCount ?? this.roomCount,
      searchDate: searchDate ?? this.searchDate,
      resultCount: resultCount ?? this.resultCount,
      locationDisplayName: locationDisplayName ?? this.locationDisplayName,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      selectedFilters: selectedFilters ?? this.selectedFilters,
    );
  }
}
