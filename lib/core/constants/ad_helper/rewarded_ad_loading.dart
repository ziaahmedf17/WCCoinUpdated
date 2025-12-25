import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';
import 'package:wc_coin_app/core/constants/ad_helper/ad_helper.dart';
import 'package:wc_coin_app/core/constants/colors.dart';
import 'package:wc_coin_app/core/constants/size_utils.dart';
import 'package:wc_coin_app/shared/text_view.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class RewardedAdLoading {
  static void show(
    BuildContext context, {
    required Function() onComplete,
    required Function() onFailed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _RewardedAdDialog(
          onComplete: () {
            Navigator.of(dialogContext).pop();
            onComplete();
          },
          onFailed: () {
            Navigator.of(dialogContext).pop();
            onFailed();
          },
        );
      },
    );
  }
}

class _RewardedAdDialog extends StatefulWidget {
  final Function() onComplete;
  final Function() onFailed;

  const _RewardedAdDialog({
    required this.onComplete,
    required this.onFailed,
  });

  @override
  State<_RewardedAdDialog> createState() => _RewardedAdDialogState();
}

class _RewardedAdDialogState extends State<_RewardedAdDialog> {
  bool _showWaitingMessage = false;
  int _retryAttempt = 0;
  static const int _maxRetryCount = 3;
  bool _rewardEarned = false;
  RewardedAd? _rewardedAd;
  bool _isAdReady = false;

  @override
  void initState() {
    super.initState();
    _loadRewardedAd();
  }

  void _loadRewardedAd() {
    if (AppAdIds.revAdId.isEmpty) {
      widget.onFailed();
      return;
    }

    RewardedAd.load(
      adUnitId: AppAdIds.revAdId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          print("✅ Rewarded ad loaded");
          _rewardedAd = ad;
          _isAdReady = true;
          _retryAttempt = 0;

          // Set up callbacks
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              print("📢 Rewarded ad displayed");
              setState(() => _showWaitingMessage = true);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print("❌ Rewarded ad failed to display: ${error.message}");
              ad.dispose();
              widget.onFailed();
            },
            onAdDismissedFullScreenContent: (ad) {
              print("🙌 Rewarded ad closed");
              ad.dispose();
              // Only call onFailed if reward was NOT earned
              if (!_rewardEarned) {
                widget.onFailed();
              }
            },
            onAdImpression: (ad) {
              print("👁️ Rewarded ad impression");
            },
          );

          // Try to show after short delay
          Future.delayed(const Duration(seconds: 1), _showRewardAd);
        },
        onAdFailedToLoad: (error) {
          print("❌ Rewarded ad failed to load: ${error.code} - ${error.message}");
          
          if (_retryAttempt < _maxRetryCount) {
            _retryAttempt++;
            Future.delayed(
              Duration(seconds: 2 * _retryAttempt),
              _loadRewardedAd,
            );
          } else {
            widget.onFailed();
          }
        },
      ),
    );
  }

  void _showRewardAd() {
    if (_isAdReady && _rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          print("🎉 User earned reward: ${reward.amount} ${reward.type}");
          _rewardEarned = true;
          widget.onComplete();
        },
      );
    } else {
      print("⚠️ Rewarded ad not ready");
      widget.onFailed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SpinKitDualRing(color: AppColors.white),
            Gap.v(25),
            CustomText(
              title: _showWaitingMessage
                  ? "Please Wait a While..."
                  : "Loading Rewarded Ad...",
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }
}