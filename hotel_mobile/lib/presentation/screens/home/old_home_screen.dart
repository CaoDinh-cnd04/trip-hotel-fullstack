import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/hotel.dart';
import '../../../data/models/promotion.dart';
import '../../../data/models/destination.dart';
import '../../../data/models/country.dart';
import '../../../data/services/public_api_service.dart';
import '../hotel/hotel_list_screen.dart';
import '../login_screen.dart';
import '../profile/profile_screen.dart';

class OldHomeScreen extends StatefulWidget {
  final bool isAuthenticated;
  final VoidCallback? onAuthStateChanged;

  const OldHomeScreen({
    Key? key,
    this.isAuthenticated = false,
    this.onAuthStateChanged,
  }) : super(key: key);

  @override
  State<OldHomeScreen> createState() => _OldHomeScreenState();
}

class _OldHomeScreenState extends State<OldHomeScreen> {
  final PublicApiService _publicApiService = PublicApiService();

  // Search form controllers
  final TextEditingController _locationController = TextEditingController();
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int _guestCount = 1;
  int _roomCount = 1;

  List<Hotel> _featuredHotels = [];
  List<Promotion> _featuredPromotions = [];
  List<Destination> _hotDestinations = [];
  List<Country> _popularCountries = [];

  bool _isLoading = true;
  String? _error;

  /// Khởi tạo state widget và tải dữ liệu ban đầu cho trang chủ
  @override
  void initState() {
    super.initState();
    _loadHomePageData();
  }

  /// Giải phóng bộ nhớ và hủy các controller khi widget bị destroy
  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  /// Tải dữ liệu trang chủ từ API bao gồm khách sạn nổi bật, khuyến mãi, địa điểm hot và quốc gia phổ biến
  Future<void> _loadHomePageData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('🚀 Bắt đầu tải dữ liệu trang chủ...');

      // Load all data in parallel
      final results = await Future.wait([
        _publicApiService.getFeaturedHotels(limit: 6),
        _publicApiService.getFeaturedPromotions(limit: 4),
        _publicApiService.getHotDestinations(limit: 8),
        _publicApiService.getPopularCountries(limit: 6),
      ]);

      setState(() {
        _featuredHotels = results[0] as List<Hotel>;
        _featuredPromotions = results[1] as List<Promotion>;
        _hotDestinations = results[2] as List<Destination>;
        _popularCountries = results[3] as List<Country>;
        _isLoading = false;
      });

