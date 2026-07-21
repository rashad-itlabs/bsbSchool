import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/models/auth_user_model.dart';

/// Persists the logged-in user next to the token, so the name / child name
/// survive an app restart (only the token is otherwise stored).
abstract class UserStorage {
  /// Synchronous access to the last known user (null when logged out).
  AuthUserModel? get cachedUser;

  Future<void> saveUser(AuthUserModel user);
  Future<void> clear();
}

class UserStorageImpl implements UserStorage {
  static const _userKey = 'auth_user';

  final SharedPreferences _prefs;
  AuthUserModel? _cached;

  UserStorageImpl(this._prefs) {
    _cached = _read();
  }

  @override
  AuthUserModel? get cachedUser => _cached;

  @override
  Future<void> saveUser(AuthUserModel user) async {
    _cached = user;
    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  @override
  Future<void> clear() async {
    _cached = null;
    await _prefs.remove(_userKey);
  }

  AuthUserModel? _read() {
    final raw = _prefs.getString(_userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      // Caches written before `role` was persisted would silently restore a
      // teacher as a roleless account and drop them into the student portal.
      // They're indistinguishable from a real empty role, so treat them as
      // logged out and make the user sign in again — same reasoning as
      // `AuthRepositoryImpl.isLoggedIn`.
      if (!decoded.containsKey('role')) return null;
      return AuthUserModel.fromJson(decoded);
    } on FormatException {
      return null;
    }
  }
}
