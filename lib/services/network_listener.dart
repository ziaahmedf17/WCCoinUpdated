// Create this file: lib/core/helpers/connectivity_helper.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:wc_coin_app/core/constants/colors.dart';
import 'package:wc_coin_app/core/constants/size_utils.dart';
import 'package:wc_coin_app/shared/text_view.dart';
import 'package:wc_coin_app/shared/primary_btn.dart';

class ConnectivityHelper {
  // Singleton pattern
  static final ConnectivityHelper _instance = ConnectivityHelper._internal();
  factory ConnectivityHelper() => _instance;
  ConnectivityHelper._internal();

  /// Truly checks internet by attempting a real DNS lookup.
  /// This is the ONLY reliable way — connectivity_plus only checks
  /// if a network interface is active, not if internet is reachable.
  static Future<bool> checkInternetConnection() async {
    try {
      // Try multiple well-known hosts for reliability
      final hosts = ['google.com', 'cloudflare.com', '8.8.8.8'];

      for (final host in hosts) {
        try {
          final result = await InternetAddress.lookup(host)
              .timeout(const Duration(seconds: 5));
          if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
            return true; // Got a valid response — internet is up
          }
        } catch (_) {
          // This host failed, try the next one
          continue;
        }
      }

      // All hosts failed — truly no internet
      return false;
    } catch (e) {
      debugPrint('Error checking internet: $e');
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

  /// Check internet and show dialog if no connection.
  /// Returns true if connected, false if not.
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

  /// Listen to connectivity changes.
  /// NOTE: Use this only as a hint to trigger a real check via
  /// [checkInternetConnection], not as the final verdict.
  // static Stream<List<ConnectivityResult>> get connectivityStream =>
  //     Connectivity().onConnectivityChanged;

  /// Check if connectivity result indicates no internet.
  /// Prefer using [checkInternetConnection] over this for accuracy.
  // static bool hasNoInternet(List<ConnectivityResult> results) {
  //   return results.contains(ConnectivityResult.none) ||
  //       results.isEmpty ||
  //       (results.length == 1 && results.first == ConnectivityResult.none);
  // }
}
