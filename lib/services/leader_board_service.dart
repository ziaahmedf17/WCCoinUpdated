import 'dart:convert';
import 'dart:io'; // Add this for SocketException
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wc_coin_app/models/leader_board_user_model.dart';

class LeaderboardService {
  static const String _baseUrl = "https://wc-admin.genwizz.com/api/leaderboard";

  Future<List<LeaderboardUser>> fetchLeaderboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) {
        throw Exception("auth_error");
      }

      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> leaderboard = data['leaderboard'];
        return leaderboard.map((e) => LeaderboardUser.fromJson(e)).toList();
      } else if (response.statusCode == 401) {
        throw Exception("auth_error");
      } else {
        throw Exception("server_error: ${response.statusCode}");
      }
    } on SocketException {
      throw Exception("No Internet");
    } on http.ClientException {
      throw Exception("network_error");
    } catch (e) {
      if (e.toString().contains("no_internet") ||
          e.toString().contains("network_error") ||
          e.toString().contains("auth_error") ||
          e.toString().contains("server_error")) {
        rethrow;
      }
      throw Exception("unknown_error: ${e.toString()}");
    }
  }
}
