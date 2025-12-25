// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:wc_coin_app/core/constants/colors.dart';
// import 'package:wc_coin_app/core/constants/size_utils.dart';
// import 'package:curved_navigation_bar/curved_navigation_bar.dart';
// import 'package:wc_coin_app/screens/home/home.dart';
// import 'package:wc_coin_app/screens/invite/invite_friends.dart';
// import 'package:wc_coin_app/screens/leaderboard/leaderboard.dart';
// import 'package:wc_coin_app/screens/recent_activites/recent_activites.dart';
// import 'package:wc_coin_app/screens/withdrawl_history/withdrawl_history.dart';
// import 'package:wc_coin_app/shared/text_view.dart';

// class RootView extends StatefulWidget {
//   const RootView({super.key});
//   @override
//   State<RootView> createState() => _RootViewState();
// }

// class _RootViewState extends State<RootView> {
//   int _selectedIndex = 0;
//   // List of screens
//   final List<Widget> _screens = [
//     HomeView(),
//     const RecentActivites(),
//     const LeaderboardView(),
//     const InviteFriendsView(),
//   ];
//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async {
//         return false;
//       },
//       child: Scaffold(
//         body: _screens[_selectedIndex],
//         bottomNavigationBar: CurvedNavigationBar(
//           index: _selectedIndex,
//           height: 70.v,
//           backgroundColor: AppColors.primary,
//           color: Color(0xff3600A4),
//           buttonBackgroundColor: AppColors.yellow,
//           animationCurve: Curves.easeInBack,
//           animationDuration: const Duration(milliseconds: 300),
//           onTap: _onItemTapped,
//           items: List.generate(4, (index) {
//             final isSelected = _selectedIndex == index;

//             final List<String> icons = [
//               'assets/icons/bn1.png',
//               'assets/icons/bn2.png',
//               'assets/icons/bn3.png',
//               'assets/icons/bn4.png',
//             ];

//             return Image.asset(
//               icons[index],
//               scale: 7.v,
//               color: isSelected ? AppColors.white : AppColors.white,
//             );
//           }),
//         ),
//       ),
//     );
//   }
// }

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wc_coin_app/core/constants/colors.dart';
import 'package:wc_coin_app/core/constants/size_utils.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:wc_coin_app/screens/home/home.dart';
import 'package:wc_coin_app/screens/invite/invite_friends.dart';
import 'package:wc_coin_app/screens/leaderboard/leaderboard.dart';
import 'package:wc_coin_app/screens/recent_activites/recent_activites.dart';
import 'package:wc_coin_app/screens/withdrawl_history/withdrawl_history.dart';
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Method to show exit confirmation dialog
  Future<bool> _showExitDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false, // User must tap a button to dismiss
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: CustomText(
                title: 'Exit App',
                size: 20,
              ),
              content: CustomText(
                title: 'Are you sure you want to exit?',
                size: 16,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true); // Return true (exit)
                  },
                  child: CustomText(
                    title: 'YES',
                    size: 16,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context)
                        .pop(false); // Return false (don't exit)
                  },
                  child: CustomText(
                    title: 'NO',
                    size: 16,
                  ),
                ),
              ],
            );
          },
        ) ??
        false; // Return false if dialog is dismissed without selection
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Show the exit confirmation dialog
        bool shouldExit = await _showExitDialog();

        if (shouldExit) {
          // Exit the app
          if (Platform.isAndroid) {
            SystemNavigator.pop(); // For Android
          } else if (Platform.isIOS) {
            exit(0); // For iOS
          }
        }

        return false; // Always return false to prevent default back behavior
      },
      child: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: CurvedNavigationBar(
          index: _selectedIndex,
          height: 70.v,
          backgroundColor: AppColors.primary,
          color: Color(0xff3600A4),
          buttonBackgroundColor: AppColors.yellow,
          animationCurve: Curves.easeInBack,
          animationDuration: const Duration(milliseconds: 300),
          onTap: _onItemTapped,
          items: List.generate(4, (index) {
            final isSelected = _selectedIndex == index;

            final List<String> icons = [
              'assets/icons/bn1.png',
              'assets/icons/bn2.png',
              'assets/icons/bn3.png',
              'assets/icons/bn4.png',
            ];

            return Image.asset(
              icons[index],
              scale: 7.v,
              color: isSelected ? AppColors.white : AppColors.white,
            );
          }),
        ),
      ),
    );
  }
}
