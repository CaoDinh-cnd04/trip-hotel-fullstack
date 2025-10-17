import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;
import '../models/image_model.dart';

class ImageUploadService {
  static final ImageUploadService _instance = ImageUploadService._internal();
  factory ImageUploadService() => _instance;
  ImageUploadService._internal();

  late Dio _dio;
  static const String baseUrl =
      'https://your-backend-api.com/api/images'; // Thay đổi URL này

  void initialize() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 60), // Tăng timeout cho upload
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'multipart/form-data',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors for logging and error handling
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false, // Không log body vì có thể chứa file lớn
        responseBody: true,
        error: true,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          print('Image Upload API Error: ${error.message}');
          print('Response: ${error.response?.data}');
          handler.next(error);
        },
      ),
    );
  }

  // Set authorization token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Upload single image
  Future<ImageUploadResponse> uploadImage({
    required File imageFile,
    required String category,
    required String entityType,
    String? entityId,
    String? description,
    String? altText,
    String? uploadedBy,
    int? maxWidth,
    int? maxHeight,
    int? quality,
  }) async {
    try {
      // Resize image if needed
      final processedFile = await _processImage(
        imageFile,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
      );

      // Get image info
      final imageInfo = await _getImageInfo(processedFile);

      // Create form data
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          processedFile.path,
          filename: imageInfo['fileName'],
        ),
        'originalName': imageInfo['originalName'],
        'mimeType': imageInfo['mimeType'],
        'fileSize': imageInfo['fileSize'],
        'width': imageInfo['width'],
        'height': imageInfo['height'],
        'category': category,
        'entityType': entityType,
        if (entityId != null) 'entityId': entityId,
        if (description != null) 'description': description,
        if (altText != null) 'altText': altText,
        if (uploadedBy != null) 'uploadedBy': uploadedBy,
      });

      final response = await _dio.post('/upload', data: formData);

      if (response.statusCode == 200) {
        final imageData = response.data;
        return ImageUploadResponse(
          success: true,
          message: 'Upload thành công',
          image: ImageModel.fromJson(imageData),
        );
      } else {
        return ImageUploadResponse(
          success: false,
          error: 'Upload thất bại: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      return ImageUploadResponse(success: false, error: _handleDioError(e));
    } catch (e) {
      return ImageUploadResponse(success: false, error: 'Lỗi xử lý ảnh: $e');
    }
  }

  // Upload multiple images
  Future<List<ImageUploadResponse>> uploadMultipleImages({
    required List<File> imageFiles,
    required String category,
    required String entityType,
    String? entityId,
    String? description,
    String? altText,
    String? uploadedBy,
    int? maxWidth,
    int? maxHeight,
    int? quality,
  }) async {
    final results = <ImageUploadResponse>[];

    for (final imageFile in imageFiles) {
      final result = await uploadImage(
        imageFile: imageFile,
        category: category,
        entityType: entityType,
        entityId: entityId,
        description: description,
        altText: altText,
        uploadedBy: uploadedBy,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
      );
      results.add(result);
    }

    return results;
  }

  // Get image by ID
  Future<ImageModel?> getImageById(String id) async {
    try {
      final response = await _dio.get('/$id');
      return ImageModel.fromJson(response.data);
    } on DioException catch (e) {
      print('Error getting image: ${_handleDioError(e)}');
      return null;
    }
  }

  // Get images by entity
  Future<List<ImageModel>> getImagesByEntity({
    required String entityType,
    String? entityId,
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'entity_type': entityType,
        'page': page,
        'limit': limit,
      };

      if (entityId != null) queryParams['entity_id'] = entityId;
      if (category != null) queryParams['category'] = category;

      final response = await _dio.get('/entity', queryParameters: queryParams);

      final List<dynamic> imagesJson = response.data['data'] ?? response.data;
      return imagesJson.map((json) => ImageModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Delete image
  Future<bool> deleteImage(String id) async {
    try {
      final response = await _dio.delete('/$id');
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('Error deleting image: ${_handleDioError(e)}');
      return false;
    }
  }

  // Update image info
  Future<ImageModel?> updateImageInfo(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put('/$id', data: data);
      return ImageModel.fromJson(response.data);
    } on DioException catch (e) {
      print('Error updating image: ${_handleDioError(e)}');
      return null;
    }
  }

  // Get image URL
  String getImageUrl(String imageId, {String? size}) {
    final sizeParam = size != null ? '?size=$size' : '';
    return '$baseUrl/$imageId/url$sizeParam';
  }

  // Get thumbnail URL
  String getThumbnailUrl(String imageId, {int width = 150, int height = 150}) {
    return '$baseUrl/$imageId/thumbnail?width=$width&height=$height';
  }

  // Process image (resize, compress)
  Future<File> _processImage(
    File imageFile, {
    int? maxWidth,
    int? maxHeight,
    int? quality,
  }) async {
    try {
      // Read image bytes
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Không thể đọc ảnh');
      }

      img.Image processedImage = image;

      // Resize if needed
      if (maxWidth != null || maxHeight != null) {
        final originalWidth = image.width;
        final originalHeight = image.height;

        int newWidth = originalWidth;
        int newHeight = originalHeight;

        if (maxWidth != null && originalWidth > maxWidth) {
          newWidth = maxWidth;
          newHeight = (originalHeight * maxWidth / originalWidth).round();
        }

        if (maxHeight != null && newHeight > maxHeight) {
          newHeight = maxHeight;
          newWidth = (newWidth * maxHeight / newHeight).round();
        }

        if (newWidth != originalWidth || newHeight != originalHeight) {
          processedImage = img.copyResize(
            image,
            width: newWidth,
            height: newHeight,
            interpolation: img.Interpolation.linear,
          );
        }
      }

      // Encode with quality
      final qualityValue = quality ?? 85;
      final processedBytes = img.encodeJpg(
        processedImage,
        quality: qualityValue,
      );

      // Create temporary file
      final tempDir = Directory.systemTemp;
      final tempFile = File(
        '${tempDir.path}/processed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(processedBytes);

      return tempFile;
    } catch (e) {
      print('Error processing image: $e');
      return imageFile; // Return original file if processing fails
    }
  }

  // Get image info
  Future<Map<String, dynamic>> _getImageInfo(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Không thể đọc thông tin ảnh');
      }

      final fileName = imageFile.path.split('/').last;
      final originalName = fileName;
      final mimeType = _getMimeType(fileName);
      final fileSize = bytes.length;

      return {
        'fileName': fileName,
        'originalName': originalName,
        'mimeType': mimeType,
        'fileSize': fileSize,
        'width': image.width,
        'height': image.height,
      };
    } catch (e) {
      throw Exception('Lỗi đọc thông tin ảnh: $e');
    }
  }

  // Get MIME type from file extension
  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      default:
        return 'image/jpeg';
    }
  }

  // Error handling
  String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Kết nối timeout. Vui lòng kiểm tra kết nối mạng.';
      case DioExceptionType.sendTimeout:
        return 'Gửi dữ liệu timeout. File có thể quá lớn.';
      case DioExceptionType.receiveTimeout:
        return 'Nhận dữ liệu timeout. Vui lòng thử lại.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 'Lỗi server';
        return 'Lỗi $statusCode: $message';
      case DioExceptionType.cancel:
        return 'Upload đã bị hủy.';
      case DioExceptionType.connectionError:
        return 'Lỗi kết nối. Vui lòng kiểm tra kết nối mạng.';
      case DioExceptionType.badCertificate:
        return 'Lỗi chứng chỉ SSL.';
      case DioExceptionType.unknown:
        return 'Lỗi không xác định: ${error.message}';
    }
  }
}
