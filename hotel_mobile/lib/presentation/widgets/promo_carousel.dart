import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/promotion.dart';
import 'promotion_card.dart';

class PromoCarousel extends StatefulWidget {
  final List<Promotion> promotions;
  final Function(Promotion) onPromotionTap;
  final Function(Promotion)? onPromotionApply;

  const PromoCarousel({
    super.key,
    required this.promotions,
    required this.onPromotionTap,
    this.onPromotionApply,
  });

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.9,
      initialPage: 0,
    );
    _startAutoScroll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    if (widget.promotions.isEmpty) return;
    
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      
      int nextPage = _currentPage + 1;
      if (nextPage >= widget.promotions.length) {
        nextPage = 0;
      }

      if (_pageController.hasClients && _pageController.positions.isNotEmpty) {
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  String _getTimeLeft(DateTime endDate) {
    final now = DateTime.now();
    final difference = endDate.difference(now);

    if (difference.isNegative) {
      return 'Đã hết hạn';
    }

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;

    if (days > 0) {
      return 'Còn lại: ${days}d ${hours}h';
    } else if (hours > 0) {
      return 'Còn lại: ${hours}h ${minutes}m';
    } else {
      return 'Còn lại: ${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.promotions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Carousel
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.promotions.length,
            itemBuilder: (context, index) {
              final promotion = widget.promotions[index];
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.hasClients &&
                      _pageController.positions.isNotEmpty &&
                      _pageController.position.haveDimensions) {
                    value = (_pageController.page ?? 0) - index;
                    value = (1 - (value.abs() * 0.1)).clamp(0.9, 1.0);
                  }
                  
                  return Center(
                    child: SizedBox(
                      height: Curves.easeInOut.transform(value) * 300,
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: PromotionCard(
                    promotion: promotion,
                    timeLeft: _getTimeLeft(promotion.ngayKetThuc),
                    onTap: () => widget.onPromotionTap(promotion),
                    onApply: widget.onPromotionApply != null
                        ? () => widget.onPromotionApply!(promotion)
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Page Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.promotions.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? const Color(0xFF003580)
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

