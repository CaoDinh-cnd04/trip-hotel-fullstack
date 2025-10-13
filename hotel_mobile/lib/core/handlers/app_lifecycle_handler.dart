import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';

class AppLifecycleHandler extends StatefulWidget {
  final Widget child;

  const AppLifecycleHandler({Key? key, required this.child}) : super(key: key);

  @override
  State<AppLifecycleHandler> createState() => _AppLifecycleHandlerState();
}

class _AppLifecycleHandlerState extends State<AppLifecycleHandler>
    with WidgetsBindingObserver {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App trở lại foreground, check session validity
        _checkSessionOnResume();
        break;
      case AppLifecycleState.paused:
        // App chuyển sang background
        print('App paused');
        break;
      case AppLifecycleState.inactive:
        // App temporarily inactive
        break;
      case AppLifecycleState.detached:
        // App đang bị terminate
        break;
      case AppLifecycleState.hidden:
        // App hidden
        break;
    }
  }

  Future<void> _checkSessionOnResume() async {
    print('App resumed, checking session validity...');

    try {
      await _authService.checkAndHandleExpiredSession();

      // If session expired and user was logged out, navigate to login
      if (_authService.currentUser == null) {
        // Use Navigator to go to login screen
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      }
    } catch (e) {
      print('Error checking session on app resume: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
