import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wc_coin_app/core/constants/ad_helper/ad_helper.dart';
import 'package:wc_coin_app/core/constants/ad_helper/app_open_ad_helper.dart';
import 'package:wc_coin_app/core/constants/colors.dart';
import 'package:wc_coin_app/core/constants/size_utils.dart';
import 'package:wc_coin_app/main.dart';
import 'package:wc_coin_app/shared/primary_btn.dart';
import 'package:wc_coin_app/shared/snackbar.dart';
import 'package:wc_coin_app/shared/text_view.dart';

class CoinsEarnedSection extends StatefulWidget {
  final int coins;
  final bool isLoading;
  final Function() ontap;
  final String value;
  // final VoidCallback? onCoinsUpdated;

  const CoinsEarnedSection({
    required this.coins,
    this.isLoading = false,
    // this.onCoinsUpdated,
    super.key,
    required this.ontap,
    required this.value,
  });

  @override
  State<CoinsEarnedSection> createState() => _CoinsEarnedSectionState();
}

class _CoinsEarnedSectionState extends State<CoinsEarnedSection>
    with SingleTickerProviderStateMixin {
  bool _isClaimingBonus = false;
  String? _nextClaimTime;
  bool _canClaim = false;
  Timer? _countdownTimer;
  Timer? _apiCheckTimer;
  int _remainingMinutes = 0;
  int _remainingSeconds = 0;
  int _remainingHours = 0;
  GoogleAdmobProvider adVM = GoogleAdmobProvider();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    adVM.loadInterAd();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
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
        Uri.parse("https://wc-admin.genwizz.com/api/timer/hourly_bonus"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _canClaim = data['can_claim'] ?? false;
          _remainingMinutes = data['remaining_minutes'] ?? 0;
          _remainingSeconds = data['remaining_seconds'] ?? 0;
          _nextClaimTime = data['next_claim_at'];
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
      // Silently ignore — timer UI stays as-is, no snackbar spam on mobile data
      debugPrint('_checkTimerStatus error: $e');
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
        } else if (_remainingMinutes > 0) {
          _remainingMinutes--;
          _remainingSeconds = 59;
        } else {
          timer.cancel();
          _checkTimerStatus();
        }
      });
    });
  }

  String _formatTime() {
    if (_canClaim) return "Ready to claim!";
    return "${_remainingMinutes}m ${_remainingSeconds}s";
  }

  Future<void> _handleClaimBonus() async {
    if (_isClaimingBonus || !_canClaim) return;

    setState(() {
      _isClaimingBonus = true;
    });

    try {
      // Show ad if available
      if (apads['int'] == true) {
        bool adShown = await _showInterstitialAd();

        // Claim bonus regardless of ad success
        await _claimBonusApiCall();
      } else {
        // No ad required, just claim bonus
        await _claimBonusApiCall();
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar("Error claiming bonus: $e", context, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isClaimingBonus = false;
        });
      }
    }
  }

  Future<bool> _showInterstitialAd() async {
    try {
      adVM.showInterAd();
      return true;
    } catch (e) {
      print("Ad failed to show: $e");
      return false;
    }
  }

  Future<void> _claimBonusApiCall() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');

    if (token == null) {
      if (!mounted) return;
      showCustomSnackBar("No API token found", context, isError: true);
      return;
    }

    final response = await http.post(
      Uri.parse("https://wc-admin.genwizz.com/api/hourly-bonus"),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
    ).timeout(const Duration(seconds: 30));

    if (!mounted) return;

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      String successMessage =
          data["message"] ?? "Hourly bonus claimed successfully!";
      showCustomSnackBar(successMessage, context, isError: false);

      if (data["data"] != null &&
          data["data"]["next_claim_available"] != null) {
        setState(() {
          _nextClaimTime = data["data"]["next_claim_available"];
          _canClaim = false;
        });
      }

      _checkTimerStatus();

      // if (widget.onCoinsUpdated != null) {
      //   widget.onCoinsUpdated!();
      // }
    } else {
      String errorMessage = data["message"] ?? "Failed to claim hourly bonus";

      if (data["data"] != null &&
          data["data"]["next_claim_available"] != null) {
        setState(() {
          _nextClaimTime = data["data"]["next_claim_available"];
          _canClaim = false;
        });
      } else if (data["next_claim_available"] != null) {
        setState(() {
          _nextClaimTime = data["next_claim_available"];
          _canClaim = false;
        });
      }

      showCustomSnackBar(errorMessage, context, isError: true);
    }
  }

  // Keep the original _claimHourlyBonus for backward compatibility
  Future<void> _claimHourlyBonus() async {
    await _handleClaimBonus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // height: 190.v,
      width: SizeUtils.width,
      padding: EdgeInsets.symmetric(horizontal: 15.h, vertical: 10.v),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Gap.v(20),
          CustomText(
            title: 'Total Coins Earn',
            size: 14,
            color: AppColors.white.withOpacity(.7),
            height: 0,
          ),
          // Gap.v(4),
          Row(
            children: [
              Gap.h(15),
              widget.isLoading
                  ? Container(
                      height: 20,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )
                  : CustomText(
                      title: '${widget.coins}',
                      size: 35,
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      height: 0,
                    ),
              Gap.h(5),
              GestureDetector(
                onTap: widget.ontap,
                child: Icon(
                  Icons.refresh,
                  color: Colors.white.withOpacity(0.7),
                  size: 25.v,
                ),
              ),
              Spacer(),
              Image.asset(
                'assets/images/gift.png',
                scale: 8.v,
              ),
            ],
          ),

          // ListTile(
          //   title: const CustomText(
          //     title: 'Hourly Reward',
          //     size: 24,
          //   ),
          // ),
          // Gap.v(16),
          // const CustomText(
          //   title: 'Hourly Reward',
          //   size: 24,
          // ),
          // CustomText(
          //   title: _formatTime(),
          //   size: 12,
          //   color: _canClaim ? AppColors.green : Colors.white70,
          // ),
          Gap.v(10),
          Container(
            decoration: BoxDecoration(
                color: AppColors.white.withOpacity(.2),
                borderRadius: BorderRadius.circular(16)),
            padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 5.v),
            child: ListTile(
              contentPadding: EdgeInsets.all(0),
              leading: Image.asset(
                'assets/images/h.png',
                scale: 5.v,
              ),
              title: const CustomText(
                title: 'Hourly Reward',
                size: 17,
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    title: widget.value,
                    size: 12,
                    color: Colors.white,
                  ),
                  CustomText(
                    title: _formatTime(),
                    size: 12,
                    color: Colors.white,
                  ),
                ],
              ),
              trailing: _isClaimingBonus
                  ? Container(
                      height: 40,
                      width: 40,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : ScaleTransition(
                      scale: _canClaim
                          ? _scaleAnimation
                          : AlwaysStoppedAnimation(1.0),
                      child: PrimaryBTN(
                        buttonTitle: _canClaim ? 'Claim' : 'Wait',
                        onCLick: _handleClaimBonus,
                        btColor: _canClaim
                            ? AppColors.secondary
                            : AppColors.secondary.withOpacity(.7),
                        width: 100.h,
                        height: 40.v,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
