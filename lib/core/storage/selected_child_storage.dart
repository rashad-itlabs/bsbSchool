import 'package:shared_preferences/shared_preferences.dart';

/// Remembers which of a parent's students the app is currently showing, so the
/// pick survives an app restart. Read synchronously (like [TokenStorage]) —
/// every request that carries `student_id` needs it without an async hop.
abstract class SelectedChildStorage {
  /// `child_id` of the student the parent last switched to (null when they
  /// never switched, or after logout).
  int? get selectedChildId;

  Future<void> save(int childId);
  Future<void> clear();
}

class SelectedChildStorageImpl implements SelectedChildStorage {
  static const _key = 'selected_child_id';

  final SharedPreferences _prefs;
  int? _cached;

  SelectedChildStorageImpl(this._prefs) {
    _cached = _prefs.getInt(_key);
  }

  @override
  int? get selectedChildId => _cached;

  @override
  Future<void> save(int childId) async {
    _cached = childId;
    await _prefs.setInt(_key, childId);
  }

  @override
  Future<void> clear() async {
    _cached = null;
    await _prefs.remove(_key);
  }
}
