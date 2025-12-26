import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/backend_auth_service.dart';
import '../../../data/services/user_profile_service.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../../../core/services/language_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../data/models/user_role_model.dart'; // ✅ FIX: Import UserRole
import '../login_screen.dart';
import '../auth/triphotel_style_login_screen.dart';
import 'profile_edit_screen.dart';
import 'account_security_screen.dart';
import 'about_us_screen.dart';
import 'help_center_screen.dart';
import 'saved_cards_screen.dart';
import '../messages/messages_screen.dart';
import '../chat/modern_conversation_list_screen.dart';
import '../saved/saved_items_screen.dart';
import '../reviews/my_reviews_screen.dart';
import '../booking/booking_history_screen.dart';
import '../hotel_registration/hotel_registration_screen.dart';
import '../hotel_owner/hotel_owner_dashboard.dart';
import '../../../data/services/hotel_owner_service.dart';
import '../../../data/services/message_service.dart';
import '../../../data/services/review_service.dart';
import 'triphotel_vip_screen.dart';
import '../../../core/theme/vip_theme_provider.dart';
import '../../../core/services/currency_service.dart';
import '../../../core/providers/currency_provider.dart';

class TriphotelStyleProfileScreen extends StatefulWidget {
  const TriphotelStyleProfileScreen({Key? key}) : super(key: key);

  @override
  State<TriphotelStyleProfileScreen> createState() => _TriphotelStyleProfileScreenState();
}

class _TriphotelStyleProfileScreenState extends State<TriphotelStyleProfileScreen> {
  final AuthService _authService = AuthService();
  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService();
  final BackendAuthService _backendAuthService = BackendAuthService();
  final UserProfileService _userProfileService = UserProfileService();
  final HotelOwnerService _hotelOwnerService = HotelOwnerService();
  final MessageService _messageService = MessageService();
  final ReviewService _reviewService = ReviewService();
  final StorageService _storageService = StorageService();
  
  String _userName = 'User';
  String _userEmail = '';
  String _vipStatus = 'Bronze';
  bool _isLoading = true;
  bool _notificationsEnabled = true;
  bool _emailNotificationsEnabled = true; // Email notification preference
  String _selectedCurrency = '₫ | VND';
  String _selectedDistance = 'km';
  String _selectedPriceDisplay = 'Theo mỗi đêm';
  bool _isHotelOwner = false;
  int _hotelCount = 0;
  int _unreadReviewsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Ưu tiên lấy thông tin user từ Backend (OTP login)
      final backendUser = _backendAuthService.currentUser;
      if (backendUser != null) {
        print('✅ Loading user from BackendAuthService: ${backendUser.email}');
        setState(() {
          _userName = backendUser.hoTen ?? 'User';
          _userEmail = backendUser.email;
          _vipStatus = 'Bronze'; // Mặc định Bronze, có thể lấy từ backend
        });
      } else {
        // Fallback: Lấy thông tin user từ Firebase (Google/Facebook login)
        final firebaseUser = _firebaseAuthService.currentUser;
        if (firebaseUser != null) {
          print('✅ Loading user from FirebaseAuthService: ${firebaseUser.email}');
          setState(() {
            _userName = firebaseUser.displayName ?? 'User';
            _userEmail = firebaseUser.email ?? '';
            _vipStatus = 'Bronze';
          });
        } else {
          print('⚠️ No user found in BackendAuthService or FirebaseAuthService');
        }
      }

      // Lấy thông tin VIP status từ backend API
      try {
        final vipResponse = await _userProfileService.getVipStatus();
        if (vipResponse.success && vipResponse.data != null) {
          final newVipLevel = vipResponse.data!['vipLevel'] ?? 'Bronze';
          setState(() {
            _vipStatus = newVipLevel;
          });
          
          // ✅ Cập nhật VIP theme khi load profile
          if (mounted) {
            final vipThemeProvider = Provider.of<VipThemeProvider>(context, listen: false);
            vipThemeProvider.setVipLevel(newVipLevel);
            print('✅ Updated VIP theme to: $newVipLevel');
          }
        }
      } catch (e) {
        print('❌ Error loading VIP status: $e');
        // Keep default Bronze if API fails
      }

