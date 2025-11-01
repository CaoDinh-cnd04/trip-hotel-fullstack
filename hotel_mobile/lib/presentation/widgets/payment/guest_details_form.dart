import 'package:flutter/material.dart';

class GuestDetailsForm extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final bool isLoggedIn;

  const GuestDetailsForm({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    this.isLoggedIn = false,
  });

  @override
  State<GuestDetailsForm> createState() => _GuestDetailsFormState();
}

class _GuestDetailsFormState extends State<GuestDetailsForm> {
  final _formKey = GlobalKey<FormState>();

  bool validateForm() {
    return _formKey.currentState?.validate() ?? false;
  }

  String? _validatePhone(String? value) {
    if (!widget.isLoggedIn) {
      if (value == null || value.trim().isEmpty) {
        return 'Vui lòng nhập số điện thoại';
      }
      if (!RegExp(r'^[0-9]{10,11}$').hasMatch(value.replaceAll(' ', ''))) {
        return 'Số điện thoại không hợp lệ';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.person, color: Colors.purple[600], size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Thông tin khách hàng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Họ và tên
              _buildTextField(
                controller: widget.nameController,
                label: 'Họ và tên',
                hint: 'Nhập họ và tên đầy đủ',
                icon: Icons.person_outline,
                iconColor: Colors.blue[600]!,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập họ và tên';
                  }
                  if (value.trim().length < 2) {
                    return 'Họ và tên phải có ít nhất 2 ký tự';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Email
              _buildTextField(
                controller: widget.emailController,
                label: 'Email',
                hint: 'example@email.com',
                icon: Icons.email_outlined,
                iconColor: Colors.orange[600]!,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),

              // Số điện thoại (nếu chưa đăng nhập)
              if (!widget.isLoggedIn) ...[
                const SizedBox(height: 16),
                _buildTextField(
                  controller: widget.phoneController,
                  label: 'Số điện thoại',
                  hint: '0987654321',
                  icon: Icons.phone_outlined,
                  iconColor: Colors.green[600]!,
                  keyboardType: TextInputType.phone,
                  validator: _validatePhone,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color iconColor,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(icon, color: iconColor),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: iconColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}