      print('✅ Tải dữ liệu trang chủ thành công');
    } catch (e) {
      print('❌ Lỗi tải dữ liệu trang chủ: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Xử lý sự kiện khi người dùng nhấn nút tìm kiếm
  /// Điều hướng đến màn hình danh sách khách sạn với các tham số tìm kiếm
  void _onSearchPressed() {
    if (_locationController.text.trim().isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HotelListScreen(
            location: _locationController.text.trim(),
            checkInDate: _checkInDate,
            checkOutDate: _checkOutDate,
            guestCount: _guestCount,
            roomCount: _roomCount,
          ),
        ),
      );
    }
  }

  /// Xử lý sự kiện tìm kiếm nhanh theo địa điểm được chọn
  void _onQuickSearchPressed(String location) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HotelListScreen(location: location),
      ),
    );
  }

  /// Xây dựng giao diện chính của màn hình trang chủ
  /// Hiển thị loading, error hoặc nội dung chính tùy theo trạng thái
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tải dữ liệu...'),
                ],
              ),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Có lỗi xảy ra',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadHomePageData,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadHomePageData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header với logo và thông báo
                    _buildHeader(),

                    const SizedBox(height: 24),

                    // Search form
                    _buildSearchForm(),

                    const SizedBox(height: 24),

                    // Quick search buttons
                    _buildQuickSearchSection(),

                    const SizedBox(height: 24),

                    // Featured promotions
                    if (_featuredPromotions.isNotEmpty)
                      _buildFeaturedPromotions(),

                    const SizedBox(height: 24),

                    // Featured hotels
                    if (_featuredHotels.isNotEmpty) _buildFeaturedHotels(),

                    const SizedBox(height: 24),

                    // Hot destinations
                    if (_hotDestinations.isNotEmpty) _buildHotDestinations(),

                    const SizedBox(height: 24),

                    // Popular countries
                    if (_popularCountries.isNotEmpty) _buildPopularCountries(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  /// Tạo header chứa logo ứng dụng, thông báo và nút tài khoản
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Logo và tên app
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue[600],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.hotel, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Hotel App',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),

        // Thông báo và tài khoản
        Row(
          children: [
            // Thông báo
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, size: 28),
                  onPressed: () {
                    // TODO: Navigate to notifications
                  },
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        '3',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Tài khoản
            IconButton(
              icon: Icon(
                widget.isAuthenticated
                    ? Icons.account_circle
                    : Icons.person_outline,
                size: 28,
              ),
              onPressed: () {
                if (widget.isAuthenticated) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  /// Tạo form tìm kiếm khách sạn với các trường địa điểm, ngày, số khách và số phòng
  Widget _buildSearchForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tìm kiếm khách sạn',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Location input
          _buildInputField(
            label: 'Địa điểm',
            icon: Icons.location_on_outlined,
            controller: _locationController,
            hintText: 'Chọn thành phố, quốc gia',
          ),

          const SizedBox(height: 16),

          // Date inputs
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'Ngày nhận phòng',
                  icon: Icons.calendar_today_outlined,
                  date: _checkInDate,
                  onTap: () => _selectDate(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField(
                  label: 'Ngày trả phòng',
                  icon: Icons.calendar_today_outlined,
                  date: _checkOutDate,
                  onTap: () => _selectDate(false),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Guest and room inputs
          Row(
            children: [
              Expanded(
                child: _buildCounterField(
                  label: 'Số khách',
                  icon: Icons.person_outline,
                  value: _guestCount,
                  onChanged: (value) => setState(() => _guestCount = value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCounterField(
                  label: 'Số phòng',
                  icon: Icons.bed_outlined,
                  value: _roomCount,
                  onChanged: (value) => setState(() => _roomCount = value),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Search button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _onSearchPressed,
              icon: const Icon(Icons.search, color: Colors.white),
              label: const Text(
                'Tìm kiếm',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tạo widget input field cho các trường nhập liệu trong form tìm kiếm
  Widget _buildInputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue[600]!),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }

  /// Tạo widget chọn ngày cho ngày nhận phòng và trả phòng
  Widget _buildDateField({
    required String label,
    required IconData icon,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[50],
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  date != null
                      ? DateFormat('dd/MM/yyyy').format(date)
                      : 'Chọn ngày',
                  style: TextStyle(
                    color: date != null ? Colors.black87 : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Tạo widget counter cho số khách và số phòng với nút tăng/giảm
  Widget _buildCounterField({
    required String label,
    required IconData icon,
    required int value,
    required Function(int) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[50],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Text(
                '$value ${label.contains('khách') ? 'khách' : 'phòng'}',
                style: const TextStyle(color: Colors.black87, fontSize: 14),
              ),
              const Spacer(),
              Row(
                children: [
                  GestureDetector(
                    onTap: value > 1 ? () => onChanged(value - 1) : null,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: value > 1 ? Colors.blue[600] : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.remove,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => onChanged(value + 1),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.blue[600],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Tạo section tìm kiếm nhanh với các nút tìm kiếm khách sạn gần đây và yêu thích
  Widget _buildQuickSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tìm kiếm nhanh',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickSearchButton(
                title: 'Khách sạn gần đây',
                icon: Icons.hotel,
                color: Colors.blue,
                onTap: () => _onQuickSearchPressed('Gần đây'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickSearchButton(
                title: 'Khách sạn yêu thích',
                icon: Icons.favorite,
                color: Colors.purple,
                onTap: () => _onQuickSearchPressed('Yêu thích'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Tạo nút tìm kiếm nhanh với icon, tiêu đề và màu sắc tùy chỉnh
  Widget _buildQuickSearchButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Tạo section hiển thị danh sách khuyến mãi nổi bật theo chiều ngang
  Widget _buildFeaturedPromotions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ưu đãi nổi bật',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _featuredPromotions.length,
            itemBuilder: (context, index) {
              final promotion = _featuredPromotions[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue[400]!, Colors.purple[400]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${promotion.phanTramGiam.toInt()}% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        promotion.ten,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Tạo section hiển thị danh sách khách sạn nổi bật với hình ảnh và thông tin
  Widget _buildFeaturedHotels() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Khách sạn nổi bật',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _featuredHotels.length,
            itemBuilder: (context, index) {
              final hotel = _featuredHotels[index];
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Container(
                        height: 100,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child:
                            hotel.hinhAnh != null && hotel.hinhAnh!.isNotEmpty
                            ? Image.network(
                                hotel.fullImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.hotel,
                                    size: 40,
                                    color: Colors.grey,
                                  );
                                },
                              )
                            : const Icon(
                                Icons.hotel,
                                size: 40,
                                color: Colors.grey,
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hotel.ten,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hotel.displayLocation,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: 14,
                                color: Colors.amber[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                hotel.diemDanhGiaTrungBinh?.toStringAsFixed(
                                      1,
                                    ) ??
                                    'N/A',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Tạo section hiển thị danh sách địa điểm du lịch hot theo chiều ngang
  Widget _buildHotDestinations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Địa điểm hot',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _hotDestinations.length,
            itemBuilder: (context, index) {
              final destination = _hotDestinations[index];
              return GestureDetector(
                onTap: () => _onQuickSearchPressed(destination.ten),
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Container(
                          height: 80,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: destination.hinhAnh.isNotEmpty
                              ? Image.network(
                                  'http://10.0.2.2:5000${destination.hinhAnh}',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.location_on,
                                      size: 30,
                                      color: Colors.grey,
                                    );
                                  },
                                )
                              : const Icon(
                                  Icons.location_on,
                                  size: 30,
                                  color: Colors.grey,
                                ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              destination.ten,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              destination.quocGia,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Tạo section hiển thị lưới các quốc gia phổ biến với hình ảnh và số lượng khách sạn
  Widget _buildPopularCountries() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quốc gia phổ biến',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _popularCountries.length,
          itemBuilder: (context, index) {
            final country = _popularCountries[index];
            return GestureDetector(
              onTap: () => _onQuickSearchPressed(country.ten),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.grey[200],
                        child: country.hinhAnh.isNotEmpty
                            ? Image.network(
                                'http://10.0.2.2:5000${country.hinhAnh}',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.public,
                                    size: 40,
                                    color: Colors.grey,
                                  );
                                },
                              )
                            : const Icon(
                                Icons.public,
                                size: 40,
                                color: Colors.grey,
                              ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                country.ten,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${country.soKhachSan} khách sạn',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Hiển thị date picker cho người dùng chọn ngày nhận phòng hoặc trả phòng
  /// [isCheckIn] - true nếu chọn ngày nhận phòng, false nếu chọn ngày trả phòng
  Future<void> _selectDate(bool isCheckIn) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn
          ? (_checkInDate ?? DateTime.now())
          : (_checkOutDate ??
                (_checkInDate ?? DateTime.now()).add(const Duration(days: 1))),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInDate = picked;
          // Nếu ngày check-out trước ngày check-in, cập nhật ngày check-out
          if (_checkOutDate != null &&
              _checkOutDate!.isBefore(picked.add(const Duration(days: 1)))) {
            _checkOutDate = picked.add(const Duration(days: 1));
          }
        } else {
          _checkOutDate = picked;
        }
      });
    }
  }
}
