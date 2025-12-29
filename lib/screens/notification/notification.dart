import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wc_coin_app/core/constants/colors.dart';
import 'package:wc_coin_app/core/constants/size_utils.dart';
import 'package:wc_coin_app/models/announcement_model.dart';
import 'package:wc_coin_app/services/anouncement_service.dart';
import 'package:wc_coin_app/shared/custom_appbar.dart';
import 'package:wc_coin_app/shared/text_view.dart';

class NotificationView extends StatefulWidget {
  const NotificationView({super.key});

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView> {
  late Future<List<Announcement>> announcementsFuture;

  @override
  void initState() {
    super.initState();
    announcementsFuture = AnnouncementService().fetchAnnouncements();
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
            title: 'Loading Announcement...',
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
            Icons.notification_add,
            size: 64.v,
            color: AppColors.white.withOpacity(0.7),
          ),
          Gap.v(20),
          const CustomText(
            title: 'No Announcement yet',
            size: 18,
            color: AppColors.white,
          ),
          Gap.v(10),
          CustomText(
            title: 'All the Announcement will displayed here.',
            size: 14,
            color: AppColors.white.withOpacity(0.8),
            alignment: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showNotificationDialog(int announcementId) async {
    try {
      // Show loading dialog first
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
          ),
        ),
      );

      // Fetch the single announcement details
      final announcement =
          await AnnouncementService().fetchSingleAnnouncement(announcementId);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show the actual notification dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const CustomText(
                        title: "Notification Details",
                        size: 20,
                        color: AppColors.white,
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                  Gap.v(20),

                  // Title
                  const CustomText(
                    title: "Title:",
                    size: 16,
                    color: AppColors.white,
                  ),
                  Gap.v(5),
                  CustomText(
                    title: announcement.title,
                    size: 18,
                    color: AppColors.white,
                  ),
                  Gap.v(15),

                  // Type
                  const CustomText(
                    title: "Type:",
                    size: 16,
                    color: AppColors.white,
                  ),
                  Gap.v(5),
                  CustomText(
                    title: announcement.type,
                    size: 16,
                    color: AppColors.white.withOpacity(0.8),
                  ),
                  Gap.v(15),

                  // Details
                  const CustomText(
                    title: "Details:",
                    size: 16,
                    color: AppColors.white,
                  ),
                  Gap.v(5),
                  CustomText(
                    title: announcement.details ?? "No details available",
                    size: 16,
                    color: AppColors.white.withOpacity(0.8),
                    alignment: TextAlign.left,
                  ),
                  Gap.v(15),

                  // Date
                  const CustomText(
                    title: "Date:",
                    size: 16,
                    color: AppColors.white,
                  ),
                  Gap.v(5),
                  CustomText(
                    title: announcement.createdAt,
                    size: 16,
                    color: const Color(0xffAFAFAF),
                  ),
                  Gap.v(20),

                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.white,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const CustomText(
                        title: "Close",
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (error) {
      // Close loading dialog if it's showing
      if (mounted) Navigator.of(context).pop();

      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.primary,
            title: const CustomText(
              title: "Error",
              size: 18,
              color: Colors.red,
            ),
            content: CustomText(
              title: "Failed to load notification details: $error",
              size: 14,
              color: AppColors.white,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const CustomText(
                  title: "OK",
                  size: 16,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: const CustomAppBar(title: "Notifications"),
      body: FutureBuilder<List<Announcement>>(
        future: announcementsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // 🔄 Loading state
            return _buildLoadingWidget();
          } else if (snapshot.hasError) {
            // ❌ Error state
            return Center(
              child: CustomText(
                title: "Error: ${snapshot.error}",
                size: 16,
                color: Colors.red,
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // 📭 No Data state
            return Center(child: _buildEmptyState());
          }

          final announcements = snapshot.data!;

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final announcement = announcements[index];

              return _notificationTile(
                image: "assets/images/notification.png",
                title: announcement.title,
                subtitle: announcement.type,
                trailing: announcement.createdAt,
                onTap: () => _showNotificationDialog(announcement.id),
              );
            },
          );
        },
      ),
    );
  }

  Widget _notificationTile({
    required String title,
    required String image,
    required String subtitle,
    required String trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(top: 10, left: 20.h, right: 20.h),
      child: Material(
        color: AppColors.white,
        elevation: 5,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            onTap: onTap,
            leading: CircleAvatar(
              backgroundColor: AppColors.secondary,
              child: Center(
                child: Icon(
                  Icons.notifications_on,
                  color: AppColors.white,
                ),
              ),
            ),
            title: CustomText(
              title: title,
              size: 17.fSize,
              fontWeight: FontWeight.w600,
              color: AppColors.fontColor,
            ),
            subtitle: CustomText(
              title: 'Tap to see more',
              color: AppColors.fontColor.withOpacity(0.6),
            ),
            trailing: CustomText(
              size: 14.fSize,
              title: trailing,
              color: const Color(0xffAFAFAF),
            ),
          ),
        ),
      ),
    );
  }
}
