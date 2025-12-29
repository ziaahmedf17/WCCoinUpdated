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
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          Gap.v(20),
          const CustomText(
            title: 'Loading Leaderboard...',
            size: 16,
            color: AppColors.primary,
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

  Widget _buildPodiumUser(
    LeaderboardUser user,
    int position,
    double size,
    Color color,
    double topPadding, {
    required List<Color> listColors,
  }) {
    return GestureDetector(
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: size,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: size - 3,
                  backgroundImage: user.avatar != null
                      ? NetworkImage(user.avatar!)
                      : const AssetImage('assets/icons/bn4.png')
                          as ImageProvider,
                ),
              ),
              if (position == 1)
                Positioned(
                  top: -8,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      Icons.emoji_events,
                      color: Colors.white,
                      size: 16.v,
                    ),
                  ),
                ),
              if (position != 1)
                Positioned(
                  top: -5,
                  right: -5,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: CustomText(
                      title: position.toString(),
                      size: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          Gap.v(8),
          CustomText(
            title: user.name,
            size: position == 1 ? 18 : 16,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          Gap.v(12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 4.v),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/icons/coin.png',
                  scale: 6.v,
                ),
                Gap.h(4),
                CustomText(
                  title: _formatCoins(user.coins),
                  size: 13,
                  height: 0,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
          ),
          Gap.v(10),
          Container(
            width: 120.h,
            height: position == 1 ? 120.v : (position == 2 ? 100.v : 80.v),
            decoration: BoxDecoration(
              // color: color.withOpacity(0.8),
              gradient: LinearGradient(
                  colors: listColors, begin: Alignment.topLeft),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Icon(
                position == 1
                    ? Icons.emoji_events
                    : (position == 2
                        ? Icons.military_tech
                        : Icons.workspace_premium),
                color: Colors.white,
                size: position == 1 ? 50.v : 40.v,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCoins(int coins) {
    if (coins >= 1000000) {
      return '${(coins / 1000000).toStringAsFixed(1)}M';
    } else if (coins >= 1000) {
      return '${(coins / 1000).toStringAsFixed(1)}K';
    }
    return coins.toString();
  }

  Widget _buildTopThree(List<LeaderboardUser> users) {
    final topThree = users.take(3).toList();

    return Container(
      height: 320.v,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 2nd Place (Left)
                if (topThree.length > 1)
                  Expanded(
                    child: _buildPodiumUser(
                      topThree[1],
                      2,
                      25.v,
                      const Color(0xff6A7282),
                      12,
                      listColors: [const Color(0xffD1D5DC), const Color(0xff6A7282)],
                    ),
                  ),
                Gap.h(8),
                // 1st Place (Center)
                if (topThree.isNotEmpty)
                  Expanded(
                    child: _buildPodiumUser(
                      topThree[0],
                      1,
                      42.v,
                      const Color(0xffD08700),
                      0,
                      listColors: [const Color(0xffFDC700), const Color(0xffD08700)],
                    ),
                  ),
                Gap.h(8),
                // 3rd Place (Right)
                if (topThree.length > 2)
                  Expanded(
                    child: _buildPodiumUser(
                      topThree[2],
                      3,
                      25.v,
                      const Color(0xffF54900),
                      24,
                      listColors: [const Color(0xffFF8904), const Color(0xffF54900)],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestOfList(List<LeaderboardUser> users) {
    final restUsers = users.skip(3).toList();

    if (restUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.only(top: 20.v, left: 20.h, right: 20.h),
        itemCount: restUsers.length,
        itemBuilder: (BuildContext context, int index) {
          final user = restUsers[index];

          return Container(
            margin: EdgeInsets.only(bottom: 12.v),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Material(
              borderRadius: BorderRadius.circular(16),
              elevation: 5,
              child: ListTile(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.v),
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
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38.h,
                      height: 38.v,
                      decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.7),
                          )),
                      child: Center(
                        child: CustomText(
                          title: user.rank.toString(),
                          size: 14,
                          color: AppColors.fontColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Gap.h(12),
                    CircleAvatar(
                      radius: 26.v,
                      backgroundColor: Colors.blue,
                      child: CircleAvatar(
                        radius: 24.v,
                        backgroundImage: user.avatar != null
                            ? NetworkImage(user.avatar!)
                            : const AssetImage('assets/icons/bn4.png')
                                as ImageProvider,
                      ),
                    ),
                  ],
                ),
                title: CustomText(
                  title: user.name,
                  size: 17,
                  color: AppColors.fontColor,
                  fontWeight: FontWeight.w600,
                ),
                subtitle: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/icons/coin.png',
                      scale: 8.v,
                    ),
                    Gap.h(4),
                    CustomText(
                      title: _formatCoins(user.coins),
                      size: 13,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ],
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: AppColors.fontColor.withOpacity(.5),
                  size: 24.v,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: const CustomAppBar(
        title: 'Leaderboard',
        hasLeading: false,
      ),
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

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildTopThree(leaderboard),
                _buildRestOfList(leaderboard),
                Gap.v(20),
              ],
            ),
          );
        },
      ),
    );
  }
}
