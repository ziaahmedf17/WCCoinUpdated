import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wc_coin_app/core/constants/colors.dart';
import 'package:wc_coin_app/core/constants/size_utils.dart';
import 'package:wc_coin_app/services/auth_service.dart';
import 'package:wc_coin_app/shared/snackbar.dart';
import 'package:wc_coin_app/shared/text_view.dart';

import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({
    super.key,
    required this.email,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }
    if (value.length != 6) {
      return 'OTP must be 6 digits';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  void _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _authService.resetPassword(
        email: widget.email,
        otp: _otpController.text.trim(),
        password: _passwordController.text,
      );

      setState(() => _isLoading = false);

      if (result.success && mounted) {
        showCustomSnackBar(
          result.message ?? 'Password reset successful!',
          context,
          isError: false,
        );

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
            );
          }
        });
      } else {
        showCustomSnackBar(
          result.message ?? 'Password reset failed',
          context,
          isError: true,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      showCustomSnackBar(
        'An unexpected error occurred. Please try again.',
        context,
        isError: true,
      );
    }
  }

  void _handleResendOTP() async {
    setState(() => _isLoading = true);

    try {
      final result = await _authService.forgotPassword(email: widget.email);

      setState(() => _isLoading = false);

      if (result.success && mounted) {
        showCustomSnackBar(
          'OTP has been resent to your email',
          context,
          isError: false,
        );
      } else {
        showCustomSnackBar(
          result.message ?? 'Failed to resend OTP',
          context,
          isError: true,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      showCustomSnackBar(
        'An unexpected error occurred. Please try again.',
        context,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.fontColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const CustomText(
                  title: 'Reset Password',
                  size: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.fontColor,
                ),
                Gap.v(8),
                CustomText(
                  title: 'Enter the OTP sent to ${widget.email}',
                  size: 16,
                  color: Colors.grey,
                ),
                Gap.v(40),

                // OTP Field
                const CustomText(
                  title: 'OTP Code',
                  size: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.fontColor,
                ),
                Gap.v(8),
                TextFormField(
                  controller: _otpController,
                  validator: _validateOTP,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: 'Enter 6-digit OTP',
                    prefixIcon: const Icon(Icons.pin_outlined),
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                Gap.v(12),

                // Resend OTP
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _isLoading ? null : _handleResendOTP,
                    child: CustomText(
                      title: 'Resend OTP',
                      size: 14,
                      fontWeight: FontWeight.w600,
                      color: _isLoading ? Colors.grey : AppColors.primary,
                    ),
                  ),
                ),
                Gap.v(20),

                // New Password Field
                const CustomText(
                  title: 'New Password',
                  size: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.fontColor,
                ),
                Gap.v(8),
                TextFormField(
                  controller: _passwordController,
                  validator: _validatePassword,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Enter new password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                Gap.v(20),

                // Confirm Password Field
                const CustomText(
                  title: 'Confirm Password',
                  size: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.fontColor,
                ),
                Gap.v(8),
                TextFormField(
                  controller: _confirmPasswordController,
                  validator: _validateConfirmPassword,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: 'Confirm new password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(
                                () => _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                Gap.v(30),

                // Reset Password Button
                SizedBox(
                  width: double.infinity,
                  height: 56.v,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleResetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const CustomText(
                      title: 'Reset Password',
                      size: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}