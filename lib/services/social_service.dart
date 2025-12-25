import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wc_coin_app/models/social_model.dart';
import 'package:wc_coin_app/shared/snackbar.dart';

/// -------------------- SERVICE --------------------
class SocialService {
  static const String _url = "https://wc-admin.genwizz.com/api/social";

  Future<List<Social>> fetchSocials() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');

    if (token == null) {
      throw Exception("No API token found in SharedPreferences");
    }

    final response = await http.get(
      Uri.parse(_url),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data["socials"] is List) {
        return (data["socials"] as List)
            .map((e) => Social.fromJson(e))
            .toList();
      } else if (data["socials"] is Map) {
        return [Social.fromJson(data["socials"])];
      }

      throw Exception("Unexpected API response format");
    } else {
      throw Exception("Failed to load socials: ${response.statusCode}");
    }
  }

  /// Claim reward API
  Future<void> claimSocialReward(int socialId, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');

    if (token == null) {
      showCustomSnackBar("No API token found", context, isError: true);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"social_id": socialId}),
      );

      final data = json.decode(response.body);

      // ✅ Always show the message from API if present
      final apiMessage = data["message"]?.toString() ?? "Something went wrong";

      if (response.statusCode == 200) {
        showCustomSnackBar(apiMessage, context, isError: false);
      } else {
        showCustomSnackBar(apiMessage, context, isError: true);
      }
    } catch (e) {
      // ✅ Show error message in catch also
      showCustomSnackBar("Error: $e", context, isError: true);
    }
  }
}
