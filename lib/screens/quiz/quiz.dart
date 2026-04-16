import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wc_coin_app/core/constants/ad_helper/ad_helper.dart';
import 'package:wc_coin_app/core/constants/ad_helper/rewarded_ad_loading.dart';
import 'package:wc_coin_app/core/constants/colors.dart';
import 'package:wc_coin_app/core/constants/size_utils.dart';
import 'package:wc_coin_app/main.dart';
import 'package:wc_coin_app/screens/quiz/quiz_result.dart';
import 'package:wc_coin_app/shared/custom_appbar.dart';
import 'package:wc_coin_app/shared/primary_btn.dart';
import 'package:wc_coin_app/shared/snackbar.dart';
import 'package:wc_coin_app/shared/text_view.dart';

import '../../models/quiz_model.dart';
import '../../services/quiz_service.dart';

class QuizView extends StatefulWidget {
  const QuizView({Key? key}) : super(key: key);

  @override
  State<QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<QuizView>
    with SingleTickerProviderStateMixin {
  late Future<List<Quiz>> quizzesFuture;
  int currentIndex = 0;
  int? selectedAnswerIndex;
  List<bool> answers = [];
  int wcCoins = 0;
  int winCoins = 0;
  bool isSubmitting = false;

  bool _canClaim = false;
  int _remainingSeconds = 0;
  Timer? _countdownTimer;
  Timer? _apiCheckTimer;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    quizzesFuture = QuizService().fetchQuizzes(context);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _checkTimerStatus();
    _startApiCheckTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _apiCheckTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startApiCheckTimer() {
    _apiCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkTimerStatus();
    });
  }

  Future<void> _checkTimerStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) return;

      final response = await http.get(
        Uri.parse("https://wc-admin.genwizz.com/api/timer/quiz"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _canClaim = data['can_claim'] ?? false;
          _remainingSeconds = (data['remaining_seconds'] ?? 0).ceil();
        });

        if (_canClaim) {
          _startBlinkingAnimation();
          _countdownTimer?.cancel();
        } else {
          _animationController.stop();
          _animationController.reset();
          _startCountdown();
        }
      }
    } catch (e) {
      print("Error checking timer status: $e");
    }
  }

  void _startBlinkingAnimation() {
    _animationController.repeat(reverse: true);
  }

  void _startCountdown() {
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          timer.cancel();
          _checkTimerStatus();
        }
      });
    });
  }

  String _formatTime() {
    if (_canClaim) return "Ready to play!";

    int hours = _remainingSeconds ~/ 3600;
    int minutes = (_remainingSeconds % 3600) ~/ 60;
    int seconds = _remainingSeconds % 60;

    if (hours > 0) {
      return "$hours hr $minutes min $seconds sec";
    } else if (minutes > 0) {
      return "$minutes min $seconds sec";
    }
    return "$seconds seconds";
  }

  Future<void> _claim2xReward(String originalCoins) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) {
        if (!mounted) return;
        showCustomSnackBar("No API token found", context, isError: true);
        return;
      }

      // Calculate double the coins
      final doubleCoins = (int.parse(originalCoins) * 2).toString();

      final response = await http.post(
        Uri.parse("https://wc-admin.genwizz.com/api/ads"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "coins": originalCoins,
          "type": "ad",
        }),
      );

      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Show success message
        if (data["message"] != null) {
          showCustomSnackBar(data["message"], context, isError: false);
        }

        // Show congratulation dialog for 2x reward
        _show2xRewardDialog(originalCoins, doubleCoins, data);
      } else {
        if (data["message"] != null) {
          showCustomSnackBar(data["message"], context, isError: true);
        }
      }
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar("Error claiming 2x reward: $e", context,
          isError: true);
    }
  }

  void _show2xRewardDialog(String originalCoins, String doubleCoins,
      Map<String, dynamic> responseData) {
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
                  Colors.purple.shade600,
                  Colors.purple.shade800,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: Colors.amber,
                  size: 60,
                ),
                const SizedBox(height: 16),
                const CustomText(
                  title: 'Amazing!',
                  size: 24,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                const CustomText(
                  title: 'You doubled your quiz reward!',
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      CustomText(
                        title: 'Original: $originalCoins coins',
                        size: 14,
                        color: Colors.white70,
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        title: '2x Reward: $doubleCoins coins',
                        size: 16,
                        color: Colors.amber,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (responseData['message'] != null)
                  CustomText(
                    title: responseData['message'],
                    size: 14,
                    color: Colors.white70,
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showQuizCompletedDialog(int totalWinCoins) {
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
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.8),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.celebration,
                  color: Colors.amber,
                  size: 60,
                ),
                const SizedBox(height: 16),
                const CustomText(
                  title: 'Quiz Completed!',
                  size: 24,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                CustomText(
                  title: 'You earned $totalWinCoins coins!',
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                SizedBox(height: 20),
                CustomText(
                  title: 'Watch Ad to double your Reward',
                  size: 15,
                  color: AppColors.white,
                ),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Navigate to quiz result screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuizResultScreen(
                                answers: answers,
                                totalQuestions: answers.length,
                                wcCoins: wcCoins,
                                winCoins: winCoins,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Center(
                            child: CustomText(
                          title: 'Continue',
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          size: 14,
                        )),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          RewardedAdLoading.show(context, onComplete: () {
                            // Integrate the 2x reward API here
                            _claim2xReward(totalWinCoins.toString());
                            print("✅ User rewarded successfully");
                          }, onFailed: () {
                            print("⚠️ Rewarded ad failed or skipped");
                            // Still navigate to result screen if ad fails
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QuizResultScreen(
                                  answers: answers,
                                  totalQuestions: answers.length,
                                  wcCoins: wcCoins,
                                  winCoins: winCoins,
                                ),
                              ),
                            );
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Center(
                            child: CustomText(
                          title: '2x Reward',
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          size: 14,
                        )),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _nextQuestion(List<Quiz> quizzes) async {
    if (selectedAnswerIndex == null) {
      showCustomSnackBar("Please select an answer", context, isError: true);
      return;
    }

    if (isSubmitting) return; // Prevent multiple submissions

    setState(() {
      isSubmitting = true;
    });

    final currentQuiz = quizzes[currentIndex];
    final selectedOption = currentQuiz.options[selectedAnswerIndex!];

    try {
      final result =
          await QuizService().submitAnswer(currentQuiz.id, selectedOption.id);

      final bool isCorrect = result["correct"] == true;
      final int reward = result["reward_coin"] ?? 0;
      final int total = result["total_coins"] ?? 0;
      final String apiMessage = result["message"] ?? "";

      setState(() {
        answers.add(isCorrect);
        wcCoins = total;
        winCoins += reward;
      });

      // Show API message for both correct and incorrect answers
      if (apiMessage.isNotEmpty) {
        final String apiMessage = result["message"] ?? "";

        showCustomSnackBar(
          apiMessage,
          context,
          isError: !isCorrect,
        );
      } else {
        // Fallback messages if API message is empty
        if (isCorrect) {
          showCustomSnackBar("Correct! +$reward coins", context,
              isError: false);
        } else {
          showCustomSnackBar("Wrong answer!", context, isError: true);
        }
      }

      if (currentIndex < quizzes.length - 1) {
        setState(() {
          currentIndex++;
          selectedAnswerIndex = null;
        });
      } else {
        // Quiz completed - show dialog with 2x reward option
        _showQuizCompletedDialog(winCoins);
      }
    } catch (e) {
      // Try to extract API message from the exception
      String errorMessage = "Error submitting answer";

      if (e.toString().contains('message')) {
        try {
          // If the error contains JSON, try to parse it
          final errorString = e.toString();
          if (errorString.contains('{') && errorString.contains('}')) {
            final jsonStart = errorString.indexOf('{');
            final jsonEnd = errorString.lastIndexOf('}') + 1;
            final jsonString = errorString.substring(jsonStart, jsonEnd);
            final errorData = jsonDecode(jsonString);

            if (errorData['message'] != null) {
              errorMessage = errorData['message'];
            }
          }
        } catch (parseError) {
          // If parsing fails, use default message
          errorMessage = "Error submitting answer";
        }
      }

      showCustomSnackBar(errorMessage, context, isError: true);
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 24.h, vertical: 20.v),
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.red.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated/Shaking icon (optional)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64.v,
                color: Colors.red.withOpacity(0.7),
              ),
            ),
            Gap.v(20),
            CustomText(
              title: "Error loading Quiz",
              size: 18,
              color: AppColors.fontColor,
              fontWeight: FontWeight.w600,
            ),
            Gap.v(12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12.v),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomText(
                title: 'No Internet',
                size: 14,
                color: Colors.red.withOpacity(0.8),
                alignment: TextAlign.center,
                maxLines: 5,
              ),
            ),
            Gap.v(24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  quizzesFuture = QuizService().fetchQuizzes(context);
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.primary,
                elevation: 2,
                padding: EdgeInsets.symmetric(horizontal: 32.h, vertical: 12.v),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, size: 18),
                  Gap.h(8),
                  const Text('Try Again'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Quiz Screen"),
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        child: FutureBuilder<List<Quiz>>(
          future: quizzesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 20),
                    CustomText(
                      title: 'Loading Quizzes...',
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: _buildErrorWidget(snapshot.error.toString()),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: CustomText(
                  title: "No quizzes available",
                  color: AppColors.primary,
                  size: 16,
                ),
              );
            }

            final quizzes = snapshot.data!;
            final quiz = quizzes[currentIndex];

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Timer indicator at the top
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: _canClaim
                            ? Colors.green.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _canClaim ? Colors.green : Colors.orange,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _canClaim ? Icons.check_circle : Icons.timer,
                            color: _canClaim ? Colors.green : Colors.orange,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          CustomText(
                            title: _formatTime(),
                            size: 16,
                            color: _canClaim ? Colors.green : Colors.orange,
                          ),
                        ],
                      ),
                    ),
                    Gap.v(10),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5.h),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Material(
                          elevation: 5,
                          borderRadius: BorderRadius.circular(32),
                          child: Column(
                            children: [
                              Gap.v(20),
                              CircleAvatar(
                                radius: 40.fSize,
                                backgroundColor: AppColors.secondary,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      value:
                                          (currentIndex + 1) / quizzes.length,
                                      backgroundColor:
                                          AppColors.white.withOpacity(.3),
                                      valueColor: const AlwaysStoppedAnimation(
                                          AppColors.white),
                                      strokeWidth: 3,
                                    ),
                                    CustomText(
                                      title: "${currentIndex + 1}",
                                      size: 20.fSize,
                                      color: AppColors.white,
                                    )
                                  ],
                                ),
                              ),
                              Gap.v(15),
                              CustomText(
                                title:
                                    "QUESTION ${currentIndex + 1} OF ${quizzes.length}",
                                color: const Color(0XFF858494),
                                size: 20.fSize,
                                fontWeight: FontWeight.w500,
                              ),
                              Gap.v(5),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10.h),
                                child: CustomText(
                                  size: 23.fSize,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                  alignment: TextAlign.center,
                                  title: quiz.question,
                                ),
                              ),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Gap.v(10),
                    ...List.generate(quiz.options.length, (index) {
                      final isSelected = selectedAnswerIndex == index;
                      return Padding(
                        // padding: const EdgeInsets.symmetric(vertical: 8.0),
                        padding: EdgeInsets.symmetric(
                            horizontal: 5.h, vertical: 8.v),

                        child: GestureDetector(
                          onTap: _canClaim
                              ? () {
                                  setState(() {
                                    selectedAnswerIndex = index;
                                  });
                                }
                              : null,
                          child: Opacity(
                            opacity: _canClaim ? 1.0 : 0.5,
                            child: Material(
                              elevation: 5,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: isSelected
                                      ? Border.all(
                                          color: Colors.white, width: 2)
                                      : null,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0),
                                  child: CustomText(
                                    size: 22.fSize,
                                    title: quiz.options[index].text,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    Gap.v(10),
                    isSubmitting
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                CustomText(
                                  title: 'Submitting...',
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          )
                        : ScaleTransition(
                            scale: _canClaim
                                ? _scaleAnimation
                                : AlwaysStoppedAnimation(1.0),
                            child: Opacity(
                              opacity: _canClaim ? 1.0 : 0.5,
                              // child: GestureDetector(
                              // onTap: _canClaim
                              //     ? () => _nextQuestion(quizzes)
                              //     : null,
                              // child: Image.asset(
                              //   "assets/images/button.png",
                              //   scale: 5.v,
                              // ),
                              // ),

                              child: PrimaryBTN(
                                btColor: AppColors.secondary,
                                buttonTitle: 'Continue',
                                onCLick: _canClaim
                                    ? () => _nextQuestion(quizzes)
                                    : () {},
                              ),
                            ),
                          )
                  ],
                ),
              ),
            );
          },
        ),
      ),
      // bottomNavigationBar: apads['banner']
      //     ? Container(
      //         // color: AppColors.white,
      //         child: Column(
      //           mainAxisSize: MainAxisSize.min,
      //           children: [
      //             // Gap.v(5),
      //             const CustomText(
      //               title: 'Advertisement',
      //               // color: AppColors.fontColor,
      //             ),
      //             Gap.v(5),
      //             const BannerAD(),
      //             Gap.v(5),
      //           ],
      //         ),
      //       )
      //     : SizedBox(),
    );
  }
}
