import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wc_coin_app/core/constants/ad_helper/ad_helper.dart';
import 'package:wc_coin_app/core/constants/ad_helper/app_open_ad_helper.dart';
import 'package:wc_coin_app/core/constants/colors.dart';
import 'package:wc_coin_app/core/constants/size_utils.dart';
import 'package:wc_coin_app/main.dart';
import 'package:wc_coin_app/shared/custom_appbar.dart';
import 'package:wc_coin_app/shared/snackbar.dart';
import 'package:wc_coin_app/shared/text_view.dart';

class InviteFriendsView extends StatefulWidget {
  const InviteFriendsView({super.key});

  @override
  State<InviteFriendsView> createState() => _InviteFriendsViewState();
}

class _InviteFriendsViewState extends State<InviteFriendsView> {
  final TextEditingController _referralController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingReferralInfo = true;
  GoogleAdmobProvider adVM = GoogleAdmobProvider();

  String _myReferralCode = "";
  int _selfBonus = 0;
  int _referrerBonus = 0;

  @override
  void initState() {
    super.initState();
    adVM.loadInterAd();
    _fetchReferralInfo();
  }

  Future<void> _fetchReferralInfo() async {
    setState(() {
      _isLoadingReferralInfo = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) {
        if (!mounted) return;
        showCustomSnackBar("No API token found", context, isError: true);
        setState(() => _isLoadingReferralInfo = false);
        return;
      }

      final url = Uri.parse("https://wc-admin.genwizz.com/api/referral");

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _myReferralCode = data["referral_code"] ?? "";
            _selfBonus = data["self_bonus"] ?? 0;
            _referrerBonus = data["referrer_bonus"] ?? 0;
            _isLoadingReferralInfo = false;
          });
        }
      } else {
        if (!mounted) return;
        showCustomSnackBar(
            "Failed to load referral info: ${response.statusCode}", context,
            isError: true);
        setState(() => _isLoadingReferralInfo = false);
      }
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar("Error loading referral info: $e", context,
          isError: true);
      setState(() => _isLoadingReferralInfo = false);
    }
  }

  void _showWinningDialog(int coinsWon) {
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
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xff6D1AE7),
                  Color(0xff4400CE),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Trophy Icon (New style)
                const Icon(
                  Icons.emoji_events,
                  color: Colors.amber,
                  size: 60,
                ),
                const SizedBox(height: 16),

                // Main Title
                const Text(
                  "Congratulations!",
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Boogaloo',
                  ),
                ),
                const SizedBox(height: 10),

                // Subheading "You Won"
                const Text(
                  "You Won",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                    fontFamily: 'Boogaloo',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Coins Box (modernized same as new dialog)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        color: Color(0xffFFD700),
                        size: 40,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "$coinsWon",
                        style: const TextStyle(
                          fontSize: 28,
                          color: Color(0xff6D1AE7),
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Boogaloo',
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        "Coins",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff6D1AE7),
                          fontFamily: 'Boogaloo',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Success Message
                const Text(
                  "Referral code applied successfully!\nCoins added to your wallet.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontFamily: 'Boogaloo',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Continue Button (Same UI as new dialog)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xff4400CE),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Continue",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Boogaloo',
                        color: Color(0xff6D1AE7),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _redeemReferral() async {
    if (_referralController.text.trim().isEmpty) {
      showCustomSnackBar("Please enter a referral code", context,
          isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) {
        if (!mounted) return;
        showCustomSnackBar("No API token found", context, isError: true);
        setState(() => _isLoading = false);
        return;
      }

      final url = Uri.parse("https://wc-admin.genwizz.com/api/referral/redeem");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
        body: jsonEncode({"referral_code": _referralController.text.trim()}),
      );

      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (!mounted) return;

        // Extract coins won from the "awarded" field in user object
        int coinsWon = _referrerBonus; // Default fallback

        if (data.containsKey("user") && data["user"] != null) {
          if (data["user"].containsKey("awarded")) {
            coinsWon = data["user"]["awarded"] ?? _referrerBonus;
          }
        }

        _referralController.clear();
        _showWinningDialog(coinsWon);
      } else if (response.statusCode == 409) {
        if (!mounted) return;
        final data = jsonDecode(response.body);
        showCustomSnackBar(
            data["message"] ?? "This referral code has already been used",
            context,
            isError: true);
      } else {
        if (!mounted) return;
        try {
          final data = jsonDecode(response.body);
          showCustomSnackBar(
              data["message"] ?? "Failed: ${response.statusCode}", context,
              isError: true);
        } catch (e) {
          showCustomSnackBar(
              "Failed: ${response.statusCode} ${response.reasonPhrase}",
              context,
              isError: true);
        }
      }
    } catch (e) {
      if (!mounted) return;
      print("Error: $e");
      showCustomSnackBar("Error: $e", context, isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // void _copyReferralCode() {
  //   if (_myReferralCode.isNotEmpty) {
  //     Clipboard.setData(ClipboardData(text: _myReferralCode));
  //     showCustomSnackBar("Referral code copied to clipboard!", context,
  //         isError: false);
  //   }
  // }

  // 👉 Replace your old _copyReferralCode() function with this
  void _copyReferralCode() {
    if (_myReferralCode.isEmpty) {
      showCustomSnackBar("Referral code not available", context, isError: true);
      return;
    }

    // ⭐ This is the full message (same as shareText)
    final fullMessage = '''
🎁 Join me here and win free UCrewards! 🎁

App Name: Win UC Get UC
App Link: https://play.google.com/store/apps/details?id=com.get_unlimited_uc.earnuc_winuc_getuc

📝 Steps to claim your $_referrerBonus coins:
1️⃣ Sign up first
2️⃣ Open Invite Friends Section
3️⃣ Use the code below to claim upto $_referrerBonus coins in app

🎟️ Referral Code: $_myReferralCode

Download now and start earning! 💰
''';

    // ⭐ Copy full message instead of only the code
    Clipboard.setData(ClipboardData(text: fullMessage));

    showCustomSnackBar("Message copied successfully!", context, isError: false);
  }

  void _shareReferralCode() {
    if (_myReferralCode.isEmpty) {
      showCustomSnackBar("Referral code not available", context, isError: true);
      return;
    }
// complete message
    final shareText = '''
🎁 Join me here and win free UCrewards! 🎁

App Name: Win UC Get UC
App Link: https://play.google.com/store/apps/details?id=com.get_unlimited_uc.earnuc_winuc_getuc

📝 Steps to claim your $_referrerBonus coins:
1️⃣ Sign up first
2️⃣ Open Invite Friends Section
3️⃣ Use the code below to claim upto $_referrerBonus coins in app

🎟️ Referral Code: $_myReferralCode

Download now and start earning! 💰
''';

    Share.share(shareText);
  }

  @override
  void dispose() {
    _referralController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: CustomAppBar(
        title: 'Invite Friends',
        hasLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Gap.v(20),

            // Section 1: My Referral Code
            Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 20.h),
              child: Material(
                borderRadius: BorderRadius.circular(10),
                elevation: 5,
                child: Container(
                  // margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Center(
                        child: Image.asset(
                          "assets/images/invite_image.png",
                          scale: 4.v,
                        ),
                      ),
                      Gap.v(20),
                      CustomText(
                        size: 26.fSize,
                        title: "Invite friends and get bonus coins!",
                        color: AppColors.fontColor,
                        fontWeight: FontWeight.bold,
                        alignment: TextAlign.center,
                      ),
                      Gap.v(15),
                      CustomText(
                        size: 17,
                        title: "Earn rewards for every new member you refer",
                        color: AppColors.fontColor.withOpacity(.7),
                        fontWeight: FontWeight.w300,
                        alignment: TextAlign.center,
                      ),
                      Gap.v(15),
                      _isLoadingReferralInfo
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: CircularProgressIndicator(
                                    color: AppColors.primary),
                              ),
                            )
                          : Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(15),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withOpacity(.03),
                                          border: Border.all(
                                              color: AppColors.primary
                                                  .withOpacity(.3),
                                              width: 2),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: CustomText(
                                          size: 22.fSize,
                                          title: _myReferralCode,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Gap.h(10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        GestureDetector(
                                          onTap: _copyReferralCode,
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                color: AppColors.primary),
                                            child: const Center(
                                              child: Icon(Icons.copy,
                                                  color: AppColors.white),
                                            ),
                                          ),
                                        ),
                                        Gap.h(10),

                                        GestureDetector(
                                          onTap: _shareReferralCode,
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                color: AppColors.primary),
                                            child: const Center(
                                              child: Icon(Icons.share,
                                                  color: AppColors.white),
                                            ),
                                          ),
                                        ),
                                        // IconButton(
                                        //   onPressed: _shareReferralCode,
                                        //   icon: const Icon(Icons.share,
                                        //       color: Color(0xff6D1AE7)),
                                        //   tooltip: "Share",
                                        // ),
                                      ],
                                    ),
                                  ],
                                ),
                                Gap.v(15),
                                // CustomText(
                                //   alignment: TextAlign.center,
                                //   size: 18.fSize,
                                //   title:
                                //       "Share this code with friends and earn $_selfBonus coins for each referral!",
                                //   color: const Color(0xff27AE60),
                                // ),
                              ],
                            ),
                    ],
                  ),
                ),
              ),
            ),

            Gap.v(20),

            // Section 2: Redeem Referral Code
            Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 20.h),
              child: Material(
                borderRadius: BorderRadius.circular(10),
                elevation: 5,
                child: Container(
                  // margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        size: 26.fSize,
                        title: "Have a Referral Code?",
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      Gap.v(10),
                      CustomText(
                        alignment: TextAlign.left,
                        size: 18.fSize,
                        title: "Enter a referral code to get bonus coins!",
                        color: const Color(0xff27AE60),
                      ),
                      Gap.v(20),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 56.v,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                border: Border.all(
                                  color: AppColors.primary,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: TextField(
                                controller: _referralController,
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 20.fSize,
                                  fontFamily: 'Boogaloo',
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Enter Referral Code",
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 17.h, vertical: 0),
                                  hintStyle: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ),
                          Gap.h(10),
                          GestureDetector(
                            onTap: () async {
                              if (_isLoading) return;

                              apads['int']
                                  ? InterstitialAdLoading.show(
                                      context,
                                      onComplete: _redeemReferral,
                                      onFailed: _redeemReferral,
                                    )
                                  : _redeemReferral();
                            },
                            child: Container(
                              height: 56.v,
                              // width: 80.h,
                              padding: EdgeInsets.symmetric(horizontal: 14.h),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                border:
                                    Border.all(color: const Color(0xff6D1AE7)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.white),
                                    )
                                  : const Icon(Icons.check,
                                      color: AppColors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Gap.v(30),
          ],
        ),
      ),
    );
  }
}
