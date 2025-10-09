import 'user.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final Map<String, dynamic>? pagination;
  final List<String>? errors;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.pagination,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
      pagination: json['pagination'],
      errors: json['errors'] != null ? List<String>.from(json['errors']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
      'pagination': pagination,
      'errors': errors,
    };
  }
}

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {'email': email, 'mat_khau': password};
  }
}

class RegisterRequest {
  final String hoTen;
  final String email;
  final String password;
  final String? sdt;
  final String? ngaySinh;
  final String? gioiTinh;

  RegisterRequest({
    required this.hoTen,
    required this.email,
    required this.password,
    this.sdt,
    this.ngaySinh,
    this.gioiTinh,
  });

  Map<String, dynamic> toJson() {
    return {
      'ho_ten': hoTen,
      'email': email,
      'mat_khau': password,
      'sdt': sdt,
      'ngay_sinh': ngaySinh,
      'gioi_tinh': gioiTinh,
    };
  }
}

class AuthResponse {
  final bool success;
  final String message;
  final String? token;
  final User? user;

  AuthResponse({
    required this.success,
    required this.message,
    this.token,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      token: json['token'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }
}
