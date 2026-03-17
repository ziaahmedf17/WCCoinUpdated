// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'dart:math';
//
// enum AuthError {
//   userCancelled,
//   networkError,
//   serverError,
//   firebaseError,
//   deviceRestricted,
//   unknownError,
// }
//
// class AuthResult {
//   final bool success;
//   final AuthError? error;
//   final String? message;
//   final String? registeredEmail; // Add this field
//
//   AuthResult({
//     required this.success,
//     this.error,
//     this.message,
//     this.registeredEmail, // Add this parameter
//   });
// }
//
// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final GoogleSignIn _googleSignIn = GoogleSignIn();
//
//   Future<String> _generateDeviceId() async {
//     try {
//       DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
//       String deviceId = '';
//
//       if (Platform.isAndroid) {
//         AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
//
//         // Use Android ID as primary identifier
//         deviceId = androidInfo.id;
//
//         // If Android ID is null/empty, try using other hardware identifiers
//         if (deviceId.isEmpty || deviceId == 'unknown') {
//           // Create composite ID from hardware info
//           final brand = androidInfo.brand ?? 'unknown';
//           final model = androidInfo.model ?? 'unknown';
//           final product = androidInfo.product ?? 'unknown';
//           final hardware = androidInfo.hardware ?? 'unknown';
//
//           deviceId = '${brand}_${model}_${product}_${hardware}';
//         }
//       } else if (Platform.isIOS) {
//         IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
//
//         // Use identifierForVendor as primary identifier
//         deviceId = iosInfo.identifierForVendor ?? '';
//
//         // If identifierForVendor is null/empty, create composite ID
//         if (deviceId.isEmpty) {
//           final name = iosInfo.name ?? 'iPhone';
//           final model = iosInfo.model ?? 'unknown';
//           final systemVersion = iosInfo.systemVersion ?? 'unknown';
//
//           deviceId = '${name}_${model}_${systemVersion}';
//         }
//       } else {
//         // For other platforms, throw an error instead of generating random ID
//         throw UnsupportedError(
//             'Device ID generation not supported on this platform');
//       }
//
//       // Validate that we have a real device ID
//       if (deviceId.isEmpty || deviceId == 'unknown') {
//         throw Exception('Unable to obtain real device identifier');
//       }
//
//       // Clean the ID but ensure it's not empty after cleaning
//       String cleanedId =
//           deviceId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '').toLowerCase();
//
//       if (cleanedId.isEmpty) {
//         throw Exception('Device ID became empty after cleaning');
//       }
//
//       // Limit length but ensure we don't create an empty string
//       final maxLength = 50;
//       if (cleanedId.length > maxLength) {
//         cleanedId = cleanedId.substring(0, maxLength);
//       }
//
//       print('Generated real device ID: $cleanedId');
//       return cleanedId;
//     } catch (e) {
//       print('Critical error generating device ID: $e');
//       // Instead of falling back to random ID, rethrow the error
//       // This way the calling code knows there's an issue
//       rethrow;
//     }
//   }
//
//   // Updated _getDeviceId method with better error handling
//   Future<String> _getDeviceId() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       String? deviceId = prefs.getString('device_id');
//
//       if (deviceId == null || deviceId.isEmpty) {
//         // Try to generate real device ID
//         try {
//           deviceId = await _generateDeviceId();
//           await prefs.setString('device_id', deviceId);
//           print('Stored new real device ID: $deviceId');
//         } catch (e) {
//           print('Failed to generate real device ID: $e');
//           // Instead of generating random ID, return an error
//           throw Exception('Unable to obtain device identifier: $e');
//         }
//       } else {
//         print('Using stored device ID: $deviceId');
//       }
//
//       return deviceId;
//     } catch (e) {
//       print('Error in _getDeviceId: $e');
//       rethrow; // Don't mask the error with a random ID
//     }
//   }
//
//   // If you absolutely need a fallback (not recommended), make it explicit
//   Future<String> _getDeviceIdWithFallback() async {
//     try {
//       return await _getDeviceId();
//     } catch (e) {
//       print('WARNING: Using fallback random ID due to error: $e');
//       // Generate a more identifiable random ID that indicates it's a fallback
//       final randomId = 'fallback_${_generateRandomId()}';
//
//       // Optionally store this with a flag indicating it's not a real device ID
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString('device_id', randomId);
//       await prefs.setBool('is_fallback_device_id', true);
//
//       return randomId;
//     }
//   }
//
//   String _generateRandomId() {
//     const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
//     Random random = Random();
//     return List.generate(20, (index) => chars[random.nextInt(chars.length)])
//         .join();
//   }
//
//   // Quick check if user has login data (without API validation)
//   Future<bool> hasLoginData() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('api_token');
//       final playerId = prefs.getString('player_id');
//
//       return token != null &&
//           token.isNotEmpty &&
//           playerId != null &&
//           playerId.isNotEmpty;
//     } catch (e) {
//       print('Error checking login data: $e');
//       return false;
//     }
//   }
//
//   // Check if user is already logged in
//   Future<bool> isUserLoggedIn() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('api_token');
//       final playerId = prefs.getString('player_id');
//       final user = _auth.currentUser;
//
//       print('Checking login status...');
//       print('Token exists: ${token != null && token.isNotEmpty}');
//       print('Player ID exists: ${playerId != null && playerId.isNotEmpty}');
//       print('Firebase user exists: ${user != null}');
//
//       // First check if we have basic authentication data
//       if (token != null &&
//           token.isNotEmpty &&
//           playerId != null &&
//           playerId.isNotEmpty) {
//         print('Basic auth data found, validating token...');
//
//         // Validate the token with your API
//         final isValid = await _validateToken(token);
//         print('Token validation result: $isValid');
//
//         if (!isValid) {
//           // Clear invalid token data
//           print('Token invalid, clearing stored data...');
//           await _clearStoredData();
//           return false;
//         }
//
//         print('User is logged in and token is valid');
//         return true;
//       }
//
//       print('User is not logged in - missing auth data');
//       return false;
//     } catch (e) {
//       print('Error checking login status: $e');
//       return false;
//     }
//   }
//
//   // Validate token with your API
//   Future<bool> _validateToken(String token) async {
//     try {
//       print('Validating token with API...');
//       final response = await http.get(
//         Uri.parse('https://wc-admin.genwizz.com/api/user/profile'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       ).timeout(const Duration(seconds: 10));
//
//       print('Token validation response: ${response.statusCode}');
//
//       if (response.statusCode == 200) {
//         print('Token is valid');
//         return true;
//       } else if (response.statusCode == 401) {
//         print('Token is expired or invalid');
//         return false;
//       } else {
//         print('Unexpected response code: ${response.statusCode}');
//         // For other status codes, assume token might be valid but API is having issues
//         // We'll allow the user to stay logged in
//         return true;
//       }
//     } catch (e) {
//       print('Token validation error: $e');
//       // If validation fails due to network issues, assume user is still logged in
//       // This prevents logging out users when they have no internet
//       return true;
//     }
//   }
//
//   Future<AuthResult> signInWithGoogle() async {
//     try {
//       // ✅ CRITICAL FIX: Sign out from Google first to ensure account picker shows
//       // This ensures that if the previous login failed, the user can select account again
//       await _googleSignIn.signOut();
//
//       // Start Google Sign-In process - this will now show the account picker
//       final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
//
//       if (googleUser == null) {
//         return AuthResult(
//           success: false,
//           error: AuthError.userCancelled,
//           message: 'Sign-in was cancelled',
//         );
//       }
//
//       final GoogleSignInAuthentication googleAuth =
//           await googleUser.authentication;
//
//       final credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );
//
//       // Sign in to Firebase
//       await _auth.signInWithCredential(credential);
//
//       // Get device ID
//       final deviceId = await _getDeviceId();
//
//       // Prepare data for your API
//       final name = googleUser.displayName ?? '';
//       final email = googleUser.email;
//       final avatar = googleUser.photoUrl ?? '';
//
//       // Call your API with device_id parameter
//       final response = await http
//           .post(
//             Uri.parse('https://wc-admin.genwizz.com/api/auth/google'),
//             headers: {'Content-Type': 'application/json'},
//             body: jsonEncode({
//               'name': name,
//               'email': email,
//               'avatar': avatar,
//               'device_id': deviceId,
//             }),
//           )
//           .timeout(const Duration(seconds: 15));
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//
//         // Validate response data
//         if (data['token'] == null) {
//           // ✅ Sign out on failure so user can try again
//           await _signOutGoogle();
//           return AuthResult(
//             success: false,
//             error: AuthError.serverError,
//             message: 'Invalid response from server',
//           );
//         }
//
//         final token = data['token'].toString();
//         final playerId = data['id']?.toString() ??
//             data['user_id']?.toString() ??
//             data['player_id']?.toString() ??
//             '';
//         final playerEmail = data['email']?.toString() ?? email;
//
//         print('API Response data:');
//         print(
//             'Token: ${token.isNotEmpty ? 'EXISTS (${token.length} chars)' : 'EMPTY'}');
//         print('Player ID from API: $playerId');
//         print('Player Email from API: $playerEmail');
//
//         // Save token to SharedPreferences
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.setString('api_token', token);
//         await prefs.setString('player_id', playerId);
//         await prefs.setString('player_email', playerEmail);
//
//         // Verify data was saved
//         final savedToken = prefs.getString('api_token');
//         final savedPlayerId = prefs.getString('player_id');
//         final savedEmail = prefs.getString('player_email');
//
//         print('Data saved to SharedPreferences:');
//         print(
//             'Saved Token: ${savedToken?.isNotEmpty == true ? 'EXISTS (${savedToken!.length} chars)' : 'EMPTY'}');
//         print('Saved Player ID: $savedPlayerId');
//         print('Saved Email: $savedEmail');
//
//         // ✅ SUCCESS: Keep user signed in with Google
//         return AuthResult(success: true);
//       } else if (response.statusCode == 409) {
//         // ✅ Sign out on device restriction so user can try with different account
//         await _signOutGoogle();
//
//         // Handle conflict (device restriction)
//         final errorData = jsonDecode(response.body);
//         final errorType = errorData['error'] ?? '';
//         final registeredEmail =
//             errorData['registered_email'] ?? errorData['email'];
//
//         if (errorType == 'device_reuse_not_allowed') {
//           return AuthResult(
//             success: false,
//             error: AuthError.deviceRestricted,
//             message: errorData['message'] ??
//                 'This device is already registered with another email: $registeredEmail',
//             registeredEmail: registeredEmail,
//           );
//         }
//
//         return AuthResult(
//           success: false,
//           error: AuthError.serverError,
//           message: errorData['message'] ?? 'Registration conflict occurred',
//           registeredEmail: registeredEmail,
//         );
//       } else if (response.statusCode >= 500) {
//         // ✅ Sign out on server error so user can try again
//         await _signOutGoogle();
//
//         return AuthResult(
//           success: false,
//           error: AuthError.serverError,
//           message: 'Server is temporarily unavailable. Please try again later.',
//         );
//       } else {
//         // ✅ Sign out on any other error
//         await _signOutGoogle();
//
//         final errorData = jsonDecode(response.body);
//         final errorType = errorData['error'] ?? '';
//         final registeredEmail =
//             errorData['registered_email'] ?? errorData['email'];
//
//         if (errorType == 'device_reuse_not_allowed') {
//           return AuthResult(
//             success: false,
//             error: AuthError.deviceRestricted,
//             message: errorData['message'] ??
//                 'This device is already registered with another email: $registeredEmail',
//             registeredEmail: registeredEmail,
//           );
//         }
//
//         return AuthResult(
//           success: false,
//           error: AuthError.serverError,
//           message: errorData['message'] ?? 'Authentication failed',
//           registeredEmail: registeredEmail,
//         );
//       }
//     } on SocketException {
//       // ✅ Sign out on network error so user can try again
//       await _signOutGoogle();
//
//       return AuthResult(
//         success: false,
//         error: AuthError.networkError,
//         message: 'No internet connection. Please check your network.',
//       );
//     } on FirebaseAuthException catch (e) {
//       // ✅ Sign out on Firebase error so user can try again
//       await _signOutGoogle();
//
//       String message = 'Firebase authentication failed';
//       switch (e.code) {
//         case 'account-exists-with-different-credential':
//           message =
//               'An account with this email already exists with different credentials';
//           break;
//         case 'invalid-credential':
//           message = 'Invalid credentials provided';
//           break;
//         case 'operation-not-allowed':
//           message = 'Google sign-in is not enabled';
//           break;
//         case 'user-disabled':
//           message = 'This account has been disabled';
//           break;
//       }
//       return AuthResult(
//         success: false,
//         error: AuthError.firebaseError,
//         message: message,
//       );
//     } on TimeoutException {
//       // ✅ Sign out on timeout so user can try again
//       await _signOutGoogle();
//
//       return AuthResult(
//         success: false,
//         error: AuthError.networkError,
//         message: 'Connection timeout. Please try again.',
//       );
//     } catch (e) {
//       // ✅ Sign out on any unexpected error
//       await _signOutGoogle();
//
//       print('Unexpected Google Sign-In Error: $e');
//       return AuthResult(
//         success: false,
//         error: AuthError.unknownError,
//         message: 'An unexpected error occurred. Please try again.',
//       );
//     }
//   }
//
//   // ✅ Helper method to sign out from Google and Firebase (but not clear SharedPreferences)
//   Future<void> _signOutGoogle() async {
//     try {
//       await _auth.signOut();
//       await _googleSignIn.signOut();
//       print('Signed out from Google and Firebase after failed login attempt');
//     } catch (e) {
//       print('Error signing out from Google: $e');
//     }
//   }
//
//   // Clear stored authentication data
//   Future<void> _clearStoredData() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.remove('api_token');
//       await prefs.remove('player_id');
//       await prefs.remove('player_email');
//       // Note: We don't remove device_id as it should persist
//     } catch (e) {
//       print('Error clearing stored data: $e');
//     }
//   }
//
//   // Sign out method (full logout)
//   Future<void> signOut() async {
//     try {
//       await _auth.signOut();
//       await _googleSignIn.signOut();
//
//       // Clear stored authentication data
//       await _clearStoredData();
//     } catch (e) {
//       print('Sign out error: $e');
//     }
//   }
//
//   // Get current user info
//   Future<Map<String, String?>> getCurrentUserInfo() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       return {
//         'token': prefs.getString('api_token'),
//         'playerId': prefs.getString('player_id'),
//         'email': prefs.getString('player_email'),
//         'deviceId': prefs.getString('device_id'),
//       };
//     } catch (e) {
//       return {};
//     }
//   }
//
//   // Get device ID (public method)
//   Future<String> getDeviceId() async {
//     return await _getDeviceId();
//   }
// }

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:device_info_plus/device_info_plus.dart';
import 'dart:math';

