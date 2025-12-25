import 'package:flutter/material.dart';
import 'package:wc_coin_app/core/constants/ad_helper/ad_helper.dart';
import 'package:wc_coin_app/core/constants/ad_helper/app_open_ad_helper.dart';
import 'package:wc_coin_app/core/constants/colors.dart';
import 'package:wc_coin_app/core/constants/size_utils.dart';
import 'package:wc_coin_app/main.dart';
import 'package:wc_coin_app/models/leader_board_user_model.dart';
import 'package:wc_coin_app/screens/profile/profile_detail.dart';
import 'package:wc_coin_app/services/leader_board_service.dart';
import 'package:wc_coin_app/shared/custom_appbar.dart';
import 'package:wc_coin_app/shared/text_view.dart';

class LeaderboardView extends StatefulWidget {
  const LeaderboardView({super.key});

  @override
  State<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<LeaderboardView> {
  late Future<List<LeaderboardUser>> leaderboardFuture;
  GoogleAdmobProvider adVM = GoogleAdmobProvider();

  @override
  void initState() {
    super.initState();
    adVM.loadInterAd();

    leaderboardFuture = LeaderboardService().fetchLeaderboard();
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
          ),
          Gap.v(20),
          const CustomText(
            title: 'Loading Leaderboard...',
            size: 16,
            color: AppColors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.leaderboard,
            size: 64.v,
            color: AppColors.white.withOpacity(0.7),
          ),
          Gap.v(20),
          const CustomText(
            title: 'No Leaderboard yet',
            size: 18,
            color: AppColors.white,
          ),
          Gap.v(10),
          CustomText(
            title: 'All the users will displayed here.',
            size: 14,
            color: AppColors.white.withOpacity(0.8),
            alignment: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const CustomText(
          title: 'Leaderboard',
          size: 24,
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
      ),
      backgroundColor: AppColors.primary,
      body: FutureBuilder<List<LeaderboardUser>>(
        future: leaderboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingWidget();
          } else if (snapshot.hasError) {
            return Center(
              child: CustomText(
                title: "Error: ${snapshot.error}",
                size: 16,
                color: Colors.red,
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final leaderboard = snapshot.data!;

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: leaderboard.length,
            itemBuilder: (BuildContext context, int index) {
              final user = leaderboard[index];

              return Container(
                margin: EdgeInsets.only(bottom: 15.v, left: 26.h, right: 26.h),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  onTap: () {
               

                    apads['int']
                        ? InterstitialAdLoading.show(context, onComplete: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (context) {
                                return ProfileDetailView(userId: user.id);
                              },
                            ));
                          }, onFailed: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (context) {
                                return ProfileDetailView(userId: user.id);
                              },
                            ));
                          })
                        : () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (context) {
                                return ProfileDetailView(userId: user.id);
                              },
                            ));
                          };
                  },
                  leading: CircleAvatar(
                    radius: 28.v,
                    backgroundImage: user.avatar != null
                        ? NetworkImage(user.avatar!)
                        : const AssetImage('assets/icons/bn4.png')
                            as ImageProvider,
                  ),
                  title: CustomText(
                    title: user.name,
                    size: 20,
                    color: Colors.white,
                  ),
                  subtitle: Row(
                    children: [
                      Image.asset(
                        'assets/icons/coin.png',
                        scale: 7.v,
                      ),
                      Gap.h(5),
                      CustomText(
                        title: user.coins.toString(),
                        size: 14,
                        color: Colors.white,
                      ),
                    ],
                  ),
                  trailing: CustomText(
                    title: "#${user.rank}",
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