      // Lấy cài đặt user từ backend
      final settingsResponse = await _userProfileService.getUserSettings();
      if (settingsResponse.success && settingsResponse.data != null) {
        setState(() {
          _selectedCurrency = settingsResponse.data!['currency'] ?? '₫ | VND';
          _selectedDistance = settingsResponse.data!['distanceUnit'] ?? 'km';
          _selectedPriceDisplay = settingsResponse.data!['priceDisplay'] ?? 'Theo mỗi đêm';
          _notificationsEnabled = settingsResponse.data!['notificationsEnabled'] ?? true;
        });
        // Lưu vào SharedPreferences
        await _storageService.saveBool('notifications_enabled', _notificationsEnabled);
      } else {
        // Nếu API fail, load từ SharedPreferences
        final savedNotifications = await _storageService.getBool('notifications_enabled');
        if (savedNotifications != null) {
          setState(() {
            _notificationsEnabled = savedNotifications;
          });
        }
      }
      
      // Load email notification preference từ SharedPreferences
      final savedEmailNotifications = await _storageService.getBool('email_notifications_enabled');
      if (savedEmailNotifications != null) {
        setState(() {
          _emailNotificationsEnabled = savedEmailNotifications;
        });
      }

      // Kiểm tra xem user có phải là hotel owner không
      final hotelsResponse = await _hotelOwnerService.getMyHotels();
      if (hotelsResponse.success && hotelsResponse.data != null) {
        setState(() {
          _isHotelOwner = hotelsResponse.data!.isNotEmpty;
          _hotelCount = hotelsResponse.data!.length;
        });
      }

      // Lấy số lượng tin nhắn chưa đọc
      // ✅ IMPLEMENTED: Real-time unread count from Firestore
      // Được cập nhật tự động qua StreamBuilder trong _buildMenuItem

      // Lấy số lượng nhận xét chưa đánh giá
      final reviewsResponse = await _reviewService.getMyReviews();
      if (reviewsResponse.success && reviewsResponse.data != null) {
        setState(() {
          _unreadReviewsCount = reviewsResponse.data!.where((review) => !review.isReviewed).length;
        });
      }

