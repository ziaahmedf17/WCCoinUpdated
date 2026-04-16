// lib/services/user_cache_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wc_coin_app/models/user_model.dart';

class UserCacheService {
  static const String _userKey = 'cached_user_profile';
  static const String _lastFetchKey = 'user_last_fetched';

  /// Save user to local cache
  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    await prefs.setInt(_lastFetchKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Load user from local cache (returns null if nothing cached)
  static Future<UserModel?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? json = prefs.getString(_userKey);
    if (json == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(json));
    } catch (_) {
      return null;
    }
  }

  /// Clear the cache (e.g. on logout)
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_lastFetchKey);
  }
}