import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class UserService {
  Future<void> updateProfile(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');

    final response = await http
        .post(
          Uri.parse('https://wc-admin.genwizz.com/api/profile'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'name': name}),
        )
        .timeout(const Duration(seconds: 30));

    // Debug logs
    print('updateProfile -> status: ${response.statusCode}');
    print('updateProfile -> body: ${response.body}');

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception('Unauthorized (401). Token may be invalid or expired.');
      }
      throw Exception('Failed to update profile: ${response.statusCode}');
    }

    // tolerate different response shapes after update
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        // If API returns { success: true, ... }
        if (data.containsKey('success')) {
          if (data['success'] == true) return;
          throw Exception('Update failed: server returned success=false');
        }
        // If API returns updated user object or { user: {...} }
        if (data.containsKey('user') ||
            (data.containsKey('id') && data.containsKey('email'))) {
          return;
        }
        throw Exception(
            'Update failed: unexpected response structure: ${data.keys.toList()}');
      } else {
        throw Exception('Update failed: response JSON is not an object');
      }
    } catch (e) {
      throw Exception(
          'Update failed: could not parse response (${e.toString()})');
    }
  }

  Future<UserModel?> fetchProfile() async {
    // ✅ NO try-catch wrapper here — let SocketException, TimeoutException,
    // etc. bubble up naturally so home_view.dart can catch them correctly.

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');

    if (token == null) {
      throw Exception('Token not found');
    }

    final response = await http.get(
      Uri.parse('https://wc-admin.genwizz.com/api/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    ).timeout(
        const Duration(seconds: 30)); // ✅ increased timeout for mobile data

    // Debug logs - will help you see what the server actually returned
    print('fetchProfile -> status: ${response.statusCode}');
    print('fetchProfile -> body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Defensive parsing: many APIs use different shapes
      if (data is Map<String, dynamic>) {
        // Case A: { success: true, user: {...} }
        if (data.containsKey('success')) {
          if (data['success'] == true) {
            if (data.containsKey('user')) {
              return UserModel.fromJson(data); // our model handles 'user'
            }
            // some APIs nest under 'data'
            if (data.containsKey('data') &&
                data['data'] is Map<String, dynamic>) {
              return UserModel.fromJson(data['data']);
            }
            // if success true but user not found - return helpful error
            throw Exception(
                'Server returned success=true but no user object found: ${response.body}');
          } else {
            throw Exception('Server returned success=false: ${response.body}');
          }
        }

        // Case B: { user: {...} } (no success flag)
        if (data.containsKey('user')) {
          return UserModel.fromJson(data); // userModel handles nested user
        }

        // Case C: response is the user object directly: { id: ..., email: ... }
        if (data.containsKey('id') && data.containsKey('email')) {
          return UserModel.fromJson(data);
        }

        // Unexpected structure
        throw Exception('Unexpected response structure: ${data.keys.toList()}');
      } else {
        throw Exception(
            'Invalid JSON structure: expected a JSON object, got ${data.runtimeType}');
      }
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized (401). Token may be invalid or expired.');
    } else {
      throw Exception(
          'Failed to fetch profile: ${response.statusCode} ${response.body}');
    }
  }
}
