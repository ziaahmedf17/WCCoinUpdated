// import 'package:flutter/material.dart';
// import 'package:upgrader/upgrader.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:wc_coin_app/core/constants/colors.dart';
// import 'package:wc_coin_app/core/constants/size_utils.dart';
// import 'package:wc_coin_app/screens/home/home.dart';
// import 'package:wc_coin_app/screens/root/root_view.dart';
// import 'package:wc_coin_app/shared/snackbar.dart';
// import 'package:wc_coin_app/shared/text_view.dart';
// import 'package:wc_coin_app/services/auth_service.dart';
//
// class LoginView extends StatefulWidget {
//   const LoginView({super.key});
//
//   @override
//   State<LoginView> createState() => _LoginViewState();
// }
//
// class _LoginViewState extends State<LoginView>
//     with SingleTickerProviderStateMixin {
//   final AuthService _authService = AuthService();
//   bool _isLoading = false;
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Initialize animations
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 1500),
//       vsync: this,
//     );
//
//     _fadeAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
//     ));
//
//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 0.3),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
//     ));
//
//     _animationController.forward();
//   }
//
//   void _handleGoogleSignIn() async {
//     if (_isLoading) return;
//
//     setState(() => _isLoading = true);
//
//     try {
//       final result = await _authService.signInWithGoogle();
//
//       setState(() => _isLoading = false);
//
//       if (result.success && mounted) {
//         showCustomSnackBar(
//           'Welcome! Signed in successfully',
//           context,
//           isError: false,
//         );
//
//         Future.delayed(const Duration(milliseconds: 500), () {
//           if (mounted) {
//             Navigator.pushAndRemoveUntil(
//               context,
//               _createRoute(const RootView()),
//               (route) => false,
//             );
//           }
//         });
//       } else {
//         if (result.error == AuthError.userCancelled) {
//           return;
//         } else if (result.error == AuthError.deviceRestricted) {
//           // Get the registered email from the result
//           String registeredEmail = result.registeredEmail ?? 'another email';
//           _showDeviceRestrictionDialog(registeredEmail);
//           return;
//         }
//
//         String errorMessage = result.message ?? 'Sign-in failed';
//         showCustomSnackBar(errorMessage, context, isError: true);
//         String registeredEmail = result.registeredEmail ?? 'another email';
//
//         _showDeviceRestrictionDialog(registeredEmail);
//       }
//     } catch (e) {
//       setState(() => _isLoading = false);
//       showCustomSnackBar(
//         'An unexpected error occurred. Please try again.',
//         context,
//         isError: true,
//       );
//     }
//   }
//
//   void _showDeviceRestrictionDialog(String registeredEmail) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           backgroundColor: Colors.white,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           contentPadding: EdgeInsets.zero,
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Header with gradient background
//               Container(
//                 width: double.infinity,
//                 padding:
//                     const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [Colors.orange.shade400, Colors.orange.shade600],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   borderRadius: const BorderRadius.only(
//                     topLeft: Radius.circular(20),
//                     topRight: Radius.circular(20),
//                   ),
//                 ),
//                 child: Column(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: const BoxDecoration(
//                         color: Colors.white,
//                         shape: BoxShape.circle,
//                       ),
//                       child: Icon(
//                         Icons.device_hub_outlined,
//                         color: Colors.orange.shade600,
//                         size: 32,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     const Text(
//                       'Device Restricted',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               // Content
//               Padding(
//                 padding: const EdgeInsets.all(24),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Text(
//                       'This device is already registered with:',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         color: AppColors.fontColor,
//                         fontSize: 13,
//                         height: 1.4,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     // Display the registered email
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         vertical: 12,
//                         horizontal: 16,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.grey.shade100,
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(
//                           color: Colors.grey.shade300,
//                           width: 1,
//                         ),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(
//                             Icons.email_outlined,
//                             color: Colors.grey.shade700,
//                             size: 18,
//                           ),
//                           const SizedBox(width: 8),
//                           Flexible(
//                             child: Text(
//                               registeredEmail,
//                               style: TextStyle(
//                                 color: Colors.grey.shade800,
//                                 fontSize: 14.fSize,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                               textAlign: TextAlign.center,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: Colors.orange.shade50,
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(
//                           color: Colors.orange.shade200,
//                           width: 1,
//                         ),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(
//                             Icons.info_outline,
//                             color: Colors.orange.shade700,
//                             size: 20,
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: Text(
//                               'For security reasons, only one email can be registered per device.',
//                               style: TextStyle(
//                                 color: Colors.orange.shade900,
//                                 fontSize: 13,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     const Text(
//                       'Please contact our support team for assistance.',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         color: Colors.grey,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               // Action buttons
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: TextButton(
//                         onPressed: () {
//                           Navigator.of(context).pop();
//                         },
//                         style: TextButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                         ),
//                         child: const Text(
//                           'Close',
//                           style: TextStyle(
//                             color: Colors.grey,
//                             fontWeight: FontWeight.w600,
//                             fontSize: 15,
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: () async {
//                           // Replace with your support URL
//                           final Uri url = Uri.parse(
//                               'https://docs.google.com/forms/d/e/1FAIpQLSc9L3GsOIPDjih_XzI-ppw88HRKaYyICDdWK-YQF9z17MmUHg/viewform?usp=publish-editor');
//                           if (await canLaunchUrl(url)) {
//                             await launchUrl(url,
//                                 mode: LaunchMode.externalApplication);
//                           }
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: AppColors.primary,
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                           elevation: 0,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                         ),
//                         child: const Text(
//                           'Contact Support',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.w600,
//                             fontSize: 15,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Route _createRoute(Widget destination) {
//     return PageRouteBuilder(
//       pageBuilder: (context, animation, secondaryAnimation) => destination,
//       transitionDuration: const Duration(milliseconds: 600),
//       transitionsBuilder: (context, animation, secondaryAnimation, child) {
//         return SlideTransition(
//           position: Tween<Offset>(
//             begin: const Offset(1.0, 0.0),
//             end: Offset.zero,
//           ).animate(animation),
//           child: child,
//         );
//       },
//     );
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return UpgradeAlert(
//       showIgnore: false, // Set to false for force update
//       showLater: false, // Set to false for force update
//       barrierDismissible: false,
//       dialogStyle: UpgradeDialogStyle.cupertino,
//       upgrader: Upgrader(
//         // Configure the upgrader
//         debugDisplayAlways: false, // Set to true for testing
//         durationUntilAlertAgain: const Duration(days: 1),
//
//         messages: UpgraderMessages(
//           code: 'en',
//         ),
//       ),
//       child: Scaffold(
//         backgroundColor: AppColors.primary,
//         body: SafeArea(
//           child: AnimatedBuilder(
//             animation: _animationController,
//             builder: (context, child) {
//               return FadeTransition(
//                 opacity: _fadeAnimation,
//                 child: SlideTransition(
//                   position: _slideAnimation,
//                   child: Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Container(
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           child: Image.asset(
//                             'assets/images/WC COIN.png',
//                             scale: 3.v,
//                           ),
//                         ),
//
//                         const CustomText(
//                           title: 'WVC APP',
//                           fontWeight: FontWeight.bold,
//                           color: AppColors.white,
//                           size: 30,
//                         ),
//
//                         // Gap.v(50),
//
//                         Container(
//                           width: 180.h,
//                           padding: EdgeInsets.symmetric(
//                               vertical: 10.v, horizontal: 20.h),
//                           decoration: BoxDecoration(
//                               color: AppColors.white.withOpacity(.2),
//                               borderRadius: BorderRadius.circular(30)),
//                           child: Center(
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Image.asset(
//                                   'assets/icons/coin.png',
//                                   scale: 4.v,
//                                 ),
//                                 Gap.h(12),
//                                 const CustomText(
//                                   title: 'Get Rewards',
//                                   color: AppColors.white,
//                                   fontWeight: FontWeight.w500,
//                                 )
//                               ],
//                             ),
//                           ),
//                         ),
//                         // Loading indicator
//                         // SizedBox(
//                         //   height: 4,
//                         //   width: 200,
//                         //   child: LinearProgressIndicator(
//                         //     backgroundColor: Colors.white.withOpacity(0.2),
//                         //     valueColor: AlwaysStoppedAnimation<Color>(
//                         //       Colors.white.withOpacity(0.8),
//                         //     ),
//                         //   ),
//                         // ),
//                         // const Spacer(),
//                         Gap.v(100),
//                         // Enhanced Google Sign-in Button
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 25),
//                           child: AnimatedContainer(
//                             duration: const Duration(milliseconds: 200),
//                             height: 60.v,
//                             width: double.infinity,
//                             decoration: BoxDecoration(
//                               color: _isLoading
//                                   ? Colors.grey.shade300
//                                   : AppColors.white,
//                               borderRadius: BorderRadius.circular(12),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.black.withOpacity(0.1),
//                                   blurRadius: 10,
//                                   offset: const Offset(0, 5),
//                                 ),
//                               ],
//                             ),
//                             child: Material(
//                               color: Colors.transparent,
//                               child: InkWell(
//                                 onTap: _isLoading ? null : _handleGoogleSignIn,
//                                 borderRadius: BorderRadius.circular(12),
//                                 child: Container(
//                                   padding: const EdgeInsets.symmetric(
//                                       horizontal: 20),
//                                   child: _isLoading
//                                       ? _buildLoadingWidget()
//                                       : _buildSignInContent(),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//
//                         Gap.v(30),
//                       ],
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildLoadingWidget() {
//     return const Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         SizedBox(
//           width: 20,
//           height: 20,
//           child: CircularProgressIndicator(
//             strokeWidth: 2,
//             valueColor: AlwaysStoppedAnimation<Color>(
//               AppColors.primary,
//             ),
//           ),
//         ),
//         SizedBox(width: 16),
//         Text(
//           'Signing you in...',
//           style: TextStyle(
//             color: AppColors.fontColor,
//             fontSize: 16,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildSignInContent() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Image.asset(
//           'assets/icons/google.png',
//           width: 24,
//           height: 24,
//         ),
//         const SizedBox(width: 16),
//         const CustomText(
//           title: 'Continue with Google',
//           color: AppColors.fontColor,
//           fontWeight: FontWeight.w600,
//           size: 20,
//         )
//       ],
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wc_coin_app/core/constants/colors.dart';
import 'package:wc_coin_app/core/constants/size_utils.dart';
import 'package:wc_coin_app/screens/auth/login_screen.dart';
import 'package:wc_coin_app/screens/auth/register_screen.dart';
import 'package:wc_coin_app/screens/root/root_view.dart';
import 'package:wc_coin_app/shared/snackbar.dart';
import 'package:wc_coin_app/shared/text_view.dart';
import 'package:wc_coin_app/services/auth_service.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  void _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final result = await _authService.signInWithGoogle();

      setState(() => _isLoading = false);

      if (result.success && mounted) {
        showCustomSnackBar(
          'Welcome! Signed in successfully',
          context,
          isError: false,
        );

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              _createRoute(const RootView()),
                  (route) => false,
            );
          }
        });
      } else {
        if (result.error == AuthError.userCancelled) {
          return;
        } else if (result.error == AuthError.deviceRestricted) {
          String registeredEmail = result.registeredEmail ?? 'another email';
          _showDeviceRestrictionDialog(registeredEmail);
          return;
        }

        String errorMessage = result.message ?? 'Sign-in failed';
        showCustomSnackBar(errorMessage, context, isError: true);
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

  void _showDeviceRestrictionDialog(String registeredEmail) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient background
              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.orange.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.device_hub_outlined,
                        color: Colors.orange.shade600,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Device Restricted',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'This device is already registered with:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.fontColor,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.email_outlined,
                            color: Colors.grey.shade700,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              registeredEmail,
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'For security reasons, only one email can be registered per device.',
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Please contact our support team for assistance.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Action buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final Uri url = Uri.parse(
                              'https://docs.google.com/forms/d/e/1FAIpQLSc9L3GsOIPDjih_XzI-ppw88HRKaYyICDdWK-YQF9z17MmUHg/viewform?usp=publish-editor');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url,
                                mode: LaunchMode.externalApplication);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Contact Support',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Route _createRoute(Widget destination) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => destination,
      transitionDuration: const Duration(milliseconds: 600),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UpgradeAlert(
      showIgnore: false,
      showLater: false,
      barrierDismissible: false,
      dialogStyle: UpgradeDialogStyle.cupertino,
      upgrader: Upgrader(
        debugDisplayAlways: false,
        durationUntilAlertAgain: const Duration(days: 1),
        messages: UpgraderMessages(
          code: 'en',
        ),
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Image.asset(
                            'assets/images/WC COIN.png',
                            scale: 3.v,
                          ),
                        ),
                        const CustomText(
                          title: 'WVC APP',
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                          size: 30,
                        ),
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
                                const CustomText(
                                  title: 'Get Rewards',
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w500,
                                )
                              ],
                            ),
                          ),
                        ),
                        Gap.v(100),

                        // Google Sign-in Button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 60.v,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: _isLoading
                                  ? Colors.grey.shade300
                                  : AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _isLoading ? null : _handleGoogleSignIn,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: _isLoading
                                      ? _buildLoadingWidget()
                                      : _buildSignInContent(),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Gap.v(16),

                        // Divider
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              Padding(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                                child: CustomText(
                                  title: 'OR',
                                  color: Colors.white.withOpacity(0.8),
                                  size: 14,
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Gap.v(16),

                        // Email Sign-in/Register Buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 60.v,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                            const LoginScreen(),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: const Center(
                                        child: CustomText(
                                          title: 'Sign In',
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Gap.h(12),
                              Expanded(
                                child: Container(
                                  height: 60.v,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                            const RegisterScreen(),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: const Center(
                                        child: CustomText(
                                          title: 'Sign Up',
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Gap.v(30),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.primary,
            ),
          ),
        ),
        SizedBox(width: 16),
        Text(
          'Signing you in...',
          style: TextStyle(
            color: AppColors.fontColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSignInContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/icons/google.png',
          width: 24,
          height: 24,
        ),
        const SizedBox(width: 16),
        const CustomText(
          title: 'Continue with Google',
          color: AppColors.fontColor,
          fontWeight: FontWeight.w600,
          size: 20,
        )
      ],
    );
  }
}