import 'package:json_annotation/json_annotation.dart';

part 'user_role_model.g.dart';

/// Enum đại diện cho các vai trò người dùng trong hệ thống
/// 
/// Bao gồm:
/// - user: Người dùng thường
/// - hotelManager: Quản lý khách sạn
/// - admin: Quản trị viên
enum UserRole {
  @JsonValue('user')
  user,
  @JsonValue('hotel_manager')
  hotelManager,
  @JsonValue('admin')
  admin,
}

/// Extension cho UserRole để thêm các phương thức tiện ích
extension UserRoleExtension on UserRole {
  /// Lấy tên hiển thị của vai trò bằng tiếng Việt
  /// 
  /// Trả về: "Người dùng", "Quản lý khách sạn", hoặc "Quản trị viên"
  String get displayName {
    switch (this) {
      case UserRole.user:
        return 'Người dùng';
      case UserRole.hotelManager:
        return 'Quản lý khách sạn';
      case UserRole.admin:
        return 'Quản trị viên';
    }
  }

  /// Lấy giá trị string của enum
  /// 
  /// Trả về: "user", "hotel_manager", hoặc "admin"
  String get value {
    switch (this) {
      case UserRole.user:
        return 'user';
      case UserRole.hotelManager:
        return 'hotel_manager';
      case UserRole.admin:
        return 'admin';
    }
  }

  List<String> get defaultPermissions {
    switch (this) {
      case UserRole.admin:
        return [
          'user:read',
          'user:write',
          'user:delete',
          'hotel:read',
          'hotel:write',
          'hotel:delete',
          'booking:read',
          'booking:write',
          'booking:delete',
          'system:admin',
        ];
      case UserRole.hotelManager:
        return [
          'hotel:read',
          'hotel:write',
          'booking:read',
          'booking:write',
          'room:read',
          'room:write',
          'promotion:read',
          'promotion:write',
        ];
      case UserRole.user:
        return ['booking:read', 'booking:write', 'hotel:read', 'room:read'];
    }
  }
}

/// Model đại diện cho vai trò và quyền của người dùng
/// 
/// Chứa thông tin:
/// - Thông tin user: uid, email, displayName, photoURL
/// - Vai trò: role (UserRole enum), isActive
/// - Quyền: permissions (danh sách các quyền)
/// - Thông tin khách sạn: hotelId (nếu là hotel manager)
/// - Thời gian: createdAt, updatedAt
@JsonSerializable()
class UserRoleModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? hotelId; // For hotel managers
  final List<String> permissions;

  const UserRoleModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.hotelId,
    required this.permissions,
  });

  /// Tạo đối tượng UserRoleModel từ JSON
  /// 
  /// [json] - Map chứa dữ liệu JSON từ API
  /// 
  /// Sử dụng code generation từ json_annotation
  factory UserRoleModel.fromJson(Map<String, dynamic> json) =>
      _$UserRoleModelFromJson(json);

  /// Chuyển đổi đối tượng UserRoleModel sang JSON
  /// 
  /// Trả về Map chứa tất cả các trường dưới dạng JSON
  /// Sử dụng code generation từ json_annotation
  Map<String, dynamic> toJson() => _$UserRoleModelToJson(this);

  UserRoleModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? hotelId,
    List<String>? permissions,
  }) {
    return UserRoleModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      hotelId: hotelId ?? this.hotelId,
      permissions: permissions ?? this.permissions,
    );
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isHotelManager => role == UserRole.hotelManager;
  bool get isUser => role == UserRole.user;

  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  List<String> get defaultPermissions {
    switch (role) {
      case UserRole.admin:
        return [
          'user:read',
          'user:write',
          'user:delete',
          'hotel:read',
          'hotel:write',
          'hotel:delete',
          'booking:read',
          'booking:write',
          'booking:delete',
          'system:admin',
        ];
      case UserRole.hotelManager:
        return [
          'hotel:read',
          'hotel:write',
          'booking:read',
          'booking:write',
          'room:read',
          'room:write',
          'promotion:read',
          'promotion:write',
        ];
      case UserRole.user:
        return ['booking:read', 'booking:write', 'hotel:read', 'room:read'];
    }
  }
}
