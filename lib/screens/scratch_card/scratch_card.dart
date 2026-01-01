import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:scratcher/scratcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wc_coin_app/core/constants/ad_helper/ad_helper.dart';
import 'package:wc_coin_app/core/constants/ad_helper/app_open_ad_helper.dart';
import 'package:wc_coin_app/core/constants/ad_helper/rewarded_ad_loading.dart';
import 'package:wc_coin_app/core/constants/colors.dart';
import 'package:wc_coin_app/core/constants/size_utils.dart';
import 'package:wc_coin_app/main.dart';
import 'package:wc_coin_app/screens/quiz/congratulation.dart';
import 'package:wc_coin_app/shared/custom_appbar.dart';
import 'package:wc_coin_app/shared/primary_btn.dart';
import 'package:wc_coin_app/shared/snackbar.dart';
import 'package:wc_coin_app/shared/text_view.dart';

class ScratchCardView extends StatefulWidget {
  const ScratchCardView({super.key});

  @override
  State<ScratchCardView> createState() => _ScratchCardViewState();
}

class _ScratchCardViewState extends State<ScratchCardView>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  bool _isScratched = false;
  bool _canClaim = false;
  int _remainingSeconds = 0;
  Timer? _countdownTimer;
  Timer? _apiCheckTimer;

  GoogleAdmobProvider adVM = GoogleAdmobProvider();
  String? _errorMessage;
  String? _nextClaimTime;
  String _hiddenCoins = '';
  final scratchKey = GlobalKey<ScratcherState>();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Predefined coin values for scratch cards
  final List<String> coinOptions = ['33', '33', '33', '33', '33', '33', '33'];

  @override
  void initState() {
    super.initState();
    _generateRandomCoins();
    adVM.loadInterAd();
    adVM.loadRewardedAd();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
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
        Uri.parse("https://wc-admin.genwizz.com/api/timer/scratch"),
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

  void _generateRandomCoins() {
    final random = Random();
    _hiddenCoins = coinOptions[random.nextInt(coinOptions.length)];
  }

  Future<void> _claimScratchCard() async {
    if (!_canClaim || _loading) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) {
        if (!mounted) return;
        showCustomSnackBar("No API token found", context, isError: true);
        setState(() => _loading = false);
        return;
      }

      final response = await http.post(
        Uri.parse("https://wc-admin.genwizz.com/api/scratch"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "coins": _hiddenCoins,
          "type": "scratch",
        }),
      );

      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // ✅ Show API message in snackbar
        if (data["message"] != null) {
          showCustomSnackBar(data["message"], context, isError: false);
        }

        // ✅ Success dialog with details
        _showSuccessDialog(_hiddenCoins, data);

        // ✅ Update next claim time if available
        if (data["next_claim_at"] != null) {
          setState(() {
            _nextClaimTime = data["next_claim_at"];
          });
        }

        // Refresh timer status after claiming
        await _checkTimerStatus();
      } else {
        if (data["message"] != null) {
          showCustomSnackBar(data["message"], context, isError: true);
        }
      }
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar("Error: $e", context, isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _claim2xReward(String originalCoins) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) {
        if (!mounted) return;
        showCustomSnackBar("No API token found", context, isError: true);
        return;
      }

      // Calculate double the coins
      final doubleCoins = (int.parse(originalCoins) * 2).toString();

      final response = await http.post(
        Uri.parse("https://wc-admin.genwizz.com/api/ads"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "coins": originalCoins,
          "type": "ad",
        }),
      );

      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Show success message
        if (data["message"] != null) {
          showCustomSnackBar(data["message"], context, isError: false);
        }

        // Show congratulation dialog for 2x reward
        _show2xRewardDialog(originalCoins, doubleCoins, data);
      } else {
        if (data["message"] != null) {
          showCustomSnackBar(data["message"], context, isError: true);
        }
      }
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar("Error claiming 2x reward: $e", context,
          isError: true);
    }
  }

  void _show2xRewardDialog(String originalCoins, String doubleCoins,
      Map<String, dynamic> responseData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple.shade600,
                  Colors.purple.shade800,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: Colors.amber,
                  size: 60,
                ),
                const SizedBox(height: 16),
                const CustomText(
                  title: 'Amazing!',
                  size: 24,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                const CustomText(
                  title: 'You doubled your reward!',
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      CustomText(
                        title: 'Original: $originalCoins coins',
                        size: 14,
                        color: Colors.white70,
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        title: '2x Reward: $doubleCoins coins',
                        size: 16,
                        color: Colors.amber,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (responseData['message'] != null)
                  CustomText(
                    title: responseData['message'],
                    size: 14,
                    color: Colors.white70,
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _resetScratchCard();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.purple.shade800,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Play Again'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSuccessDialog(String coins, Map<String, dynamic> responseData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.8),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.celebration,
                  color: Colors.amber,
                  size: 60,
                ),
                const SizedBox(height: 16),
                const CustomText(
                  title: 'Congratulations!',
                  size: 24,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                CustomText(
                  title: 'You won $coins coins!',
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                if (responseData['message'] != null)
                  CustomText(
                    title: responseData['message'],
                    size: 14,
                    color: Colors.white70,
                  ),
                SizedBox(height: 20.v),
                const CustomText(
                  title: 'Watch Ad to double your Reward',
                  size: 15,
                  color: AppColors.white,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Center(
                            child: CustomText(
                          title: 'Continue',
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        )),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          RewardedAdLoading.show(context, onComplete: () {
                            _claim2xReward(coins);
                            print("✅ User rewarded successfully");
                          }, onFailed: () {
                            print("⚠️ Rewarded ad failed or skipped");
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Center(
                            child: CustomText(
                          title: '2x Reward',
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        )),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _resetScratchCard() {
    setState(() {
      _isScratched = false;
      _errorMessage = null;
      _nextClaimTime = null;
    });
    _generateRandomCoins();
    scratchKey.currentState?.reset();
    _checkTimerStatus();
  }

  void _onScratchComplete() {
    if (!_canClaim) {
      showCustomSnackBar("Please wait for the timer to finish", context,
          isError: true);
      return;
    }

    setState(() {
      _isScratched = true;
    });

    // Auto claim after 1 second delay
    Future.delayed(const Duration(seconds: 1), () async {
      if (mounted && _canClaim) {
        if (apads['int']) {
          // if (await isReady()) {
          InterstitialAdLoading.show(context, onComplete: () {
            _claimScratchCard();
          }, onFailed: () {
            _claimScratchCard();
          });
        } else {
          _claimScratchCard();
        }
      } else {
        _claimScratchCard();
      }
      // }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: const CustomAppBar(title: 'Scratch Card'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Timer or Ready indicator
            Container(
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
                mainAxisSize: MainAxisSize.min,
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

            Gap.v(20),

            // Scratch Card
            ScaleTransition(
              scale: _canClaim ? _scaleAnimation : AlwaysStoppedAnimation(1.0),
              child: Opacity(
                opacity: _canClaim ? 1.0 : 0.5,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AbsorbPointer(
                      absorbing: !_canClaim,
                      child: Scratcher(
                        key: scratchKey,
                        brushSize: 30,
                        threshold: 50,
                        color: Colors.grey.shade600,
                        onThreshold: _onScratchComplete,
                        child: Container(
                          height: 200,
                          width: 300,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.amber.shade400,
                                Colors.amber.shade600,
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.monetization_on,
                                color: Colors.white,
                                size: 40,
                              ),
                              const SizedBox(height: 10),
                              CustomText(
                                title: _hiddenCoins,
                                size: 48,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 5),
                              const CustomText(
                                title: 'COINS',
                                size: 18,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Gap.v(30),

            // Status and buttons
            if (_loading)
              Column(
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  Gap.v(10),
                  const CustomText(
                    title: 'Processing your reward...',
                    size: 16,
                    color: Colors.white70,
                  ),
                ],
              )
            else if (!_canClaim && _errorMessage != null)
              Column(
                children: [
                  const CustomText(
                    title: 'Come back later!',
                    size: 18,
                    color: AppColors.primary,
                  ),
                  Gap.v(10),
                  if (_nextClaimTime != null)
                    CustomText(
                      title: 'Next claim: $_nextClaimTime',
                      size: 14,
                      color: AppColors.primary,
                    ),
                ],
              )
            else if (_isScratched)
              Container(
                  margin: const EdgeInsets.all(20),
                  padding:
                      EdgeInsets.symmetric(vertical: 10.v, horizontal: 12.h),
                  width: SizeUtils.width,
                  // height: 150.v,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: AppColors.primary.withOpacity(.3)),
                      gradient: const LinearGradient(
                          colors: [Color(0xffEFF6FF), Color(0xffFFF7ED)])),
                  child: CustomText(
                    title: 'Great! Your reward is being processed...',
                    size: 14,
                    color: AppColors.fontColor.withOpacity(.6),
                    alignment: TextAlign.center,
                  ))
            else
              Container(
                margin: const EdgeInsets.all(20),
                padding: EdgeInsets.symmetric(vertical: 10.v, horizontal: 12.h),
                width: SizeUtils.width,
                // height: 150.v,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: AppColors.primary.withOpacity(.3)),
                    gradient: const LinearGradient(
                        colors: [Color(0xffEFF6FF), Color(0xffFFF7ED)])),
                child: CustomText(
                  title: _canClaim
                      ? '💡 Tip: Scratch with your finger to reveal the prize'
                      : 'Please wait for the timer to finish',
                  size: 14,
                  color: _canClaim
                      ? AppColors.fontColor.withOpacity(.6)
                      : Colors.orange,
                  alignment: TextAlign.center,
                ),
              ),

            Gap.v(30),
          ],
        ),
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
