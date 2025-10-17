import 'package:json_annotation/json_annotation.dart';

part 'feedback_model.g.dart';

@JsonSerializable()
class FeedbackModel {
  final int id;
  final int nguoiDungId;
  final String? hoTen;
  final String? email;
  final String tieuDe;
  final String noiDung;
  final String loaiPhanHoi; // 'complaint', 'suggestion', 'compliment', 'question'
  final String trangThai; // 'pending', 'in_progress', 'resolved', 'closed'
  final int? uuTien; // 1-5, 5 là cao nhất
  final String? phanHoiCuaAdmin;
  final int? adminId;
  final String? adminName;
  final DateTime? ngayPhanHoi;
  final DateTime? ngayGiaiQuyet;
  final DateTime ngayTao;
  final DateTime? ngayCapNhat;
  final List<String>? hinhAnh;
  final Map<String, dynamic>? metadata;

  const FeedbackModel({
    required this.id,
    required this.nguoiDungId,
    this.hoTen,
    this.email,
    required this.tieuDe,
    required this.noiDung,
    required this.loaiPhanHoi,
    required this.trangThai,
    this.uuTien,
    this.phanHoiCuaAdmin,
    this.adminId,
    this.adminName,
    this.ngayPhanHoi,
    this.ngayGiaiQuyet,
    required this.ngayTao,
    this.ngayCapNhat,
    this.hinhAnh,
    this.metadata,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) =>
      _$FeedbackModelFromJson(json);

  Map<String, dynamic> toJson() => _$FeedbackModelToJson(this);

  // Helper methods
  bool get isPending => trangThai == 'pending';
  bool get isInProgress => trangThai == 'in_progress';
  bool get isResolved => trangThai == 'resolved';
  bool get isClosed => trangThai == 'closed';

  String get trangThaiText {
    switch (trangThai) {
      case 'pending':
        return 'Chờ xử lý';
      case 'in_progress':
        return 'Đang xử lý';
      case 'resolved':
        return 'Đã giải quyết';
      case 'closed':
        return 'Đã đóng';
      default:
        return trangThai;
    }
  }

  String get loaiPhanHoiText {
    switch (loaiPhanHoi) {
      case 'complaint':
        return 'Khiếu nại';
      case 'suggestion':
        return 'Góp ý';
      case 'compliment':
        return 'Khen ngợi';
      case 'question':
        return 'Câu hỏi';
      default:
        return loaiPhanHoi;
    }
  }

  String get uuTienText {
    switch (uuTien) {
      case 1:
        return 'Thấp';
      case 2:
        return 'Trung bình';
      case 3:
        return 'Bình thường';
      case 4:
        return 'Cao';
      case 5:
        return 'Rất cao';
      default:
        return 'Không xác định';
    }
  }

  String get formattedNgayTao {
    return '${ngayTao.day.toString().padLeft(2, '0')}/${ngayTao.month.toString().padLeft(2, '0')}/${ngayTao.year}';
  }

  String get formattedNgayPhanHoi {
    if (ngayPhanHoi == null) return 'Chưa phản hồi';
    return '${ngayPhanHoi!.day.toString().padLeft(2, '0')}/${ngayPhanHoi!.month.toString().padLeft(2, '0')}/${ngayPhanHoi!.year}';
  }

  // Copy with method
  FeedbackModel copyWith({
    int? id,
    int? nguoiDungId,
    String? hoTen,
    String? email,
    String? tieuDe,
    String? noiDung,
    String? loaiPhanHoi,
    String? trangThai,
    int? uuTien,
    String? phanHoiCuaAdmin,
    int? adminId,
    String? adminName,
    DateTime? ngayPhanHoi,
    DateTime? ngayGiaiQuyet,
    DateTime? ngayTao,
    DateTime? ngayCapNhat,
    List<String>? hinhAnh,
    Map<String, dynamic>? metadata,
  }) {
    return FeedbackModel(
      id: id ?? this.id,
      nguoiDungId: nguoiDungId ?? this.nguoiDungId,
      hoTen: hoTen ?? this.hoTen,
      email: email ?? this.email,
      tieuDe: tieuDe ?? this.tieuDe,
      noiDung: noiDung ?? this.noiDung,
      loaiPhanHoi: loaiPhanHoi ?? this.loaiPhanHoi,
      trangThai: trangThai ?? this.trangThai,
      uuTien: uuTien ?? this.uuTien,
      phanHoiCuaAdmin: phanHoiCuaAdmin ?? this.phanHoiCuaAdmin,
      adminId: adminId ?? this.adminId,
      adminName: adminName ?? this.adminName,
      ngayPhanHoi: ngayPhanHoi ?? this.ngayPhanHoi,
      ngayGiaiQuyet: ngayGiaiQuyet ?? this.ngayGiaiQuyet,
      ngayTao: ngayTao ?? this.ngayTao,
      ngayCapNhat: ngayCapNhat ?? this.ngayCapNhat,
      hinhAnh: hinhAnh ?? this.hinhAnh,
      metadata: metadata ?? this.metadata,
    );
  }
}

// Enum for feedback types
enum FeedbackType {
  complaint('complaint', 'Khiếu nại'),
  suggestion('suggestion', 'Góp ý'),
  compliment('compliment', 'Khen ngợi'),
  question('question', 'Câu hỏi');

  const FeedbackType(this.value, this.displayName);
  final String value;
  final String displayName;
}

// Enum for feedback status
enum FeedbackStatus {
  pending('pending', 'Chờ xử lý'),
  inProgress('in_progress', 'Đang xử lý'),
  resolved('resolved', 'Đã giải quyết'),
  closed('closed', 'Đã đóng');

  const FeedbackStatus(this.value, this.displayName);
  final String value;
  final String displayName;
}

// Enum for priority levels
enum FeedbackPriority {
  low(1, 'Thấp'),
  medium(2, 'Trung bình'),
  normal(3, 'Bình thường'),
  high(4, 'Cao'),
  urgent(5, 'Rất cao');

  const FeedbackPriority(this.value, this.displayName);
  final int value;
  final String displayName;
}
