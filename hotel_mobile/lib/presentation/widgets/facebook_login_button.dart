import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/services/facebook_auth_service.dart';

class FacebookLoginButton extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  final Function(String)? onLoginError;
  final VoidCallback? onLoginCancelled;
  final String? customText;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  const FacebookLoginButton({
    Key? key,
    this.onLoginSuccess,
    this.onLoginError,
    this.onLoginCancelled,
    this.customText,
    this.margin,
    this.padding,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  State<FacebookLoginButton> createState() => _FacebookLoginButtonState();
}

class _FacebookLoginButtonState extends State<FacebookLoginButton> {
  bool _isLoading = false;
  final FacebookAuthService _facebookAuthService = FacebookAuthService();

  Future<void> _handleFacebookLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _facebookAuthService.signInWithFacebook();

      if (result.isSuccess) {
        // Đăng nhập thành công
        print('Đăng nhập Facebook thành công!');
        print('Tên: ${result.name}');
        print('Email: ${result.email}');
        print('ID: ${result.userId}');
        print('Access Token: ${result.accessToken}');

        widget.onLoginSuccess?.call();
      } else if (result.isCancelled) {
        // User hủy đăng nhập
        print('Người dùng hủy đăng nhập Facebook');
        widget.onLoginCancelled?.call();
      } else {
        // Có lỗi xảy ra
        print('Lỗi đăng nhập Facebook: ${result.error}');
        widget.onLoginError?.call(result.error ?? 'Đăng nhập thất bại');
      }
    } catch (e) {
      print('Exception khi đăng nhập Facebook: $e');
      widget.onLoginError?.call('Có lỗi xảy ra: $e');
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
    return Container(
      margin: widget.margin,
      width: widget.width ?? double.infinity,
      height: widget.height ?? 50.h,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleFacebookLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1877F2), // Facebook Blue
          foregroundColor: Colors.white,
          padding:
              widget.padding ??
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Facebook Icon
                  Container(
                    width: 24.w,
                    height: 24.w,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        'f',
                        style: TextStyle(
                          color: const Color(0xFF1877F2),
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Button Text
                  Text(
                    widget.customText ?? 'Đăng nhập bằng Facebook',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Widget đơn giản chỉ có icon Facebook
class FacebookIconButton extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  final Function(String)? onLoginError;
  final VoidCallback? onLoginCancelled;
  final double? size;

  const FacebookIconButton({
    Key? key,
    this.onLoginSuccess,
    this.onLoginError,
    this.onLoginCancelled,
    this.size,
  }) : super(key: key);

  @override
  State<FacebookIconButton> createState() => _FacebookIconButtonState();
}

class _FacebookIconButtonState extends State<FacebookIconButton> {
  bool _isLoading = false;
  final FacebookAuthService _facebookAuthService = FacebookAuthService();

  Future<void> _handleFacebookLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _facebookAuthService.signInWithFacebook();

      if (result.isSuccess) {
        widget.onLoginSuccess?.call();
      } else if (result.isCancelled) {
        widget.onLoginCancelled?.call();
      } else {
        widget.onLoginError?.call(result.error ?? 'Đăng nhập thất bại');
      }
    } catch (e) {
      widget.onLoginError?.call('Có lỗi xảy ra: $e');
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
    final buttonSize = widget.size ?? 50.w;

    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        color: const Color(0xFF1877F2),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleFacebookLogin,
          borderRadius: BorderRadius.circular(buttonSize / 2),
          child: Center(
            child: _isLoading
                ? SizedBox(
                    width: buttonSize * 0.4,
                    height: buttonSize * 0.4,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'f',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: buttonSize * 0.4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
