


import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity_model.dart';

class ActivityService {
  static const String _baseUrl = "https://wc-admin.genwizz.com/api/activity";

  Future<ActivityResponse> fetchActivities({int page = 1}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');

    if (token == null) {
      throw Exception("No API token found in SharedPreferences");
    }

    final url = page > 1 ? "$_baseUrl?page=$page" : _baseUrl;

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return ActivityResponse.fromJson(jsonData);
    } else {
      throw Exception("Failed to load activities: ${response.statusCode}");
    }
  }

  // Method to get all activities (for backwards compatibility)
  Future<List<Activity>> fetchAllActivities() async {
    final response = await fetchActivities();
    return response.data;
  }
}