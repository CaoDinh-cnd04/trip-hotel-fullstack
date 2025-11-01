import 'package:dio/dio.dart';
import '../models/hotel.dart';
import '../models/promotion.dart';
import '../models/destination.dart';
import '../models/country.dart';

class PublicApiService {
  static const String baseUrl = 'http://10.0.2.2:5000/api/public';
  late final Dio _dio;

  PublicApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
  }

  // Lấy khách sạn nổi bật
  Future<List<Hotel>> getFeaturedHotels({int limit = 6}) async {
    try {
      print('🚀 Lấy khách sạn nổi bật...');
      final response = await _dio.get('/featured-hotels', queryParameters: {
        'limit': limit,
      });

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        final hotels = data.map((json) => Hotel.fromJson(json)).toList();
        print('✅ Lấy được ${hotels.length} khách sạn nổi bật');
        return hotels;
      } else {
        throw Exception('Lỗi API: ${response.data['message']}');
      }
    } catch (e) {
      print('❌ Lỗi lấy khách sạn nổi bật: $e');
      rethrow;
    }
  }

  // Lấy ưu đãi nổi bật
  Future<List<Promotion>> getFeaturedPromotions({int limit = 4}) async {
    try {
      print('🚀 Lấy ưu đãi nổi bật...');
      final response = await _dio.get('/featured-promotions', queryParameters: {
        'limit': limit,
      });

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        final promotions = data.map((json) => Promotion.fromJson(json)).toList();
        print('✅ Lấy được ${promotions.length} ưu đãi nổi bật');
        return promotions;
      } else {
        throw Exception('Lỗi API: ${response.data['message']}');
      }
    } catch (e) {
      print('❌ Lỗi lấy ưu đãi nổi bật: $e');
      rethrow;
    }
  }

  // Lấy địa điểm hot
  Future<List<Destination>> getHotDestinations({int limit = 8}) async {
    try {
      print('🚀 Lấy địa điểm hot...');
      final response = await _dio.get('/hot-destinations', queryParameters: {
        'limit': limit,
      });

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        final destinations = data.map((json) => Destination.fromJson(json)).toList();
        print('✅ Lấy được ${destinations.length} địa điểm hot');
        return destinations;
      } else {
        throw Exception('Lỗi API: ${response.data['message']}');
      }
    } catch (e) {
      print('❌ Lỗi lấy địa điểm hot: $e');
      rethrow;
    }
  }

  // Lấy quốc gia phổ biến
  Future<List<Country>> getPopularCountries({int limit = 6}) async {
    try {
      print('🚀 Lấy quốc gia phổ biến...');
      final response = await _dio.get('/popular-countries', queryParameters: {
        'limit': limit,
      });

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        final countries = data.map((json) => Country.fromJson(json)).toList();
        print('✅ Lấy được ${countries.length} quốc gia phổ biến');
        return countries;
      } else {
        throw Exception('Lỗi API: ${response.data['message']}');
      }
    } catch (e) {
      print('❌ Lỗi lấy quốc gia phổ biến: $e');
      rethrow;
    }
  }

  // Lấy tất cả dữ liệu trang chủ
  Future<Map<String, dynamic>> getHomePageData() async {
    try {
      print('🚀 Lấy dữ liệu trang chủ...');
      final response = await _dio.get('/homepage');

      if (response.data['success'] == true) {
        final data = response.data['data'];
        print('✅ Lấy dữ liệu trang chủ thành công');
        return data;
      } else {
        throw Exception('Lỗi API: ${response.data['message']}');
      }
    } catch (e) {
      print('❌ Lỗi lấy dữ liệu trang chủ: $e');
      rethrow;
    }
  }
}
