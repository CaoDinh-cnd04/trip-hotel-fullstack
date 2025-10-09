import 'package:flutter/material.dart';
import 'package:hotel_mobile/core/services/google_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoogleSignInButton extends StatefulWidget {
  final VoidCallback? onSuccess;
  final Function(String)? onError;

  const GoogleSignInButton({Key? key, this.onSuccess, this.onError})
    : super(key: key);

  @override
  _GoogleSignInButtonState createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final UserCredential? userCredential = await _googleAuthService
          .signInWithGoogle();

      if (userCredential != null && userCredential.user != null) {
        // Đăng nhập thành công
        print('🎉 Google Sign-In thành công!');
        print('👤 Tên: ${userCredential.user!.displayName}');
        print('📧 Email: ${userCredential.user!.email}');
        print('🆔 UID: ${userCredential.user!.uid}');

        if (widget.onSuccess != null) {
          widget.onSuccess!();
        }
      }
    } catch (e) {
      // Đăng nhập thất bại
      print('❌ Lỗi đăng nhập Google: $e');
      if (widget.onError != null) {
        widget.onError!(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleGoogleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 1,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 24,
                    width: 24,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.g_mobiledata,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Đăng nhập với Google',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
      ),
    );
  }
}
