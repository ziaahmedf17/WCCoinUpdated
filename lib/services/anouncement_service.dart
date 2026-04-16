import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/announcement_model.dart';

class AnnouncementService {
  static const String _baseUrl = "https://wc-admin.genwizz.com/api/announcements";

  Future<List<Announcement>> fetchAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');

    if (token == null) {
      throw Exception("No API token found in SharedPreferences");
    }

    final response = await http.get(
      Uri.parse(_baseUrl),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => Announcement.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load announcements: ${response.statusCode}");
    }
  }

  Future<Announcement> fetchSingleAnnouncement(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');

    if (token == null) {
      throw Exception("No API token found in SharedPreferences");
    }

    final response = await http.get(
      Uri.parse("$_baseUrl/$id"),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return Announcement.fromJson(data);
    } else {
      throw Exception("Failed to load announcement: ${response.statusCode}");
    }
  }
}