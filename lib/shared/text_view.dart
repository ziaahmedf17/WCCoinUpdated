import 'package:flutter/material.dart';
import 'package:wc_coin_app/core/constants/colors.dart';
import 'package:wc_coin_app/core/constants/size_utils.dart';

class CustomText extends StatelessWidget {
  final String title;
  final TextAlign alignment;
  final TextOverflow txtOverFlow;
  final bool isDark;
  final FontStyle style;
  final double letterSpacce;
  final Color? color;
  final TextDecoration textDecoration;
  final FontWeight fontWeight;
  final double size;
  // final FontType fontType;
  final int? maxLines;
  final double height;
  const CustomText({
    super.key,
    this.isDark = true,
    // this.fontType = FontType.poppins,
    this.size = 14,
    this.fontWeight = FontWeights.regular,
    this.textDecoration = TextDecoration.none,
    this.color,
    this.letterSpacce = 0,
    this.style = FontStyle.normal,
    this.alignment = TextAlign.start,
    this.txtOverFlow = TextOverflow.visible,
    required this.title,
    this.maxLines,
    this.height = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: alignment,
      maxLines: maxLines,
      style: TextStyle(
        overflow: txtOverFlow,
        fontStyle: style,
        letterSpacing: letterSpacce,
        fontFamily: 'Boogaloo',
        // color: color ??
        //     (isDark
        //         ? ColorsConstants.primaryTextColor
        //         : ColorsConstants.textColoWhite),
        color: color ?? AppColors.white,
        decoration: textDecoration,
        fontWeight: fontWeight,
        fontSize: size.fSize,
        height: height.v,
        decorationThickness: 1,
        decorationStyle: TextDecorationStyle.wavy,
      ),
    );
  }
}

class FontWeights {
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
}
