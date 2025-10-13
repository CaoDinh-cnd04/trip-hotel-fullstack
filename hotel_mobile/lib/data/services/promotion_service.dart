import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/promotion.dart';
import '../models/discount_voucher.dart';
import 'auth_service.dart';

class PromotionService {
  static const String baseUrl = 'http://10.0.2.2:3000/api';
  final AuthService _authService = AuthService();

  // Lấy tất cả khuyến mãi đang hoạt động
  Future<List<Promotion>> getActivePromotions({int? hotelId}) async {
    try {
      final url = Uri.parse('$baseUrl/khuyenmai/active');
      final queryParams = <String, String>{};

      if (hotelId != null) {
        queryParams['ma_khach_san'] = hotelId.toString();
      }

      final uri = url.replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      print('Get active promotions response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> promotionsData = data['data'] ?? [];
          return promotionsData
              .map((json) => Promotion.fromJson(json))
              .toList();
        }
      }

      return [];
    } catch (e) {
      print('Error getting active promotions: $e');
      return [];
    }
  }

  // Lấy tất cả mã giảm giá đang hoạt động (public)
  Future<List<DiscountVoucher>> getActiveDiscountVouchers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/magiamgia/active'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Get active discount vouchers response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> vouchersData = data['data'] ?? [];
          return vouchersData
              .map((json) => DiscountVoucher.fromJson(json))
              .toList();
        }
      }

      return [];
    } catch (e) {
      print('Error getting active discount vouchers: $e');
      return [];
    }
  }

  // Lấy mã giảm giá của người dùng hiện tại
  Future<List<DiscountVoucher>> getMyDiscountVouchers({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/magiamgia/my?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
      );

      print('Get my discount vouchers response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> vouchersData = data['data'] ?? [];
          return vouchersData
              .map((json) => DiscountVoucher.fromJson(json))
              .toList();
        }
      }

      return [];
    } catch (e) {
      print('Error getting my discount vouchers: $e');
      return [];
    }
  }

  // Validate mã giảm giá
  Future<Map<String, dynamic>> validateDiscountVoucher(
    String voucherCode,
    double orderAmount,
  ) async {
    try {
      final user = _authService.currentUser;

      final response = await http.post(
        Uri.parse('$baseUrl/magiamgia/validate'),
        headers: {
          'Content-Type': 'application/json',
          if (user != null) 'Authorization': 'Bearer ${await _getAuthToken()}',
        },
        body: json.encode({
          'ma_giam_gia': voucherCode,
          'tong_tien': orderAmount,
          'ma_nguoi_dung': user?.id,
        }),
      );

      print('Validate discount voucher response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? '',
          'isValid': data['data']?['isValid'] ?? false,
          'discountAmount': data['data']?['discountAmount']?.toDouble() ?? 0.0,
          'voucher': data['data']?['voucher'] != null
              ? DiscountVoucher.fromJson(data['data']['voucher'])
              : null,
          'errors': data['data']?['errors'] ?? [],
        };
      }

      final errorData = json.decode(response.body);
      return {
        'success': false,
        'message': errorData['message'] ?? 'Lỗi không xác định',
        'isValid': false,
        'discountAmount': 0.0,
        'voucher': null,
        'errors': [errorData['message'] ?? 'Lỗi không xác định'],
      };
    } catch (e) {
      print('Error validating discount voucher: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối mạng',
        'isValid': false,
        'discountAmount': 0.0,
        'voucher': null,
        'errors': ['Lỗi kết nối mạng'],
      };
    }
  }

  // Lấy chi tiết mã giảm giá theo code
  Future<DiscountVoucher?> getDiscountVoucherByCode(String voucherCode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/magiamgia/$voucherCode/details'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Get discount voucher by code response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return DiscountVoucher.fromJson(data['data']);
        }
      }

      return null;
    } catch (e) {
      print('Error getting discount voucher by code: $e');
      return null;
    }
  }

  // Validate khuyến mãi
  Future<Map<String, dynamic>> validatePromotion(
    int promotionId,
    double orderAmount,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/khuyenmai/validate/$promotionId?tong_tien=$orderAmount',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      print('Validate promotion response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? '',
          'isValid': data['data']?['isValid'] ?? false,
          'discountAmount': data['data']?['discountAmount']?.toDouble() ?? 0.0,
          'promotion': data['data']?['promotion'] != null
              ? Promotion.fromJson(data['data']['promotion'])
              : null,
        };
      }

      final errorData = json.decode(response.body);
      return {
        'success': false,
        'message': errorData['message'] ?? 'Lỗi không xác định',
        'isValid': false,
        'discountAmount': 0.0,
        'promotion': null,
      };
    } catch (e) {
      print('Error validating promotion: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối mạng',
        'isValid': false,
        'discountAmount': 0.0,
        'promotion': null,
      };
    }
  }

  // Sử dụng mã giảm giá (khi booking thành công)
  Future<Map<String, dynamic>> useDiscountVoucher(
    int voucherId,
    double orderAmount,
  ) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/magiamgia/$voucherId/use'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
        body: json.encode({'gia_tri_don_hang': orderAmount}),
      );

      print('Use discount voucher response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? '',
          'discountAmount': data['data']?['discountAmount']?.toDouble() ?? 0.0,
          'finalAmount':
              data['data']?['finalAmount']?.toDouble() ?? orderAmount,
        };
      }

      final errorData = json.decode(response.body);
      return {
        'success': false,
        'message': errorData['message'] ?? 'Lỗi sử dụng mã giảm giá',
      };
    } catch (e) {
      print('Error using discount voucher: $e');
      return {'success': false, 'message': 'Lỗi kết nối mạng'};
    }
  }

  // Helper method to get auth token (mock implementation)
  Future<String> _getAuthToken() async {
    // In a real implementation, this would get the actual JWT token
    // For now, we'll use a mock token or user session data
    return 'mock_token_${_authService.currentUser?.id}';
  }
}
