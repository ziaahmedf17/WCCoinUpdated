import 'package:flutter/material.dart';
import 'package:wc_coin_app/core/constants/colors.dart';
import 'package:wc_coin_app/core/constants/size_utils.dart';

import 'package:wc_coin_app/screens/login/register.dart';
import 'package:wc_coin_app/screens/root/root_view.dart';
import 'package:wc_coin_app/services/auth_service.dart';
import 'package:wc_coin_app/shared/snackbar.dart';
import 'package:wc_coin_app/shared/text_view.dart';

import 'forget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _authService.signInWithForm(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      setState(() => _isLoading = false);

      if (result.success && mounted) {
        showCustomSnackBar(
          result.message ?? 'Login successful!',
          context,
          isError: false,
        );

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const RootView()),
              (route) => false,
            );
          }
        });
      } else {
        if (result.validationErrors != null) {
          // Show first validation error
          final firstError = result.validationErrors!.values.first;
          final errorMessage =
              firstError is List ? firstError.first : firstError;
          showCustomSnackBar(errorMessage.toString(), context, isError: true);
        } else {
          showCustomSnackBar(
            result.message ?? 'Login failed',
            context,
            isError: true,
          );
        }
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
                  title: 'Welcome Back',
                  size: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.fontColor,
                ),
                Gap.v(8),
                const CustomText(
                  title: 'Sign in to continue',
                  size: 16,
                  color: Colors.grey,
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
                Gap.v(20),

                // Password Field
                const CustomText(
                  title: 'Password',
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
                    hintText: 'Enter your password',
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
                Gap.v(12),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: const CustomText(
                      title: 'Forgot Password?',
                      size: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Gap.v(30),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 56.v,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
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
                            title: 'Sign In',
                            size: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                  ),
                ),
                Gap.v(24),

                // Don't have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CustomText(
                      title: "Don't have an account? ",
                      size: 14,
                      color: Colors.grey,
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const CustomText(
                        title: 'Sign Up',
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
