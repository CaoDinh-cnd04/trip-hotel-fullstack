import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/image_model.dart';

class ImageDisplayWidget extends StatelessWidget {
  final ImageModel image;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool showInfo;
  final bool showDeleteButton;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final String? placeholder;
  final String? errorWidget;

  const ImageDisplayWidget({
    super.key,
    required this.image,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.showInfo = false,
    this.showDeleteButton = false,
    this.onDelete,
    this.onTap,
    this.placeholder,
    this.errorWidget,
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
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: borderRadius ?? BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: image.url,
                width: width,
                height: height,
                fit: fit,
                placeholder: (context, url) => _buildPlaceholder(),
                errorWidget: (context, url, error) => _buildErrorWidget(),
                fadeInDuration: const Duration(milliseconds: 300),
                fadeOutDuration: const Duration(milliseconds: 300),
              ),
            ),
            if (showInfo) _buildInfoOverlay(),
            if (showDeleteButton) _buildDeleteButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 8),
          Text(
            placeholder ?? 'Đang tải...',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            errorWidget ?? 'Lỗi tải ảnh',
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: borderRadius?.bottomLeft ?? const Radius.circular(8),
            bottomRight: borderRadius?.bottomRight ?? const Radius.circular(8),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              image.originalName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  image.formattedFileSize,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
                Text(
                  image.formattedDimensions,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Positioned(
      top: 4,
      right: 4,
      child: GestureDetector(
        onTap: onDelete,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.close,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }
}

class ImageGalleryWidget extends StatelessWidget {
  final List<ImageModel> images;
  final double? itemWidth;
  final double? itemHeight;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final bool showInfo;
  final bool showDeleteButton;
  final Function(ImageModel)? onImageTap;
  final Function(ImageModel)? onImageDelete;
  final String? emptyMessage;

  const ImageGalleryWidget({
    super.key,
    required this.images,
    this.itemWidth,
    this.itemHeight,
    this.crossAxisCount = 3,
    this.crossAxisSpacing = 8,
    this.mainAxisSpacing = 8,
    this.showInfo = false,
    this.showDeleteButton = false,
    this.onImageTap,
    this.onImageDelete,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage ?? 'Chưa có ảnh nào',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: itemWidth != null && itemHeight != null
            ? itemWidth! / itemHeight!
            : 1,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final image = images[index];
        return ImageDisplayWidget(
          image: image,
          width: itemWidth,
          height: itemHeight,
          showInfo: showInfo,
          showDeleteButton: showDeleteButton,
          onTap: onImageTap != null ? () => onImageTap!(image) : null,
          onDelete: onImageDelete != null ? () => onImageDelete!(image) : null,
        );
      },
    );
  }
}

class ImageCarouselWidget extends StatefulWidget {
  final List<ImageModel> images;
  final double height;
  final bool showIndicators;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final Function(ImageModel)? onImageTap;

  const ImageCarouselWidget({
    super.key,
    required this.images,
    this.height = 200,
    this.showIndicators = true,
    this.autoPlay = false,
    this.autoPlayInterval = const Duration(seconds: 3),
    this.onImageTap,
  });

  @override
  State<ImageCarouselWidget> createState() => _ImageCarouselWidgetState();
}

class _ImageCarouselWidgetState extends State<ImageCarouselWidget> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    if (widget.autoPlay && widget.images.length > 1) {
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    Future.delayed(widget.autoPlayInterval, () {
      if (mounted && widget.autoPlay) {
        _nextImage();
        _startAutoPlay();
      }
    });
  }

  void _nextImage() {
    if (!_pageController.hasClients || _pageController.positions.isEmpty) return;
    
    if (_currentIndex < widget.images.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 48,
                color: Colors.grey,
              ),
              SizedBox(height: 8),
              Text(
                'Chưa có ảnh nào',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              final image = widget.images[index];
              return ImageDisplayWidget(
                image: image,
                width: double.infinity,
                height: widget.height,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(8),
                onTap: widget.onImageTap != null ? () => widget.onImageTap!(image) : null,
              );
            },
          ),
        ),
        if (widget.showIndicators && widget.images.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.images.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == index
                      ? Theme.of(context).primaryColor
                      : Colors.grey[300],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class ImageViewerDialog extends StatelessWidget {
  final List<ImageModel> images;
  final int initialIndex;
  final String? title;

  const ImageViewerDialog({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (title != null) ...[
                    Expanded(
                      child: Text(
                        title!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Image viewer
            Expanded(
              child: PageView.builder(
                itemCount: images.length,
                controller: PageController(initialPage: initialIndex),
                itemBuilder: (context, index) {
                  final image = images[index];
                  return InteractiveViewer(
                    child: Center(
                      child: CachedNetworkImage(
                        imageUrl: image.url,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(
                            Icons.error,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Image info
            if (images.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      images[initialIndex].originalName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${images[initialIndex].formattedFileSize} • ${images[initialIndex].formattedDimensions}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
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

  static void show(BuildContext context, {
    required List<ImageModel> images,
    int initialIndex = 0,
    String? title,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ImageViewerDialog(
        images: images,
        initialIndex: initialIndex,
        title: title,
      ),
    );
  }
}
