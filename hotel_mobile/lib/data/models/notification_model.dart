// Notification model
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

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
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

    // Support both Vietnamese and English field names
    final id = parseInt(json['id'] ?? json['ma_thong_bao']) ?? 0;
    final tieuDe = json['tieu_de'] ?? json['title'] ?? '';
    final noiDung = json['noi_dung'] ?? json['content'] ?? '';
    
    // Map loai_thong_bao (Vietnamese) to type (English) if needed
    String loaiThongBao = json['loai_thong_bao'] ?? json['type'] ?? 'system';
    // Reverse mapping: Vietnamese → English for consistency
    if (loaiThongBao == 'Ưu đãi') loaiThongBao = 'promotion';
    else if (loaiThongBao == 'Phòng mới') loaiThongBao = 'new_room';
    else if (loaiThongBao == 'Chương trình app') loaiThongBao = 'app_program';
    else if (loaiThongBao == 'Đặt phòng thành công') loaiThongBao = 'booking_success';

    final ngayTao = parseDate(json['ngay_tao'] ?? json['created_at']) ?? DateTime.now();

    return NotificationModel(
      id: id,
      tieuDe: tieuDe.toString(),
      noiDung: noiDung.toString(),
      loaiThongBao: loaiThongBao,
      urlHinhAnh: json['url_hinh_anh'] ?? json['image_url'],
      urlHanhDong: json['url_hanh_dong'] ?? json['action_url'],
      vanBanNut: json['van_ban_nut'] ?? json['action_text'],
      khachSanId: parseInt(json['khach_san_id'] ?? json['hotel_id']),
      ngayHetHan: parseDate(json['ngay_het_han'] ?? json['expires_at']),
      hienThi: parseBool(json['hien_thi'] ?? json['is_visible'] ?? true),
      doiTuongNhan: json['doi_tuong_nhan'] ?? json['target_audience'] ?? 'all',
      nguoiDungId: parseInt(json['nguoi_dung_id'] ?? json['user_id']),
      guiEmail: parseBool(json['gui_email'] ?? json['send_email']),
      nguoiTaoId: parseInt(json['nguoi_tao_id'] ?? json['created_by_id']) ?? 0,
      ngayTao: ngayTao,
      ngayCapNhat: parseDate(json['ngay_cap_nhat'] ?? json['updated_at']),
      daDoc: parseBool(json['da_doc'] ?? json['is_read']),
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
