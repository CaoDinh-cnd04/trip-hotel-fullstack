import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/booking.dart';

class VoucherHeader extends StatelessWidget {
  final Booking booking;

  const VoucherHeader({Key? key, required this.booking}) : super(key: key);

  Color _getStatusBgColor() {
    switch (booking.trangThai) {
      case BookingStatus.confirmed:
        return Colors.green[50]!;
      case BookingStatus.pending:
        return Colors.orange[50]!;
      case BookingStatus.cancelled:
        return Colors.red[50]!;
      case BookingStatus.checkedIn:
        return Colors.blue[50]!;
      case BookingStatus.checkedOut:
        return Colors.purple[50]!;
    }
  }

  Color _getStatusTextColor() {
    switch (booking.trangThai) {
      case BookingStatus.confirmed:
        return Colors.green[700]!;
      case BookingStatus.pending:
        return Colors.orange[700]!;
      case BookingStatus.cancelled:
        return Colors.red[700]!;
      case BookingStatus.checkedIn:
        return Colors.blue[700]!;
      case BookingStatus.checkedOut:
        return Colors.purple[700]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusBgColor(),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getStatusTextColor()),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      booking.trangThai == BookingStatus.confirmed
                          ? Icons.check_circle
                          : booking.trangThai == BookingStatus.pending
                          ? Icons.schedule
                          : booking.trangThai == BookingStatus.cancelled
                          ? Icons.cancel
                          : Icons.info,
                      color: _getStatusTextColor(),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getStatusDisplayName(),
                      style: TextStyle(
                        color: _getStatusTextColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Booking Date
              Text(
                'Đặt: ${DateFormat('dd/MM/yyyy').format(booking.ngayTao ?? DateTime.now())}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Hotel Name
          Text(
            booking.tenKhachSan ?? 'Tên khách sạn',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // Hotel Address
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Địa chỉ khách sạn', // You might want to add address to booking model
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Check-in/out Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Check-in
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NHẬN PHÒNG',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM/yyyy').format(booking.ngayNhanPhong),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat(
                          'EEEE',
                          'vi_VN',
                        ).format(booking.ngayNhanPhong),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  width: 2,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),

                const SizedBox(width: 16),

                // Check-out
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TRẢ PHÒNG',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM/yyyy').format(booking.ngayTraPhong),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat(
                          'EEEE',
                          'vi_VN',
                        ).format(booking.ngayTraPhong),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusDisplayName() {
    switch (booking.trangThai) {
      case BookingStatus.pending:
        return 'Đang xử lý';
      case BookingStatus.confirmed:
        return 'Đã xác nhận';
      case BookingStatus.checkedIn:
        return 'Đã nhận phòng';
      case BookingStatus.checkedOut:
        return 'Đã trả phòng';
      case BookingStatus.cancelled:
        return 'Đã hủy';
    }
  }
}
