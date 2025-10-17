// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImageModel _$ImageModelFromJson(Map<String, dynamic> json) => ImageModel(
  id: json['id'] as String,
  fileName: json['fileName'] as String,
  originalName: json['originalName'] as String,
  filePath: json['filePath'] as String,
  url: json['url'] as String,
  mimeType: json['mimeType'] as String,
  fileSize: (json['fileSize'] as num).toInt(),
  width: (json['width'] as num).toInt(),
  height: (json['height'] as num).toInt(),
  description: json['description'] as String?,
  altText: json['altText'] as String?,
  category: json['category'] as String,
  entityId: json['entityId'] as String?,
  entityType: json['entityType'] as String,
  isActive: json['isActive'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  uploadedBy: json['uploadedBy'] as String?,
);

Map<String, dynamic> _$ImageModelToJson(ImageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fileName': instance.fileName,
      'originalName': instance.originalName,
      'filePath': instance.filePath,
      'url': instance.url,
      'mimeType': instance.mimeType,
      'fileSize': instance.fileSize,
      'width': instance.width,
      'height': instance.height,
      'description': instance.description,
      'altText': instance.altText,
      'category': instance.category,
      'entityId': instance.entityId,
      'entityType': instance.entityType,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'uploadedBy': instance.uploadedBy,
    };

ImageUploadRequest _$ImageUploadRequestFromJson(Map<String, dynamic> json) =>
    ImageUploadRequest(
      fileName: json['fileName'] as String,
      originalName: json['originalName'] as String,
      mimeType: json['mimeType'] as String,
      fileSize: (json['fileSize'] as num).toInt(),
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      description: json['description'] as String?,
      altText: json['altText'] as String?,
      category: json['category'] as String,
      entityId: json['entityId'] as String?,
      entityType: json['entityType'] as String,
      uploadedBy: json['uploadedBy'] as String?,
    );

Map<String, dynamic> _$ImageUploadRequestToJson(ImageUploadRequest instance) =>
    <String, dynamic>{
      'fileName': instance.fileName,
      'originalName': instance.originalName,
      'mimeType': instance.mimeType,
      'fileSize': instance.fileSize,
      'width': instance.width,
      'height': instance.height,
      'description': instance.description,
      'altText': instance.altText,
      'category': instance.category,
      'entityId': instance.entityId,
      'entityType': instance.entityType,
      'uploadedBy': instance.uploadedBy,
    };

ImageUploadResponse _$ImageUploadResponseFromJson(Map<String, dynamic> json) =>
    ImageUploadResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      image: json['image'] == null
          ? null
          : ImageModel.fromJson(json['image'] as Map<String, dynamic>),
      error: json['error'] as String?,
    );

Map<String, dynamic> _$ImageUploadResponseToJson(
  ImageUploadResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'image': instance.image,
  'error': instance.error,
};
