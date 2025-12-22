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
  bool _isExpanded = false; // Trạng thái mở rộng chi tiết

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

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: valueColor ?? Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
    final canCancelFree = widget.booking.cancellationAllowed &&
        ['pending', 'confirmed'].contains(widget.booking.bookingStatus) &&
        hoursUntilCheckIn >= 24;
    
    // Có thể hủy (bao gồm cả trường hợp không miễn phí)
    final canCancel = ['pending', 'confirmed'].contains(widget.booking.bookingStatus);
    
    final showCancelButton = canCancelFree && _secondsLeft > 0;
    final showCancelButtonGeneral = canCancel && !canCancelFree && widget.booking.bookingStatus != 'cancelled';
    
    print('   - hoursUntilCheckIn: $hoursUntilCheckIn');
    print('   - canCancelFree (recalculated): $canCancelFree');
    print('   - canCancel (general): $canCancel');
    print('   - showCancelButton: $showCancelButton');
    print('   - showCancelButtonGeneral: $showCancelButtonGeneral');

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
                
                // Non-refundable booking notice OR Cancel button for non-free cancellation
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

                // Nút hủy cho trường hợp có thể hủy nhưng không miễn phí (hết thời gian hoặc không hoàn tiền)
                if (showCancelButtonGeneral) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[300]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.booking.cancellationAllowed 
                                        ? 'Hủy có thể không hoàn tiền hoặc mất phí'
                                        : 'Hủy không hoàn tiền',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange[900],
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 36,
                              child: ElevatedButton(
                                onPressed: widget.onCancel,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                ),
                                child: const Text('Hủy phòng'),
                              ),
                            ),
                          ],
                        ),
                        if (hoursUntilCheckIn < 24) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange[700], size: 16),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Đã qua thời gian hủy miễn phí (24h trước check-in)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else if (!widget.booking.cancellationAllowed) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange[700], size: 16),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Giá ưu đãi - Hủy sẽ không được hoàn tiền',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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

                // Xem thêm / Thu gọn chi tiết
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey[300]!, width: 1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isExpanded ? 'Thu gọn chi tiết' : 'Xem thêm chi tiết',
                          style: TextStyle(
                            color: const Color(0xFF8B4513),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: const Color(0xFF8B4513),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                // Chi tiết mở rộng
                if (_isExpanded) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thông tin người đặt
                        if (widget.booking.userName != null || widget.booking.userPhone != null) ...[
                          _buildDetailRow(
                            icon: Icons.person,
                            label: 'Người đặt',
                            value: widget.booking.userName ?? 'N/A',
                          ),
                          if (widget.booking.userPhone != null) ...[
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              icon: Icons.phone,
                              label: 'Số điện thoại',
                              value: widget.booking.userPhone!,
                            ),
                          ],
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                        ],

                        // Chi tiết giá
                        _buildDetailRow(
                          icon: Icons.attach_money,
                          label: 'Giá phòng/đêm',
                          value: CurrencyFormatter.format(widget.booking.roomPrice),
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          icon: Icons.receipt_long,
                          label: 'Tổng giá',
                          value: CurrencyFormatter.format(widget.booking.totalPrice),
                        ),
                        if (widget.booking.discountAmount > 0) ...[
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            icon: Icons.local_offer,
                            label: 'Giảm giá',
                            value: '-${CurrencyFormatter.format(widget.booking.discountAmount)}',
                            valueColor: Colors.green[700],
                          ),
                        ],
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),

                        // Thông tin thanh toán
                        _buildDetailRow(
                          icon: Icons.payment,
                          label: 'Trạng thái thanh toán',
                          value: widget.booking.paymentStatusText,
                          valueColor: widget.booking.paymentStatus == 'paid' 
                              ? Colors.green[700] 
                              : Colors.orange[700],
                        ),
                        if (widget.booking.paymentDate != null) ...[
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            icon: Icons.calendar_today,
                            label: 'Ngày thanh toán',
                            value: DateFormat('dd/MM/yyyy HH:mm').format(widget.booking.paymentDate!),
                          ),
                        ],
                        if (widget.booking.paymentTransactionId != null) ...[
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            icon: Icons.receipt,
                            label: 'Mã giao dịch',
                            value: widget.booking.paymentTransactionId!,
                          ),
                        ],
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),

                        // Thông tin đặt phòng
                        _buildDetailRow(
                          icon: Icons.access_time,
                          label: 'Ngày tạo đơn',
                          value: DateFormat('dd/MM/yyyy HH:mm').format(widget.booking.createdAt),
                        ),
                        if (widget.booking.cancelledAt != null) ...[
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            icon: Icons.cancel,
                            label: 'Ngày hủy',
                            value: DateFormat('dd/MM/yyyy HH:mm').format(widget.booking.cancelledAt!),
                            valueColor: Colors.red[700],
                          ),
                        ],
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          icon: Icons.hotel,
                          label: 'Số phòng',
                          value: '${widget.booking.roomCount} phòng',
                        ),

                        // Yêu cầu đặc biệt
                        if (widget.booking.specialRequests != null && widget.booking.specialRequests!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.note, size: 18, color: Colors.grey[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Yêu cầu đặc biệt',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.booking.specialRequests!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Thông tin hoàn tiền (nếu có)
                        if (widget.booking.refundTransactionId != null || widget.booking.refundDate != null) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          if (widget.booking.refundTransactionId != null)
                            _buildDetailRow(
                              icon: Icons.receipt_long,
                              label: 'Mã giao dịch hoàn tiền',
                              value: widget.booking.refundTransactionId!,
                            ),
                          if (widget.booking.refundDate != null) ...[
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              icon: Icons.event,
                              label: 'Ngày hoàn tiền',
                              value: DateFormat('dd/MM/yyyy HH:mm').format(widget.booking.refundDate!),
                            ),
                          ],
                          if (widget.booking.refundReason != null && widget.booking.refundReason!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info, size: 18, color: Colors.grey[700]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Lý do hoàn tiền',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.booking.refundReason!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
