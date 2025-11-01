import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/models/booking_model.dart';
import 'package:hotel_mobile/core/utils/currency_formatter.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class BookingCard extends StatefulWidget {
  final BookingModel booking;
  final VoidCallback? onCancel;
  final VoidCallback? onRefresh;
  final VoidCallback? onChatWithHotel;

  const BookingCard({
    Key? key,
    required this.booking,
    this.onCancel,
    this.onRefresh,
    this.onChatWithHotel,
  }) : super(key: key);

  @override
  State<BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<BookingCard> {
  Timer? _countdownTimer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    
    // Tính lại thời gian còn lại từ checkInDate nếu cần
    final now = DateTime.now();
    final timeUntilCheckIn = widget.booking.checkInDate.difference(now);
    final calculatedSecondsLeft = timeUntilCheckIn.inSeconds;
    
    // Sử dụng giá trị từ backend hoặc tính lại nếu backend trả về giá trị không hợp lệ
    if (widget.booking.secondsLeftToCancel > 0) {
      _secondsLeft = widget.booking.secondsLeftToCancel;
    } else if (calculatedSecondsLeft > 0) {
      _secondsLeft = calculatedSecondsLeft;
      print('⚠️ Backend secondsLeftToCancel = ${widget.booking.secondsLeftToCancel}, '
          'using calculated value: $_secondsLeft');
    } else {
      _secondsLeft = 0;
    }
    
    // Kiểm tra lại canCancel để khởi động countdown
    final hoursUntilCheckIn = timeUntilCheckIn.inHours;
    final canCancel = widget.booking.cancellationAllowed &&
        ['pending', 'confirmed'].contains(widget.booking.bookingStatus) &&
        hoursUntilCheckIn >= 24;
    
    if (canCancel && _secondsLeft > 0) {
      _startCountdown();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        timer.cancel();
        widget.onRefresh?.call(); // Refresh to update UI
      }
    });
  }

  String _formatCountdown(int seconds) {
    // ✅ NEW: Format as hours if > 60 minutes, otherwise show minutes
    final totalMinutes = seconds ~/ 60;
    
    if (totalMinutes >= 60) {
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      return '$hours giờ ${minutes > 0 ? '$minutes phút' : ''}';
    } else if (totalMinutes > 0) {
      return '$totalMinutes phút';
    } else {
      return '$seconds giây';
    }
  }

  Color _getStatusColor() {
    switch (widget.booking.bookingStatus) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentIcon() {
    switch (widget.booking.paymentMethod) {
      case 'vnpay':
        return Icons.credit_card;
      case 'momo':
        return Icons.account_balance_wallet;
      case 'cash':
        return Icons.money;
      default:
        return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    // Debug: Log booking cancellation info
    print('🔍 Booking ${widget.booking.bookingCode}:');
    print('   - cancellationAllowed: ${widget.booking.cancellationAllowed}');
    print('   - canCancelNow: ${widget.booking.canCancelNow}');
    print('   - secondsLeft: $_secondsLeft');
    print('   - bookingStatus: ${widget.booking.bookingStatus}');
    print('   - checkInDate: ${widget.booking.checkInDate}');
    
    // Tính toán lại thời gian còn lại nếu cần
    final now = DateTime.now();
    final timeUntilCheckIn = widget.booking.checkInDate.difference(now);
    final hoursUntilCheckIn = timeUntilCheckIn.inHours;
    
    // Kiểm tra có thể hủy: cancellationAllowed + status hợp lệ + >= 24h
    final canCancel = widget.booking.cancellationAllowed &&
        ['pending', 'confirmed'].contains(widget.booking.bookingStatus) &&
        hoursUntilCheckIn >= 24;
    
    final showCancelButton = canCancel && _secondsLeft > 0;
    
    print('   - hoursUntilCheckIn: $hoursUntilCheckIn');
    print('   - canCancel (recalculated): $canCancel');
    print('   - showCancelButton: $showCancelButton');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
              color: const Color(0xFF8B4513).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.booking.bookingCode,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.booking.hotelName ?? 'Khách sạn',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.booking.bookingStatusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            ),
          ],
        ),
          ),

          // Content
          Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                // Room info
                Row(
                  children: [
                    Icon(Icons.meeting_room, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${widget.booking.roomType ?? 'Phòng'} - Số ${widget.booking.roomNumber}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Check-in / Check-out
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.login, size: 20, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nhận phòng',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              Text(
                                dateFormat.format(widget.booking.checkInDate),
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 20, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Trả phòng',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              Text(
                                dateFormat.format(widget.booking.checkOutDate),
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Guests
                Row(
                  children: [
                    Icon(Icons.people, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.booking.guestCount} khách, ${widget.booking.nights} đêm',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Payment info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
              Row(
                children: [
                        Icon(_getPaymentIcon(), size: 20, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          widget.booking.paymentMethodText,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    Text(
                      CurrencyFormatter.format(widget.booking.finalPrice),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF8B4513),
                      ),
                    ),
                  ],
                ),

                // Refund info
                if (widget.booking.refundStatus != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.booking.refundStatus == 'completed'
                          ? Colors.green[50]
                          : Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.booking.refundStatus == 'completed'
                            ? Colors.green[300]!
                            : Colors.orange[300]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.booking.refundStatus == 'completed'
                              ? Icons.check_circle
                              : Icons.info,
                          color: widget.booking.refundStatus == 'completed'
                              ? Colors.green[700]
                              : Colors.orange[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                                widget.booking.refundStatusText,
                                style: TextStyle(
                            fontWeight: FontWeight.bold,
                                  color: widget.booking.refundStatus == 'completed'
                                      ? Colors.green[900]
                                      : Colors.orange[900],
                          ),
                        ),
                              if (widget.booking.refundAmount > 0)
                        Text(
                                  CurrencyFormatter.format(widget.booking.refundAmount),
                          style: TextStyle(
                                    fontSize: 12,
                                    color: widget.booking.refundStatus == 'completed'
                                        ? Colors.green[800]
                                        : Colors.orange[800],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Cancel button with countdown (for refundable bookings)
                if (showCancelButton) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[300]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Hủy miễn phí',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[900],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 36,
                              child: ElevatedButton(
                                onPressed: widget.onCancel,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                ),
                                child: const Text('Hủy phòng'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.timer, color: Colors.orange[700], size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Còn ${_formatCountdown(_secondsLeft)} để hủy miễn phí (trước 24h check-in)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Non-refundable booking notice
                if (!widget.booking.cancellationAllowed && 
                    widget.booking.bookingStatus == 'confirmed') ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.block, color: Colors.grey[600], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Không thể hủy - Giá ưu đãi không hoàn tiền',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Chat with hotel button
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: widget.onChatWithHotel,
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Chat với khách sạn'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8B4513),
                      side: const BorderSide(color: Color(0xFF8B4513)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
