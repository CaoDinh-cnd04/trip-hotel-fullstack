import 'package:json_annotation/json_annotation.dart';

part 'phieu_dat_phong_model.g.dart';

@JsonSerializable()
class PhieuDatPhongModel {
  final String id;
  final String maPhieu;
  final String tenKhachHang;
  final String soDienThoai;
  final String email;
  final String maPhong;
  final String tenPhong;
  final DateTime ngayCheckIn;
  final DateTime ngayCheckOut;
  final int soDem;
  final double giaPhong;
  final double tongTien;
  final String trangThai;
  final String ghiChu;
  final DateTime ngayTao;
  final DateTime? ngayCapNhat;

  const PhieuDatPhongModel({
    required this.id,
    required this.maPhieu,
    required this.tenKhachHang,
    required this.soDienThoai,
    required this.email,
    required this.maPhong,
    required this.tenPhong,
    required this.ngayCheckIn,
    required this.ngayCheckOut,
    required this.soDem,
    required this.giaPhong,
    required this.tongTien,
    required this.trangThai,
    required this.ghiChu,
    required this.ngayTao,
    this.ngayCapNhat,
  });

  factory PhieuDatPhongModel.fromJson(Map<String, dynamic> json) =>
      _$PhieuDatPhongModelFromJson(json);

  Map<String, dynamic> toJson() => _$PhieuDatPhongModelToJson(this);

  PhieuDatPhongModel copyWith({
    String? id,
    String? maPhieu,
    String? tenKhachHang,
    String? soDienThoai,
    String? email,
    String? maPhong,
    String? tenPhong,
    DateTime? ngayCheckIn,
    DateTime? ngayCheckOut,
    int? soDem,
    double? giaPhong,
    double? tongTien,
    String? trangThai,
    String? ghiChu,
    DateTime? ngayTao,
    DateTime? ngayCapNhat,
  }) {
    return PhieuDatPhongModel(
      id: id ?? this.id,
      maPhieu: maPhieu ?? this.maPhieu,
      tenKhachHang: tenKhachHang ?? this.tenKhachHang,
      soDienThoai: soDienThoai ?? this.soDienThoai,
      email: email ?? this.email,
      maPhong: maPhong ?? this.maPhong,
      tenPhong: tenPhong ?? this.tenPhong,
      ngayCheckIn: ngayCheckIn ?? this.ngayCheckIn,
      ngayCheckOut: ngayCheckOut ?? this.ngayCheckOut,
      soDem: soDem ?? this.soDem,
      giaPhong: giaPhong ?? this.giaPhong,
      tongTien: tongTien ?? this.tongTien,
      trangThai: trangThai ?? this.trangThai,
      ghiChu: ghiChu ?? this.ghiChu,
      ngayTao: ngayTao ?? this.ngayTao,
      ngayCapNhat: ngayCapNhat ?? this.ngayCapNhat,
    );
  }

  // Helper methods
  bool get isConfirmed => trangThai == 'confirmed';
  bool get isPending => trangThai == 'pending';
  bool get isCancelled => trangThai == 'cancelled';
  bool get isCompleted => trangThai == 'completed';

  String get statusDisplayName {
    switch (trangThai) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'cancelled':
        return 'Đã hủy';
      case 'completed':
        return 'Hoàn thành';
      default:
        return 'Không xác định';
    }
  }

  String get formattedCheckIn => 
      '${ngayCheckIn.day.toString().padLeft(2, '0')}/${ngayCheckIn.month.toString().padLeft(2, '0')}/${ngayCheckIn.year}';
  
  String get formattedCheckOut => 
      '${ngayCheckOut.day.toString().padLeft(2, '0')}/${ngayCheckOut.month.toString().padLeft(2, '0')}/${ngayCheckOut.year}';

  String get formattedTongTien => '${tongTien.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
    (Match m) => '${m[1]},'
  )} VNĐ';
}
