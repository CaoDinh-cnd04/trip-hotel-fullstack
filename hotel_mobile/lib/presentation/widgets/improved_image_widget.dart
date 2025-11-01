import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImprovedImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final VoidCallback? onTap;

  const ImprovedImageWidget({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? BorderRadius.circular(8),
          color: Colors.grey[200],
        ),
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.circular(8),
          child: _buildImageContent(),
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    // If no image URL, show placeholder
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildDefaultPlaceholder();
    }

    // Check if URL is valid
    if (!_isValidUrl(imageUrl!)) {
      print('❌ IMAGE ERROR: Invalid URL: $imageUrl');
      return _buildDefaultPlaceholder();
    }
    
    // Use CachedNetworkImage for better performance
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? _buildLoadingPlaceholder(),
      errorWidget: (context, url, error) {
        print('❌ IMAGE LOAD ERROR: $url - $error');
        return errorWidget ?? _buildErrorPlaceholder();
      },
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 300),
      memCacheWidth: (width != null && width!.isFinite && !width!.isNaN) ? width!.toInt() : null,
      memCacheHeight: (height != null && height!.isFinite && !height!.isNaN) ? height!.toInt() : null,
    );
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: (height != null && height! < 100) ? 24 : 48,
            color: Colors.grey[400],
          ),
          if (height != null && height! > 60) ...[
            const SizedBox(height: 8),
            Text(
              'Không có hình ảnh',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: (height != null && height! < 100) ? 20 : 40,
            color: Colors.grey[400],
          ),
          if (height != null && height! > 60) ...[
            const SizedBox(height: 8),
            Text(
              'Lỗi tải hình',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
}

// Hotel Image Widget with specific styling
class HotelImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const HotelImageWidget({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.onTap,
  });
  
  String? _getFullImageUrl() {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return null;
    }
    
    // If already a full URL, return as is
    if (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://')) {
      return imageUrl;
    }
    
    // Otherwise, prepend base URL
    final fullUrl = 'http://10.0.2.2:5000/images/hotels/$imageUrl';
    print('📸 HotelImageWidget: $imageUrl -> $fullUrl');
    return fullUrl;
  }

  @override
  Widget build(BuildContext context) {
    return ImprovedImageWidget(
      imageUrl: _getFullImageUrl(),
      width: width,
      height: height,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      placeholder: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hotel,
              size: (height != null && height! < 100) ? 24 : 48,
              color: Colors.grey[400],
            ),
            if (height != null && height! > 60) ...[
              const SizedBox(height: 8),
              Text(
                'Khách sạn',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
      errorWidget: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hotel,
              size: (height != null && height! < 100) ? 24 : 48,
              color: Colors.grey[400],
            ),
            if (height != null && height! > 60) ...[
              const SizedBox(height: 8),
              Text(
                'Khách sạn',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Room Image Widget with specific styling
class RoomImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const RoomImageWidget({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.onTap,
  });
  
  String? _getFullImageUrl() {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return null;
    }
    
    // If already a full URL, return as is
    if (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://')) {
      return imageUrl;
    }
    
    // Otherwise, prepend base URL for rooms
    return 'http://10.0.2.2:5000/images/rooms/$imageUrl';
  }

  @override
  Widget build(BuildContext context) {
    return ImprovedImageWidget(
      imageUrl: _getFullImageUrl(),
      width: width,
      height: height,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      placeholder: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bed,
              size: (height != null && height! < 100) ? 24 : 48,
              color: Colors.grey[400],
            ),
            if (height != null && height! > 60) ...[
              const SizedBox(height: 8),
              Text(
                'Phòng',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
      errorWidget: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bed,
              size: (height != null && height! < 100) ? 24 : 48,
              color: Colors.grey[400],
            ),
            if (height != null && height! > 60) ...[
              const SizedBox(height: 8),
              Text(
                'Phòng',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
