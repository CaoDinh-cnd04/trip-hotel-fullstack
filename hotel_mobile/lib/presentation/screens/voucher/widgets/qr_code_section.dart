import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../data/models/booking.dart';

class QRCodeSection extends StatelessWidget {
  final Booking booking;
  final VoidCallback onCopyCode;

  const QRCodeSection({
    Key? key,
    required this.booking,
    required this.onCopyCode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Section Header
          Row(
            children: [
              Icon(Icons.qr_code, color: Colors.blue[600], size: 24),
              const SizedBox(width: 12),
              const Text(
                'Mã xác nhận đặt phòng',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: QrImageView(
              data: _generateQRData(),
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
            ),
          ),

          const SizedBox(height: 20),

          // Confirmation Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              children: [
                Text(
                  'MÃ XÁC NHẬN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  booking.id.toString(),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Copy Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onCopyCode,
              icon: Icon(Icons.copy, color: Colors.blue[600], size: 18),
              label: Text(
                'Sao chép mã',
                style: TextStyle(
                  color: Colors.blue[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide(color: Colors.blue[600]!),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // QR Instructions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber[700], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Xuất trình mã QR này tại quầy lễ tân để check-in',
                    style: TextStyle(fontSize: 12, color: Colors.amber[800]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _generateQRData() {
    // Create a comprehensive QR code data string
    return 'HOTEL_BOOKING|'
        'ID:${booking.id}|'
        'HOTEL:${booking.tenKhachSan ?? "Hotel"}|'
        'CHECKIN:${booking.ngayNhanPhong.toIso8601String()}|'
        'CHECKOUT:${booking.ngayTraPhong.toIso8601String()}|'
        'GUESTS:${booking.soLuongKhach}|'
        'AMOUNT:${booking.tongTien}';
  }
}
