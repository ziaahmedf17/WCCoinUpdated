import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:wc_coin_app/core/constants/ad_helper/ad_helper.dart';
import 'package:wc_coin_app/core/constants/ad_helper/app_open_ad_helper.dart';
import 'package:wc_coin_app/core/constants/ad_helper/rewarded_ad_loading.dart';
import 'package:wc_coin_app/core/constants/colors.dart';
import 'package:wc_coin_app/core/constants/size_utils.dart';
import 'package:wc_coin_app/main.dart';
import 'package:wc_coin_app/models/reward_values_model.dart';
import 'package:wc_coin_app/screens/home/components/bonus.dart';
import 'package:wc_coin_app/screens/home/components/coin_earned.dart';
import 'package:wc_coin_app/screens/home/components/home_appbar.dart';
import 'package:wc_coin_app/screens/promo_code/enter_code.dart';
import 'package:wc_coin_app/screens/quiz/quiz.dart';
import 'package:wc_coin_app/screens/redeem_uc/redeem_uc.dart';
import 'package:wc_coin_app/screens/scratch_card/scratch_card.dart';
import 'package:wc_coin_app/screens/spin_and_win/spin_and_win.dart';
import 'package:wc_coin_app/screens/subscribe/subscribe_view.dart';
import 'package:wc_coin_app/screens/visit_to_earn/visit_to_earn_view.dart';
import 'package:wc_coin_app/services/network_listener.dart';
import 'package:wc_coin_app/services/reward_values_service.dart';
import 'package:wc_coin_app/services/user_profile_service.dart';
import 'package:wc_coin_app/shared/primary_btn.dart';
import 'package:wc_coin_app/shared/snackbar.dart';
import 'package:wc_coin_app/shared/text_view.dart';
import 'package:wc_coin_app/models/user_model.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final UserService _userService = UserService();
  UserModel? _user;
  bool _isLoading = true;
  String _errorMessage = '';

  // Connectivity listener
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isDialogShowing = false;

  // Ad timer variables
  bool _canClaimAd = false;
  int _remainingAdSeconds = 0;
  Timer? _adCountdownTimer;
  Timer? _adApiCheckTimer;
  late AnimationController _adAnimationController;
  late Animation<double> _adScaleAnimation;
  GoogleAdmobProvider adVM = GoogleAdmobProvider();
  final RewardsService _rewardsService = RewardsService();
  RewardsModel _rewards = RewardsModel.defaults();
  List img = [
    'spin.png',
    'scratch.png',
    'quiz.png',
    'ads.png',
    'visit.png',
    'subscribe.png',
    'promo.png',
    'uc.png',
  ];

  List nameText = [
    'Spin & Win',
    'Scratch & Win',
    'Solve Quiz',
    'Watch & Win',
    'Visit to Earn',
    'Social Rewards',
    'Promo Code',
    'Redeem UC',
  ];

  List get cardSubtitles => [
        'Win up to 100 Coins',
        'Win up to 100 Coins',
        'Win up to 100 Coins',
        'Win up to ${_rewards.ads} Coins',
        'Win up to ${_rewards.link} Coins',
        'Win up to ${_rewards.social} Coins',
        'Win up to ${_rewards.promocode} Coins',
        'Redeem PUBG UC',
      ];

  List nameTap = [
    'TAP TO SPIN',
    'TAP TO SCRATCH',
    'TAP TO PLAY',
    'TAP TO WATCH',
    'TAP TO VISIT',
    'TAP TO SUBSCRIBE',
    'PROMO CODE',
    'REDEEM PUBG UC',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    adVM.loadInterAd();

    // Initialize ad animation
    _adAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _adScaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _adAnimationController, curve: Curves.easeInOut),
    );

    _initializeScreen();
    _startRealtimeInternetListener();
  }

  void _initializeScreen() async {
    bool hasInternet = await ConnectivityHelper.checkAndShowDialog(
      context,
      onRetry: _initializeScreen,
    );

    if (!hasInternet) return;

    _fetchUserProfile();
    _checkAdTimerStatus();
    _startAdApiCheckTimer();
    _fetchRewards();
  }

  Future<void> _fetchRewards() async {
    try {
      final rewards = await _rewardsService.fetchRewards();
      if (!mounted) return;
      setState(() => _rewards = rewards);
    } catch (e) {
      // Silently fail — defaults (0) will be used
      debugPrint('Failed to load rewards: $e');
    }
  }

  void _startRealtimeInternetListener() {
    _connectivitySubscription =
        ConnectivityHelper.connectivityStream.listen((results) {
      // Check if lost connection
      if (ConnectivityHelper.hasNoInternet(results)) {
        print("🔴 Internet connection lost");
        if (!_isDialogShowing && mounted) {
          _isDialogShowing = true;
          ConnectivityHelper.showNoInternetDialog(
            context,
            onRetry: () {
              _isDialogShowing = false;
              _initializeScreen();
            },
          ).then((_) {
            _isDialogShowing = false;
          });
        }
      } else {
        print("🟢 Internet connection restored");
        // Optionally refresh data when connection is restored
        if (mounted && !_isDialogShowing) {
          _fetchUserProfile();
          _checkAdTimerStatus();
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    _adCountdownTimer?.cancel();
    _adApiCheckTimer?.cancel();
    _adAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Update coins when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _fetchUserProfile();
      _checkAdTimerStatus();
    }
  }

  void _startAdApiCheckTimer() {
    _adApiCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkAdTimerStatus();
    });
  }

  Future<void> _checkAdTimerStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) return;

      final response = await http.get(
        Uri.parse("https://wc-admin.genwizz.com/api/timer/ad"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _canClaimAd = data['can_claim'] ?? false;
          _remainingAdSeconds = (data['remaining_seconds'] ?? 0).ceil();
        });

        if (_canClaimAd) {
          _startAdBlinkingAnimation();
          _adCountdownTimer?.cancel();
        } else {
          _adAnimationController.stop();
          _adAnimationController.reset();
          _startAdCountdown();
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

  void _startAdBlinkingAnimation() {
    _adAnimationController.repeat(reverse: true);
  }

  void _startAdCountdown() {
    _adCountdownTimer?.cancel();

    _adCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_remainingAdSeconds > 0) {
          _remainingAdSeconds--;
        } else {
          timer.cancel();
          _checkAdTimerStatus();
        }
      });
    });
  }

  // String _formatAdTime() {
  //   if (_canClaimAd) return "Ready!";

  //   int minutes = _remainingAdSeconds ~/ 60;
  //   int seconds = _remainingAdSeconds % 60;

  //   if (minutes > 0) {
  //     return "${minutes}m ${seconds}s";
  //   }
  //   return "${seconds}s";
  // }

  String _formatAdTime() {
    if (_canClaimAd) return "Ready!";

    int hours = _remainingAdSeconds ~/ 3600;
    int minutes = (_remainingAdSeconds % 3600) ~/ 60;
    int seconds = _remainingAdSeconds % 60;

    if (hours > 0) {
      return "$hours hr $minutes min $seconds sec";
    } else if (minutes > 0) {
      return "$minutes min $seconds sec";
    }
    return "$seconds seconds";
  }

  Future<void> _fetchUserProfile() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final user = await _userService.fetchProfile();

      if (!mounted) return;

      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = "No internet connection.";
        _isLoading = false;
      });

      showCustomSnackBar(
        "No internet connection. Please check your network and try again.",
        context,
        isError: true,
      );
    }
  }

  // Method to handle coin updates from child screens
  void _updateCoins() {
    if (mounted) {
      _fetchUserProfile();
    }
  }

  Future<void> _claimWatchReward() async {
    if (!mounted) return;

    // Add loading indicator to prevent user interaction during API call
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) {
        Navigator.of(context).pop(); // Close loading dialog
        if (!mounted) return;
        showCustomSnackBar("No API token found", context, isError: true);
        return;
      }

      final response = await http.post(
        Uri.parse("https://wc-admin.genwizz.com/api/ads"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "coins": "250",
          "type": "ad",
        }),
      );

      // Close loading dialog first
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Show success message
        if (data["message"] != null) {
          showCustomSnackBar(data["message"], context, isError: false);
        }

        // Show success dialog
        _showWatchRewardDialog("250", data);

        // Update coins only if widget is still mounted
        if (mounted) {
          _updateCoins();
          // Refresh ad timer after claiming
          _checkAdTimerStatus();
        }
      } else {
        if (data["message"] != null) {
          showCustomSnackBar(data["message"], context, isError: true);
        }
      }
    } catch (e) {
      // Close loading dialog in case of error
      if (mounted) {
        Navigator.of(context).pop();
      }
      if (!mounted) return;
      showCustomSnackBar("Error claiming watch reward: $e", context,
          isError: true);
    }
  }

  void _showConfirmationDialog() {
    if (!_canClaimAd) {
      showCustomSnackBar(
          "Please wait ${_formatAdTime()} before watching another ad", context,
          isError: true);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
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
                  Colors.blue.shade600,
                  Colors.blue.shade800,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.video_library,
                  color: Colors.white,
                  size: 60,
                ),
                const SizedBox(height: 16),
                const CustomText(
                  title: 'Watch Ad to Earn',
                  size: 24,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                const CustomText(
                  title: 'Watch a short video ad to earn coins!',
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.monetization_on,
                          color: Colors.amber, size: 20),
                      SizedBox(width: 8),
                      CustomText(
                        title: cardSubtitles[3],
                        size: 16,
                        color: Colors.amber,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showRewardedAd();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Watch Ad'),
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

  void _showRewardedAd() {
    if (!mounted) return;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );

      RewardedAdLoading.show(context, onComplete: () {
        print("✅ Ad completed successfully");
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            _claimWatchReward();
          }
        });
      }, onFailed: () {
        print("⚠️ Rewarded ad failed or skipped");
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop();

            // 🟠 Custom "Reward Expired" dialog with orange gradient
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
                          Colors.orange.shade600,
                          Colors.orange.shade800,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        const CustomText(
                          title: 'Reward Expired!',
                          size: 24,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        const CustomText(
                          title:
                              'The reward is expired or unavailable.\nPlease try again later.',
                          size: 16,
                          color: Colors.white,
                          alignment: TextAlign.center,
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
                              foregroundColor: Colors.orange.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('OK, Got it!'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        });
      });
    } catch (e) {
      print("Error showing rewarded ad: $e");
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      });
      if (mounted) {
        showCustomSnackBar("Unable to load ad at this time", context,
            isError: true);
      }
    }
  }

  void _showWatchRewardDialog(String coins, Map<String, dynamic> responseData) {
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
                  Colors.orange.shade600,
                  Colors.orange.shade800,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
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
                  title: 'You earned $coins coins!',
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
                      const CustomText(
                        title: 'Watch & Win Reward',
                        size: 14,
                        color: AppColors.white,
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        title: '$coins COINS',
                        size: 18,
                        color: AppColors.white,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (responseData['message'] != null)
                  CustomText(
                    title: responseData['message'],
                    size: 14,
                    color: AppColors.white,
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
                      foregroundColor: Colors.orange.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Great!'),
                  ),
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
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80.v),
        child: HomeAppBar(
          user: _user,
          isLoading: _isLoading,
          onRefresh: _fetchUserProfile,
        ),
      ),
      body: _isLoading
          ? Center(
              child: Lottie.asset('assets/images/loading.json', height: 500.v),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CustomText(
                        title: 'Error loading profile',
                        size: 16,
                        color: Colors.white,
                      ),
                      Gap.v(10),
                      CustomText(
                        title: _errorMessage,
                        size: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      Gap.v(20),
                      ElevatedButton(
                        onPressed: _fetchUserProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchUserProfile,
                  color: Colors.white,
                  backgroundColor: AppColors.primary,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 0.h),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          Gap.v(10),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 25.h),
                            child: CoinsEarnedSection(
                              coins: _user?.coins ?? 0,
                              value: 'Win up to ${_rewards.hourly} coins',
                              // ontap: _fetchUserProfile,
                              ontap: () async {
                                apads['int']
                                    ? InterstitialAdLoading.show(
                                        context,
                                        onComplete: _fetchUserProfile,
                                        onFailed: _fetchUserProfile,
                                      )
                                    : _fetchUserProfile();
                              },

                              // onCoinsUpdated: _updateCoins,
                            ),
                          ),
                          Gap.v(20),
                          Padding(
                              padding: EdgeInsets.symmetric(horizontal: 25.h),
                              child: BonusSection(
                                value: 'Win up to ${_rewards.daily} coins',
                              )),
                          Gap.v(10),
                          GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: 25.h),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 35.h,
                              mainAxisSpacing: 20.v,
                              childAspectRatio: .73,
                            ),
                            itemCount: 8,
                            scrollDirection: Axis.vertical,
                            shrinkWrap: true,
                            itemBuilder: (BuildContext context, int index) {
                              // Special handling for Watch & Win (index 3)
                              bool isWatchAd = index == 3;
                              bool canUseCard = isWatchAd ? _canClaimAd : true;

                              return Material(
                                elevation: 5,
                                borderRadius: BorderRadius.circular(17),
                                child: ScaleTransition(
                                  scale: (isWatchAd && _canClaimAd)
                                      ? _adScaleAnimation
                                      : AlwaysStoppedAnimation(1.0),
                                  child: Opacity(
                                    opacity: canUseCard ? 1.0 : 0.7,
                                    child: SizedBox(
                                      height: 300.v,
                                      width: double.infinity,
                                      child: Container(
                                        height: 241.v,
                                        width: 150.h,
                                        decoration: BoxDecoration(
                                          color: gradients[index],
                                          borderRadius:
                                              BorderRadius.circular(17),
                                          border: (isWatchAd && _canClaimAd)
                                              ? Border.all(
                                                  color: Colors.green
                                                      .withOpacity(0.5),
                                                  width: 2)
                                              : null,
                                        ),
                                        child: Column(
                                          children: [
                                            Gap.v(13),
                                            Image.asset(
                                              'assets/images/${img[index]}',
                                              scale: 5.2.v,
                                            ),
                                            Gap.v(10),
                                            CustomText(
                                              title: nameText[index],
                                              fontWeight: FontWeight.w600,
                                              size: 18,
                                            ),
                                            Gap.v(5),
                                            CustomText(
                                              // title: cardSubtitles[index],

                                              title: isWatchAd
                                                  ? (_canClaimAd
                                                      ? '${cardSubtitles[3]}\nReady'
                                                      : _formatAdTime())
                                                  : cardSubtitles[index],
                                              alignment: TextAlign.center,
                                              size: 12,
                                              fontWeight: FontWeight.w400,
                                              color: isWatchAd
                                                  ? (_canClaimAd
                                                      ? Colors.green
                                                      : Colors.orange)
                                                  : AppColors.fontColor
                                                      .withOpacity(.6),
                                            ),
                                            Gap.v(20),
                                            PrimaryBTN(
                                              width: 140,
                                              height: 40,
                                              fontSize: 14,
                                              btColor: AppColors.secondary,
                                              onCLick: () async {
                                                if (index == 0) {
                                                  final result =
                                                      await Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                    builder: (context) {
                                                      return const SpinAndWinView();
                                                    },
                                                  ));
                                                  if (result == true)
                                                    _updateCoins();
                                                } else if (index == 1) {
                                                  final result =
                                                      await Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                    builder: (context) {
                                                      return const ScratchCardView();
                                                    },
                                                  ));
                                                  if (result == true)
                                                    _updateCoins();
                                                } else if (index == 2) {
                                                  final result =
                                                      await Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                    builder: (context) {
                                                      return const QuizView();
                                                    },
                                                  ));
                                                  if (result == true)
                                                    _updateCoins();
                                                } else if (index == 3) {
                                                  // Watch & Win - Show confirmation dialog first

                                                  (isWatchAd && _canClaimAd)
                                                      ? _showConfirmationDialog()
                                                      : () {};
                                                } else if (index == 6) {
                                                  final result =
                                                      await Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                    builder: (context) {
                                                      return const EnterPromoCodeView();
                                                    },
                                                  ));
                                                  if (result == true)
                                                    _updateCoins();
                                                } else if (index == 7) {
                                                  final result =
                                                      await Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                    builder: (context) {
                                                      return const RedeemUCView();
                                                    },
                                                  ));
                                                  if (result == true)
                                                    _updateCoins();
                                                } else if (index == 4) {
                                                  final result =
                                                      await Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                    builder: (context) {
                                                      return const VisitToEarnView();
                                                    },
                                                  ));
                                                  if (result == true)
                                                    _updateCoins();
                                                } else if (index == 5) {
                                                  final result =
                                                      await Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                    builder: (context) {
                                                      return const SubscribeToEarnView();
                                                    },
                                                  ));
                                                  if (result == true)
                                                    _updateCoins();
                                                }
                                              },
                                              buttonTitle: nameTap[index],
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          Gap.v(20),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
