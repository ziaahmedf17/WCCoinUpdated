import 'package:flutter/material.dart';
import 'package:wc_coin_app/core/constants/ad_helper/ad_helper.dart';
import 'package:wc_coin_app/core/constants/ad_helper/app_open_ad_helper.dart';
import 'package:wc_coin_app/core/constants/colors.dart';
import 'package:wc_coin_app/core/constants/size_utils.dart';
import 'package:wc_coin_app/main.dart';
import 'package:wc_coin_app/models/redeem_uc_pckg_model.dart';
import 'package:wc_coin_app/services/redeem_uc_service.dart';
import 'package:wc_coin_app/shared/custom_appbar.dart';
import 'package:wc_coin_app/shared/primary_btn.dart';
import 'package:wc_coin_app/shared/text_view.dart';

class RedeemUCView extends StatefulWidget {
  const RedeemUCView({super.key});

  @override
  State<RedeemUCView> createState() => _RedeemUCViewState();
}

class _RedeemUCViewState extends State<RedeemUCView> {
  List<Package> packages = [];
  bool isLoading = true;
  String? errorMessage;
  Set<int> redeemingPackages = {};
  GoogleAdmobProvider adVM = GoogleAdmobProvider();

  @override
  void initState() {
    super.initState();
    adVM.loadInterAd();

    _loadPackages();
  }

  Future<void> _loadPackages() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final fetchedPackages = await ApiService.getPackages();

