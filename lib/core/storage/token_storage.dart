import 'package:shared_preferences/shared_preferences.dart';

/// Persists the API auth token and keeps an in-memory copy so interceptors
/// can attach it to every request without an async read.
abstract class TokenStorage {
  /// Synchronous access to the last known token (null when logged out).
  String? get cachedToken;

  bool get hasToken;

  Future<void> saveToken(String token);
  Future<void> clear();
}

class TokenStorageImpl implements TokenStorage {
  static const _tokenKey = 'auth_token';

  final SharedPreferences _prefs;
  String? _cached;

  TokenStorageImpl(this._prefs) {
    _cached = _prefs.getString(_tokenKey);
  }

  @override
  String? get cachedToken => _cached;

  @override
  bool get hasToken => _cached != null && _cached!.isNotEmpty;

  @override
  Future<void> saveToken(String token) async {
    _cached = token;
    await _prefs.setString(_tokenKey, token);
  }

  @override
  Future<void> clear() async {
    _cached = null;
    await _prefs.remove(_tokenKey);
  }
}
