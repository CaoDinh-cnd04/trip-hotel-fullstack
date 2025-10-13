import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/google_auth_service.dart';
import '../../../core/services/facebook_auth_service.dart';
import '../../../data/services/backend_auth_service.dart';

class AuthDebugScreen extends StatefulWidget {
  const AuthDebugScreen({super.key});

  @override
  State<AuthDebugScreen> createState() => _AuthDebugScreenState();
}

class _AuthDebugScreenState extends State<AuthDebugScreen> {
  final GoogleAuthService _googleAuth = GoogleAuthService();
  final FacebookAuthService _facebookAuth = FacebookAuthService();
  final BackendAuthService _backendAuth = BackendAuthService();

  List<String> _logs = [];
  bool _isLoading = false;

  void _addLog(String message) {
    setState(() {
      _logs.add('[${DateTime.now().toString().substring(11, 19)}] $message');
    });
    print(message);
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  Future<void> _testFirebaseInit() async {
    setState(() => _isLoading = true);
    try {
      _addLog('🔄 Testing Firebase initialization...');

      // Check if Firebase is already initialized
      try {
        final app = Firebase.app();
        _addLog('✅ Firebase already initialized: ${app.name}');
      } catch (e) {
        _addLog('❌ Firebase not initialized: $e');
        return;
      }

      // Test Firebase Auth
      final auth = FirebaseAuth.instance;
      _addLog('✅ Firebase Auth instance created');
      _addLog('📱 Current user: ${auth.currentUser?.email ?? 'None'}');
    } catch (e) {
      _addLog('❌ Firebase test failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      _addLog('🔄 Testing Google Sign-In configuration...');

      _addLog('✅ GoogleSignIn instance created');

      // Test if can show sign-in dialog
      _addLog('🔄 Attempting Google Sign-In...');
      final result = await _googleAuth.signInWithGoogle();
      if (result != null) {
        _addLog('✅ Google Sign-In successful!');
        _addLog('👤 User: ${result.user?.displayName ?? result.user?.email}');

        // Sign out immediately for testing
        await _googleAuth.signOut();
        _addLog('🔄 Signed out for testing');
      } else {
        _addLog('⚠️ Google Sign-In cancelled by user');
      }
    } catch (e) {
      _addLog('❌ Google Sign-In failed: $e');
      _addLog(
        '💡 Check: Google Services, SHA fingerprints, OAuth configuration',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testFacebookSignIn() async {
    setState(() => _isLoading = true);
    try {
      _addLog('🔄 Testing Facebook Sign-In configuration...');

      // Test Facebook Auth
      _addLog('🔄 Attempting Facebook Sign-In...');
      final result = await _facebookAuth.signInWithFacebook();

      if (result.isSuccess) {
        _addLog('✅ Facebook Sign-In successful!');
        _addLog('👤 User: ${result.name ?? result.email}');
        _addLog('🔑 Token: ${result.accessToken?.substring(0, 20)}...');
      } else if (result.isCancelled) {
        _addLog('⚠️ Facebook Sign-In cancelled by user');
      } else {
        _addLog('❌ Facebook Sign-In failed: ${result.error}');
      }
    } catch (e) {
      _addLog('❌ Facebook Sign-In failed: $e');
      _addLog('💡 Check: Facebook App ID, Client Token, App configuration');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testBackendConnection() async {
    setState(() => _isLoading = true);
    try {
      _addLog('🔄 Testing backend connection...');

      // Test a simple backend call
      final result = await _backendAuth.signInWithFacebook();

      if (result.isSuccess) {
        _addLog('✅ Backend connection successful');
      } else {
        _addLog('❌ Backend connection failed: ${result.error}');
      }
    } catch (e) {
      _addLog('❌ Backend test failed: $e');
      _addLog('💡 Check: Backend server running, network connection');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth Debug'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _clearLogs, icon: const Icon(Icons.clear)),
        ],
      ),
      body: Column(
        children: [
          // Test Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _testFirebaseInit,
                  child: const Text('Test Firebase'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testGoogleSignIn,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Test Google Sign-In'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testFacebookSignIn,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('Test Facebook Sign-In'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testBackendConnection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Test Backend'),
                ),
              ],
            ),
          ),

          // Loading indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),

          // Logs
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _logs.isEmpty
                  ? const Center(
                      child: Text(
                        'Press buttons above to run tests...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        Color textColor = Colors.white;
                        if (log.contains('✅')) textColor = Colors.green;
                        if (log.contains('❌')) textColor = Colors.red;
                        if (log.contains('⚠️')) textColor = Colors.orange;
                        if (log.contains('🔄')) textColor = Colors.blue;
                        if (log.contains('💡')) textColor = Colors.yellow;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            log,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
