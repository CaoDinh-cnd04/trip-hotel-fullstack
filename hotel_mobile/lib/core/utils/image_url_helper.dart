import '../constants/app_constants.dart';

class ImageUrlHelper {
  // Base URL for images (without /api/v2)
  // Sử dụng base URL từ AppConstants để đồng bộ
  static String get _baseUrl => AppConstants.baseUrl;

  /// Get full image URL for any image path
  static String getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return getDefaultImageUrl();
    }

    // If it's already a full URL, return as is
    if (imagePath.startsWith('http')) {
      return imagePath;
    }

    // If it starts with /, remove it to avoid double slashes
    if (imagePath.startsWith('/')) {
      return '$_baseUrl$imagePath';
    }

    // Otherwise, add /images/ prefix for static images
    return '$_baseUrl/images/$imagePath';
  }

  /// Get hotel image URL
  static String getHotelImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return getDefaultHotelImageUrl();
    }

    if (imagePath.startsWith('http')) {
      return imagePath;
    }

    // For hotel images, they are usually in /images/hotels/
    if (imagePath.startsWith('/')) {
      return '$_baseUrl$imagePath';
    }

    return '$_baseUrl/images/hotels/$imagePath';
  }

  /// Get room image URL
  static String getRoomImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return getDefaultRoomImageUrl();
    }

    if (imagePath.startsWith('http')) {
      return imagePath;
    }

    // For room images, they are usually in /images/rooms/
    if (imagePath.startsWith('/')) {
      return '$_baseUrl$imagePath';
    }

    return '$_baseUrl/images/rooms/$imagePath';
  }

  /// Get location image URL
  static String getLocationImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return getDefaultLocationImageUrl();
    }

    if (imagePath.startsWith('http')) {
      return imagePath;
    }

    // For location images, they are usually in /images/locations/
    if (imagePath.startsWith('/')) {
      return '$_baseUrl$imagePath';
    }

    return '$_baseUrl/images/locations/$imagePath';
  }

  /// Get province/country image URL
  static String getProvinceImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return getDefaultProvinceImageUrl();
    }

    if (imagePath.startsWith('http')) {
      return imagePath;
    }

    // For province images, they are usually in /images/provinces/
    if (imagePath.startsWith('/')) {
      return '$_baseUrl$imagePath';
    }

    return '$_baseUrl/images/provinces/$imagePath';
  }

  /// Get country image URL
  static String getCountryImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return getDefaultCountryImageUrl();
    }

    if (imagePath.startsWith('http')) {
      return imagePath;
    }

    // For country images, they are usually in /images/countries/
    if (imagePath.startsWith('/')) {
      return '$_baseUrl$imagePath';
    }

    return '$_baseUrl/images/countries/$imagePath';
  }

  /// Get user avatar URL (from uploads folder)
  static String getUserAvatarUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return getDefaultUserAvatarUrl();
    }

    if (imagePath.startsWith('http')) {
      return imagePath;
    }

    // For user avatars, they are in /uploads/
    if (imagePath.startsWith('/')) {
      return '$_baseUrl$imagePath';
    }

    return '$_baseUrl/uploads/$imagePath';
  }

  // Default image URLs
  static String getDefaultImageUrl() {
    return 'https://via.placeholder.com/300x200?text=No+Image';
  }

  static String getDefaultHotelImageUrl() {
    return '$_baseUrl/images/Defaut.jpg';
  }

  static String getDefaultRoomImageUrl() {
    return '$_baseUrl/images/Defaut.jpg';
  }

  static String getDefaultLocationImageUrl() {
    return '$_baseUrl/images/Defaut.jpg';
  }

  static String getDefaultProvinceImageUrl() {
    return '$_baseUrl/images/Defaut.jpg';
  }

  static String getDefaultCountryImageUrl() {
    return '$_baseUrl/images/Defaut.jpg';
  }

  static String getDefaultUserAvatarUrl() {
    return '$_baseUrl/images/Defaut.jpg';
  }

  /// Get hero banner URL
  static String getHeroBannerUrl() {
    return '$_baseUrl/images/hero-banner.jpg';
  }

  /// Get logo URL
  static String getLogoUrl() {
    return '$_baseUrl/images/logo.png';
  }

  /// Check if image URL is valid
  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('http') || url.startsWith('/');
  }

  /// Get image URLs for a list of image paths
  static List<String> getImageUrls(List<String?> imagePaths) {
    return imagePaths
        .where((path) => path != null && path.isNotEmpty)
        .map((path) => getImageUrl(path))
        .toList();
  }

  /// Get hotel image URLs
  static List<String> getHotelImageUrls(List<String?> imagePaths) {
    return imagePaths
        .where((path) => path != null && path.isNotEmpty)
        .map((path) => getHotelImageUrl(path))
        .toList();
  }

  /// Get room image URLs
  static List<String> getRoomImageUrls(List<String?> imagePaths) {
    return imagePaths
        .where((path) => path != null && path.isNotEmpty)
        .map((path) => getRoomImageUrl(path))
        .toList();
  }
}
