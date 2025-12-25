// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:wc_coin_app/models/redeem_uc_pckg_model.dart';

// class ApiService {
//   static const String baseUrl = 'https://wc-admin.genwizz.com/api';

//   static Future<List<Package>> getPackages() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('api_token');

//       if (token == null) {
//         throw Exception('No authentication token found');
//       }

//       print('Making request to: $baseUrl/packages');
//       print('Token: ${token.substring(0, 10)}...');

//       final response = await http.get(
//         Uri.parse('$baseUrl/packages'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//       );

//       print('Response status: ${response.statusCode}');
//       print('Response body: ${response.body}');

//       // Check if response is HTML (error page)
//       if (response.body.trim().toLowerCase().startsWith('<!doctype') ||
//           response.body.trim().toLowerCase().startsWith('<html')) {
//         throw Exception(
//             'Server returned HTML instead of JSON. Please check API endpoint and authentication.');
//       }

//       // Check if response is empty
//       if (response.body.trim().isEmpty) {
//         throw Exception('Empty response from server');
//       }

//       if (response.statusCode == 200) {
//         try {
//           final List<dynamic> data = jsonDecode(response.body);
//           return data.map((json) => Package.fromJson(json)).toList();
//         } catch (e) {
//           throw Exception('Invalid JSON response from server');
//         }
//       } else if (response.statusCode == 401) {
//         throw Exception('Authentication failed. Please login again.');
//       } else {
//         // Try to parse error message
//         try {
//           final errorData = jsonDecode(response.body);
//           throw Exception(errorData['message'] ??
//               'Failed to load packages. Status code: ${response.statusCode}');
//         } catch (e) {
//           throw Exception(
//               'Failed to load packages. Status code: ${response.statusCode}');
//         }
//       }
//     } on FormatException catch (e) {
//       throw Exception('Invalid response format from server');
//     } catch (e) {
//       if (e is Exception) {
//         rethrow;
//       } else {
//         throw Exception('Network error: Please check your internet connection');
//       }
//     }
//   }

//   static Future<Map<String, dynamic>> redeemPackage(int packageId) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('api_token');
//       final playerId = prefs.getString('player_id');
//       final playerEmail = prefs.getString('player_email');

//       if (token == null) {
//         throw Exception('No authentication token found');
//       }

//       if (playerId == null) {
//         throw Exception('Player ID not found. Please login again.');
//       }

//       if (playerEmail == null) {
//         throw Exception('Player email not found. Please login again.');
//       }

//       print('Making redeem request to: $baseUrl/packageRadeem');
//       print('Package ID: $packageId');
//       print('Player ID: $playerId');
//       print('Player Email: $playerEmail');
//       print('Token: ${token.substring(0, 10)}...');

//       final requestBody = {
//         'package_id': packageId,
//         'player_id': playerId,
//         'player_email': playerEmail,
//       };

//       print('Request body: $requestBody');

//       final response = await http.post(
//         Uri.parse('$baseUrl/packageRadeem'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',

//         },
//         body: jsonEncode(requestBody),
//       );

//       print('Response status: ${response.statusCode}');
//       print('Response headers: ${response.headers}');
//       print('Response body: ${response.body}');

//       // Check if response is HTML (error page)
//       if (response.body.trim().toLowerCase().startsWith('<!doctype') ||
//           response.body.trim().toLowerCase().startsWith('<html')) {
//         throw Exception(
//             'Server returned HTML instead of JSON. Please check API endpoint and authentication.');
//       }

//       // Check if response is empty
//       if (response.body.trim().isEmpty) {
//         throw Exception('Empty response from server');
//       }

//       dynamic data;
//       try {
//         data = jsonDecode(response.body);
//       } catch (e) {
//         throw Exception('Invalid JSON response from server');
//       }

//       if (response.statusCode == 200) {
//         // Success response
//         return {
//           'success': true,
//           'message': data['message'] ?? 'Package redeemed successfully!',
//           'data': data
//         };
//       } else if (response.statusCode == 400) {
//         // Bad request - insufficient coins, etc.
//         return {
//           'success': false,
//           'message': data['message'] ?? 'Unable to redeem package',
//         };
//       } else if (response.statusCode == 401) {
//         throw Exception('Authentication failed. Please login again.');
//       } else if (response.statusCode == 404) {
//         throw Exception('Package not found');
//       } else if (response.statusCode == 422) {
//         // Validation error
//         String errorMessage = 'Validation error';
//         if (data is Map && data.containsKey('message')) {
//           errorMessage = data['message'];
//         } else if (data is Map && data.containsKey('errors')) {
//           errorMessage = data['errors'].toString();
//         }
//         return {
//           'success': false,
//           'message': errorMessage,
//         };
//       } else {
//         throw Exception(data is Map && data.containsKey('message')
//             ? data['message']
//             : 'Failed to redeem package (Status: ${response.statusCode})');
//       }
//     } on FormatException catch (e) {
//       throw Exception('Invalid response format from server');
//     } catch (e) {
//       if (e is Exception) {
//         rethrow;
//       } else {
//         throw Exception('Network error: Please check your internet connection');
//       }
//     }
//   }
// }


import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wc_coin_app/models/redeem_uc_pckg_model.dart';

class ApiService {
  static const String baseUrl = 'https://wc-admin.genwizz.com/api';

  static Future<List<Package>> getPackages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) {
        throw Exception('No authentication token found');
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
      );

      print('Response status: ${response.statusCode}');
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

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = jsonDecode(response.body);
          return data.map((json) => Package.fromJson(json)).toList();
        } catch (e) {
          throw Exception('Invalid JSON response from server');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
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

  static Future<Map<String, dynamic>> redeemPackage(int packageId, String playerId, String playerEmail) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) {
        throw Exception('No authentication token found');
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

      final response = await http.post(
        Uri.parse('$baseUrl/packageRadeem'),
        headers: {
          'Authorization': 'Bearer $token',
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
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Package not found');
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