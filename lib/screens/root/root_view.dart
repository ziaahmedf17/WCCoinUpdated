import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wc_coin_app/core/constants/colors.dart';
import 'package:wc_coin_app/core/constants/size_utils.dart';
import 'package:wc_coin_app/screens/home/home.dart';
import 'package:wc_coin_app/screens/invite/invite_friends.dart';
import 'package:wc_coin_app/screens/leaderboard/leaderboard.dart';
import 'package:wc_coin_app/screens/recent_activites/recent_activites.dart';
import 'package:wc_coin_app/shared/text_view.dart';

class RootView extends StatefulWidget {
  const RootView({super.key});
  @override
  State<RootView> createState() => _RootViewState();
}

class _RootViewState extends State<RootView> {
  int _selectedIndex = 0;

  // List of screens
  final List<Widget> _screens = [
    HomeView(),
    const RecentActivities(),
    const LeaderboardView(),
    const InviteFriendsView(),
  ];

  // Navigation items data
  final List<Map<String, dynamic>> _navItems = [
    {
      'icon': 'assets/icons/bn1.png',
      'title': 'Home',
    },
    {
      'icon': 'assets/icons/bn2.png',
      'title': 'History',
    },
    {
      'icon': 'assets/icons/bn3.png',
      'title': 'Rewards',
    },
    {
      'icon': 'assets/icons/bn4.png',
      'title': 'Friends',
    },
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

// Method to show exit confirmation dialog
  Future<bool> _showExitDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with icon
                    Padding(
                      padding: const EdgeInsets.only(top: 24, bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.exit_to_app_rounded,
                          color: AppColors.white,
                          size: 32,
                        ),
                      ),
                    ),

                    // Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: CustomText(
                        title: 'Exit App',
                        size: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: CustomText(
                        title: 'Are you sure you want to exit?',
                        size: 16,
                        color: AppColors.white.withOpacity(0.9),
                        alignment: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(false);
                              },
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor:
                                    AppColors.white.withOpacity(0.2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: CustomText(
                                title: 'NO',
                                size: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop(true);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: CustomText(
                                title: 'YES',
                                size: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool shouldExit = await _showExitDialog();

        if (shouldExit) {
          if (Platform.isAndroid) {
            SystemNavigator.pop();
          } else if (Platform.isIOS) {
            exit(0);
          }
        }

        return false;
      },
      child: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Container(
              height: 80.v, // Adjust height as needed
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(
                  _navItems.length,
                  (index) {
                    final isSelected = _selectedIndex == index;
                    final item = _navItems[index];

                    return GestureDetector(
                      onTap: () => _onItemTapped(index),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 20.h, vertical: 10.v),
                        decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Icon with selected color effect
                            Image.asset(
                              item['icon'],
                              width: 24.v,
                              height: 24.v,
                              color: isSelected
                                  ? AppColors.white
                                  : Colors.grey[600],
                            ),
                            SizedBox(height: 4.v),
                            // Title
                            Text(
                              item['title'],
                              style: TextStyle(
                                fontSize: 12.v,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? AppColors.white
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
