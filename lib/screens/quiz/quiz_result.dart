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
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Grid
              Gap.v(20),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.h),
                child: Material(
                  borderRadius: BorderRadius.circular(12),
                  elevation: 5,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.primary,
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 35.fSize,
                          backgroundColor: AppColors.white.withOpacity(.2),
                          child: Center(
                            child: Icon(
                              Icons.leaderboard,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        Gap.v(13),
                        const CustomText(
                          title: 'Great Job!',
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                          size: 23,
                        ),
                        Gap.v(15),
                        const CustomText(
                          title: 'You have completed the quiz',
                          fontWeight: FontWeight.w300,
                          color: AppColors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Gap.v(20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.h),
                child: Material(
                  elevation: 5,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 1),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: List.generate(answers.length, (index) {
                        bool isCorrect = answers[index];
                        return Container(
                          width: 80.h,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? AppColors.green.withOpacity(.1)
                                : AppColors.red.withOpacity(.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    isCorrect ? AppColors.green : AppColors.red,
                                width: 2),
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
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Score Summary Box
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.h),
                child: Material(
                  elevation: 5,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 1),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CustomText(
                          title: 'Quiz Summary',
                          fontWeight: FontWeight.w600,
                          size: 20,
                        ),
                        Gap.v(10),
                        resultRow(
                            label: 'Total Questions',
                            value: totalQuestions.toString()),
                        Gap.v(10),

                        // Divider(color: Colors.white.withOpacity(0.6)),
                        resultRow(
                            label: 'Correct Answers',
                            value: correct.toString()),
                        Gap.v(10),

                        // Divider(color: Colors.white.withOpacity(0.6)),
                        resultRow(
                            label: 'Wrong Answers', value: wrong.toString()),
                        Gap.v(10),

                        // Divider(color: Colors.white.withOpacity(0.6)),
                        resultRow(label: 'Win We Coins', value: '$winCoins '),
                        Gap.v(10),

                        // Divider(color: Colors.white.withOpacity(0.6)),
                        resultRow(label: 'TOTAL WC Coins', value: '$wcCoins '),
                      ],
                    ),
                  ),
                ),
              ),

              Gap.v(30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(20.h),
        decoration: const BoxDecoration(
          color: AppColors.white,
        ),
        child: PrimaryBTN(
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
          buttonTitle: 'Continue',
          btColor: AppColors.secondary,
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
            color: AppColors.fontColor,
            size: 14.fSize,
          ),
          Row(
            children: [
              Image.asset("assets/icons/coin.png", scale: 5.v),
              Gap.h(10),
              CustomText(
                title: value,
                color: AppColors.fontColor,
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
