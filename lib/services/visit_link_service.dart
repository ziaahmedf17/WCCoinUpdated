import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wc_coin_app/models/visit_link_model.dart';

class LinkService {
  static const String _url = "https://wc-admin.genwizz.com/api/link";

  Future<List<VisitLink>> fetchVisitLinks() async {
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

      if (data["links"] is List) {
        return (data["links"] as List)
            .map<VisitLink>((e) => VisitLink.fromJson(e))
            .toList();
      } else if (data["links"] is Map) {
        return [VisitLink.fromJson(data["links"])];
      }

      throw Exception("Unexpected API response format");
    } else {
      throw Exception("Failed to load links: ${response.statusCode}");
    }
  }

  Future<String> claimLinkReward(int linkId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');

    if (token == null) {
      throw Exception("No API token found in SharedPreferences");
    }

    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"link_id": linkId}),
      );

      final data = json.decode(response.body);

      // ✅ Always prefer API "message"
      final apiMessage = data["message"]?.toString() ?? "Something went wrong";

      if (response.statusCode == 200) {
        return apiMessage;
      } else {
        return apiMessage;
      }
    } catch (e) {
      // ✅ Catch also returns a readable message
      return "Error: $e";
    }
  }
}
