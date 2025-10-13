class FilterCriteria {
  double minPrice;
  double maxPrice;
  List<int> selectedStarRatings;
  List<String> selectedAmenities;
  List<String> selectedAccommodationTypes;

  FilterCriteria({
    this.minPrice = 0.0,
    this.maxPrice = 10000000.0, // 10 triệu VND
    this.selectedStarRatings = const [],
    this.selectedAmenities = const [],
    this.selectedAccommodationTypes = const [],
  });

  FilterCriteria copyWith({
    double? minPrice,
    double? maxPrice,
    List<int>? selectedStarRatings,
    List<String>? selectedAmenities,
    List<String>? selectedAccommodationTypes,
  }) {
    return FilterCriteria(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      selectedStarRatings:
          selectedStarRatings ?? List.from(this.selectedStarRatings),
      selectedAmenities: selectedAmenities ?? List.from(this.selectedAmenities),
      selectedAccommodationTypes:
          selectedAccommodationTypes ??
          List.from(this.selectedAccommodationTypes),
    );
  }

  void clear() {
    minPrice = 0.0;
    maxPrice = 10000000.0;
    selectedStarRatings.clear();
    selectedAmenities.clear();
    selectedAccommodationTypes.clear();
  }

  bool get hasActiveFilters {
    return minPrice > 0.0 ||
        maxPrice < 10000000.0 ||
        selectedStarRatings.isNotEmpty ||
        selectedAmenities.isNotEmpty ||
        selectedAccommodationTypes.isNotEmpty;
  }

  int get estimatedResultCount {
    // Mock calculation - trong thực tế sẽ gọi API để lấy số lượng thực tế
    if (!hasActiveFilters) return 150;

    int baseCount = 150;

    // Giảm dần dựa trên số tiêu chí được chọn
    if (selectedStarRatings.isNotEmpty) baseCount = (baseCount * 0.8).round();
    if (selectedAmenities.isNotEmpty) baseCount = (baseCount * 0.7).round();
    if (selectedAccommodationTypes.isNotEmpty)
      baseCount = (baseCount * 0.6).round();
    if (minPrice > 0 || maxPrice < 10000000)
      baseCount = (baseCount * 0.5).round();

    return baseCount.clamp(5, 150);
  }
}

// Danh sách các tiện ích phổ biến
class CommonAmenities {
  static const List<String> all = [
    'WiFi miễn phí',
    'Bể bơi',
    'Phòng gym',
    'Spa & Massage',
    'Nhà hàng',
    'Quầy bar',
    'Phòng họp',
    'Dịch vụ phòng 24/7',
    'Đỗ xe miễn phí',
    'Trung tâm thể dục',
    'Dịch vụ giặt ủi',
    'Dịch vụ đưa đón sân bay',
    'Phòng không hút thuốc',
    'Thang máy',
    'Điều hòa không khí',
    'Ban công/Sân hiên',
  ];
}

// Danh sách loại hình chỗ ở
class AccommodationTypes {
  static const List<String> all = [
    'Khách sạn',
    'Resort',
    'Villa',
    'Homestay',
    'Hostel',
    'Căn hộ dịch vụ',
    'Nhà nghỉ',
    'Motel',
    'Biệt thự',
    'Nhà riêng',
  ];
}
