import 'package:json_annotation/json_annotation.dart';

part 'image_model.g.dart';

@JsonSerializable()
class ImageModel {
  final String id;
  final String fileName;
  final String originalName;
  final String filePath;
  final String url;
  final String mimeType;
  final int fileSize;
  final int width;
  final int height;
  final String? description;
  final String? altText;
  final String category;
  final String? entityId; // ID của entity liên quan (booking, room, user, etc.)
  final String entityType; // Type của entity (booking, room, user, etc.)
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? uploadedBy;

  const ImageModel({
    required this.id,
    required this.fileName,
    required this.originalName,
    required this.filePath,
    required this.url,
    required this.mimeType,
    required this.fileSize,
    required this.width,
    required this.height,
    this.description,
    this.altText,
    required this.category,
    this.entityId,
    required this.entityType,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    this.uploadedBy,
  });

  factory ImageModel.fromJson(Map<String, dynamic> json) =>
      _$ImageModelFromJson(json);

  Map<String, dynamic> toJson() => _$ImageModelToJson(this);

  ImageModel copyWith({
    String? id,
    String? fileName,
    String? originalName,
    String? filePath,
    String? url,
    String? mimeType,
    int? fileSize,
    int? width,
    int? height,
    String? description,
    String? altText,
    String? category,
    String? entityId,
    String? entityType,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? uploadedBy,
  }) {
    return ImageModel(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      originalName: originalName ?? this.originalName,
      filePath: filePath ?? this.filePath,
      url: url ?? this.url,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      width: width ?? this.width,
      height: height ?? this.height,
      description: description ?? this.description,
      altText: altText ?? this.altText,
      category: category ?? this.category,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      uploadedBy: uploadedBy ?? this.uploadedBy,
    );
  }

  // Helper methods
  String get formattedFileSize {
    if (fileSize < 1024) {
      return '${fileSize} B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  String get formattedDimensions => '${width}x${height}';

  String get categoryDisplayName {
    switch (category.toLowerCase()) {
      case 'avatar':
        return 'Ảnh đại diện';
      case 'room':
        return 'Ảnh phòng';
      case 'hotel':
        return 'Ảnh khách sạn';
      case 'booking':
        return 'Ảnh đặt phòng';
      case 'user':
        return 'Ảnh người dùng';
      case 'promotion':
        return 'Ảnh khuyến mãi';
      case 'gallery':
        return 'Thư viện ảnh';
      default:
        return category;
    }
  }

  String get entityTypeDisplayName {
    switch (entityType.toLowerCase()) {
      case 'user':
        return 'Người dùng';
      case 'room':
        return 'Phòng';
      case 'hotel':
        return 'Khách sạn';
      case 'booking':
        return 'Đặt phòng';
      case 'promotion':
        return 'Khuyến mãi';
      default:
        return entityType;
    }
  }

  bool get isImage => mimeType.startsWith('image/');
  bool get isJpeg => mimeType == 'image/jpeg';
  bool get isPng => mimeType == 'image/png';
  bool get isWebp => mimeType == 'image/webp';

  String get formattedCreatedAt => 
      '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';

  String get formattedUpdatedAt => updatedAt != null
      ? '${updatedAt!.day.toString().padLeft(2, '0')}/${updatedAt!.month.toString().padLeft(2, '0')}/${updatedAt!.year}'
      : 'Chưa cập nhật';
}

@JsonSerializable()
class ImageUploadRequest {
  final String fileName;
  final String originalName;
  final String mimeType;
  final int fileSize;
  final int width;
  final int height;
  final String? description;
  final String? altText;
  final String category;
  final String? entityId;
  final String entityType;
  final String? uploadedBy;

  const ImageUploadRequest({
    required this.fileName,
    required this.originalName,
    required this.mimeType,
    required this.fileSize,
    required this.width,
    required this.height,
    this.description,
    this.altText,
    required this.category,
    this.entityId,
    required this.entityType,
    this.uploadedBy,
  });

  factory ImageUploadRequest.fromJson(Map<String, dynamic> json) =>
      _$ImageUploadRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ImageUploadRequestToJson(this);

  ImageUploadRequest copyWith({
    String? fileName,
    String? originalName,
    String? mimeType,
    int? fileSize,
    int? width,
    int? height,
    String? description,
    String? altText,
    String? category,
    String? entityId,
    String? entityType,
    String? uploadedBy,
  }) {
    return ImageUploadRequest(
      fileName: fileName ?? this.fileName,
      originalName: originalName ?? this.originalName,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      width: width ?? this.width,
      height: height ?? this.height,
      description: description ?? this.description,
      altText: altText ?? this.altText,
      category: category ?? this.category,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      uploadedBy: uploadedBy ?? this.uploadedBy,
    );
  }
}

@JsonSerializable()
class ImageUploadResponse {
  final bool success;
  final String? message;
  final ImageModel? image;
  final String? error;

  const ImageUploadResponse({
    required this.success,
    this.message,
    this.image,
    this.error,
  });

  factory ImageUploadResponse.fromJson(Map<String, dynamic> json) =>
      _$ImageUploadResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ImageUploadResponseToJson(this);

  ImageUploadResponse copyWith({
    bool? success,
    String? message,
    ImageModel? image,
    String? error,
  }) {
    return ImageUploadResponse(
      success: success ?? this.success,
      message: message ?? this.message,
      image: image ?? this.image,
      error: error ?? this.error,
    );
  }
}
