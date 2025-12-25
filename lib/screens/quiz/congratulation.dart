// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:wc_coin_app/core/constants/colors.dart';
// import 'package:wc_coin_app/core/constants/size_utils.dart';
// import 'package:wc_coin_app/screens/home/home.dart';
// import 'package:wc_coin_app/screens/quiz/watch_add.dart';
// import 'package:wc_coin_app/screens/root/root_view.dart';
// import 'package:wc_coin_app/shared/custom_button.dart';
// import 'package:wc_coin_app/shared/primary_btn.dart';
// import 'package:wc_coin_app/shared/text_view.dart';

// class CongratulationsView extends StatelessWidget {
//   final int coins = 140;

//   const CongratulationsView({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // appBar: Custom,
//       backgroundColor: AppColors.fontColor,
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               // Trophy Container
//               Container(
//                 padding: const EdgeInsets.all(24),
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.white, width: 2),
//                   borderRadius: BorderRadius.circular(16),
//                   color: const Color(0xFF3F00B5),
//                 ),
//                 child: Column(
//                   children: [
//                     // Replace with your trophy asset if available
//                     Image.asset(
//                       'assets/images/trophy.png', // make sure to add this to your assets
//                       // height: 100,
//                     ),
//                     const SizedBox(height: 20),

//                     CustomText(
//                       title: "Congratulations !",
//                       fontWeight: FontWeight.bold,
//                       size: 34.fSize,
//                     ),
//                     // Text(
//                     //   'Congratulations !',
//                     //   style: GoogleFonts.poppins(
//                     //     color: Colors.white,
//                     //     fontSize: 20,
//                     //     fontWeight: FontWeight.bold,
//                     //   ),
//                     // ),
//                     const SizedBox(height: 10),
//                     // Text(
//                     //   'You get +$coins Coins',
//                     //   style: GoogleFonts.poppins(
//                     //     color: Colors.white,
//                     //     fontSize: 16,
//                     //   ),
//                     // ),
//                     CustomText(
//                       title: 'You get +$coins Coins',
//                       size: 34.fSize,
//                     )
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 40),

//               // Return to Home Button
//               // ElevatedButton(
//               //   onPressed: () {
//               //     // Navigate to Home
//               //   },
//               //   style: ElevatedButton.styleFrom(
//               //     backgroundColor: Colors.orange,
//               //     shape: RoundedRectangleBorder(
//               //       borderRadius: BorderRadius.circular(30),
//               //     ),
//               //     padding:
//               //         const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
//               //   ),
//               //   child: CustomText(
//               //     title: "Return to Home",
//               //     size: 16.fSize,
//               //     fontWeight: FontWeight.bold,
//               //   ),

//               //   //  Text(
//               //   //   'Return to Home',
//               //   //   style: GoogleFonts.poppins(
//               //   //     fontSize: 16,
//               //   //     color: Colors.white,
//               //   //     fontWeight: FontWeight.bold,
//               //   //   ),
//               //   // ),
//               // ),

//               OrangeButton(
//                 text: "Return to home",
//                 onTap: () {
//                   Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => RootView(),
//                       ));
//                 },
//               ),

//               const SizedBox(height: 16),

//               // Watch Ad Button
//               OutlinedButton.icon(
//                   onPressed: () {
//                     // Show ad logic

//                     Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => WatchAddView(),
//                         ));
//                   },
//                   style: OutlinedButton.styleFrom(
//                     backgroundColor: Colors.white,
//                     side: const BorderSide(color: Colors.white, width: 2),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
//                   ),
//                   icon: const Icon(Icons.play_circle_fill,
//                       size: 40, color: Colors.deepPurple),
//                   label: CustomText(
//                     title: "Watch ad to 2x Your Rewar",
//                     size: 22.fSize,
//                     color: Color(0xff4400CE),
//                   )

//                   //  Text(
//                   //   'Watch ad to 2x Your Reward',
//                   //   style: GoogleFonts.poppins(
//                   //     color: Colors.deepPurple,
//                   //     fontWeight: FontWeight.bold,
//                   //     fontSize: 14,
//                   //   ),
//                   // ),
//                   ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
