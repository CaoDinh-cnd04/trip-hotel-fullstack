import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/promotion_offer.dart';

class PromotionOfferCard extends StatefulWidget {
  final PromotionOffer offer;
  final VoidCallback? onTap;
  final VoidCallback? onBook;

  const PromotionOfferCard({
    super.key,
    required this.offer,
    this.onTap,
    this.onBook,
  });

  @override
  State<PromotionOfferCard> createState() => _PromotionOfferCardState();
}

class _PromotionOfferCardState extends State<PromotionOfferCard> {
  @override
  void initState() {
    super.initState();
    // Cập nhật UI mỗi phút để hiển thị thời gian còn lại
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(minutes: 1), () {
      if (mounted && widget.offer.isCurrentlyActive) {
        setState(() {});
        _startTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.offer.isCurrentlyActive 
                ? Colors.red.withOpacity(0.3)
                : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.offer.isCurrentlyActive
                    ? [
                        Colors.red.shade50,
                        Colors.orange.shade50,
                      ]
                    : [
                        Colors.grey.shade50,
                        Colors.grey.shade100,
                      ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header với badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.offer.isCurrentlyActive
                              ? Colors.red
                              : Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.offer.isCurrentlyActive
                              ? 'ĐANG HOT'
                              : 'HẾT HẠN',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (widget.offer.isCurrentlyActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Còn ${widget.offer.availableRooms} phòng',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Title
                  Text(
                    widget.offer.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Description
                  Text(
                    widget.offer.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Price comparison
                  Row(
                    children: [
                      // Original price
                      Text(
                        widget.offer.formattedOriginalPrice,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Discounted price
                      Text(
                        widget.offer.formattedDiscountedPrice,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Discount percentage
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-${widget.offer.discountPercentage.isFinite && !widget.offer.discountPercentage.isNaN ? widget.offer.discountPercentage.toInt() : 0}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Savings
                  Text(
                    'Tiết kiệm ${widget.offer.formattedSavings}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Time remaining
                  if (widget.offer.isCurrentlyActive) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Còn lại: ${widget.offer.remainingTimeFormatted}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                  ],
                  
                  // Conditions
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: widget.offer.conditions.map((condition) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          condition,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[700],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Book button
                  if (widget.offer.canBook)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: widget.onBook,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'ĐẶT NGAY',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'HẾT PHÒNG',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Widget hiển thị countdown timer
class CountdownTimer extends StatefulWidget {
  final DateTime endTime;
  final VoidCallback? onExpired;

  const CountdownTimer({
    super.key,
    required this.endTime,
    this.onExpired,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Duration _remainingTime;

  @override
  void initState() {
    super.initState();
    _updateRemainingTime();
    _startTimer();
  }

  void _updateRemainingTime() {
    final now = DateTime.now();
    if (now.isBefore(widget.endTime)) {
      _remainingTime = widget.endTime.difference(now);
    } else {
      _remainingTime = Duration.zero;
      widget.onExpired?.call();
    }
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _updateRemainingTime();
        });
        if (_remainingTime > Duration.zero) {
          _startTimer();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_remainingTime <= Duration.zero) {
      return const Text(
        'Hết hạn',
        style: TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    final hours = _remainingTime.inHours;
    final minutes = _remainingTime.inMinutes % 60;
    final seconds = _remainingTime.inSeconds % 60;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTimeUnit(hours.toString().padLeft(2, '0'), 'GIỜ'),
        const Text(':', style: TextStyle(fontWeight: FontWeight.bold)),
        _buildTimeUnit(minutes.toString().padLeft(2, '0'), 'PHÚT'),
        const Text(':', style: TextStyle(fontWeight: FontWeight.bold)),
        _buildTimeUnit(seconds.toString().padLeft(2, '0'), 'GIÂY'),
      ],
    );
  }

  Widget _buildTimeUnit(String value, String label) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }
}
