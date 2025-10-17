import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/config/facebook_config.dart';
import 'core/handlers/app_lifecycle_handler.dart';
import 'core/services/language_service.dart';
import 'presentation/main_wrapper.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/register_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/main_navigation_screen.dart';
import 'presentation/screens/search/search_results_screen.dart';
import 'presentation/screens/property/property_detail_screen.dart';
import 'presentation/screens/deals/deals_screen.dart';
import 'presentation/screens/map/map_view_screen.dart';
import 'presentation/screens/hotel_manager/hotel_manager_screen.dart';
import 'presentation/screens/admin/admin_main_screen.dart';
import 'presentation/screens/language_demo_screen.dart';
import 'presentation/screens/feedback/user_feedback_screen.dart';
import 'presentation/screens/admin/feedback_management_screen.dart';
import 'presentation/screens/notification/notification_screen.dart';
import 'presentation/screens/admin/create_notification_screen.dart';
import 'data/services/api_service.dart';
import 'data/services/auth_service.dart';

void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize Firebase - check if already initialized
      try {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
          print('🔥 Firebase đã được khởi tạo thành công!');
        } else {
          print('🔥 Firebase đã được khởi tạo trước đó!');
        }
      } catch (e) {
        print('❌ Lỗi khởi tạo Firebase: $e');
      }

      // Initialize services
      ApiService().initialize();
      await FacebookAuthConfig.initialize();

      // Initialize AuthService để check session khi app khởi động
      await AuthService().initialize();

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.dumpErrorToConsole(details);
      };
      runApp(const MyApp());
    },
    (Object error, StackTrace stack) {
      // TODO: send error to crash reporting or logging service
      // print is used as a placeholder for now
      // ignore: avoid_print
      print('Uncaught zone error: $error');
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LanguageService(),
      child: Consumer<LanguageService>(
        builder: (context, languageService, child) {
          return AppLifecycleHandler(
            child: MaterialApp(
              title: 'Hotel Booking',
              theme: AppTheme.lightTheme,
              debugShowCheckedModeBanner: false,

              // Internationalization
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: LanguageService.supportedLocales,
              locale: languageService.currentLocale,

              home:
                  const MainWrapper(), // Sử dụng MainWrapper để hiển thị giao diện chính
              routes: {
                '/login': (context) => const LoginScreen(),
                '/register': (context) => const RegisterScreen(),
                '/home': (context) => const HomeScreen(),
                '/main': (context) => const MainNavigationScreen(),
                '/search-results': (context) {
                  final args =
                      ModalRoute.of(context)!.settings.arguments
                          as Map<String, dynamic>;
                  return SearchResultsScreen(
                    location: args['location'],
                    checkInDate: args['checkInDate'],
                    checkOutDate: args['checkOutDate'],
                    guestCount: args['guestCount'],
                    roomCount: args['roomCount'],
                  );
                },
                '/property-detail': (context) {
                  final args =
                      ModalRoute.of(context)!.settings.arguments
                          as Map<String, dynamic>;
                  return PropertyDetailScreen(
                    hotel: args['hotel'],
                    checkInDate: args['checkInDate'],
                    checkOutDate: args['checkOutDate'],
                    guestCount: args['guestCount'] ?? 1,
                  );
                },
                '/deals': (context) => const DealsScreen(),
                '/map-view': (context) {
                  final args =
                      ModalRoute.of(context)!.settings.arguments
                          as Map<String, dynamic>;
                  return MapViewScreen(
                    hotels: args['hotels'],
                    location: args['location'],
                    checkInDate: args['checkInDate'],
                    checkOutDate: args['checkOutDate'],
                    guestCount: args['guestCount'],
                    roomCount: args['roomCount'],
                  );
                },
                '/hotel-manager': (context) => const HotelManagerScreen(),
                '/admin': (context) => const AdminMainScreen(),
                '/language-demo': (context) => const LanguageDemoScreen(),
                '/feedback': (context) => const UserFeedbackScreen(),
                '/admin/feedback': (context) =>
                    const FeedbackManagementScreen(),
                '/notifications': (context) => const NotificationScreen(),
                '/admin/create-notification': (context) => const CreateNotificationScreen(),
              },
            ),
          );
        },
      ),
    );
  }
}