      print('✅ Đã tải thông tin user: $_userName ($_userEmail)');
    } catch (e) {
      print('❌ Lỗi tải thông tin user: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // Hiển thị dialog xác nhận
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.logoutConfirmTitle),
          content: Text(l10n.logoutConfirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.logout),
            ),
          ],
        ),
      );

      if (shouldLogout == true) {
        // Đăng xuất
        await _authService.signOut();
        await _firebaseAuthService.signOut();
        
        // Chuyển về màn hình đăng nhập
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const TriphotelStyleLoginScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      print('❌ Lỗi đăng xuất: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đăng xuất: $e')),
        );
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // Hiển thị dialog xác nhận
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.deleteAccountTitle),
          content: Text(l10n.deleteAccountMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.delete),
            ),
          ],
        ),
      );

      if (shouldDelete == true) {
        // Gọi API xóa tài khoản từ backend
        final deleteResponse = await _userProfileService.deleteAccount();
        if (deleteResponse.success) {
          // Đăng xuất và chuyển về màn hình đăng nhập
          await _authService.signOut();
          await _firebaseAuthService.signOut();
          
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
              (route) => false,
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${AppLocalizations.of(context)!.deleteAccountError}: ${deleteResponse.message}')),
            );
          }
        }
      }
    } catch (e) {
      print('❌ Lỗi xóa tài khoản: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.deleteAccountError}: $e')),
        );
      }
    }
  }

  void _showLanguageDialog() {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.chooseLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('vi', l10n.vietnamese, '🇻🇳', languageService),
            _buildLanguageOption('en', l10n.english, '🇺🇸', languageService),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String languageCode, String languageName, String flag, LanguageService languageService) {
    final isSelected = languageService.currentLanguageCode == languageCode;
    
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(languageName),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: () async {
        // Thay đổi ngôn ngữ của app
        await languageService.changeLanguage(languageCode);
        
        // Lưu cài đặt vào backend (optional)
        await _userProfileService.updateUserSettings(language: languageName);
        
        Navigator.of(context).pop();
        
        // Hiển thị thông báo - Lấy l10n mới sau khi đổi ngôn ngữ
        if (mounted) {
          // Đợi một chút để UI rebuild với ngôn ngữ mới
          await Future.delayed(const Duration(milliseconds: 100));
          final l10n = AppLocalizations.of(context)!;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.languageChanged),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  void _showCurrencyDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.chooseCurrency),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCurrencyOption('₫ | VND', 'Việt Nam Đồng'),
            _buildCurrencyOption('\$ | USD', 'US Dollar'),
            _buildCurrencyOption('€ | EUR', 'Euro'),
            _buildCurrencyOption('¥ | JPY', 'Japanese Yen'),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyOption(String currency, String description) {
    return ListTile(
      title: Text(currency),
      subtitle: Text(description),
      trailing: _selectedCurrency == currency ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: () async {
        setState(() {
          _selectedCurrency = currency;
        });
        Navigator.of(context).pop();
        
        // Lưu cài đặt vào CurrencyProvider (sẽ tự động notify listeners)
        if (mounted) {
          final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
          await currencyProvider.setCurrency(currency);
          print('✅ [Profile] Currency changed to: $currency');
        }
      },
    );
  }

  void _showPriceDisplayDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.priceDisplay),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPriceDisplayOption(l10n.perNight),
            _buildPriceDisplayOption(l10n.perStay),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceDisplayOption(String option) {
    return ListTile(
      title: Text(option),
      trailing: _selectedPriceDisplay == option ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: () async {
        setState(() {
          _selectedPriceDisplay = option;
        });
        Navigator.of(context).pop();
        
        // Lưu cài đặt
        await _userProfileService.updateUserSettings(priceDisplay: option);
      },
    );
  }

  void _showDistanceDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.chooseDistance),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDistanceOption('km'),
            _buildDistanceOption('miles'),
          ],
        ),
      ),
    );
  }

  Widget _buildDistanceOption(String unit) {
    return ListTile(
      title: Text(unit),
      trailing: _selectedDistance == unit ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: () async {
        setState(() {
          _selectedDistance = unit;
        });
        Navigator.of(context).pop();
        
        // Lưu cài đặt
        await _userProfileService.updateUserSettings(distanceUnit: unit);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Header với thông tin user
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  backgroundColor: const Color(0xFF8B4513), // Brown color like Triphotel
                  actions: [
                    // 🐛 DEBUG: Show role info
                    IconButton(
                      icon: const Icon(Icons.bug_report, color: Colors.yellow),
                      tooltip: 'Debug Role Info',
                      onPressed: () {
                        final backendUser = _backendAuthService.currentUser;
                        final backendRole = _backendAuthService.currentUserRole;
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Row(
                              children: [
                                Icon(Icons.bug_report, color: Colors.orange),
                                SizedBox(width: 8),
                                Text('🐛 DEBUG ROLE INFO'),
                              ],
                            ),
                            content: SingleChildScrollView(
                              child: SelectableText(
                                '👤 USER INFO:\n'
                                'Email: ${backendUser?.email}\n'
                                'Họ tên: ${backendUser?.hoTen}\n'
                                'Chức vụ (chucVu): ${backendUser?.chucVu}\n'
                                '\n'
                                '🎭 ROLE MODEL INFO:\n'
                                'Role enum: ${backendRole?.role}\n'
                                'Role toString: ${backendRole?.role.toString()}\n'
                                'Role name: ${backendRole?.role.name}\n'
                                'Is admin: ${backendRole?.isAdmin}\n'
                                'Is active: ${backendRole?.isActive}\n'
                                'Hotel ID: ${backendRole?.hotelId}\n'
                                '\n'
                                '🔍 CHECKS:\n'
                                'Is HotelManager (enum check)? ${backendRole?.role == UserRole.hotelManager}\n'
                                'Is User? ${backendRole?.role == UserRole.user}\n'
                                'Is Admin (getter)? ${backendRole?.isAdmin}\n',
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(AppLocalizations.of(context)!.close),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF8B4513), Color(0xFFA0522D)],
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Chào mừng, $_userName',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _userEmail,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // VIP Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'VIP',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[800],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _getVipLevelName(_vipStatus),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Content sections
                SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 16),
                    
                    // Quyền lợi thành viên
                    _buildSectionCard(
                      title: l10n.memberBenefits,
                      children: [
                        _buildMenuItem(
                          icon: Icons.star,
                          title: 'TriphotelVIP',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TriphotelVipScreen(),
                              ),
                            ).then((_) {
                              // Reload VIP status after returning
                              _loadUserData();
                            });
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.card_membership,
                          title: 'PointsMAX',
                          onTap: () {
                            // TODO: Navigate to PointsMAX details
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Tài khoản của tôi
                    _buildSectionCard(
                      title: l10n.myAccount,
                      children: [
                        _buildMenuItem(
                          icon: Icons.person,
                          title: l10n.profile,
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfileEditScreen(),
                              ),
                            );
                            if (result == true) {
                              // Reload user data if profile was updated
                              _loadUserData();
                            }
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.chat_bubble_outline,
                          title: l10n.messagesFromHotel,
                          trailing: StreamBuilder<int>(
                            stream: _messageService.getTotalUnreadCount(),
                            builder: (context, snapshot) {
                              final unreadCount = snapshot.data ?? 0;
                              if (unreadCount == 0) return const SizedBox.shrink();
                              
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ModernConversationListScreen(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.favorite_border,
                          title: l10n.savedItems,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SavedItemsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.history,
                          title: l10n.bookingHistory,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BookingHistoryScreen(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.credit_card,
                          title: l10n.savedCards,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SavedCardsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.rate_review,
                          title: l10n.myReviews,
                          trailing: _unreadReviewsCount > 0
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$_unreadReviewsCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : null,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MyReviewsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Hotel Owner Section (luôn hiển thị để user có thể đăng ký khách sạn)
                    _buildSectionCard(
                      title: l10n.hotelManagement,
                        children: [
                          if (_isHotelOwner) ...[
                            _buildMenuItem(
                              icon: Icons.business,
                              title: l10n.manageMyHotels,
                              trailing: _hotelCount > 0 
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$_hotelCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : null,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HotelOwnerDashboard(),
                                  ),
                                ).then((_) {
                                  _loadUserData(); // Refresh data after returning
                                });
                              },
                            ),
                          ],
                          _buildMenuItem(
                            icon: Icons.add_business,
                            title: _isHotelOwner ? l10n.registerNewHotel : l10n.registerHotel,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HotelRegistrationScreen(),
                                ),
                              ).then((_) {
                                _loadUserData(); // Refresh data after returning
                              });
                            },
                          ),
                        ],
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Cài đặt
                    _buildSectionCard(
                      title: l10n.settings,
                      children: [
                        _buildMenuItem(
                          icon: Icons.language,
                          title: l10n.language,
                          trailing: Consumer<LanguageService>(
                            builder: (context, languageService, child) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  languageService.currentLanguageDisplayName,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  languageService.isVietnamese ? '🇻🇳' : '🇺🇸',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                          onTap: _showLanguageDialog,
                        ),
                        _buildMenuItem(
                          icon: Icons.local_offer,
                          title: l10n.priceDisplay,
                          trailing: Text(
                            _selectedPriceDisplay,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          onTap: _showPriceDisplayDialog,
                        ),
                        _buildMenuItem(
                          icon: Icons.currency_exchange,
                          title: l10n.currency,
                          trailing: Text(
                            _selectedCurrency,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          onTap: _showCurrencyDialog,
                        ),
                        _buildMenuItem(
                          icon: Icons.location_on,
                          title: l10n.distance,
                          trailing: Text(
                            _selectedDistance,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          onTap: _showDistanceDialog,
                        ),
                        _buildMenuItem(
                          icon: Icons.notifications,
                          title: l10n.notifications,
                          trailing: Switch(
                            value: _notificationsEnabled,
                            onChanged: (value) async {
                              setState(() {
                                _notificationsEnabled = value;
                              });
                              
                              // Lưu vào SharedPreferences ngay lập tức
                              await _storageService.saveBool('notifications_enabled', value);
                              
                              // Lưu vào backend
                              final result = await _userProfileService.updateUserSettings(notificationsEnabled: value);
                              if (!result.success) {
                                // Nếu backend fail, revert lại
                                setState(() {
                                  _notificationsEnabled = !value;
                                });
                                await _storageService.saveBool('notifications_enabled', !value);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(result.message ?? 'Không thể cập nhật cài đặt'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(AppLocalizations.of(context)!.notificationSettingsUpdated),
                                      backgroundColor: Colors.green,
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          onTap: null,
                        ),
                        _buildMenuItem(
                          icon: Icons.email,
                          title: l10n.receiveEmailNotifications,
                          trailing: Switch(
                            value: _emailNotificationsEnabled,
                            onChanged: (value) async {
                              setState(() {
                                _emailNotificationsEnabled = value;
                              });
                              
                              // Lưu vào SharedPreferences ngay lập tức
                              await _storageService.saveBool('email_notifications_enabled', value);
                              
                              // Lưu cài đặt vào backend
                              final emailResult = await _userProfileService.updateEmailNotificationPreference(value);
                              if (!emailResult) {
                                // Nếu backend fail, revert lại
                                setState(() {
                                  _emailNotificationsEnabled = !value;
                                });
                                await _storageService.saveBool('email_notifications_enabled', !value);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(AppLocalizations.of(context)!.cannotUpdateEmailSettings),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(AppLocalizations.of(context)!.emailSettingsUpdated),
                                      backgroundColor: Colors.green,
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                }
                              }
                              await _userProfileService.updateEmailNotificationPreference(value);
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    value 
                                      ? 'Đã bật nhận email thông báo' 
                                      : 'Đã tắt nhận email thông báo',
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                          onTap: null,
                        ),
                        _buildMenuItem(
                          icon: Icons.security,
                          title: l10n.accountSecurity,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AccountSecurityScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Trợ giúp và thông tin
                    _buildSectionCard(
                      title: l10n.helpAndSupport,
                      children: [
                        _buildMenuItem(
                          icon: Icons.info_outline,
                          title: l10n.aboutUs,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AboutUsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.help_outline,
                          title: l10n.helpCenter,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HelpCenterScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Quản lý tài khoản
                    _buildSectionCard(
                      title: l10n.accountSettingsTitle,
                      children: [
                        _buildMenuItem(
                          icon: Icons.delete_outline,
                          title: 'Xóa Tài Khoản',
                          titleColor: Colors.red[700],
                          iconColor: Colors.red[700],
                          onTap: _handleDeleteAccount,
                        ),
                        _buildMenuItem(
                          icon: Icons.logout,
                          title: l10n.logout,
                          titleColor: Colors.red[700],
                          iconColor: Colors.red[700],
                          onTap: _handleLogout,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 100), // Space for bottom nav
                  ]),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionCard({
    String? title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
          ...children,
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    Color? titleColor,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (iconColor ?? Colors.grey[600])!.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor ?? Colors.grey[600],
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: titleColor ?? Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing,
            ],
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper method để convert VIP level sang tên tiếng Việt
  String _getVipLevelName(String level) {
    switch (level) {
      case 'Diamond':
        return 'Kim Cương';
      case 'Gold':
        return 'Vàng';
      case 'Silver':
        return 'Bạc';
      case 'Bronze':
      default:
        return 'Đồng';
    }
  }
}
