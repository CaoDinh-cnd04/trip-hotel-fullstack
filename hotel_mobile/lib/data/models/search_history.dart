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

  int get nights {
    return checkOutDate.difference(checkInDate).inDays;
  }

  String get dateRangeString {
    return '${checkInDate.day}/${checkInDate.month} - ${checkOutDate.day}/${checkOutDate.month}';
  }

  String get guestRoomString {
    return '$guestCount khách, $roomCount phòng';
  }

  String get displayLocation {
    return locationDisplayName ?? location;
  }

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

  // Create search parameters for re-search
  Map<String, dynamic> get searchParams {
    return {
      'location': location,
      'checkInDate': checkInDate,
      'checkOutDate': checkOutDate,
      'guestCount': guestCount,
      'roomCount': roomCount,
    };
  }

  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(searchDate);
    return difference.inDays <= 30; // Considered recent if within 30 days
  }

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
