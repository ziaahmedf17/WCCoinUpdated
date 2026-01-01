import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:wc_coin_app/core/constants/colors.dart';
import 'package:wc_coin_app/core/constants/size_utils.dart';
import 'package:wc_coin_app/screens/home/home.dart';
import 'package:wc_coin_app/screens/root/root_view.dart';
import 'package:wc_coin_app/screens/login/login.dart';
import 'package:wc_coin_app/services/auth_service.dart';
import 'package:wc_coin_app/services/network_listener.dart';
import 'package:wc_coin_app/shared/text_view.dart';
import 'package:wc_coin_app/shared/primary_btn.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
    ));

    // Start animation and check authentication
    _animationController.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Check internet connection first
    if (await checkInternetConnection() == false) {
      if (mounted) {
        ConnectivityHelper.showNoInternetDialog(
          context,
          onRetry: () {
            _initializeApp();
          },
        );
      }
      return;
    }

    try {
      print('=== SPLASH DEBUG START ===');

      // Wait for minimum splash duration
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) {
        print('Widget not mounted, returning');
        return;
      }

      // Check SharedPreferences directly first
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      final playerId = prefs.getString('player_id');
      final playerEmail = prefs.getString('player_email');

      print('Direct SharedPreferences check:');
      print(
          'Token: ${token != null ? 'EXISTS (${token.length} chars)' : 'NULL'}');
      print('Player ID: ${playerId ?? 'NULL'}');
      print('Player Email: ${playerEmail ?? 'NULL'}');

      // More flexible check: if we have token and email, user should be logged in
      // Some APIs might not return player_id, so we'll be flexible
      final hasAuthData = token != null &&
          token.isNotEmpty &&
          playerEmail != null &&
          playerEmail.isNotEmpty;

      print('Has auth data: $hasAuthData');

      // If we have token and email but no player ID, let's still consider user logged in
      // and try to get the player ID from API call later
      if (hasAuthData) {
        print('Auth data found - navigating to RootView');
        _navigateToMain();
      } else {
        print('No auth data - navigating to Login');
        _navigateToLogin();
      }

      print('=== SPLASH DEBUG END ===');
    } catch (e) {
      print('Error in splash initialization: $e');
      _navigateToLogin();
    }
  }

  Future<bool> checkInternetConnection() async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult.contains(ConnectivityResult.mobile)) {
        return true;
      } else if (connectivityResult.contains(ConnectivityResult.wifi)) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error checking internet: $e');
      return false;
    }
  }

  void _navigateToMain() {
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RootView(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
      (route) => false,
    );
  }

  void _navigateToLogin() {
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginView(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with subtle glow effect
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Image.asset(
                        'assets/images/WC COIN.png',
                        scale: 3.v,
                      ),
                    ),

                    CustomText(
                      title: 'WC APP',
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                      size: 30,
                    ),

                    // Gap.v(50),

                    Container(
                      width: 180.h,
                      padding: EdgeInsets.symmetric(
                          vertical: 10.v, horizontal: 20.h),
                      decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(.2),
                          borderRadius: BorderRadius.circular(30)),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/icons/coin.png',
                              scale: 4.v,
                            ),
                            Gap.h(12),
                            CustomText(
                              title: 'Get Rewards',
                              color: AppColors.white,
                              fontWeight: FontWeight.w500,
                            )
                          ],
                        ),
                      ),
                    )
                    // Loading indicator
                    // SizedBox(
                    //   height: 4,
                    //   width: 200,
                    //   child: LinearProgressIndicator(
                    //     backgroundColor: Colors.white.withOpacity(0.2),
                    //     valueColor: AlwaysStoppedAnimation<Color>(
                    //       Colors.white.withOpacity(0.8),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
