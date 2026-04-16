import 'dart:convert';
import 'dart:io'; // Add this for SocketException
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wc_coin_app/models/social_model.dart';
import 'package:wc_coin_app/shared/snackbar.dart';

/// -------------------- SERVICE --------------------
class SocialService {
  static const String _url = "https://wc-admin.genwizz.com/api/social";
  static const int connectionTimeout = 30;

  Future<List<Social>> fetchSocials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) {
        throw Exception('auth_error');
      }

      final response = await http.get(
        Uri.parse(_url),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      ).timeout(const Duration(seconds: connectionTimeout));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data["socials"] is List) {
          return (data["socials"] as List)
              .map((e) => Social.fromJson(e))
              .toList();
        } else if (data["socials"] is Map) {
          return [Social.fromJson(data["socials"])];
        }

        throw Exception('invalid_format');
      } else if (response.statusCode == 401) {
        throw Exception('auth_error');
      } else {
        throw Exception('server_error: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('No Internet');
    } on http.ClientException {
      throw Exception('network_error');
    } on FormatException {
      throw Exception('invalid_response');
    } catch (e) {
      if (e.toString().contains('no_internet') ||
          e.toString().contains('network_error') ||
          e.toString().contains('auth_error') ||
          e.toString().contains('invalid_format') ||
          e.toString().contains('invalid_response')) {
        rethrow;
      }
      throw Exception('unknown_error: ${e.toString()}');
    }
  }

  /// Claim reward API
  Future<void> claimSocialReward(int socialId, BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) {
        showCustomSnackBar(
          "Session expired. Please login again.",
          context,
          isError: true,
        );
        return;
      }

      final response = await http
          .post(
            Uri.parse(_url),
            headers: {
              "Authorization": "Bearer $token",
              "Accept": "application/json",
              "Content-Type": "application/json",
            },
            body: jsonEncode({"social_id": socialId}),
          )
          .timeout(const Duration(seconds: connectionTimeout));

      final data = json.decode(response.body);
      final apiMessage = data["message"]?.toString() ?? "Something went wrong";

      if (response.statusCode == 200) {
        showCustomSnackBar(apiMessage, context, isError: false);
      } else if (response.statusCode == 401) {
        showCustomSnackBar(
          "Session expired. Please login again.",
          context,
          isError: true,
        );
      } else {
        showCustomSnackBar(apiMessage, context, isError: true);
      }
    } on SocketException {
      showCustomSnackBar(
        "No internet connection. Please check your network and try again.",
        context,
        isError: true,
      );
    } on http.ClientException {
      showCustomSnackBar(
        "Network error. Please check your internet connection.",
        context,
        isError: true,
      );
    } catch (e) {
      String errorMsg = _getUserFriendlyMessage(e);
      showCustomSnackBar(errorMsg, context, isError: true);
    }
  }

  String _getUserFriendlyMessage(Object? error) {
    if (error == null) return 'An unknown error occurred';

    String errorStr = error.toString().toLowerCase();

    if (errorStr.contains('no_internet') ||
        errorStr.contains('network_error')) {
      return "No internet connection. Please check your network and try again.";
    } else if (errorStr.contains('auth_error')) {
      return "Session expired. Please login again.";
    } else if (errorStr.contains('invalid_format') ||
        errorStr.contains('invalid_response')) {
      return "Invalid response from server. Please try again later.";
    } else if (errorStr.contains('timeout')) {
      return "Connection timeout. Please check your internet speed.";
    }

    return error.toString().replaceAll('Exception:', '').trim();
  }
}
