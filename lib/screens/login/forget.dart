import 'package:flutter/material.dart';
import 'package:wc_coin_app/core/constants/colors.dart';
import 'package:wc_coin_app/core/constants/size_utils.dart';
import 'package:wc_coin_app/screens/login/reset.dart';
import 'package:wc_coin_app/services/auth_service.dart';
import 'package:wc_coin_app/shared/snackbar.dart';
import 'package:wc_coin_app/shared/text_view.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  void _handleSendOTP() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _authService.forgotPassword(
        email: _emailController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (result.success && mounted) {
        showCustomSnackBar(
          result.message ?? 'OTP sent successfully',
          context,
          isError: false,
        );

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResetPasswordScreen(
                  email: _emailController.text.trim(),
                ),
              ),
            );
          }
        });
      } else {
        showCustomSnackBar(
          result.message ?? 'Failed to send OTP',
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
                  title: 'Forgot Password',
                  size: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.fontColor,
                ),
                Gap.v(8),
                const CustomText(
                  title:
                  'Enter your email address and we\'ll send you an OTP to reset your password',
                  size: 16,
                  color: Colors.grey,
                ),
                Gap.v(40),

                // Illustration
                Center(
                  child: Container(
                    padding: EdgeInsets.all(40.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_reset,
                      size: 80.h,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Gap.v(40),

                // Email Field
                const CustomText(
                  title: 'Email',
                  size: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.fontColor,
                ),
                Gap.v(8),
                TextFormField(
                  controller: _emailController,
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    prefixIcon: const Icon(Icons.email_outlined),
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

                // Send OTP Button
                SizedBox(
                  width: double.infinity,
                  height: 56.v,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSendOTP,
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
                      title: 'Send OTP',
                      size: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Gap.v(24),

                // Back to login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CustomText(
                      title: 'Remember your password? ',
                      size: 14,
                      color: Colors.grey,
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const CustomText(
                        title: 'Sign In',
                        size: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}