import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wc_coin_app/models/leader_board_user_model.dart';

class LeaderboardService {
  static const String _baseUrl = "https://wc-admin.genwizz.com/api/leaderboard";

  Future<List<LeaderboardUser>> fetchLeaderboard() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');

    if (token == null) {
      throw Exception("No API token found in shared preferences");
    }

    final response = await http.get(
      Uri.parse(_baseUrl),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> leaderboard = data['leaderboard'];

      return leaderboard.map((e) => LeaderboardUser.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load leaderboard: ${response.statusCode}");
    }
  }
}
