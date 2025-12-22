import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/booking.dart';

/// Service tạo và xuất PDF voucher cho booking
/// 
/// Chức năng:
/// - Tạo PDF voucher từ thông tin booking
/// - Bao gồm: Header, Booking Info, QR Code, Booking Details, Policy Info, Footer
/// - Lưu PDF vào temporary directory
/// - Share PDF để in hoặc gửi
/// 
/// Singleton pattern - chỉ có 1 instance duy nhất
class PDFService {
  static final PDFService _instance = PDFService._internal();
  factory PDFService() => _instance;
  PDFService._internal();

  /// Tạo và xuất PDF voucher cho booking
  /// 
  /// [booking] - Thông tin booking cần tạo voucher
  /// 
  /// Quy trình:
  /// 1. Load font (Roboto-Regular.ttf) để hiển thị tiếng Việt
  /// 2. Tạo PDF với các section: Header, Booking Info, QR Code, Details, Policy, Footer
  /// 3. Lưu PDF vào temporary directory
  /// 4. Share PDF để user có thể in hoặc gửi
  /// 
  /// Throws Exception nếu không thể tạo PDF
  Future<void> generateVoucherPDF(Booking booking) async {
    try {
      final pdf = pw.Document();

      // Load font for Vietnamese text
      final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final ttf = pw.Font.ttf(fontData);

      // Add pages to PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) => [
            _buildHeader(booking, ttf),
            pw.SizedBox(height: 20),
            _buildBookingInfo(booking, ttf),
            pw.SizedBox(height: 20),
            _buildQRCodeSection(booking, ttf),
            pw.SizedBox(height: 20),
            _buildBookingDetails(booking, ttf),
            pw.SizedBox(height: 20),
            _buildPolicyInfo(booking, ttf),
            pw.SizedBox(height: 20),
            _buildFooter(booking, ttf),
          ],
        ),
      );

      // Save and share PDF
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/voucher_${booking.id}.pdf');
      await file.writeAsBytes(await pdf.save());

      // Share PDF
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'voucher_${booking.id}.pdf',
      );
    } catch (e) {
      throw Exception('Không thể tạo PDF: ${e.toString()}');
    }
  }

  pw.Widget _buildHeader(Booking booking, pw.Font font) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'VOUCHER ĐẶT PHÒNG',
            style: pw.TextStyle(
              font: font,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Mã đặt phòng: ${booking.id}',
            style: pw.TextStyle(
              font: font,
              fontSize: 16,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Ngày tạo: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: pw.TextStyle(
              font: font,
              fontSize: 12,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildBookingInfo(Booking booking, pw.Font font) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'THÔNG TIN KHÁCH SẠN',
            style: pw.TextStyle(
              font: font,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            booking.tenKhachSan ?? 'Tên khách sạn',
            style: pw.TextStyle(
              font: font,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Địa chỉ khách sạn',
            style: pw.TextStyle(font: font, fontSize: 12),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'NHẬN PHÒNG',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    DateFormat('dd/MM/yyyy').format(booking.ngayNhanPhong),
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    DateFormat('EEEE', 'vi_VN').format(booking.ngayNhanPhong),
                    style: pw.TextStyle(font: font, fontSize: 10),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'TRẢ PHÒNG',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    DateFormat('dd/MM/yyyy').format(booking.ngayTraPhong),
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    DateFormat('EEEE', 'vi_VN').format(booking.ngayTraPhong),
                    style: pw.TextStyle(font: font, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildQRCodeSection(Booking booking, pw.Font font) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'MÃ XÁC NHẬN',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  booking.id.toString(),
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Xuất trình mã này tại quầy lễ tân',
                  style: pw.TextStyle(font: font, fontSize: 10),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 20),
          pw.BarcodeWidget(
            barcode: pw.Barcode.qrCode(),
            data: _generateQRData(booking),
            width: 100,
            height: 100,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildBookingDetails(Booking booking, pw.Font font) {
    final nights = booking.ngayTraPhong
        .difference(booking.ngayNhanPhong)
        .inDays;

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'CHI TIẾT ĐẶT PHÒNG',
            style: pw.TextStyle(
              font: font,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          _buildDetailRow(
            'Loại phòng',
            booking.tenLoaiPhong ?? 'Standard Room',
            font,
          ),
          _buildDetailRow('Số khách', '${booking.soLuongKhach} người', font),
          _buildDetailRow('Số đêm', '$nights đêm', font),
          _buildDetailRow(
            'Khách hàng',
            booking.tenNguoiDung ?? 'Tên khách hàng',
            font,
          ),
          _buildDetailRow('Email', booking.emailNguoiDung ?? 'Email', font),
          _buildDetailRow(
            'Điện thoại',
            booking.soDienThoai ?? 'Số điện thoại',
            font,
          ),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'TỔNG TIỀN',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                _formatCurrency(booking.tongTien),
                style: pw.TextStyle(
                  font: font,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDetailRow(String label, String value, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: font, fontSize: 10)),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPolicyInfo(Booking booking, pw.Font font) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'CHÍNH SÁCH KHÁCH SẠN',
            style: pw.TextStyle(
              font: font,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '• Check-in: Từ 14:00, Check-out: Trước 12:00',
            style: pw.TextStyle(font: font, fontSize: 10),
          ),
          pw.Text(
            '• Hủy miễn phí: Trước 24h so với ngày nhận phòng',
            style: pw.TextStyle(font: font, fontSize: 10),
          ),
          pw.Text(
            '• Mang theo CMND/CCCD khi check-in',
            style: pw.TextStyle(font: font, fontSize: 10),
          ),
          pw.Text(
            '• Hotline hỗ trợ: 1900-1234 (24/7)',
            style: pw.TextStyle(font: font, fontSize: 10),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(Booking booking, pw.Font font) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'Cảm ơn bạn đã đặt phòng!',
            style: pw.TextStyle(
              font: font,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Chúc bạn có một kỳ nghỉ tuyệt vời!',
            style: pw.TextStyle(font: font, fontSize: 10),
          ),
        ],
      ),
    );
  }

  String _generateQRData(Booking booking) {
    return 'HOTEL_BOOKING|'
        'ID:${booking.id}|'
        'HOTEL:${booking.tenKhachSan ?? "Hotel"}|'
        'CHECKIN:${booking.ngayNhanPhong.toIso8601String()}|'
        'CHECKOUT:${booking.ngayTraPhong.toIso8601String()}|'
        'GUESTS:${booking.soLuongKhach}|'
        'AMOUNT:${booking.tongTien}';
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '',
      decimalDigits: 0,
    );
    return '${formatter.format(amount)} VND';
  }
}
