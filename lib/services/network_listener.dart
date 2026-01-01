// Create this file: lib/core/helpers/connectivity_helper.dart

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:wc_coin_app/core/constants/colors.dart';
import 'package:wc_coin_app/core/constants/size_utils.dart';
import 'package:wc_coin_app/shared/text_view.dart';
import 'package:wc_coin_app/shared/primary_btn.dart';

class ConnectivityHelper {
  // Singleton pattern
  static final ConnectivityHelper _instance = ConnectivityHelper._internal();
  factory ConnectivityHelper() => _instance;
  ConnectivityHelper._internal();

  /// Check if device has internet connection
  static Future<bool> checkInternetConnection() async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult.contains(ConnectivityResult.mobile)) {
        return true;
      } else if (connectivityResult.contains(ConnectivityResult.wifi)) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error checking internet: $e');
      return false;
    }
  }

  /// Show no internet dialog
  static Future<void> showNoInternetDialog(
    BuildContext context, {
    VoidCallback? onRetry,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 100,
          backgroundColor: AppColors.bgColor,
          content: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Gap.v(20),
              Icon(
                Icons.wifi_off_rounded,
                size: 80.v,
                color: Colors.red.shade400,
              ),
              Gap.v(20),
              const CustomText(
                title: 'No Internet',
                fontWeight: FontWeight.bold,
                size: 28,
                color: AppColors.fontColor,
              ),
              Gap.v(15),
              const CustomText(
                title: 'Please check your network settings\nand try again',
                alignment: TextAlign.center,
                size: 16,
                color: AppColors.fontColor,
              ),
              Gap.v(25),
              PrimaryBTN(
                onCLick: () {
                  Navigator.of(context).pop();
                  if (onRetry != null) {
                    onRetry();
                  }
                },
                buttonTitle: 'Retry',
                btColor: AppColors.secondary,
              ),
              Gap.v(10),
            ],
          ),
        );
      },
    );
  }

  /// Check internet and show dialog if no connection
  /// Returns true if connected, false if not
  static Future<bool> checkAndShowDialog(
    BuildContext context, {
    VoidCallback? onRetry,
  }) async {
    bool hasInternet = await checkInternetConnection();
    if (!hasInternet) {
      if (context.mounted) {
        await showNoInternetDialog(context, onRetry: onRetry);
      }
    }
    return hasInternet;
  }

  /// Listen to connectivity changes
  static Stream<List<ConnectivityResult>> get connectivityStream =>
      Connectivity().onConnectivityChanged;

  /// Check if connectivity result indicates no internet
  static bool hasNoInternet(List<ConnectivityResult> results) {
    return results.contains(ConnectivityResult.none) ||
        results.isEmpty ||
        (results.length == 1 && results.first == ConnectivityResult.none);
  }
}
