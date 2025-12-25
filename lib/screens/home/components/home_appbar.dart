// import 'package:flutter/material.dart';
// import 'package:wc_coin_app/core/constants/colors.dart';
// import 'package:wc_coin_app/core/constants/size_utils.dart';
// import 'package:wc_coin_app/screens/notification/notification.dart';
// import 'package:wc_coin_app/screens/profile/my_profile.dart';
// import 'package:wc_coin_app/shared/text_view.dart';

// class HomeAppBar extends StatelessWidget {
//   const HomeAppBar({
//     super.key,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return AppBar(
//       toolbarHeight: 80.v,
//       elevation: 0,
//       leading: Padding(
//         padding: EdgeInsets.only(top: 5.v, left: 17.h),
//         child: GestureDetector(
//           onTap: () {
//             Navigator.push(context, MaterialPageRoute(
//               builder: (context) {
//                 return MyProfileView();
//               },
//             ));
//           },
//           child: CircleAvatar(
//             radius: 18.v,
//             backgroundImage: const NetworkImage(
//                 'https://marketplace.canva.com/EAF21qlw744/1/0/1600w/canva-blue-modern-facebook-profile-picture-mtu4sNVuKIU.jpg'),
//           ),
//         ),
//       ),
//       backgroundColor: AppColors.primary,
//       title: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const CustomText(
//             title: 'Hi, Zia Ahmed 👋',
//             size: 16,
//             height: 0,
//           ),
//           CustomText(
//             title: 'Let’s Play, Win, Cash Out Your Luck\nYour Rewards!',
//             size: 14,
//             height: 0,
//             fontWeight: FontWeight.w400,
//             color: AppColors.white.withOpacity(.5),
//           ),
//         ],
//       ),
//       actions: [
//         IconButton(
//           onPressed: () {
//             Navigator.push(context, MaterialPageRoute(
//               builder: (context) {
//                 return NotificationView();
//               },
//             ));
//           },
//           icon: Image.asset(
//             'assets/icons/ntf.png',
//             scale: 5.v,
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:wc_coin_app/core/constants/colors.dart';
import 'package:wc_coin_app/core/constants/size_utils.dart';
import 'package:wc_coin_app/screens/notification/notification.dart';
import 'package:wc_coin_app/screens/profile/my_profile.dart';
import 'package:wc_coin_app/shared/text_view.dart';
import 'package:wc_coin_app/models/user_model.dart';

class HomeAppBar extends StatelessWidget {
  final UserModel? user;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const HomeAppBar({
    super.key,
    this.user,
    this.isLoading = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 80.v,
      elevation: 0,
      leading: Padding(
        padding: EdgeInsets.only(top: 5.v, left: 17.h),
        child: GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) {
                return MyProfileView();
              },
            ));
          },
          child: isLoading
              ? Container(
                  width: 36.v,
                  height: 36.v,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey,
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                )
              : CircleAvatar(
                  radius: 18.v,
                  backgroundImage: NetworkImage(
                    user?.avatar.isNotEmpty == true
                        ? user!.avatar
                        : 'https://marketplace.canva.com/EAF21qlw744/1/0/1600w/canva-blue-modern-facebook-profile-picture-mtu4sNVuKIU.jpg',
                  ),
                  onBackgroundImageError: (exception, stackTrace) {
                    // Handle image loading error
                    print('Error loading avatar: $exception');
                  },
                  child: user?.avatar.isEmpty == true
                      ? Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 18.v,
                        )
                      : null,
                ),
        ),
      ),
      backgroundColor: AppColors.primary,
      title: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) {
              return MyProfileView();
            },
          ));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isLoading
                ? Container(
                    height: 16,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )
                : CustomText(
                    title: 'Hi, ${user?.name ?? 'Guest'} 👋',
                    size: 16,
                    height: 0,
                  ),
            Gap.v(2),
            isLoading
                ? Column(
                    children: [
                      Container(
                        height: 12,
                        width: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Gap.v(2),
                      Container(
                        height: 12,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  )
                : CustomText(
                    title: "Let's Play, Win, Cash Out Your Luck\nYour Rewards!",
                    size: 14,
                    height: 0,
                    fontWeight: FontWeight.w400,
                    color: AppColors.white.withOpacity(.5),
                  ),
          ],
        ),
      ),
      actions: [
        // Display coins if available
        // if (!isLoading && user?.coins != null)
        //   Padding(
        //     padding: EdgeInsets.only(right: 10.h),
        //     child: Container(
        //       padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 4.v),
        //       decoration: BoxDecoration(
        //         color: Colors.orange.withOpacity(0.2),
        //         borderRadius: BorderRadius.circular(12),
        //         border: Border.all(
        //           color: Colors.orange,
        //           width: 1,
        //         ),
        //       ),
        //       child: Row(
        //         mainAxisSize: MainAxisSize.min,
        //         children: [
        //           Icon(
        //             Icons.monetization_on,
        //             color: Colors.orange,
        //             size: 16.v,
        //           ),
        //           Gap.h(4),
        //           CustomText(
        //             title: '${user!.coins}',
        //             size: 12,
        //             color: Colors.orange,
        //             fontWeight: FontWeight.bold,
        //           ),
        //         ],
        //       ),
        //     ),
        //   ),
        IconButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) {
                return NotificationView();
              },
            ));
          },
          icon: Image.asset(
            'assets/icons/ntf.png',
            scale: 7.v,
          ),
        ),
        // Refresh button for debugging/manual refresh
        // if (onRefresh != null)
        // IconButton(
        //   onPressed: onRefresh,
        //   icon: Icon(
        //     Icons.refresh,
        //     color: Colors.white.withOpacity(0.7),
        //     size: 25.v,
        //   ),
        // ),
      ],
    );
  }
}
