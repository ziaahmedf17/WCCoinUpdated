import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wc_coin_app/models/reward_values_model.dart';

class RewardsService {
  static const String _baseUrl = 'https://wc-admin.genwizz.com/api/rewards';

  Future<RewardsModel> fetchRewards() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');

    if (token == null) throw Exception('No API token found');

    final response = await http.get(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return RewardsModel.fromJson(data);
    } else {
      throw Exception('Failed to load rewards: ${response.statusCode}');
    }
  }
}
