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
      guestCount: json['guest_count'] ?? 1,
      roomCount: json['room_count'] ?? 1,
      searchDate: DateTime.parse(json['search_date']),
      resultCount: json['result_count'],
      locationDisplayName: json['location_display_name'],
      minPrice: json['min_price']?.toDouble(),
      maxPrice: json['max_price']?.toDouble(),
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
