import 'package:flutter/material.dart';
import 'package:wc_coin_app/core/constants/colors.dart';
import 'package:wc_coin_app/core/constants/size_utils.dart';
import 'package:wc_coin_app/shared/custom_appbar.dart';
import 'package:wc_coin_app/shared/primary_btn.dart';
import 'package:wc_coin_app/shared/text_view.dart';

class WithdrawDetailsView extends StatelessWidget {
  WithdrawDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: CustomAppBar(
        title: 'Withdraw Details',
        trailing: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/coin.png',
              scale: 7.v,
            ),
            Gap.h(5),
            const CustomText(
              title: '28,000',
              size: 16,
              color: AppColors.white,
            ),
            Gap.h(10),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 27.h),
        child: Column(
          children: [
            Container(
              height: SizeUtils.height - 203,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.white,
                ),
              ),
              child: Column(
                children: [
                  Gap.v(20),
                  Image.asset(
                    'assets/images/withdraw_png.png',
                    scale: 5.v,
                  ),
                  Gap.v(20),
                  const CustomText(
                    title: 'Congratulations !',
                    size: 34,
                  ),
                  Gap.v(20),
                  const CustomText(
                    title: 'You withdraw 60 UC',
                    size: 34,
                  ),
                  Gap.v(20),
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 10.h),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 1),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.transparent,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        resultRow(label: 'Total Questions', value: 'Red Zone'),
                        Divider(
                          color: Colors.white.withOpacity(0.6),
                        ),
                        resultRow(
                            label: 'Correct Answers', value: '27647836478'),
                        Divider(
                          color: Colors.white.withOpacity(0.6),
                        ),
                        resultRow(label: 'Wrong Answers', value: '8000'),
                        Divider(
                          color: Colors.white.withOpacity(0.6),
                        ),
                        resultRow(label: 'TOTAL WC Coins', value: '60'),
                        Divider(
                          color: Colors.white.withOpacity(0.6),
                        ),
                        resultRow(label: 'Win We Coins', value: '29 May 2025'),
                        Divider(
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Gap.v(30),
            CustomBTN(
              size: 3,
              text: 'Return to Home',
              textSize: 22,
            )
          ],
        ),
      ),
    );
  }

  Widget resultRow({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Text(label,
          //     style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),

          CustomText(
            title: label,
            color: Colors.white,
            size: 14.fSize,
          )
          // Text(value,
          //     style: GoogleFonts.poppins(
          //         color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          ,
          const Divider(),
          Row(
            children: [
              Image.asset(
                "assets/images/WC COIN.png",
                scale: 100,
              ),
              Gap.h(10),
              CustomText(
                title: value,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                size: 14.fSize,
              ),
            ],
          )
        ],
      ),
    );
  }
}
