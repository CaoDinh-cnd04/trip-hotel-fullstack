import 'package:json_annotation/json_annotation.dart';

part 'notification_model.g.dart';

// Notification model
@JsonSerializable()
class NotificationModel {
  final int id;
  final String tieuDe;
  final String noiDung;
  final String loaiThongBao;
  final String? urlHinhAnh;
  final String? urlHanhDong;
  final String? vanBanNut;
  final int? khachSanId;
  final DateTime? ngayHetHan;
  final bool hienThi;
  final String doiTuongNhan;
  final int? nguoiDungId;
  final bool guiEmail;
  final int nguoiTaoId;
  final DateTime ngayTao;
  final DateTime? ngayCapNhat;
  final bool daDoc;

  NotificationModel({
    required this.id,
    required this.tieuDe,
    required this.noiDung,
    required this.loaiThongBao,
    this.urlHinhAnh,
    this.urlHanhDong,
    this.vanBanNut,
    this.khachSanId,
    this.ngayHetHan,
    required this.hienThi,
    required this.doiTuongNhan,
    this.nguoiDungId,
    required this.guiEmail,
    required this.nguoiTaoId,
    required this.ngayTao,
    this.ngayCapNhat,
    this.daDoc = false,
  });

  /// Tạo NotificationModel từ JSON sử dụng json_serializable
  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);

  /// Chuyển NotificationModel thành JSON sử dụng json_serializable
  Map<String, dynamic> toJson() => _$NotificationModelToJson(this);

  /// Factory method tùy chỉnh để xử lý cả field tiếng Việt và tiếng Anh
  factory NotificationModel.fromJsonCustom(Map<String, dynamic> json) {
    // Safe date parsing
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      try {
        if (value is String) {
          return DateTime.parse(value);
        } else if (value is DateTime) {
          return value;
        }
        return null;
      } catch (e) {
        print('⚠️ Error parsing date: $value');
        return null;
      }
    }

    // Safe int parsing
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    // Safe bool parsing
    bool parseBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value.toLowerCase() == 'true';
      return false;
    }

    // Helper function để parse string an toàn
    String safeString(dynamic value, {String defaultValue = ''}) {
      if (value == null) return defaultValue;
      if (value is String) return value.isEmpty ? defaultValue : value;
      return value.toString();
    }

    // Support both Vietnamese and English field names
    final id = parseInt(json['id'] ?? json['ma_thong_bao']) ?? 0;
    final tieuDe = safeString(json['tieu_de'] ?? json['title'] ?? json['tieuDe'], defaultValue: '');
    final noiDung = safeString(json['noi_dung'] ?? json['content'] ?? json['noiDung'], defaultValue: '');

    // Map loai_thong_bao (Vietnamese) to type (English) if needed
    String loaiThongBao = safeString(json['loai_thong_bao'] ?? json['type'] ?? json['loaiThongBao'], defaultValue: 'system');
    // Reverse mapping: Vietnamese → English for consistency
    if (loaiThongBao == 'Ưu đãi' || loaiThongBao.toLowerCase() == 'ưu đãi')
      loaiThongBao = 'promotion';
    else if (loaiThongBao == 'Phòng mới' || loaiThongBao.toLowerCase() == 'phòng mới')
      loaiThongBao = 'new_room';
    else if (loaiThongBao == 'Chương trình app' || loaiThongBao.toLowerCase() == 'chương trình app')
      loaiThongBao = 'app_program';
    else if (loaiThongBao == 'Đặt phòng thành công' || loaiThongBao.toLowerCase() == 'đặt phòng thành công')
      loaiThongBao = 'booking_success';
    else if (loaiThongBao == 'general' || loaiThongBao.toLowerCase() == 'general')
      loaiThongBao = 'promotion'; // Map 'general' to 'promotion' for display

    final ngayTao =
        parseDate(json['ngay_tao'] ?? json['created_at']) ?? DateTime.now();

    // Helper function để parse nullable string an toàn
    String? safeStringNullable(dynamic value) {
      if (value == null) return null;
      if (value is String) return value.isEmpty ? null : value;
      final str = value.toString();
      return str.isEmpty ? null : str;
    }

    return NotificationModel(
      id: id,
      tieuDe: tieuDe,
      noiDung: noiDung,
      loaiThongBao: loaiThongBao,
      urlHinhAnh: safeStringNullable(json['url_hinh_anh'] ?? json['image_url'] ?? json['urlHinhAnh']),
      urlHanhDong: safeStringNullable(json['url_hanh_dong'] ?? json['action_url'] ?? json['urlHanhDong']),
      vanBanNut: safeStringNullable(json['van_ban_nut'] ?? json['action_text'] ?? json['vanBanNut']),
      khachSanId: parseInt(json['khach_san_id'] ?? json['hotel_id'] ?? json['khachSanId']),
      ngayHetHan: parseDate(json['ngay_het_han'] ?? json['expires_at'] ?? json['ngayHetHan']),
      hienThi: parseBool(json['hien_thi'] ?? json['is_visible'] ?? json['hienThi'] ?? true),
      doiTuongNhan: safeString(json['doi_tuong_nhan'] ?? json['target_audience'] ?? json['doiTuongNhan'] ?? 'all'),
      nguoiDungId: parseInt(json['nguoi_dung_id'] ?? json['user_id'] ?? json['nguoiDungId']),
      guiEmail: parseBool(json['gui_email'] ?? json['send_email'] ?? json['guiEmail']),
      nguoiTaoId: parseInt(json['nguoi_tao_id'] ?? json['created_by_id'] ?? json['nguoiTaoId']) ?? 0,
      ngayTao: ngayTao,
      ngayCapNhat: parseDate(json['ngay_cap_nhat'] ?? json['updated_at'] ?? json['ngayCapNhat']),
      daDoc: parseBool(json['da_doc'] ?? json['is_read'] ?? json['daDoc']),
    );
  }

  String get emoji {
    switch (loaiThongBao) {
      case 'promotion':
        return '🎉';
      case 'new_room':
        return '🏨';
      case 'app_program':
        return '📱';
      case 'booking_success':
        return '✅';
      default:
        return '🔔';
    }
  }

  String get timeAgo {
    final difference = DateTime.now().difference(ngayTao);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} năm trước';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} tháng trước';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
}
