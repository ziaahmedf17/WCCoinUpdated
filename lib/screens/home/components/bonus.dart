import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wc_coin_app/core/constants/ad_helper/ad_helper.dart';
import 'package:wc_coin_app/core/constants/colors.dart';
import 'package:wc_coin_app/core/constants/size_utils.dart';
import 'package:wc_coin_app/main.dart';
import 'package:wc_coin_app/shared/primary_btn.dart';
import 'package:wc_coin_app/shared/snackbar.dart';
import 'package:wc_coin_app/shared/text_view.dart';

class BonusSection extends StatefulWidget {
  final String value;
  // final VoidCallback? onCoinsUpdated;

  const BonusSection({
    super.key,
    required this.value,
    // this.onCoinsUpdated,
  });

  @override
  State<BonusSection> createState() => _BonusSectionState();
}

class _BonusSectionState extends State<BonusSection>
    with SingleTickerProviderStateMixin {
  bool _isClaiming = false;
  bool _canClaim = false;
  Timer? _countdownTimer;
  Timer? _apiCheckTimer;
  int _remainingHours = 0;
  int _remainingMinutes = 0;
  int _remainingSeconds = 0;
  int _currentDay = 0;
  int _todayBonus = 0;
  bool _canClaimAccumulated = false;
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
    _fetchDailyBonusStatus();
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
      _fetchDailyBonusStatus();
    });
  }

  Future<void> _fetchDailyBonusStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) return;

      final response = await http.get(
        Uri.parse("https://wc-admin.genwizz.com/api/daily-bonus-status"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            _canClaimAccumulated = data['can_claim_accumulated'] ?? false;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(
          "No internet connection. Please check your network and try again.",
          context,
          isError: true);
    }
  }

  Future<void> _checkTimerStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) return;

      final response = await http.get(
        Uri.parse("https://wc-admin.genwizz.com/api/timer/daily_bonus"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            _canClaim = data['can_claim'] ?? false;
            _remainingHours = data['remaining_hours'] ?? 0;
            _remainingMinutes = data['remaining_minutes'] ?? 0;
            _remainingSeconds = data['remaining_seconds'] ?? 0;
            _currentDay = data['current_day'] ?? 0;
          });
          print("Fetched current_day from timer: $_currentDay");
        }

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
      if (!mounted) return;
      showCustomSnackBar(
          "No internet connection. Please check your network and try again.",
          context,
          isError: true);
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
        } else if (_remainingHours > 0) {
          _remainingHours--;
          _remainingMinutes = 59;
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
    if (_remainingHours > 0) {
      return "${_remainingHours}h ${_remainingMinutes}m";
    }
    return "${_remainingMinutes}m ${_remainingSeconds}s";
  }

  Future<void> _handleClaimBonus() async {
    if (_isClaiming || !_canClaim) return;

    setState(() {
      _isClaiming = true;
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
          _isClaiming = false;
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
      Uri.parse("https://wc-admin.genwizz.com/api/daily-bonus"),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
    );

    if (!mounted) return;

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      String successMessage =
          data["message"] ?? "Daily bonus claimed successfully!";

      print("API Response: $data");

      if (mounted) {
        setState(() {
          _todayBonus = data['data']?['today_bonus'] ?? 0;
          _canClaimAccumulated =
              data['data']?['can_claim_accumulated'] ?? false;
          _canClaim = false;
        });
      }

      // Force immediate UI refresh
      await Future.delayed(const Duration(milliseconds: 100));

      // Refresh data from APIs
      await _fetchDailyBonusStatus();
      await _checkTimerStatus();

      // if (widget.onCoinsUpdated != null) {
      //   widget.onCoinsUpdated!();
      // }

      showCustomSnackBar(successMessage, context, isError: false);
    } else {
      String errorMessage = data["message"] ?? "Failed to claim daily bonus";
      showCustomSnackBar(errorMessage, context, isError: true);
    }
  }

  // Keep the original _claimDailyBonus for backward compatibility if needed
  Future<void> _claimDailyBonus() async {
    await _handleClaimBonus();
  }

  Widget _buildDayIndicator(int day) {
    // Day is collected if it's less than or equal to current_day
    bool isCollected = day <= _currentDay;

    Color bgColor;
    Widget icon;
    Color textColor;

    print(
        "Building Day $day: isCollected=$isCollected, currentDay=$_currentDay");

    if (isCollected) {
      // Days collected - show green with checkmark
      bgColor = Color(0xff8200DB);
      icon = Icon(Icons.done_rounded, color: AppColors.white, size: 11.v);
      // textColor = Color(0xff8200DB);
      textColor = AppColors.white;
    } else {
      // Future days not collected yet - show gray
      bgColor = AppColors.white.withOpacity(0.3);
      icon = CircleAvatar(
        radius: 4.v,
        backgroundColor: AppColors.fontColor.withOpacity(.3),
      );
      textColor = Color(0xff8200DB);
      bgColor = Color(0xff8200DB).withOpacity(.1);
    }

    return Container(
      height: 40.v,
      width: 40.h,
      margin: EdgeInsets.only(right: 10.v),
      decoration:
          BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Center(
        child: CustomText(
          title: 'D$day',
          size: 14,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildDivider(int beforeDay) {
    bool isCollected = beforeDay <= _currentDay;
    return SizedBox(
      width: 40.h,
      child: Divider(
        color: isCollected ? AppColors.green : AppColors.white.withOpacity(0.3),
        thickness: 2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print(
        "Building widget with _currentDay: $_currentDay, _canClaim: $_canClaim");

    return Container(
      // height: 190.v,
      width: SizeUtils.width,
      padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 10.v),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.fontColor.withOpacity(.3)),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.all(0),
            leading: Image.asset(
              'assets/images/d.png',
              scale: 3.v,
            ),
            title: const CustomText(
              title: 'Daily Bonus',
              size: 22,
              height: 0,
              fontWeight: FontWeight.w600,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  title: widget.value,
                  size: 12,
                  color: AppColors.fontColor,
                  height: 0,
                ),
                CustomText(
                  title: _formatTime(),
                  size: 12,
                  color: AppColors.fontColor,
                  height: 0,
                ),
              ],
            ),
            trailing: _isClaiming
                ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SizedBox(
                      height: 25,
                      width: 25,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : ScaleTransition(
                    scale: _canClaim
                        ? _scaleAnimation
                        : AlwaysStoppedAnimation(1.0),
                    child: PrimaryBTN(
                      buttonTitle: 'Claim',
                      onCLick: _handleClaimBonus,
                      height: 40,
                      width: 100,
                      btColor: Color(0xff8200DB),
                    ),
                  ),
          ),

          // const Spacer(),
          Container(
            width: double.infinity,
            height: 100.v,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDayIndicator(1),
                _buildDayIndicator(2),
                _buildDayIndicator(3),
                _buildDayIndicator(4),
              ],
            ),
          ),
          // Gap.v(10),
        ],
      ),
    );
  }
}
