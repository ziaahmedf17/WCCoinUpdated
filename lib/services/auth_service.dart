import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:math';

enum AuthError {
  userCancelled,
  networkError,
  serverError,
  firebaseError,
  deviceRestricted,
  unknownError,
}

class AuthResult {
  final bool success;
  final AuthError? error;
  final String? message;
  final String? registeredEmail; // Add this field

  AuthResult({
    required this.success,
    this.error,
    this.message,
    this.registeredEmail, // Add this parameter
  });
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<String> _generateDeviceId() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String deviceId = '';

      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

        // Use Android ID as primary identifier
        deviceId = androidInfo.id;

        // If Android ID is null/empty, try using other hardware identifiers
        if (deviceId.isEmpty || deviceId == 'unknown') {
          // Create composite ID from hardware info
          final brand = androidInfo.brand ?? 'unknown';
          final model = androidInfo.model ?? 'unknown';
          final product = androidInfo.product ?? 'unknown';
          final hardware = androidInfo.hardware ?? 'unknown';

          deviceId = '${brand}_${model}_${product}_${hardware}';
        }
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;

        // Use identifierForVendor as primary identifier
        deviceId = iosInfo.identifierForVendor ?? '';

        // If identifierForVendor is null/empty, create composite ID
        if (deviceId.isEmpty) {
          final name = iosInfo.name ?? 'iPhone';
          final model = iosInfo.model ?? 'unknown';
          final systemVersion = iosInfo.systemVersion ?? 'unknown';

          deviceId = '${name}_${model}_${systemVersion}';
        }
      } else {
        // For other platforms, throw an error instead of generating random ID
        throw UnsupportedError(
            'Device ID generation not supported on this platform');
      }

      // Validate that we have a real device ID
      if (deviceId.isEmpty || deviceId == 'unknown') {
        throw Exception('Unable to obtain real device identifier');
      }

      // Clean the ID but ensure it's not empty after cleaning
      String cleanedId =
          deviceId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '').toLowerCase();

      if (cleanedId.isEmpty) {
        throw Exception('Device ID became empty after cleaning');
      }

      // Limit length but ensure we don't create an empty string
      final maxLength = 50;
      if (cleanedId.length > maxLength) {
        cleanedId = cleanedId.substring(0, maxLength);
      }

      print('Generated real device ID: $cleanedId');
      return cleanedId;
    } catch (e) {
      print('Critical error generating device ID: $e');
      // Instead of falling back to random ID, rethrow the error
      // This way the calling code knows there's an issue
      rethrow;
    }
  }

  // Updated _getDeviceId method with better error handling
  Future<String> _getDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? deviceId = prefs.getString('device_id');

      if (deviceId == null || deviceId.isEmpty) {
        // Try to generate real device ID
        try {
          deviceId = await _generateDeviceId();
          await prefs.setString('device_id', deviceId);
          print('Stored new real device ID: $deviceId');
        } catch (e) {
          print('Failed to generate real device ID: $e');
          // Instead of generating random ID, return an error
          throw Exception('Unable to obtain device identifier: $e');
        }
      } else {
        print('Using stored device ID: $deviceId');
      }

      return deviceId;
    } catch (e) {
      print('Error in _getDeviceId: $e');
      rethrow; // Don't mask the error with a random ID
    }
  }

  // If you absolutely need a fallback (not recommended), make it explicit
  Future<String> _getDeviceIdWithFallback() async {
    try {
      return await _getDeviceId();
    } catch (e) {
      print('WARNING: Using fallback random ID due to error: $e');
      // Generate a more identifiable random ID that indicates it's a fallback
      final randomId = 'fallback_${_generateRandomId()}';

      // Optionally store this with a flag indicating it's not a real device ID
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('device_id', randomId);
      await prefs.setBool('is_fallback_device_id', true);

      return randomId;
    }
  }

  String _generateRandomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    Random random = Random();
    return List.generate(20, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  // Quick check if user has login data (without API validation)
  Future<bool> hasLoginData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      final playerId = prefs.getString('player_id');

      return token != null &&
          token.isNotEmpty &&
          playerId != null &&
          playerId.isNotEmpty;
    } catch (e) {
      print('Error checking login data: $e');
      return false;
    }
  }

  // Check if user is already logged in
  Future<bool> isUserLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      final playerId = prefs.getString('player_id');
      final user = _auth.currentUser;

      print('Checking login status...');
      print('Token exists: ${token != null && token.isNotEmpty}');
      print('Player ID exists: ${playerId != null && playerId.isNotEmpty}');
      print('Firebase user exists: ${user != null}');

      // First check if we have basic authentication data
      if (token != null &&
          token.isNotEmpty &&
          playerId != null &&
          playerId.isNotEmpty) {
        print('Basic auth data found, validating token...');

        // Validate the token with your API
        final isValid = await _validateToken(token);
        print('Token validation result: $isValid');

        if (!isValid) {
          // Clear invalid token data
          print('Token invalid, clearing stored data...');
          await _clearStoredData();
          return false;
        }

        print('User is logged in and token is valid');
        return true;
      }

      print('User is not logged in - missing auth data');
      return false;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // Validate token with your API
  Future<bool> _validateToken(String token) async {
    try {
      print('Validating token with API...');
      final response = await http.get(
        Uri.parse('https://wc-admin.genwizz.com/api/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      print('Token validation response: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('Token is valid');
        return true;
      } else if (response.statusCode == 401) {
        print('Token is expired or invalid');
        return false;
      } else {
        print('Unexpected response code: ${response.statusCode}');
        // For other status codes, assume token might be valid but API is having issues
        // We'll allow the user to stay logged in
        return true;
      }
    } catch (e) {
      print('Token validation error: $e');
      // If validation fails due to network issues, assume user is still logged in
      // This prevents logging out users when they have no internet
      return true;
    }
  }

  Future<AuthResult> signInWithGoogle() async {
    try {
      // ✅ CRITICAL FIX: Sign out from Google first to ensure account picker shows
      // This ensures that if the previous login failed, the user can select account again
      await _googleSignIn.signOut();

      // Start Google Sign-In process - this will now show the account picker
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return AuthResult(
          success: false,
          error: AuthError.userCancelled,
          message: 'Sign-in was cancelled',
        );
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      await _auth.signInWithCredential(credential);

      // Get device ID
      final deviceId = await _getDeviceId();

      // Prepare data for your API
      final name = googleUser.displayName ?? '';
      final email = googleUser.email;
      final avatar = googleUser.photoUrl ?? '';

      // Call your API with device_id parameter
      final response = await http
          .post(
            Uri.parse('https://wc-admin.genwizz.com/api/auth/google'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'email': email,
              'avatar': avatar,
              'device_id': deviceId,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Validate response data
        if (data['token'] == null) {
          // ✅ Sign out on failure so user can try again
          await _signOutGoogle();
          return AuthResult(
            success: false,
            error: AuthError.serverError,
            message: 'Invalid response from server',
          );
        }

        final token = data['token'].toString();
        final playerId = data['id']?.toString() ??
            data['user_id']?.toString() ??
            data['player_id']?.toString() ??
            '';
        final playerEmail = data['email']?.toString() ?? email;

        print('API Response data:');
        print(
            'Token: ${token.isNotEmpty ? 'EXISTS (${token.length} chars)' : 'EMPTY'}');
        print('Player ID from API: $playerId');
        print('Player Email from API: $playerEmail');

        // Save token to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('api_token', token);
        await prefs.setString('player_id', playerId);
        await prefs.setString('player_email', playerEmail);

        // Verify data was saved
        final savedToken = prefs.getString('api_token');
        final savedPlayerId = prefs.getString('player_id');
        final savedEmail = prefs.getString('player_email');

        print('Data saved to SharedPreferences:');
        print(
            'Saved Token: ${savedToken?.isNotEmpty == true ? 'EXISTS (${savedToken!.length} chars)' : 'EMPTY'}');
        print('Saved Player ID: $savedPlayerId');
        print('Saved Email: $savedEmail');

        // ✅ SUCCESS: Keep user signed in with Google
        return AuthResult(success: true);
      } else if (response.statusCode == 409) {
        // ✅ Sign out on device restriction so user can try with different account
        await _signOutGoogle();

        // Handle conflict (device restriction)
        final errorData = jsonDecode(response.body);
        final errorType = errorData['error'] ?? '';
        final registeredEmail =
            errorData['registered_email'] ?? errorData['email'];

        if (errorType == 'device_reuse_not_allowed') {
          return AuthResult(
            success: false,
            error: AuthError.deviceRestricted,
            message: errorData['message'] ??
                'This device is already registered with another email: $registeredEmail',
            registeredEmail: registeredEmail,
          );
        }

        return AuthResult(
          success: false,
          error: AuthError.serverError,
          message: errorData['message'] ?? 'Registration conflict occurred',
          registeredEmail: registeredEmail,
        );
      } else if (response.statusCode >= 500) {
        // ✅ Sign out on server error so user can try again
        await _signOutGoogle();

        return AuthResult(
          success: false,
          error: AuthError.serverError,
          message: 'Server is temporarily unavailable. Please try again later.',
        );
      } else {
        // ✅ Sign out on any other error
        await _signOutGoogle();

        final errorData = jsonDecode(response.body);
        final errorType = errorData['error'] ?? '';
        final registeredEmail =
            errorData['registered_email'] ?? errorData['email'];

        if (errorType == 'device_reuse_not_allowed') {
          return AuthResult(
            success: false,
            error: AuthError.deviceRestricted,
            message: errorData['message'] ??
                'This device is already registered with another email: $registeredEmail',
            registeredEmail: registeredEmail,
          );
        }

        return AuthResult(
          success: false,
          error: AuthError.serverError,
          message: errorData['message'] ?? 'Authentication failed',
          registeredEmail: registeredEmail,
        );
      }
    } on SocketException {
      // ✅ Sign out on network error so user can try again
      await _signOutGoogle();

      return AuthResult(
        success: false,
        error: AuthError.networkError,
        message: 'No internet connection. Please check your network.',
      );
    } on FirebaseAuthException catch (e) {
      // ✅ Sign out on Firebase error so user can try again
      await _signOutGoogle();

      String message = 'Firebase authentication failed';
      switch (e.code) {
        case 'account-exists-with-different-credential':
          message =
              'An account with this email already exists with different credentials';
          break;
        case 'invalid-credential':
          message = 'Invalid credentials provided';
          break;
        case 'operation-not-allowed':
          message = 'Google sign-in is not enabled';
          break;
        case 'user-disabled':
          message = 'This account has been disabled';
          break;
      }
      return AuthResult(
        success: false,
        error: AuthError.firebaseError,
        message: message,
      );
    } on TimeoutException {
      // ✅ Sign out on timeout so user can try again
      await _signOutGoogle();

      return AuthResult(
        success: false,
        error: AuthError.networkError,
        message: 'Connection timeout. Please try again.',
      );
    } catch (e) {
      // ✅ Sign out on any unexpected error
      await _signOutGoogle();

      print('Unexpected Google Sign-In Error: $e');
      return AuthResult(
        success: false,
        error: AuthError.unknownError,
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  // ✅ Helper method to sign out from Google and Firebase (but not clear SharedPreferences)
  Future<void> _signOutGoogle() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      print('Signed out from Google and Firebase after failed login attempt');
    } catch (e) {
      print('Error signing out from Google: $e');
    }
  }

  // Clear stored authentication data
  Future<void> _clearStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('api_token');
      await prefs.remove('player_id');
      await prefs.remove('player_email');
      // Note: We don't remove device_id as it should persist
    } catch (e) {
      print('Error clearing stored data: $e');
    }
  }

  // Sign out method (full logout)
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();

      // Clear stored authentication data
      await _clearStoredData();
    } catch (e) {
      print('Sign out error: $e');
    }
  }

  // Get current user info
  Future<Map<String, String?>> getCurrentUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'token': prefs.getString('api_token'),
        'playerId': prefs.getString('player_id'),
        'email': prefs.getString('player_email'),
        'deviceId': prefs.getString('device_id'),
      };
    } catch (e) {
      return {};
    }
  }

  // Get device ID (public method)
  Future<String> getDeviceId() async {
    return await _getDeviceId();
  }
}