// Import your User model
import '../models/user_model.dart';
import '../screens/login/model/user_model.dart';

enum AuthError {
  none,
  userCancelled,
  networkError,
  serverError,
  firebaseError,
  deviceRestricted,
  invalidCredentials,
  invalidOtp,
  validationError,
  unknownError,
}

class AuthResult {
  final bool success;
  final AuthError? error;
  final String? message;
  final String? registeredEmail;
  final User? user;
  final String? token;
  final bool? isNewUser;
  final Map<String, dynamic>? validationErrors;

  AuthResult({
    required this.success,
    this.error,
    this.message,
    this.registeredEmail,
    this.user,
    this.token,
    this.isNewUser,
    this.validationErrors,
  });
}

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  static const String baseUrl = 'https://wc-admin.genwizz.com/api/auth';

  // ==================== DEVICE ID METHODS (YOUR EXISTING CODE) ====================

  // Future<String> _generateDeviceId() async {
  //   try {
  //     DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  //     String deviceId = '';

  //     if (Platform.isAndroid) {
  //       AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

  //       // Use Android ID as primary identifier
  //       deviceId = androidInfo.id;

  //       // If Android ID is null/empty, try using other hardware identifiers
  //       if (deviceId.isEmpty || deviceId == 'unknown') {
  //         // Create composite ID from hardware info
  //         final brand = androidInfo.brand ?? 'unknown';
  //         final model = androidInfo.model ?? 'unknown';
  //         final product = androidInfo.product ?? 'unknown';
  //         final hardware = androidInfo.hardware ?? 'unknown';

  //         deviceId = '${brand}_${model}_${product}_${hardware}';
  //       }
  //     } else if (Platform.isIOS) {
  //       IosDeviceInfo iosInfo = await deviceInfo.iosInfo;

  //       // Use identifierForVendor as primary identifier
  //       deviceId = iosInfo.identifierForVendor ?? '';

  //       // If identifierForVendor is null/empty, create composite ID
  //       if (deviceId.isEmpty) {
  //         final name = iosInfo.name ?? 'iPhone';
  //         final model = iosInfo.model ?? 'unknown';
  //         final systemVersion = iosInfo.systemVersion ?? 'unknown';

  //         deviceId = '${name}_${model}_${systemVersion}';
  //       }
  //     } else {
  //       // For other platforms, throw an error instead of generating random ID
  //       throw UnsupportedError(
  //           'Device ID generation not supported on this platform');
  //     }

  //     // Validate that we have a real device ID
  //     if (deviceId.isEmpty || deviceId == 'unknown') {
  //       throw Exception('Unable to obtain real device identifier');
  //     }

  //     // Clean the ID but ensure it's not empty after cleaning
  //     String cleanedId =
  //         deviceId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '').toLowerCase();

  //     if (cleanedId.isEmpty) {
  //       throw Exception('Device ID became empty after cleaning');
  //     }

  //     // Limit length but ensure we don't create an empty string
  //     final maxLength = 50;
  //     if (cleanedId.length > maxLength) {
  //       cleanedId = cleanedId.substring(0, maxLength);
  //     }

  //     print('Generated real device ID: $cleanedId');
  //     return cleanedId;
  //   } catch (e) {
  //     print('Critical error generating device ID: $e');
  //     // Instead of falling back to random ID, rethrow the error
  //     // This way the calling code knows there's an issue
  //     rethrow;
  //   }
  // }

  // // Updated _getDeviceId method with better error handling
  // Future<String> _getDeviceId() async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     String? deviceId = prefs.getString('device_id');

  //     if (deviceId == null || deviceId.isEmpty) {
  //       // Try to generate real device ID
  //       try {
  //         deviceId = await _generateDeviceId();
  //         await prefs.setString('device_id', deviceId);
  //         print('Stored new real device ID: $deviceId');
  //       } catch (e) {
  //         print('Failed to generate real device ID: $e');
  //         // Instead of generating random ID, return an error
  //         throw Exception('Unable to obtain device identifier: $e');
  //       }
  //     } else {
  //       print('Using stored device ID: $deviceId');
  //     }

  //     return deviceId;
  //   } catch (e) {
  //     print('Error in _getDeviceId: $e');
  //     rethrow; // Don't mask the error with a random ID
  //   }
  // }

  // // If you absolutely need a fallback (not recommended), make it explicit
  // Future<String> _getDeviceIdWithFallback() async {
  //   try {
  //     return await _getDeviceId();
  //   } catch (e) {
  //     print('WARNING: Using fallback random ID due to error: $e');
  //     // Generate a more identifiable random ID that indicates it's a fallback
  //     final randomId = 'fallback_${_generateRandomId()}';

  //     // Optionally store this with a flag indicating it's not a real device ID
  //     final prefs = await SharedPreferences.getInstance();
  //     await prefs.setString('device_id', randomId);
  //     await prefs.setBool('is_fallback_device_id', true);

  //     return randomId;
  //   }
  // }

  String _generateRandomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    Random random = Random();
    return List.generate(20, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  // // Get device ID (public method)
  // Future<String> getDeviceId() async {
  //   return await _getDeviceId();
  // }

  // ==================== TOKEN MANAGEMENT METHODS ====================

  // Save token to shared preferences
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_token', token);
  }

  // Save user data to shared preferences
  Future<void> _saveUserData(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(user.toJson()));
    await prefs.setString('player_id', user.id.toString());
    await prefs.setString('player_email', user.email);
  }

  // Get saved token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_token');
  }

  // Get saved user data
  Future<User?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }
    return null;
  }

  // ==================== LOGIN STATUS METHODS (YOUR EXISTING CODE) ====================

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
      final firebaseUser = _auth.currentUser;

      print('Checking login status...');
      print('Token exists: ${token != null && token.isNotEmpty}');
      print('Player ID exists: ${playerId != null && playerId.isNotEmpty}');
      print('Firebase user exists: ${firebaseUser != null}');

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

  // Check if user is logged in (alias for compatibility)
  Future<bool> isLoggedIn() async {
    return await isUserLoggedIn();
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

  // ==================== FORM REGISTRATION METHOD ====================

  Future<AuthResult> registerWithForm({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      print(response.statusCode);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true) {
          final user = User.fromJson(data['user']);
          final token = data['token'];

          // Save token and user data
          await _saveToken(token);
          await _saveUserData(user);

          return AuthResult(
            success: true,
            message: data['message'] ?? 'Registration successful',
            user: user,
            token: token,
            isNewUser: data['is_new_user'] ?? true,
          );
        }
      }

      // Handle validation errors
      if (response.statusCode == 422) {
        return AuthResult(
          success: false,
          message: data['message'] ?? 'Validation failed',
          error: AuthError.validationError,
          validationErrors: data['errors'],
        );
      }

      // Handle device restriction
      if (response.statusCode == 409) {
        final errorType = data['error'] ?? '';
        final registeredEmail = data['registered_email'] ?? data['email'];

        if (errorType == 'device_reuse_not_allowed') {
          return AuthResult(
            success: false,
            error: AuthError.deviceRestricted,
            message: data['message'] ??
                'This device is already registered with another email',
            registeredEmail: registeredEmail,
          );
        }
      }

      return AuthResult(
        success: false,
        message: data['message'] ?? 'Registration failed',
        error: AuthError.serverError,
      );
    } on SocketException {
      return AuthResult(
        success: false,
        message: 'No internet connection. Please check your network.',
        error: AuthError.networkError,
      );
    } catch (e) {
      print('Registration error: $e');
      return AuthResult(
        success: false,
        message: 'Network error: ${e.toString()}',
        error: AuthError.networkError,
      );
    }
  }

  // ==================== FORM LOGIN METHOD ====================

  Future<AuthResult> signInWithForm({
    required String email,
    required String password,
  }) async {
    try {
      // Get device ID
      // final deviceId = await _getDeviceId();

      final response = await http.post(
        Uri.parse('$baseUrl/signin'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['success'] == true) {
          final user = User.fromJson(data['user']);
          final token = data['token'];

          // Save token and user data
          await _saveToken(token);
          await _saveUserData(user);

          print(data['message']);
          print("token");
          print(user.toString());
          return AuthResult(
            success: true,
            message: data['message'] ?? 'Login successful',
            user: user,
            token: token,
            isNewUser: data['is_new_user'] ?? false,
          );
        }
      }

      // Handle validation errors
      if (response.statusCode == 422) {
        return AuthResult(
          success: false,
          message: data['message'] ?? 'Validation failed',
          error: AuthError.validationError,
          validationErrors: data['errors'],
        );
      }

      // Handle invalid credentials
      if (response.statusCode == 401) {
        return AuthResult(
          success: false,
          message: data['message'] ?? 'Invalid email or password',
          error: AuthError.invalidCredentials,
        );
      }

      // Handle device restriction
      if (response.statusCode == 409) {
        final errorType = data['error'] ?? '';
        final registeredEmail = data['registered_email'] ?? data['email'];

        if (errorType == 'device_reuse_not_allowed') {
          return AuthResult(
            success: false,
            error: AuthError.deviceRestricted,
            message: data['message'] ??
                'This device is already registered with another email',
            registeredEmail: registeredEmail,
          );
        }
      }

      return AuthResult(
        success: false,
        message: data['message'] ?? 'Login failed',
        error: AuthError.serverError,
      );
    } on SocketException {
      return AuthResult(
        success: false,
        message: 'No internet connection. Please check your network.',
        error: AuthError.networkError,
      );
    } catch (e) {
      print('Login error: $e');
      return AuthResult(
        success: false,
        message: 'Network error: ${e.toString()}',
        error: AuthError.networkError,
      );
    }
  }

  // ==================== FORGOT PASSWORD METHOD ====================

  Future<AuthResult> forgotPassword({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['success'] == true) {
          return AuthResult(
            success: true,
            message:
                data['message'] ?? 'OTP has been sent to your email address.',
          );
        }
      }

      return AuthResult(
        success: false,
        message: data['message'] ?? 'Failed to send OTP',
        error: AuthError.serverError,
      );
    } on SocketException {
      return AuthResult(
        success: false,
        message: 'No internet connection. Please check your network.',
        error: AuthError.networkError,
      );
    } catch (e) {
      print('Forgot password error: $e');
      return AuthResult(
        success: false,
        message: 'Network error: ${e.toString()}',
        error: AuthError.networkError,
      );
    }
  }

  // ==================== RESET PASSWORD METHOD ====================

  Future<AuthResult> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['success'] == true) {
          return AuthResult(
            success: true,
            message: data['message'] ?? 'Password reset successful',
          );
        }
      }

      // Handle invalid OTP
      if (response.statusCode == 400 || response.statusCode == 422) {
        return AuthResult(
          success: false,
          message: data['message'] ??
              'Invalid or expired OTP. Please request a new one.',
          error: AuthError.invalidOtp,
        );
      }

      return AuthResult(
        success: false,
        message: data['message'] ?? 'Password reset failed',
        error: AuthError.serverError,
      );
    } on SocketException {
      return AuthResult(
        success: false,
        message: 'No internet connection. Please check your network.',
        error: AuthError.networkError,
      );
    } catch (e) {
      print('Reset password error: $e');
      return AuthResult(
        success: false,
        message: 'Network error: ${e.toString()}',
        error: AuthError.networkError,
      );
    }
  }

  // ==================== GOOGLE SIGN-IN METHOD (YOUR EXISTING CODE) ====================

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

      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      await _auth.signInWithCredential(credential);

      // Get device ID
      // final deviceId = await _getDeviceId();

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
              // 'device_id': deviceId,
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
    } on firebase_auth.FirebaseAuthException catch (e) {
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

  // ==================== HELPER METHODS ====================

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
      await prefs.remove('user_data');
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

  // Logout (alias for compatibility)
  Future<void> logout() async {
    await signOut();
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
}
