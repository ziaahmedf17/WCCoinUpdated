import 'dart:convert';
import 'dart:io'; // Add this for SocketException
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wc_coin_app/models/redeem_uc_pckg_model.dart';

class ApiService {
  static const String baseUrl = 'https://wc-admin.genwizz.com/api';
  static const int connectionTimeout = 30;

  static Future<List<Package>> getPackages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) {
        throw Exception('auth_error');
      }

      print('Making request to: $baseUrl/packages');
      print('Token: ${token.substring(0, 10)}...');

      final response = await http.get(
        Uri.parse('$baseUrl/packages'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: connectionTimeout));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Check if response is HTML (error page)
      if (response.body.trim().toLowerCase().startsWith('<!doctype') ||
          response.body.trim().toLowerCase().startsWith('<html')) {
        throw Exception('invalid_response');
      }

      // Check if response is empty
      if (response.body.trim().isEmpty) {
        throw Exception('empty_response');
      }

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = jsonDecode(response.body);
          return data.map((json) => Package.fromJson(json)).toList();
        } catch (e) {
          throw Exception('invalid_json');
        }
      } else if (response.statusCode == 401) {
        throw Exception('auth_error');
      } else {
        // Try to parse error message
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['message'] ??
              'Failed to load packages. Status code: ${response.statusCode}');
        } catch (e) {
          throw Exception(
              'Failed to load packages. Status code: ${response.statusCode}');
        }
      }
    } on SocketException {
      throw Exception('No Internet');
    } on http.ClientException {
      throw Exception('network_error');
    } on FormatException catch (e) {
      throw Exception('invalid_response');
    } catch (e) {
      if (e.toString().contains('No Internet') ||
          e.toString().contains('network_error') ||
          e.toString().contains('auth_error') ||
          e.toString().contains('invalid_response') ||
          e.toString().contains('empty_response') ||
          e.toString().contains('invalid_json')) {
        rethrow;
      }
      throw Exception('unknown_error: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> redeemPackage(
      int packageId, String playerId, String playerEmail) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) {
        throw Exception('auth_error');
      }

      print('Making redeem request to: $baseUrl/packageRadeem');
      print('Package ID: $packageId');
      print('Player ID: $playerId');
      print('Player Email: $playerEmail');
      print('Token: ${token.substring(0, 10)}...');

      final requestBody = {
        'package_id': packageId,
        'player_id': playerId,
        'player_email': playerEmail,
      };

      print('Request body: $requestBody');

      final response = await http
          .post(
            Uri.parse('$baseUrl/packageRadeem'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: connectionTimeout));

      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      // Check if response is HTML (error page)
      if (response.body.trim().toLowerCase().startsWith('<!doctype') ||
          response.body.trim().toLowerCase().startsWith('<html')) {
        throw Exception('invalid_response');
      }

      // Check if response is empty
      if (response.body.trim().isEmpty) {
        throw Exception('empty_response');
      }

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        throw Exception('invalid_json');
      }

      if (response.statusCode == 200) {
        // Success response
        return {
          'success': true,
          'message': data['message'] ?? 'Package redeemed successfully!',
          'data': data
        };
      } else if (response.statusCode == 400) {
        // Bad request - insufficient coins, etc.
        return {
          'success': false,
          'message': data['message'] ?? 'Unable to redeem package',
        };
      } else if (response.statusCode == 401) {
        throw Exception('auth_error');
      } else if (response.statusCode == 404) {
        throw Exception('package_not_found');
      } else if (response.statusCode == 422) {
        // Validation error
        String errorMessage = 'Validation error';
        if (data is Map && data.containsKey('message')) {
          errorMessage = data['message'];
        } else if (data is Map && data.containsKey('errors')) {
          errorMessage = data['errors'].toString();
        }
        return {
          'success': false,
          'message': errorMessage,
        };
      } else {
        throw Exception(data is Map && data.containsKey('message')
            ? data['message']
            : 'Failed to redeem package (Status: ${response.statusCode})');
      }
    } on SocketException {
      throw Exception('No Internet');
    } on http.ClientException {
      throw Exception('network_error');
    } on FormatException catch (e) {
      throw Exception('invalid_response');
    } catch (e) {
      if (e.toString().contains('No Internet') ||
          e.toString().contains('network_error') ||
          e.toString().contains('auth_error') ||
          e.toString().contains('invalid_response') ||
          e.toString().contains('empty_response') ||
          e.toString().contains('invalid_json') ||
          e.toString().contains('package_not_found')) {
        rethrow;
      }
      throw Exception('unknown_error: ${e.toString()}');
    }
  }
}
