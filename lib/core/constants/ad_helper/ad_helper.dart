import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wc_coin_app/core/constants/ad_helper/ad_actions.dart';

/// ======================================================
/// 🔹 Global Singleton for Ad IDs
/// ======================================================
class AppAdIds {
  static String bannerAdId = "";
  static String interAdId = "";
  static String nativeAdId = "";
  static String nativeMrecAdId = "";
  static String revAdId = "";
  static bool isLoaded = false;

  static void setAdIds(Map<String, dynamic> data) {
    bannerAdId = data["bannerAdId"] ?? "";
    interAdId = data["interAdId"] ?? "";
    nativeAdId = data["nativeAdId"] ?? "";
    nativeMrecAdId = data["nativeMrecAdId"] ?? "";
    revAdId = data["revAdId"] ?? "";
    isLoaded = true;
  }
}

/// ======================================================
/// 🔹 Provider: Handles Ad Loading and Display
/// ======================================================
class GoogleAdmobProvider extends ChangeNotifier {
  final int _maxExponentialRetryCount = 6;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isInterstitialAdReady = false;
  bool _isRewardedAdReady = false;
  int _interstitialRetryAttempt = 0;
  int adCount = 0;
  int adLimit = 3;

  /// ------------------------------------------------------
  /// 🧩 Initialize Ads (Fetch IDs from Firebase + Init SDK)
  /// ------------------------------------------------------
  Future<void> initializeAds() async {
    try {
      // Initialize Mobile Ads SDK
      await MobileAds.instance.initialize();

      final ref = FirebaseDatabase.instance.ref("WcAdsIds");
      final snapshot = await ref.get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        AppAdIds.setAdIds(data);

        print("✅ Ad IDs loaded globally from Firebase:");
        print("Banner: ${AppAdIds.bannerAdId}");
        print("Interstitial: ${AppAdIds.interAdId}");
        print("Native: ${AppAdIds.nativeAdId}");
        print("Rewarded: ${AppAdIds.revAdId}");

        loadInterAd();
        loadRewardedAd();
      } else {
        print("⚠️ No Ad data found in Firebase!");
      }
    } catch (e) {
      print("❌ Failed to fetch ad IDs: $e");
    }
  }

  /// ------------------------------------------------------
  /// 🎁 Rewarded Ads
  /// ------------------------------------------------------
  void loadRewardedAd() {
    if (AppAdIds.revAdId.isEmpty) return;

    RewardedAd.load(
      adUnitId: AppAdIds.revAdId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          print('✅ Rewarded ad loaded');

          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              print('Rewarded ad displayed');
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('⚠️ Rewarded failed to display: ${error.message}');
              ad.dispose();
              _isRewardedAdReady = false;
              loadRewardedAd();
            },
            onAdDismissedFullScreenContent: (ad) {
              print('ℹ️ Rewarded ad closed and reloaded');
              ad.dispose();
              _isRewardedAdReady = false;
              loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('❌ Rewarded failed to load: ${error.message}');
          _isRewardedAdReady = false;
        },
      ),
    );
  }

  void showRewardedAd(
      {Function(AdWithoutView, RewardItem)? onUserEarnedReward}) {
    if (_isRewardedAdReady && _rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: onUserEarnedReward ??
            (ad, reward) {
              print('💰 User earned reward: ${reward.amount} ${reward.type}');
            },
      );
    } else {
      print('⚠️ Rewarded not ready, loading...');
      loadRewardedAd();
    }
  }

  /// ------------------------------------------------------
  /// 🧱 Interstitial Ads
  /// ------------------------------------------------------
  void loadInterAd() async {
    if (AppAdIds.interAdId.isEmpty) return;

    print("Loading interstitial ad...");

    InterstitialAd.load(
      adUnitId: AppAdIds.interAdId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          _interstitialRetryAttempt = 0;
          print('✅ Interstitial ad loaded');

          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              print('Interstitial ad displayed');
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('⚠️ Interstitial failed to display: ${error.message}');
              ad.dispose();
              _isInterstitialAdReady = false;
              loadAd();
            },
            onAdDismissedFullScreenContent: (ad) {
              print('ℹ️ Interstitial ad closed and reloaded');
              ad.dispose();
              _isInterstitialAdReady = false;
              AdActions.OpenScreen();
              loadAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialAdReady = false;
          _interstitialRetryAttempt++;

          if (_interstitialRetryAttempt > _maxExponentialRetryCount) return;

          int retryDelay =
              pow(2, min(_maxExponentialRetryCount, _interstitialRetryAttempt))
                  .toInt();
          print(
              '❌ Interstitial failed (${error.code}) - retrying in ${retryDelay}s');

          Future.delayed(Duration(seconds: retryDelay), loadAd);
        },
      ),
    );
  }

  void showInterAd() {
    if (_isInterstitialAdReady && _interstitialAd != null) {
      _interstitialAd!.show();
    } else {
      print('⚠️ Interstitial not ready, reloading...');
      loadAd();
    }
  }

  void showInterAdForCat() {
    if (_isInterstitialAdReady && _interstitialAd != null) {
      if (adCount % adLimit == 0) {
        adCount++;
        _interstitialAd!.show();
      } else {
        adCount++;
      }
    } else {
      loadAd();
    }
  }

  void loadAd() {
    if (AppAdIds.interAdId.isNotEmpty) {
      loadInterAd();
    }
  }

  bool get isInterstitialReady => _isInterstitialAdReady;
  bool get isRewardedReady => _isRewardedAdReady;

  /// ------------------------------------------------------
  /// 🌐 URL Launcher Helper
  /// ------------------------------------------------------
  void urlLaunch({required String link}) async {
    if (link.isNotEmpty && !await launchUrl(Uri.parse(link))) {
      throw Exception('Could not launch $link');
    }
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }
}

