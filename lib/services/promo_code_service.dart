import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PromoCodeService {
  static const String baseUrl = 'https://wc-admin.genwizz.com/api';

  static Future<Map<String, dynamic>> redeemPromoCode(String promoCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      print('Making request to: $baseUrl/promocode');
      print('Promo Code: $promoCode');
      print('Token: ${token.substring(0, 10)}...');

      final requestBody = {
        'code': promoCode,
      };

      print('Request body: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/promocode'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      // Check if response is HTML (error page)
      if (response.body.trim().toLowerCase().startsWith('<!doctype') ||
          response.body.trim().toLowerCase().startsWith('<html')) {
        throw Exception(
            'Server returned HTML instead of JSON. Please check API endpoint and authentication.');
      }

      // Check if response is empty
      if (response.body.trim().isEmpty) {
        throw Exception('Empty response from server');
      }

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        throw Exception('Invalid JSON response from server');
      }

      if (response.statusCode == 200) {
        // Success response
        return {
          'success': true,
          'message': data['message'] ?? 'Promo code redeemed successfully!',
          'data': data
        };
      } else if (response.statusCode == 400) {
        // Bad request - expired promo code, invalid code, etc.
        return {
          'success': false,
          'message': data['error'] ?? data['message'] ?? 'Invalid promo code',
        };
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Promo code not found',
        };
      } else if (response.statusCode == 422) {
        // Validation error
        String errorMessage = 'Validation error';
        if (data is Map && data.containsKey('error')) {
          errorMessage = data['error'];
        } else if (data is Map && data.containsKey('message')) {
          errorMessage = data['message'];
        } else if (data is Map && data.containsKey('errors')) {
          errorMessage = data['errors'].toString();
        }
        return {
          'success': false,
          'message': errorMessage,
        };
      } else {
        return {
          'success': false,
          'message': data is Map && (data.containsKey('error') || data.containsKey('message'))
              ? (data['error'] ?? data['message'])
              : 'Failed to redeem promo code (Status: ${response.statusCode})',
        };
      }
    } on FormatException catch (e) {
      throw Exception('Invalid response format from server');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Network error: Please check your internet connection');
      }
    }
  }
}