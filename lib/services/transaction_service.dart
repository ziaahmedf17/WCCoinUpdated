

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wc_coin_app/models/transaction_model.dart';

class TransactionService {
  static const String baseUrl = 'https://wc-admin.genwizz.com/api';

  static Future<List<Transaction>> getTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      print('Making request to: $baseUrl/transactions');
      print('Token: ${token.substring(0, 10)}...');

      final response = await http.get(
        Uri.parse('$baseUrl/transactions'),
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

      if (response.statusCode == 200) {
        try {
          // Handle empty response
          if (response.body.trim().isEmpty) {
            return [];
          }

          final Map<String, dynamic> responseData = jsonDecode(response.body);

          // Extract transactions array from response
          final List<dynamic> transactionsData = responseData['transactions'] ?? [];

          // Handle empty transactions array
          if (transactionsData.isEmpty) {
            return [];
          }

          return transactionsData.map((json) => Transaction.fromJson(json)).toList();
        } catch (e) {
          print('JSON parsing error: $e');
          throw Exception('Invalid JSON response from server');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        // Try to parse error message
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['message'] ??
              'Failed to load transactions. Status code: ${response.statusCode}');
        } catch (e) {
          throw Exception(
              'Failed to load transactions. Status code: ${response.statusCode}');
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



  static Future<Transaction> getTransactionById(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      print('Making request to: $baseUrl/transactions/$id');
      print('Token: ${token.substring(0, 10)}...');

      final response = await http.get(
        Uri.parse('$baseUrl/transactions/$id'),
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

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = jsonDecode(response.body);

          // Extract transaction data from response
          final Map<String, dynamic> transactionData = responseData['transaction'] ?? responseData;

          return Transaction.fromJson(transactionData);
        } catch (e) {
          print('JSON parsing error: $e');
          throw Exception('Invalid JSON response from server');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Transaction not found.');
      } else {
        // Try to parse error message
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['message'] ??
              'Failed to load transaction. Status code: ${response.statusCode}');
        } catch (e) {
          throw Exception(
              'Failed to load transaction. Status code: ${response.statusCode}');
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

}