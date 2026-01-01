import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:http/http.dart' as http;
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

class SpinAndWinView extends StatefulWidget {
  const SpinAndWinView({super.key});

  @override
  State<SpinAndWinView> createState() => _SpinAndWinViewState();
}

class _SpinAndWinViewState extends State<SpinAndWinView>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _isSpinning = false;
  bool _canClaim = false;
  int _remainingSeconds = 0;
  Timer? _countdownTimer;
  Timer? _apiCheckTimer;

  StreamController<int> controller = StreamController<int>();
  GoogleAdmobProvider adVM = GoogleAdmobProvider();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Define the wheel items with coins
  final List<String> wheelItems = [
    '0',
    '10',
    '20',
    '30',
    '40',
    '50',
    '60',
    '70',
  ];

  // Colors for each segment
  final List<Color> segmentColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
  ];

  @override
  void dispose() {
    controller.close();
    _countdownTimer?.cancel();
    _apiCheckTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
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
        Uri.parse("https://wc-admin.genwizz.com/api/timer/spin"),
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

  Future<void> _spinWheel() async {
    if (_isSpinning || !_canClaim) return;

    setState(() {
      _isSpinning = true;
      _isLoading = true;
    });

    try {
      // Generate random index for where wheel will stop
      final randomIndex = (wheelItems.length * 0.1 +
                  (wheelItems.length - 1) *
                      0.9 *
                      (DateTime.now().millisecond / 1000))
              .floor() %
          wheelItems.length;

      // Start the wheel animation
      controller.add(randomIndex);

      // Wait for animation to complete (approximately 3 seconds)
      await Future.delayed(const Duration(seconds: 3));

      // Get the coin value where wheel stopped
      final selectedCoins = wheelItems[randomIndex];

      // Call API with the selected coins
      await _callSpinAPI(selectedCoins);

      // Refresh timer status after spin
      await _checkTimerStatus();
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar("Error: $e", context, isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSpinning = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _callSpinAPI(String coins) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) {
        if (!mounted) return;
        showCustomSnackBar("No API token found", context, isError: true);
        return;
      }

      final url = Uri.parse("https://wc-admin.genwizz.com/api/spin");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "coins": coins,
          "type": "spin",
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ✅ Show API's message in snackbar
        if (data['message'] != null) {
          showCustomSnackBar(data['message'], context, isError: false);
        }

        // Keep success dialog (optional if you still need it)
        _showSuccessDialog(coins, data);
      } else {
        final data = jsonDecode(response.body);
        if (data['message'] != null) {
          showCustomSnackBar(data['message'], context, isError: true);
        }
      }
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar("API Error: $e", context, isError: true);
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
                  title: 'You doubled your spin reward!',
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
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.purple.shade800,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Continue'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: const CustomAppBar(title: 'Spin and Win'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Fortune Wheel
            Gap.v(25),
            Container(
              height: 300,
              width: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: FortuneWheel(
                selected: controller.stream,
                animateFirst: false,
                rotationCount: 30,
                items: wheelItems.asMap().entries.map((entry) {
                  int index = entry.key;
                  String value = entry.value;
                  return FortuneItem(
                    child: Container(
                      decoration: BoxDecoration(
                        color: segmentColors[index % segmentColors.length],
                      ),
                      child: Center(
                        child: Text(
                          value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    style: FortuneItemStyle(
                      color: segmentColors[index % segmentColors.length],
                      borderColor: Colors.white,
                      borderWidth: 2,
                    ),
                  );
                }).toList(),
                onFocusItemChanged: (index) {
                  // Optional: Add haptic feedback or sound here
                },
                indicators: const <FortuneIndicator>[
                  FortuneIndicator(
                    alignment: Alignment.topCenter,
                    child: TriangleIndicator(
                      color: Colors.amber,
                      width: 20.0,
                      height: 20.0,
                    ),
                  ),
                ],
                physics: CircularPanPhysics(
                  duration: const Duration(seconds: 3),
                  curve: Curves.decelerate,
                ),
              ),
            ),

            Gap.v(40),

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

            // Instruction text
            CustomText(
              title: _canClaim
                  ? 'Spin the wheel to win coins!'
                  : 'Please wait for the timer',
              size: 16,
              color: AppColors.primary,
            ),

            Gap.v(20),

            // Spin button
            _isLoading
                ? Column(
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      Gap.v(10),
                      CustomText(
                        title: _isSpinning ? 'Spinning...' : 'Processing...',
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  )
                : ScaleTransition(
                    scale: _canClaim
                        ? _scaleAnimation
                        : AlwaysStoppedAnimation(1.0),
                    child: Opacity(
                      opacity: _canClaim ? 1.0 : 0.5,
                      child: PrimaryBTN(
                          btColor: AppColors.secondary,
                          onCLick: _canClaim
                              ? () async {
                                  if (apads['int']) {
                                    // if (await isReady()) {
                                    InterstitialAdLoading.show(context,
                                        onComplete: () {
                                      _spinWheel();
                                    }, onFailed: () {
                                      _spinWheel();
                                    });
                                    // }
                                  } else {
                                    _spinWheel();
                                  }
                                }
                              : () {},
                          buttonTitle: _canClaim ? 'Spin Now' : 'Wait...'),
                    ),
                  ),
            Gap.v(10),

            Container(
              margin: const EdgeInsets.all(20),
              padding: EdgeInsets.symmetric(vertical: 10.v, horizontal: 12.h),
              width: SizeUtils.width,
              // height: 150.v,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(.3)),
                  gradient: const LinearGradient(
                      colors: [Color(0xffEFF6FF), Color(0xffFFF7ED)])),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Gap.v(10),
                  CustomText(
                    title: '💡 Tap the button to spin the wheel and win coins!',
                  ),
                  Gap.v(10),
                ],
              ),
            )
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
