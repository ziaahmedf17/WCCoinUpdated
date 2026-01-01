import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';
import 'package:wc_coin_app/core/constants/ad_helper/ad_helper.dart';
import 'package:wc_coin_app/core/constants/colors.dart';
import 'package:wc_coin_app/core/constants/size_utils.dart';
import 'package:wc_coin_app/shared/text_view.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class InterstitialAdLoading {
  static void show(
    BuildContext context, {
    required Function() onComplete,
    required Function() onFailed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _InterstitialAdDialog(
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

class _InterstitialAdDialog extends StatefulWidget {
  final Function() onComplete;
  final Function() onFailed;

  const _InterstitialAdDialog({
    required this.onComplete,
    required this.onFailed,
  });

  @override
  State<_InterstitialAdDialog> createState() => _InterstitialAdDialogState();
}

class _InterstitialAdDialogState extends State<_InterstitialAdDialog> {
  bool _showWaitingMessage = false;
  int _retryAttempt = 0;
  static const int _maxRetryCount = 3;
  InterstitialAd? _interstitialAd;
  bool _isAdReady = false;

  @override
  void initState() {
    super.initState();
    _loadInterstitialAd();
  }

  void _loadInterstitialAd() {
    if (AppAdIds.interAdId.isEmpty) {
      widget.onFailed();
      return;
    }

    InterstitialAd.load(
      adUnitId: AppAdIds.interAdId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          print("✅ Interstitial loaded");
          _interstitialAd = ad;
          _isAdReady = true;
          _retryAttempt = 0;

          // Set up callbacks
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              print("📢 Interstitial displayed");
              setState(() => _showWaitingMessage = true);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print("❌ Failed to display: ${error.message}");
              ad.dispose();
              widget.onFailed();
            },
            onAdDismissedFullScreenContent: (ad) {
              print("🙌 Interstitial closed");
              ad.dispose();
              Future.delayed(
                  const Duration(milliseconds: 500), widget.onComplete);
            },
            onAdImpression: (ad) {
              print("👁️ Interstitial impression");
            },
          );

          // Try to show after short delay
          Future.delayed(const Duration(seconds: 1), _showInterAd);
        },
        onAdFailedToLoad: (error) {
          print("❌ Failed to load: ${error.code} - ${error.message}");

          if (_retryAttempt < _maxRetryCount) {
            _retryAttempt++;
            Future.delayed(
              Duration(seconds: 2 * _retryAttempt),
              _loadInterstitialAd,
            );
          } else {
            widget.onFailed();
          }
        },
      ),
    );
  }

  void _showInterAd() {
    if (_isAdReady && _interstitialAd != null) {
      _interstitialAd!.show();
    } else {
      print("⚠️ Interstitial not ready");
      widget.onFailed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.primary,
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
                  : "Loading Advertisement...",
              color: AppColors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }
}
