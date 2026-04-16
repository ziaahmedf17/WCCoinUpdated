import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wc_coin_app/core/constants/ad_helper/ad_helper.dart';
import 'package:wc_coin_app/core/constants/ad_helper/app_open_ad_helper.dart';
import 'package:wc_coin_app/core/constants/colors.dart';
import 'package:wc_coin_app/core/constants/size_utils.dart';
import 'package:wc_coin_app/main.dart';
import 'package:wc_coin_app/models/social_model.dart';
import 'package:wc_coin_app/services/social_service.dart';
import 'package:wc_coin_app/shared/custom_appbar.dart';
import 'package:wc_coin_app/shared/snackbar.dart';
import 'package:wc_coin_app/shared/text_view.dart';

class SubscribeToEarnView extends StatefulWidget {
  const SubscribeToEarnView({super.key});

  @override
  State<SubscribeToEarnView> createState() => _SubscribeToEarnViewState();
}

class _SubscribeToEarnViewState extends State<SubscribeToEarnView>
    with SingleTickerProviderStateMixin {
  late Future<List<Social>> socialsFuture;
  GoogleAdmobProvider adVM = GoogleAdmobProvider();

  bool _canClaim = false;
  int _remainingSeconds = 0;
  Timer? _countdownTimer;
  Timer? _apiCheckTimer;

  // Track which social links have been visited
  final Set<int> _visitedSocials = {};
  final Map<int, Timer> _verificationTimers = {};

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    adVM.loadInterAd();

    socialsFuture = SocialService().fetchSocials();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _checkTimerStatus();
    _startApiCheckTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _apiCheckTimer?.cancel();
    _animationController.dispose();
    // Cancel all verification timers
    for (var timer in _verificationTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  void _startApiCheckTimer() {
    _apiCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkTimerStatus();
    });
  }

  Future<void> _checkTimerStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) return;

      final response = await http.get(
        Uri.parse("https://wc-admin.genwizz.com/api/timer/social_visit"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _canClaim = data['can_claim'] ?? false;
          _remainingSeconds = (data['remaining_seconds'] ?? 0).ceil();
        });

        if (_canClaim) {
          _startBlinkingAnimation();
          _countdownTimer?.cancel();
        } else {
          _animationController.stop();
          _animationController.reset();
          _startCountdown();
        }
      }
    } catch (e) {
      print("Error checking timer status: $e");
    }
  }

  void _startBlinkingAnimation() {
    _animationController.repeat(reverse: true);
  }

  void _startCountdown() {
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          timer.cancel();
          _checkTimerStatus();
        }
      });
    });
  }

  String _formatTime() {
    if (_canClaim) return "Ready to play!";

    int hours = _remainingSeconds ~/ 3600;
    int minutes = (_remainingSeconds % 3600) ~/ 60;
    int seconds = _remainingSeconds % 60;

    if (hours > 0) {
      return "$hours hr $minutes min $seconds sec";
    } else if (minutes > 0) {
      return "$minutes min $seconds sec";
    }
    return "$seconds seconds";
  }

  Future<void> _openSocialLink(Social social) async {
    if (!_canClaim) {
      showCustomSnackBar("Please wait for the timer to finish", context,
          isError: true);
      return;
    }

    try {
      final Uri url = Uri.parse(social.url);

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);

        // Mark as visited
        setState(() {
          _visitedSocials.add(social.id);
        });

        // Show instruction
        showCustomSnackBar(
          "Please subscribe/follow and come back to claim your reward!",
          context,
          isError: false,
        );

        // Start verification timer (15 seconds)
        _startVerificationTimer(social.id);
      } else {
        showCustomSnackBar("Could not open the link", context, isError: true);
      }
    } catch (e) {
      showCustomSnackBar("Error opening link: $e", context, isError: true);
    }
  }

  void _startVerificationTimer(int socialId) {
    // Cancel existing timer if any
    _verificationTimers[socialId]?.cancel();

    // Start new timer - user has 15 seconds to return and claim
    _verificationTimers[socialId] = Timer(const Duration(seconds: 15), () {
      if (mounted) {
        setState(() {
          // Timer expired, user can now claim
        });
      }
    });
  }

  Future<void> _claimReward(Social social) async {
    if (!_canClaim) {
      showCustomSnackBar("Please wait for the timer to finish", context,
          isError: true);
      return;
    }

    if (!_visitedSocials.contains(social.id)) {
      showCustomSnackBar("Please visit the social link first!", context,
          isError: true);
      return;
    }

    // Claim the reward
    await SocialService().claimSocialReward(social.id, context);

    // Remove from visited set
    setState(() {
      _visitedSocials.remove(social.id);
    });

    // Refresh timer status after claiming
    _checkTimerStatus();
  }

  String _getButtonText(Social social) {
    if (!_canClaim) {
      return 'Wait';
    }

    if (_visitedSocials.contains(social.id)) {
      return 'Claim';
    }

    return 'Visit';
  }

  Color _getButtonColor(Social social) {
    if (!_canClaim) {
      return Colors.deepOrange.withOpacity(0.5);
    }

    if (_visitedSocials.contains(social.id)) {
      return Colors.green;
    }

    return Colors.deepOrange;
  }

  void _handleButtonTap(Social social) {
    if (!_canClaim) {
      showCustomSnackBar("Please wait for the timer to finish", context,
          isError: true);
      return;
    }

    if (_visitedSocials.contains(social.id)) {
      // User has visited, now claim
      // _claimReward(social);

      apads['int']
          ? InterstitialAdLoading.show(context, onComplete: () {
              _claimReward(social);
            }, onFailed: () {
              _claimReward(social);
            })
          : _claimReward(social);
    } else {
      // Open the social link
      _openSocialLink(social);
    }
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          SizedBox(height: 20),
          CustomText(
            title: 'Loading Links...',
            size: 16,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_alt,
              size: 64, color: Colors.white.withOpacity(0.7)),
          const SizedBox(height: 20),
          const CustomText(
            title: 'No Social Available',
            size: 18,
            color: Colors.white,
          ),
          const SizedBox(height: 10),
          const CustomText(
            title: 'All the social tasks will be displayed here.',
            size: 14,
            color: Colors.white70,
            alignment: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 24.h, vertical: 20.v),
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.red.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated/Shaking icon (optional)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64.v,
                color: Colors.red.withOpacity(0.7),
              ),
            ),
            Gap.v(20),
            CustomText(
              title: "Error loading Links",
              size: 18,
              color: AppColors.fontColor,
              fontWeight: FontWeight.w600,
            ),
            Gap.v(12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12.v),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomText(
                title: error.replaceAll('Exception:', ''),
                size: 14,
                color: Colors.red.withOpacity(0.8),
                alignment: TextAlign.center,
                maxLines: 5,
              ),
            ),
            Gap.v(24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Social Rewards"),
      backgroundColor: AppColors.bgColor,
      body: Column(
        children: [
          // Timer Display at the top
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: _canClaim
                  ? Colors.green.withOpacity(0.2)
                  : Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _canClaim ? Colors.green : Colors.orange,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _canClaim ? Icons.check_circle : Icons.timer,
                  color: _canClaim ? Colors.green : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 8),
                CustomText(
                  title: _formatTime(),
                  size: 16,
                  color: _canClaim ? Colors.green : Colors.orange,
                ),
              ],
            ),
          ),

          // Social List
          Expanded(
            child: FutureBuilder<List<Social>>(
              future: socialsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingWidget();
                } else if (snapshot.hasError) {
                  return Center(
                    child: _buildErrorWidget(snapshot.error.toString()),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final socials = snapshot.data!;

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: socials.length,
                  itemBuilder: (context, index) {
                    final social = socials[index];
                    final formattedDate = DateFormat("dd MMM yyyy, hh:mm a")
                        .format(social.createdAt);
                    final isVisited = _visitedSocials.contains(social.id);

                    return ScaleTransition(
                      scale: _canClaim
                          ? _scaleAnimation
                          : const AlwaysStoppedAnimation(1.0),
                      child: Opacity(
                        opacity: _canClaim ? 1.0 : 0.6,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 15),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: _canClaim
                                ? Border.all(
                                    color: isVisited
                                        ? Colors.green.withOpacity(0.5)
                                        : Colors.deepOrange.withOpacity(0.5))
                                : null,
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Image.asset('assets/images/visit.png'),
                            title: CustomText(
                              title: "Earn ${social.coins} Coins",
                              size: 18,
                              color: AppColors.fontColor,
                              fontWeight: FontWeight.w600,
                            ),
                            subtitle: CustomText(
                              title: "Platform: ${social.platform}\n"
                                  "Status: ${social.status}\n"
                                  "Added: $formattedDate",
                              size: 14,
                              color: AppColors.fontColor,
                            ),
                            trailing: GestureDetector(
                              onTap: () => _handleButtonTap(social),
                              child: Container(
                                height: 30,
                                width: 70,
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      spreadRadius: 2,
                                      blurRadius: 10,
                                      color: _getButtonColor(social)
                                          .withOpacity(.4),
                                    )
                                  ],
                                  color: _getButtonColor(social),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Center(
                                  child: CustomText(
                                    title: _getButtonText(social),
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: apads['banner']
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Gap.v(5),
                const CustomText(
                  title: 'Advertisement',
                ),
                Gap.v(5),
                const BannerAD(),
                Gap.v(5),
              ],
            )
          : const SizedBox(),
    );
  }
}
