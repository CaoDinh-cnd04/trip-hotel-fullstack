import 'package:hotel_mobile/data/models/hotel.dart';
import 'package:hotel_mobile/data/models/notification.dart';
import 'package:hotel_mobile/data/models/promotion.dart';
import 'package:hotel_mobile/data/models/discount_voucher.dart';

class MockDataService {
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal();

  // Mock Hotels Data
  List<Hotel> getMockHotels({String? search}) {
    final allHotels = [
      Hotel(
        id: 1,
        ten: 'Hanoi Deluxe Hotel',
        moTa: 'Khách sạn sang trọng tại trung tâm Hà Nội với dịch vụ 5 sao',
            hinhAnh: 'https://via.placeholder.com/400x300/2196F3/FFFFFF?text=Hanoi+Deluxe',
        soSao: 4,
        trangThai: 'active',
        diaChi: '123 Phố Huế, Hoàn Kiếm, Hà Nội',
        viTriId: 1,
        yeuCauCoc: 500000,
        tiLeCoc: 0.2,
        tongSoPhong: 150,
        diemDanhGiaTrungBinh: 4.5,
        soLuotDanhGia: 128,
        tenViTri: 'Hoàn Kiếm',
        tenTinhThanh: 'Hà Nội',
        tenQuocGia: 'Việt Nam',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Hotel(
        id: 2,
        ten: 'Lake View Hanoi',
        moTa: 'Khách sạn với view hồ Tây tuyệt đẹp',
            hinhAnh: 'https://via.placeholder.com/400x300/4CAF50/FFFFFF?text=Lake+View',
        soSao: 5,
        trangThai: 'active',
        diaChi: '456 Đường Lạc Long Quân, Tây Hồ, Hà Nội',
        viTriId: 2,
        yeuCauCoc: 800000,
        tiLeCoc: 0.25,
        tongSoPhong: 200,
        diemDanhGiaTrungBinh: 4.8,
        soLuotDanhGia: 95,
        tenViTri: 'Tây Hồ',
        tenTinhThanh: 'Hà Nội',
        tenQuocGia: 'Việt Nam',
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Hotel(
        id: 3,
        ten: 'Saigon Central Hotel',
        moTa: 'Khách sạn hiện đại tại trung tâm TP.HCM',
            hinhAnh: 'https://via.placeholder.com/400x300/FF9800/FFFFFF?text=Saigon+Central',
        soSao: 4,
        trangThai: 'active',
        diaChi: '789 Nguyễn Huệ, Quận 1, TP.HCM',
        viTriId: 3,
        yeuCauCoc: 600000,
        tiLeCoc: 0.2,
        tongSoPhong: 180,
        diemDanhGiaTrungBinh: 4.3,
        soLuotDanhGia: 156,
        tenViTri: 'Quận 1',
        tenTinhThanh: 'TP.HCM',
        tenQuocGia: 'Việt Nam',
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Hotel(
        id: 4,
        ten: 'Saigon Star Hotel',
        moTa: 'Khách sạn 5 sao tại trung tâm quận 1',
            hinhAnh: 'https://via.placeholder.com/400x300/9C27B0/FFFFFF?text=Saigon+Star',
        soSao: 5,
        trangThai: 'active',
        diaChi: '321 Lê Lợi, Quận 1, TP.HCM',
        viTriId: 4,
        yeuCauCoc: 1000000,
        tiLeCoc: 0.3,
        tongSoPhong: 300,
        diemDanhGiaTrungBinh: 4.7,
        soLuotDanhGia: 203,
        tenViTri: 'Quận 1',
        tenTinhThanh: 'TP.HCM',
        tenQuocGia: 'Việt Nam',
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Hotel(
        id: 5,
        ten: 'District 3 Boutique Hotel',
        moTa: 'Khách sạn boutique sang trọng tại quận 3',
            hinhAnh: 'https://via.placeholder.com/400x300/E91E63/FFFFFF?text=District+3+Boutique',
        soSao: 4,
        trangThai: 'active',
        diaChi: '654 Võ Văn Tần, Quận 3, TP.HCM',
        viTriId: 5,
        yeuCauCoc: 700000,
        tiLeCoc: 0.25,
        tongSoPhong: 120,
        diemDanhGiaTrungBinh: 4.4,
        soLuotDanhGia: 87,
        tenViTri: 'Quận 3',
        tenTinhThanh: 'TP.HCM',
        tenQuocGia: 'Việt Nam',
        createdAt: DateTime.now().subtract(const Duration(days: 120)),
        updatedAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ];

    // Filter by search term if provided
    if (search != null && search.isNotEmpty) {
      final searchLower = search.toLowerCase();
      return allHotels.where((hotel) {
        return hotel.ten.toLowerCase().contains(searchLower) ||
               (hotel.tenTinhThanh?.toLowerCase().contains(searchLower) ?? false) ||
               (hotel.tenViTri?.toLowerCase().contains(searchLower) ?? false) ||
               (hotel.diaChi?.toLowerCase().contains(searchLower) ?? false);
      }).toList();
    }

    return allHotels;
  }

  // Mock Notifications Data
  List<NotificationModel> getMockNotifications() {
    return [
      NotificationModel(
        id: 1,
        title: 'Ưu đãi đặc biệt cuối năm',
        content: 'Giảm giá 30% cho tất cả phòng khách sạn trong tháng 12. Đặt ngay để không bỏ lỡ cơ hội!',
        type: 'promotion',
        imageUrl: '/images/promotions/end_year_sale.jpg',
        actionUrl: '/deals',
        actionText: 'Xem ưu đãi',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        expiresAt: DateTime.now().add(const Duration(days: 15)),
        senderName: 'Admin',
        senderType: 'admin',
      ),
      NotificationModel(
        id: 2,
        title: 'Phòng mới tại Hanoi Deluxe Hotel',
        content: 'Chúng tôi vừa mở thêm 20 phòng suite mới với view hồ Tây tuyệt đẹp. Giá đặc biệt chỉ từ 1,200,000 VNĐ/đêm.',
        type: 'new_room',
        imageUrl: '/images/rooms/suite_lake_view.jpg',
        actionUrl: '/hotel-detail/1',
        actionText: 'Xem phòng',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        senderName: 'Hotel Manager',
        senderType: 'hotel_manager',
        hotelId: 1,
      ),
      NotificationModel(
        id: 3,
        title: 'Cập nhật ứng dụng mới',
        content: 'Phiên bản 2.0 với nhiều tính năng mới: đặt phòng nhanh, thanh toán online, và nhiều hơn nữa!',
        type: 'app_program',
        imageUrl: '/images/app/update_v2.jpg',
        actionUrl: '/app-programs',
        actionText: 'Tìm hiểu thêm',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        expiresAt: DateTime.now().add(const Duration(days: 60)),
        senderName: 'Admin',
        senderType: 'admin',
      ),
      NotificationModel(
        id: 4,
        title: 'Đặt phòng thành công',
        content: 'Bạn đã đặt phòng thành công tại Hanoi Deluxe Hotel từ 25/12/2024 đến 27/12/2024. Mã đặt phòng: HDH-2024-001',
        type: 'booking_success',
        actionUrl: '/booking-history',
        actionText: 'Xem chi tiết',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        senderName: 'System',
        senderType: 'system',
        hotelId: 1,
        metadata: {
          'booking_id': 'HDH-2024-001',
          'check_in': '2024-12-25',
          'check_out': '2024-12-27',
          'total_amount': 2400000,
        },
      ),
      NotificationModel(
        id: 5,
        title: 'Khuyến mãi Black Friday',
        content: 'Black Friday đã đến! Giảm giá lên đến 50% cho tất cả khách sạn. Chỉ còn 2 ngày!',
        type: 'promotion',
        imageUrl: '/images/promotions/black_friday.jpg',
        actionUrl: '/deals',
        actionText: 'Mua ngay',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        expiresAt: DateTime.now().add(const Duration(days: 2)),
        senderName: 'Admin',
        senderType: 'admin',
      ),
    ];
  }

  // Mock Promotions Data
  List<Promotion> getMockPromotions() {
    return [
      Promotion(
        id: 1,
        ten: 'Ưu đãi cuối năm',
        moTa: 'Giảm giá 30% cho tất cả phòng khách sạn',
            hinhAnh: 'https://via.placeholder.com/300x200/4CAF50/FFFFFF?text=End+Year+Sale',
        phanTramGiam: 30.0,
        ngayBatDau: DateTime.now().subtract(const Duration(days: 5)),
        ngayKetThuc: DateTime.now().add(const Duration(days: 15)),
        trangThai: true,
        ngayTao: DateTime.now().subtract(const Duration(days: 10)),
        ngayCapNhat: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Promotion(
        id: 2,
        ten: 'Black Friday Sale',
        moTa: 'Giảm giá lên đến 50% cho tất cả khách sạn',
        hinhAnh: 'https://via.placeholder.com/300x200/FF5722/FFFFFF?text=Black+Friday',
        phanTramGiam: 50.0,
        ngayBatDau: DateTime.now().subtract(const Duration(days: 2)),
        ngayKetThuc: DateTime.now().add(const Duration(days: 2)),
        trangThai: true,
        ngayTao: DateTime.now().subtract(const Duration(days: 5)),
        ngayCapNhat: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];
  }

  // Get unread notification count
  int getUnreadNotificationCount() {
    return getMockNotifications().where((notification) => !notification.isRead).length;
  }

  // Mark notification as read
  NotificationModel? markNotificationAsRead(int notificationId) {
    final notifications = getMockNotifications();
    final index = notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      return notifications[index].copyWith(isRead: true);
    }
    return null;
  }

  // Mark all notifications as read
  List<NotificationModel> markAllNotificationsAsRead() {
    return getMockNotifications().map((notification) => notification.copyWith(isRead: true)).toList();
  }

  List<DiscountVoucher> getMockDiscountCodes() {
    return [
      DiscountVoucher(
        id: 1,
        maGiamGia: 'WELCOME10',
        ten: 'Mã chào mừng 10%',
        moTa: 'Giảm 10% cho đơn hàng đầu tiên',
        loaiGiam: 'phan_tram',
        giaTriGiam: 10.0,
        giamToiDa: 500000,
        giaTriDonHangToiThieu: 1000000,
        soLuong: 100,
        soLuongConLai: 95,
        gioiHanSuDungMoiNguoi: 1,
        ngayBatDau: DateTime.now().subtract(const Duration(days: 30)),
        ngayKetThuc: DateTime.now().add(const Duration(days: 30)),
        trangThai: true,
        ngayTao: DateTime.now().subtract(const Duration(days: 30)),
        ngayCapNhat: DateTime.now().subtract(const Duration(days: 1)),
      ),
      DiscountVoucher(
        id: 2,
        maGiamGia: 'SAVE50K',
        ten: 'Tiết kiệm 50K',
        moTa: 'Giảm 50,000đ cho đơn hàng từ 500K',
        loaiGiam: 'tien_mat',
        giaTriGiam: 50000,
        giamToiDa: null,
        giaTriDonHangToiThieu: 500000,
        soLuong: 200,
        soLuongConLai: 180,
        gioiHanSuDungMoiNguoi: 2,
        ngayBatDau: DateTime.now().subtract(const Duration(days: 15)),
        ngayKetThuc: DateTime.now().add(const Duration(days: 15)),
        trangThai: true,
        ngayTao: DateTime.now().subtract(const Duration(days: 15)),
        ngayCapNhat: DateTime.now().subtract(const Duration(days: 2)),
      ),
      DiscountVoucher(
        id: 3,
        maGiamGia: 'VIP20',
        ten: 'VIP 20%',
        moTa: 'Giảm 20% cho khách VIP',
        loaiGiam: 'phan_tram',
        giaTriGiam: 20.0,
        giamToiDa: 1000000,
        giaTriDonHangToiThieu: 2000000,
        soLuong: 50,
        soLuongConLai: 45,
        gioiHanSuDungMoiNguoi: 1,
        ngayBatDau: DateTime.now().subtract(const Duration(days: 7)),
        ngayKetThuc: DateTime.now().add(const Duration(days: 7)),
        trangThai: true,
        ngayTao: DateTime.now().subtract(const Duration(days: 7)),
        ngayCapNhat: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
}
