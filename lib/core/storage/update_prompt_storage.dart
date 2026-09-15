import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the version a parent said "Sonra" to, so an optional update is
/// offered once rather than on every launch. A forced update is never stored:
/// it is not something anyone gets to dismiss.
abstract class UpdatePromptStorage {
  /// True when this exact version has already been offered and put off.
  bool isSkipped(String version);

  Future<void> skip(String version);
}

class UpdatePromptStorageImpl implements UpdatePromptStorage {
  static const _key = 'update_prompt_skipped_version';

  final SharedPreferences _prefs;
  String? _cached;

  UpdatePromptStorageImpl(this._prefs) {
    _cached = _prefs.getString(_key);
  }

  @override
  bool isSkipped(String version) =>
      version.isNotEmpty && _cached == version;

  @override
  Future<void> skip(String version) async {
    _cached = version;
    await _prefs.setString(_key, version);
  }
}
