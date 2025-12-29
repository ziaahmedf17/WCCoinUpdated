import 'package:flutter/material.dart';
import 'package:wc_coin_app/core/constants/colors.dart';
import 'package:wc_coin_app/core/constants/size_utils.dart';
import 'package:wc_coin_app/shared/text_view.dart';

class PrimaryBTN extends StatelessWidget {
  final String buttonTitle;
  final Function()? onCLick;
  final double width;
  final String? icon;
  final Color btColor;
  bool haveIcon;
  PrimaryBTN({
    super.key,
    this.onCLick,
    required this.buttonTitle,
    this.width = 292,
    this.haveIcon = false,
    this.icon,
    this.btColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      height: 56.v,
      minWidth: width.h,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      onPressed: onCLick,
      color: btColor,
      child: CustomText(
        title: buttonTitle,
        size: 18,
        color: AppColors.white,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class CustomBTN extends StatelessWidget {
  final double size;
  final String text;
  final double textSize;
  final Function()? ontap;
  const CustomBTN(
      {super.key,
      this.size = 7,
      required this.text,
      this.textSize = 10,
      this.ontap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ontap,
      child: Container(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'assets/images/custom_button.png',
              scale: size.v,
            ),
            CustomText(
              title: text,
              size: textSize,
            )
          ],
        ),
      ),
    );
  }
}
