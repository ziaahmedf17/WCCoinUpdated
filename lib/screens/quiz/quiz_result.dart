import 'package:flutter/material.dart';
import 'package:wc_coin_app/core/constants/colors.dart';
import 'package:wc_coin_app/core/constants/size_utils.dart';
import 'package:wc_coin_app/screens/quiz/congratulation.dart';
import 'package:wc_coin_app/screens/root/root_view.dart';
import 'package:wc_coin_app/shared/custom_appbar.dart';
import 'package:wc_coin_app/shared/primary_btn.dart';
import 'package:wc_coin_app/shared/text_view.dart';

class QuizResultScreen extends StatelessWidget {
  final List<bool> answers;
  final int totalQuestions;
  final int wcCoins;
  final int winCoins;

  const QuizResultScreen({
    Key? key,
    required this.answers,
    required this.totalQuestions,
    required this.wcCoins,
    required this.winCoins,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int correct = answers.where((e) => e).length;
    int wrong = answers.length - correct;

    return Scaffold(
      appBar: const CustomAppBar(title: "Quiz View"),
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
          child: Column(
            children: [
              // Grid
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(answers.length, (index) {
                  bool isCorrect = answers[index];
                  return Container(
                    width: 80.h,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.deepPurple, width: 2),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomText(
                          title: '${index + 1}',
                          fontWeight: FontWeight.bold,
                          color: AppColors.fontColor,
                          size: 30.fSize,
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: CustomText(
                            title: isCorrect ? '✅' : 'X',
                            size: isCorrect ? 18.fSize : 22.fSize,
                            color: isCorrect
                                ? const Color(0xff44FF00)
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),

              const SizedBox(height: 30),

              // Score Summary Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 1),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.transparent,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    resultRow(
                        label: 'Total Questions',
                        value: totalQuestions.toString()),
                    Divider(color: Colors.white.withOpacity(0.6)),
                    resultRow(
                        label: 'Correct Answers', value: correct.toString()),
                    Divider(color: Colors.white.withOpacity(0.6)),
                    resultRow(label: 'Wrong Answers', value: wrong.toString()),
                    Divider(color: Colors.white.withOpacity(0.6)),
                    resultRow(label: 'Win We Coins', value: '$winCoins '),
                    Divider(color: Colors.white.withOpacity(0.6)),
                    resultRow(label: 'TOTAL WC Coins', value: '$wcCoins '),
                  ],
                ),
              ),

              Gap.v(30),

              PrimaryBTN(
                onCLick: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return const RootView();
                      },
                    ),
                    (route) => false,
                  );
                },
                buttonTitle: 'Go to Home',
                btColor: AppColors.yellow,
              )

              // GestureDetector(
              //     onTap: () {
              //       Navigator.push(
              //         context,
              //         MaterialPageRoute(
              //           builder: (context) => CongratulationsView(),
              //         ),
              //       );
              //     },
              //     child: Image.asset("assets/images/button.png"))
            ],
          ),
        ),
      ),
    );
  }

  Widget resultRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(
            title: label,
            color: Colors.white,
            size: 14.fSize,
          ),
          Row(
            children: [
              Image.asset("assets/images/WC COIN.png", scale: 100),
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
