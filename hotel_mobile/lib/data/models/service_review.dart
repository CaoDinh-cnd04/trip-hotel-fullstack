import 'package:flutter/material.dart';

/// Model đánh giá dịch vụ/tiện ích của khách sạn
/// 
/// Chứa thông tin đánh giá từ người dùng về các dịch vụ như:
/// - Spa, Hồ bơi, Nhà hàng, WiFi, Bãi đỗ xe, v.v.
class ServiceReview {
  final int id;
  final String serviceName; // Tên dịch vụ: "Spa", "Hồ bơi", "Nhà hàng", etc.
  final String userName; // Tên người đánh giá
  final String? userAvatar; // Avatar người đánh giá
  final double rating; // Điểm đánh giá (1-5)
  final String comment; // Nội dung đánh giá
  final DateTime reviewDate; // Ngày đánh giá
  final List<String>? images; // Hình ảnh kèm theo (nếu có)

  ServiceReview({
    required this.id,
    required this.serviceName,
    required this.userName,
    this.userAvatar,
    required this.rating,
    required this.comment,
    required this.reviewDate,
    this.images,
  });

  /// Tạo ServiceReview từ JSON
  factory ServiceReview.fromJson(Map<String, dynamic> json) {
    return ServiceReview(
      id: json['id'] ?? 0,
      serviceName: json['service_name'] ?? json['serviceName'] ?? '',
      userName: json['user_name'] ?? json['userName'] ?? 'Người dùng',
      userAvatar: json['user_avatar'] ?? json['userAvatar'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      comment: json['comment'] ?? '',
      reviewDate: json['review_date'] != null
          ? DateTime.parse(json['review_date'])
          : DateTime.now(),
      images: json['images'] != null
          ? List<String>.from(json['images'])
          : null,
    );
  }

  /// Chuyển đổi sang JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_name': serviceName,
      'user_name': userName,
      'user_avatar': userAvatar,
      'rating': rating,
      'comment': comment,
      'review_date': reviewDate.toIso8601String(),
      'images': images,
    };
  }

  /// Format ngày đánh giá
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(reviewDate);

    if (difference.inDays == 0) {
      return 'Hôm nay';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks tuần trước';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months tháng trước';
    } else {
      return '${reviewDate.day}/${reviewDate.month}/${reviewDate.year}';
    }
  }
}

