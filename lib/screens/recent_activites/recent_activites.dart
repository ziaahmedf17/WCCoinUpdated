// recent_activities.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wc_coin_app/core/constants/colors.dart';
import 'package:wc_coin_app/core/constants/size_utils.dart';
import 'package:wc_coin_app/models/activity_model.dart';
import 'package:wc_coin_app/services/activity_service.dart';
import 'package:wc_coin_app/shared/custom_appbar.dart';
import 'package:wc_coin_app/shared/text_view.dart';

class RecentActivities extends StatefulWidget {
  const RecentActivities({super.key});

  @override
  State<RecentActivities> createState() => _RecentActivitiesState();
}

class _RecentActivitiesState extends State<RecentActivities> {
  late Future<ActivityResponse> activitiesResponseFuture;
  final ActivityService _activityService = ActivityService();

  @override
  void initState() {
    super.initState();
    activitiesResponseFuture = _activityService.fetchActivities();
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
            title: 'Loading Activities...',
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
            title: 'No Activity yet',
            size: 18,
            color: AppColors.white,
          ),
          Gap.v(10),
          CustomText(
            title: 'All the Activity will be displayed here.',
            size: 14,
            color: AppColors.white.withOpacity(0.8),
            alignment: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.v,
            color: Colors.red.withOpacity(0.7),
          ),
          Gap.v(20),
          CustomText(
            title: "Error loading activities",
            size: 18,
            color: Colors.red,
          ),
          Gap.v(10),
          CustomText(
            title: error,
            size: 14,
            color: Colors.red.withOpacity(0.8),
            alignment: TextAlign.center,
          ),
          Gap.v(20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                activitiesResponseFuture = _activityService.fetchActivities();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.primary,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _getActivityIcon(String logName) {
    switch (logName) {
      case 'package_purchase':
        return "assets/images/purchase_icon.png";
      case 'daily_bonus_claim':
        return "assets/images/bonus_icon.png";
      case 'google_signin_persistent':
        return "assets/images/login_icon.png";
      case 'transaction_view':
      case 'transaction_list':
        return "assets/images/transaction_icon.png";
      case 'profile_view':
        return "assets/images/profile_icon.png";
      default:
        return "assets/images/recent_activity1.png";
    }
  }

  String _formatTrailingText(Activity activity) {
    final properties = activity.properties;

    if (properties.containsKey('coins')) {
      final coins = properties['coins'];
      return "+$coins";
    }

    if (properties.containsKey('today_bonus')) {
      final bonus = properties['today_bonus'];
      return "+$bonus";
    }

    if (properties.containsKey('uc_value')) {
      final ucValue = properties['uc_value'];
      return "\$$ucValue";
    }

    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: CustomAppBar(
        title: 'Recent Activities',
        hasLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: FutureBuilder<ActivityResponse>(
          future: activitiesResponseFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingWidget();
            } else if (snapshot.hasError) {
              return _buildErrorWidget(snapshot.error.toString());
            } else if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
              return _buildEmptyState();
            }

            final activityResponse = snapshot.data!;
            final activities = activityResponse.data;
            final meta = activityResponse.meta;

            return ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: activities.length,
              separatorBuilder: (context, index) => Gap.v(20),
              itemBuilder: (context, index) {
                final activity = activities[index];
                final formattedDate = DateFormat("dd MMM yyyy, hh:mm a")
                    .format(activity.createdAt);

                return ActivityTile(
                  // image: _getActivityIcon(activity.logName),
                  image: "assets/images/recent_activity1.png",
                  tile: activity.description,
                  subtitle: formattedDate,
                  traling: _formatTrailingText(activity),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget ActivityTile({
    required String tile,
    required String image,
    required String subtitle,
    required String traling,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      elevation: 5,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          // boxShadow: [
          //   BoxShadow(
          //     color: AppColors.fontColor.withOpacity(.1),
          //     spreadRadius: 2,
          //     blurRadius: 10,
          //   )
          // ],
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.secondary,
            // child: Image.asset(image, height: 36, width: 36),
          ),
          title: CustomText(
            title: tile,
            size: 18.fSize,
            color: AppColors.fontColor,
            fontWeight: FontWeight.w600,
          ),
          subtitle: CustomText(
            title: subtitle,
            fontWeight: FontWeight.w400,
            size: 12,
            color: AppColors.fontColor,
          ),
          // trailing: traling.isNotEmpty
          //     ? CustomText(
          //         size: 18.fSize,
          //         title: traling,
          //         color: const Color(0xff44FF00),
          //       )
          //     : null,
          trailing: tile.contains('UC')
              ? CustomText(
                  title: traling.replaceAll('+', '-'),
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                )
              : CustomText(
                  title: traling,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
        ),
      ),
    );
  }
}
