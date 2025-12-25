import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quiz_model.dart';
import '../shared/snackbar.dart';

/// -------------------- SERVICE --------------------
class QuizService {
  static const String _url = "https://wc-admin.genwizz.com/api/quizzes";

  Future<List<Quiz>> fetchQuizzes(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');

    if (token == null) {
      throw Exception("No API token found");
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

      if (data is Map<String, dynamic> && data.containsKey("quizzes")) {
        final List quizzes = data["quizzes"];
        return quizzes.map((e) => Quiz.fromJson(e)).toList();
      } else {
        throw Exception("Unexpected API response format: $data");
      }
    } else {
      throw Exception("Failed to load quizzes: ${response.statusCode}");
    }
  }

  Future<Map<String, dynamic>> submitAnswer(
      int quizId, int optionId, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');

    if (token == null) {
      throw Exception("No API token found");
    }

    final response = await http.post(
      Uri.parse(_url),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: json.encode({"quiz_id": quizId, "option_id": optionId}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // ✅ Show API message in snackbar
      if (data["message"] != null) {
        showCustomSnackBar(data["message"], context, isError: false);
      }

      return data;
    } else {
      final data = json.decode(response.body);

      if (data["message"] != 'Correct answer') {
        showCustomSnackBar(data["message"], context, isError: true);
      }
      throw Exception("Failed to submit answer: ${response.statusCode}");
    }
  }
}
