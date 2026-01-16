import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wc_coin_app/core/constants/ad_helper/ad_helper.dart';
import 'package:wc_coin_app/core/constants/ad_helper/app_open_ad_helper.dart';
import 'package:wc_coin_app/core/constants/colors.dart';
import 'package:wc_coin_app/core/constants/size_utils.dart';
import 'package:wc_coin_app/main.dart';
import 'package:wc_coin_app/services/promo_code_service.dart';
import 'package:wc_coin_app/shared/custom_appbar.dart';
import 'package:wc_coin_app/shared/custom_button.dart';
import 'package:wc_coin_app/shared/primary_btn.dart';
import 'package:wc_coin_app/shared/text_view.dart';

class EnterPromoCodeView extends StatefulWidget {
  const EnterPromoCodeView({super.key});

  @override
  State<EnterPromoCodeView> createState() => _EnterPromoCodeViewState();
}

class _EnterPromoCodeViewState extends State<EnterPromoCodeView> {
  final TextEditingController _promoCodeController = TextEditingController();
  bool isLoading = false;
  GoogleAdmobProvider adVM = GoogleAdmobProvider();

  @override
  void initState() {
    // TODO: implement initState
    adVM.loadInterAd();

    super.initState();
  }

  @override
  void dispose() {
    _promoCodeController.dispose();
    super.dispose();
  }

  Future<void> _redeemPromoCode() async {
    final promoCode = _promoCodeController.text.trim();

    if (promoCode.isEmpty) {
      _showErrorSnackBar('Please enter a promo code');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await PromoCodeService.redeemPromoCode(promoCode);

      setState(() {
        isLoading = false;
      });

      if (result['success']) {
        _showSuccessDialog(result['message']);
        _promoCodeController.clear();
      } else {
        _showErrorSnackBar(result['message']);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showSuccessDialog(String message) {
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
                  Colors.amber.shade600,
                  Colors.orange.shade700,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Star Icon
                const Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 60,
                ),
                const SizedBox(height: 16),

                const CustomText(
                  title: 'Success!',
                  size: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: 12),

                CustomText(
                  title: message,
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
                    child: const CustomText(
                      title: 'Continue',
                      size: 16,
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.bold,
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Boogaloo',
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Enter Promo Code"),
      backgroundColor: AppColors.bgColor,
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  offset: Offset(0, 4),
                  spreadRadius: 3,
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/promo_png.png',
                  scale: 4.v,
                ),
                const CustomText(
                  title: "Enter Promo Code",
                  size: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                Gap.v(20),
                TextField(
                  controller: _promoCodeController,
                  enabled: !isLoading,
                  style: const TextStyle(
                    fontFamily: 'Boogaloo',
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: "Promo Code",
                    hintStyle: TextStyle(
                      fontFamily: 'Boogaloo',
                      color: AppColors.primary.withOpacity(.6),
                      fontWeight: FontWeight.bold,
                    ),
                    filled: true,
                    fillColor: isLoading
                        ? AppColors.primary.withOpacity(.05)
                        : AppColors.primary.withOpacity(.1),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.primary.withOpacity(.6),
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.primary.withOpacity(.6),
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  onSubmitted: isLoading ? null : (_) => _redeemPromoCode(),
                ),
                Gap.v(20),
                PrimaryBTN(
                  onCLick: () async {
                    if (isLoading) return;

                    apads['int']
                        ? InterstitialAdLoading.show(
                            context,
                            onComplete: _redeemPromoCode,
                            onFailed: _redeemPromoCode,
                          )
                        : _redeemPromoCode();
                  },
                  btColor: AppColors.secondary,
                  buttonTitle: 'Continue',
                ),
              ],
            ),
          ),
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
                const CustomText(title: '💡 Pro Tip:'),
                Gap.v(10),
                Padding(
                  padding: EdgeInsets.only(left: 20.h),
                  child: const CustomText(
                    title:
                        'Join this telegram channel to get exclusive promo codes',
                  ),
                ),
                Gap.v(20),
                Center(
                  child: PrimaryBTN(
                    height: 50,
                    width: 150,
                    buttonTitle: 'Join Now',
                    onCLick: () async {
                      final Uri url = Uri.parse('https://t.me/WcCoinsApp');

                      if (!await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      )) {
                        throw 'Could not launch $url';
                      }
                    },
                  ),
                )
              ],
            ),
          )
        ],
      ),
      bottomNavigationBar: apads['banner']
          ? Container(
              // color: AppColors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Gap.v(5),
                  const CustomText(
                    title: 'Advertisement',
                    // color: AppColors.fontColor,
                  ),
                  Gap.v(5),
                  const BannerAD(),
                  Gap.v(5),
                ],
              ),
            )
          : const SizedBox(),
    );
  }
}