      setState(() {
        packages = fetchedPackages;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Future<void> _redeemPackage(Package package) async {
    // Show dialog to get player details
    final Map<String, String>? playerDetails =
        await _showPlayerDetailsDialog(package);
    if (playerDetails == null) return;

    setState(() {
      redeemingPackages.add(package.id);
    });

    try {
      final result = await ApiService.redeemPackage(
        package.id,
        playerDetails['playerId']!,
        playerDetails['playerEmail']!,
      );

      setState(() {
        redeemingPackages.remove(package.id);
      });

      if (result['success']) {
        _showRedeemSuccessDialog();
        // Optionally reload packages to update coin balance or package availability
        _loadPackages();
      } else {
        _showErrorSnackBar(result['message']);
      }
    } catch (e) {
      setState(() {
        redeemingPackages.remove(package.id);
      });
      _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showRedeemSuccessDialog() {
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
                // Success Icon
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xff44FF00),
                    size: 60,
                  ),
                ),
                const SizedBox(height: 20),

                // Main Title
                const Text(
                  "Redeemed Successfully!",
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Boogaloo',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),

                // Success Message
                const Text(
                  "You will receive UC in your account in a few hours.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontFamily: 'Boogaloo',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                // Info Message
                const Text(
                  "Go to Withdrawal History in the Profile section to check redeem history.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontFamily: 'Boogaloo',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xff4400CE),
                      padding: const EdgeInsets.symmetric(vertical: 12),
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

  Future<Map<String, String>?> _showPlayerDetailsDialog(Package package) {
    final TextEditingController playerIdController = TextEditingController();
    final TextEditingController playerEmailController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            side: const BorderSide(color: AppColors.white),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Gap.v(5),
                const CustomText(
                  title: 'Enter Player ID',
                  size: 27,
                  color: AppColors.fontColor,
                  fontWeight: FontWeight.w600,
                ),
                Gap.v(25),
                TextFormField(
                  controller: playerIdController,
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontFamily: 'Boogaloo',
                      fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.primary.withOpacity(.2),
                    hintText: 'Player ID',
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 5.v, horizontal: 20.h),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    errorBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    focusedErrorBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Player ID is required';
                    }
                    return null;
                  },
                ),
                Gap.v(25),
                const CustomText(
                  title: 'Enter Email Address',
                  size: 27,
                  color: AppColors.fontColor,
                  fontWeight: FontWeight.w600,
                ),
                Gap.v(25),
                TextFormField(
                  controller: playerEmailController,
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontFamily: 'Boogaloo',
                      fontWeight: FontWeight.w700),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.primary.withOpacity(.2),
                    hintText: 'Player Email',
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 5.v, horizontal: 20.h),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    errorBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    focusedErrorBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Player email is required';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                Gap.v(40),
                PrimaryBTN(
                  onCLick: () {
                    if (formKey.currentState!.validate()) {
                      // Navigator.of(context).pop({
                      //   'playerId': playerIdController.text.trim(),
                      //   'playerEmail': playerEmailController.text.trim(),
                      // });

                      apads['int']
                          ? InterstitialAdLoading.show(
                              context,
                              onComplete: () {
                                Navigator.of(context).pop({
                                  'playerId': playerIdController.text.trim(),
                                  'playerEmail':
                                      playerEmailController.text.trim(),
                                });
                              },
                              onFailed: () {
                                Navigator.of(context).pop({
                                  'playerId': playerIdController.text.trim(),
                                  'playerEmail':
                                      playerEmailController.text.trim(),
                                });
                              },
                            )
                          : () {
                              Navigator.of(context).pop({
                                'playerId': playerIdController.text.trim(),
                                'playerEmail':
                                    playerEmailController.text.trim(),
                              });
                            };
                    }
                  },
                  buttonTitle: 'Continue',
                  btColor: AppColors.secondary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            Gap.h(10),
            Expanded(
              child: CustomText(
                title: message,
                size: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.all(15.h),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            Gap.h(10),
            Expanded(
              child: CustomText(
                title: message,
                size: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.all(15.h),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.v,
              color: AppColors.white.withOpacity(0.7),
            ),
            Gap.v(20),
            const CustomText(
              title: 'Oops! Something went wrong',
              size: 18,
              color: AppColors.white,
            ),
            Gap.v(10),
            CustomText(
              title: errorMessage ?? 'Unknown error occurred',
              size: 14,
              color: AppColors.white.withOpacity(0.8),
              alignment: TextAlign.center,
            ),
            Gap.v(30),
            ElevatedButton(
              onPressed: _loadPackages,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(horizontal: 30.h, vertical: 12.v),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const CustomText(
                title: 'Try Again',
                size: 16,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          Gap.v(20),
          const CustomText(
            title: 'Loading packages...',
            size: 16,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildPackageItem(Package package, int index) {
    final bool isRedeeming = redeemingPackages.contains(package.id);

    return GestureDetector(
      onTap: isRedeeming ? null : () => _redeemPackage(package),
      child: Material(
        elevation: 5,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(isRedeeming ? 0.05 : 1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isRedeeming
                    ? AppColors.white.withOpacity(0.5)
                    : AppColors.white),
          ),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Gap.v(15),
                  Container(
                    height: 100.v,
                    width: 100.h,
                    decoration: BoxDecoration(
                        color: Color(0xffFF6900),
                        border: Border.all(color: Color(0xffFF8904), width: 5),
                        borderRadius: BorderRadius.circular(10)),
                    child: Opacity(
                      opacity: isRedeeming ? 0.5 : 1.0,
                      child: Image.asset(
                        'assets/icons/WCC.png',
                        scale: 5.v,
                      ),
                    ),
                  ),
                  Gap.v(15),
                  CustomText(
                    title: '${package.ucValue} UC',
                    size: 24,
                    color: isRedeeming
                        ? AppColors.fontColor.withOpacity(0.5)
                        : AppColors.fontColor,
                    fontWeight: FontWeight.bold,
                  ),
                  Gap.v(10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Opacity(
                        opacity: isRedeeming ? 0.5 : 1.0,
                        child: Image.asset(
                          'assets/icons/coin.png',
                          scale: 6.v,
                        ),
                      ),
                      Gap.h(5),
                      CustomText(
                        title: '${package.coins}',
                        size: 18,
                        height: 0,
                        fontWeight: FontWeight.bold,
                        color: isRedeeming
                            ? const Color(0xffEF1A1A).withOpacity(0.5)
                            : const Color(0xffEF1A1A),
                      ),
                    ],
                  ),
                  // Gap.v(15),
                  Gap.v(10),

                  PrimaryBTN(
                    width: 150,
                    height: 40,
                    buttonTitle: 'Redeem',
                    onCLick: isRedeeming ? null : () => _redeemPackage(package),
                  )
                ],
              ),
              if (isRedeeming)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.white),
                        strokeWidth: 2.0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 64.v,
            color: AppColors.fontColor.withOpacity(0.7),
          ),
          Gap.v(20),
          const CustomText(
            title: 'No packages available',
            size: 18,
            color: AppColors.white,
          ),
          Gap.v(10),
          CustomText(
            title: 'Check back later for new packages',
            size: 14,
            color: AppColors.white.withOpacity(0.8),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: const CustomAppBar(
        title: 'Redeem UC',
      ),
      body: RefreshIndicator(
        onRefresh: _loadPackages,
        color: AppColors.primary,
        backgroundColor: AppColors.white,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 25.h),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return _buildLoadingWidget();
    }

    if (errorMessage != null) {
      return _buildErrorWidget();
    }

    if (packages.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      padding: EdgeInsets.symmetric(vertical: 12.v),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 20.v,
        crossAxisSpacing: 20.h,
        childAspectRatio: 0.6,
      ),
      itemCount: packages.length,
      itemBuilder: (BuildContext context, int index) {
        return _buildPackageItem(packages[index], index);
      },
    );
  }
}
