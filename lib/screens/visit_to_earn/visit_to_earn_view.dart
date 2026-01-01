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
import 'package:wc_coin_app/models/visit_link_model.dart';
import 'package:wc_coin_app/services/visit_link_service.dart';
import 'package:wc_coin_app/shared/custom_appbar.dart';
import 'package:wc_coin_app/shared/snackbar.dart';
import 'package:wc_coin_app/shared/text_view.dart';

class VisitToEarnView extends StatefulWidget {
  const VisitToEarnView({super.key});

  @override
  State<VisitToEarnView> createState() => _VisitToEarnViewState();
}

class _VisitToEarnViewState extends State<VisitToEarnView>
    with SingleTickerProviderStateMixin {
  late Future<List<VisitLink>> linksFuture;
  final LinkService _linkService = LinkService();

  bool _canClaim = false;
  int _remainingSeconds = 0;
  Timer? _countdownTimer;
  Timer? _apiCheckTimer;

  // Track which links have been visited
  final Set<int> _visitedLinks = {};
  final Map<int, Timer> _verificationTimers = {};

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  GoogleAdmobProvider adVM = GoogleAdmobProvider();

  @override
  void initState() {
    super.initState();
    linksFuture = _linkService.fetchVisitLinks();
    adVM.loadInterAd();

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
        Uri.parse("https://wc-admin.genwizz.com/api/timer/link_visit"),
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

  Future<void> _openVisitLink(VisitLink link) async {
    if (!_canClaim) {
      showCustomSnackBar("Please wait for the timer to finish", context,
          isError: true);
      return;
    }

    try {
      final Uri uri = Uri.parse(link.linkUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        // Mark as visited
        setState(() {
          _visitedLinks.add(link.id);
        });

        // Show instruction
        showCustomSnackBar(
          "Please visit the link and come back to claim your reward!",
          context,
          isError: false,
        );

        // Start verification timer (15 seconds)
        _startVerificationTimer(link.id);
      } else {
        showCustomSnackBar("Could not open the link", context, isError: true);
      }
    } catch (e) {
      showCustomSnackBar("Error opening link: $e", context, isError: true);
    }
  }

  void _startVerificationTimer(int linkId) {
    // Cancel existing timer if any
    _verificationTimers[linkId]?.cancel();

    // Start new timer - user has 15 seconds to return and claim
    _verificationTimers[linkId] = Timer(const Duration(seconds: 15), () {
      if (mounted) {
        setState(() {
          // Timer expired, user can now claim
        });
      }
    });
  }

  Future<void> _claimReward(VisitLink link) async {
    if (!_canClaim) {
      showCustomSnackBar("Please wait for the timer to finish", context,
          isError: true);
      return;
    }

    if (!_visitedLinks.contains(link.id)) {
      showCustomSnackBar("Please visit the link first!", context,
          isError: true);
      return;
    }

    try {
      final msg = await _linkService.claimLinkReward(link.id);
      if (mounted) {
        showCustomSnackBar(msg, context, isError: false);

        // Remove from visited set
        setState(() {
          _visitedLinks.remove(link.id);
        });

        // Refresh timer status after claiming
        await _checkTimerStatus();
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar("Error: $e", context, isError: true);
      }
    }
  }

  String _getButtonText(VisitLink link) {
    if (!_canClaim) {
      return 'Wait';
    }

    if (_visitedLinks.contains(link.id)) {
      return 'Claim';
    }

    return 'Visit';
  }

  Color _getButtonColor(VisitLink link) {
    if (!_canClaim) {
      return Colors.deepOrange.withOpacity(0.5);
    }

    if (_visitedLinks.contains(link.id)) {
      return Colors.green;
    }

    return Colors.deepOrange;
  }

  void _handleButtonTap(VisitLink link) {
    if (!_canClaim) {
      showCustomSnackBar("Please wait for the timer to finish", context,
          isError: true);
      return;
    }

    if (_visitedLinks.contains(link.id)) {
      // User has visited, now claim
      apads['int']
          ? InterstitialAdLoading.show(context, onComplete: () {
              _claimReward(link);
            }, onFailed: () {
              _claimReward(link);
            })
          : _claimReward(link);
    } else {
      // Open the visit link
      _openVisitLink(link);
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.leaderboard,
            size: 64,
            color: AppColors.white,
          ),
          SizedBox(height: 20),
          CustomText(
            title: 'No Link Available',
            size: 18,
            color: AppColors.white,
          ),
          SizedBox(height: 10),
          CustomText(
            title: 'All the Links will be displayed here.',
            size: 14,
            color: AppColors.white,
            alignment: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Visit to Earn"),
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

          // Links List
          Expanded(
            child: FutureBuilder<List<VisitLink>>(
              future: linksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingWidget();
                } else if (snapshot.hasError) {
                  return Center(
                    child: CustomText(
                      title: "Error: ${snapshot.error}",
                      size: 16,
                      color: Colors.red,
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final links = snapshot.data!;

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: links.length,
                  itemBuilder: (context, index) {
                    final link = links[index];
                    final formattedDate = DateFormat("dd MMM yyyy, hh:mm a")
                        .format(link.createdAt);
                    final isVisited = _visitedLinks.contains(link.id);

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
                            color: AppColors.white.withOpacity(0.1),
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
                              title: "Earn ${link.coins} Coins",
                              size: 18,
                              color: AppColors.fontColor,
                              fontWeight: FontWeight.w600,
                            ),
                            subtitle: CustomText(
                              title:
                                  "Status: ${link.status}\nAdded: $formattedDate",
                              size: 14,
                              color: AppColors.fontColor,
                            ),
                            trailing: GestureDetector(
                              onTap: () => _handleButtonTap(link),
                              child: Container(
                                height: 30,
                                width: 70,
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      spreadRadius: 2,
                                      blurRadius: 10,
                                      color:
                                          _getButtonColor(link).withOpacity(.4),
                                    )
                                  ],
                                  color: _getButtonColor(link),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Center(
                                  child: CustomText(
                                    title: _getButtonText(link),
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