/// ======================================================
/// 🔹 Widgets for Different Ad Types
/// ======================================================

/// 🟩 MREC (Medium Rectangle Ad) - 300x250
class MrecAD extends StatefulWidget {
  const MrecAD({super.key});

  @override
  State<MrecAD> createState() => _MrecADState();
}

class _MrecADState extends State<MrecAD> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: AppAdIds.nativeMrecAdId,
      size: AdSize.mediumRectangle, // 300x250
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isLoaded = true;
          });
          print('MREC Ad Loaded');
        },
        onAdFailedToLoad: (ad, error) {
          print('MREC Ad failed: ${error.message}');
          ad.dispose();
        },
      ),
    );
    _bannerAd!.load();
  }

  @override
  Widget build(BuildContext context) {
    if (_bannerAd != null && _isLoaded) {
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
}

/// 🟨 Banner Ad
class BannerAD extends StatefulWidget {
  const BannerAD({super.key});

  @override
  State<BannerAD> createState() => _BannerADState();
}

class _BannerADState extends State<BannerAD> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: AppAdIds.bannerAdId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isLoaded = true;
          });
          print('Banner Ad Loaded');
        },
        onAdFailedToLoad: (ad, error) {
          print('Banner Ad failed: ${error.message}');
          ad.dispose();
        },
      ),
    );
    _bannerAd!.load();
  }

  @override
  Widget build(BuildContext context) {
    if (_bannerAd != null && _isLoaded) {
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
}

/// 🟦 Native Ad
class NativeADView extends StatefulWidget {
  const NativeADView({super.key});

  @override
  State<NativeADView> createState() => _NativeADViewState();
}

class _NativeADViewState extends State<NativeADView> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _adFailedToLoad = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _nativeAd = NativeAd(
      adUnitId: AppAdIds.nativeAdId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isLoaded = true;
          });
          print('Native Ad Loaded');
        },
        onAdFailedToLoad: (ad, error) {
          print('Native Ad failed: ${error.message}');
          setState(() {
            _adFailedToLoad = true;
          });
          ad.dispose();
        },
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: Colors.white,
        cornerRadius: 10.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: Colors.green,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black,
          backgroundColor: Colors.white,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.grey,
          backgroundColor: Colors.white,
          style: NativeTemplateFontStyle.normal,
          size: 14.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.grey,
          backgroundColor: Colors.white,
          style: NativeTemplateFontStyle.normal,
          size: 12.0,
        ),
      ),
    );
    _nativeAd!.load();
  }

  @override
  Widget build(BuildContext context) {
    if (_adFailedToLoad) {
      return const MrecAD();
    }

    if (_nativeAd != null && _isLoaded) {
      return Container(
        margin: const EdgeInsets.all(8.0),
        height: 320,
        child: AdWidget(ad: _nativeAd!),
      );
    }

    return Container(
      margin: const EdgeInsets.all(8.0),
      height: 1,
      color: Colors.white,
    );
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }
}
