import 'package:flutter/material.dart';
import 'package:wc_coin_app/core/constants/size_utils.dart';
import 'package:wc_coin_app/shared/text_view.dart';

class OrangeButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final double borderRadius;
  // final EdgeInsets padding;

  const OrangeButton({
    super.key,
    required this.text,
    required this.onTap,
    this.borderRadius = 30,
    // this.padding = const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          width: 200,
          height: 60.v,
          // padding: padding,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF9900), Color(0xFFFF6600)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 4),
                blurRadius: 6,
              ),
            ],
          ),
          child:

              //  Text(
              //   text,
              //   style: GoogleFonts.poppins(
              //     fontSize: 16,
              //     color: Colors.white,
              //     fontWeight: FontWeight.bold,
              //   ),
              //   textAlign: TextAlign.center,
              // ),
              Center(
                  child: CustomText(
            title: text,
            alignment: TextAlign.center,
            size: 24.fSize,
            fontWeight: FontWeight.bold,
          )),
        ));
  }
}
