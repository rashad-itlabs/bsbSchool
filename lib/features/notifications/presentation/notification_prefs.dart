import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/l10n/l10n.dart';

/// One switchable notification kind.
///
/// The copy beside each switch is looked up on read rather than stored on the
/// enum: a const field would freeze whichever language was loaded first and
/// never follow a language switch.
enum NotificationKind {
  attendance('notify_attendance', '🏫'),
  cafeteria('notify_cafeteria', '☕'),
  exam('notify_exam', '📚');

  const NotificationKind(this.prefsKey, this.emoji);

  final String prefsKey;
  final String emoji;

  String get title => switch (this) {
    NotificationKind.attendance => L.s.notifPrefAttendance,
    NotificationKind.cafeteria => L.s.notifPrefBuffet,
    NotificationKind.exam => L.s.notifPrefExams,
  };

  String get subtitle => switch (this) {
    NotificationKind.attendance => L.s.notifPrefAttendanceText,
    NotificationKind.cafeteria => L.s.notifPrefBuffetText,
    NotificationKind.exam => L.s.notifPrefExamsText,
  };
}

/// Global, persisted delivery preferences for notifications.
///
/// Client-side only — the `GET /notifications` feed is not filtered by them —
/// but held in one place so every screen that shows the switches (the
/// notifications tab and the profile screen) reads and writes the same values,
/// and a choice survives a restart. Follows the [ThemeController] pattern:
/// listen with an `AnimatedBuilder` and call [setEnabled] to change one.
class NotificationPrefs extends ChangeNotifier {
  NotificationPrefs._();

  static final NotificationPrefs instance = NotificationPrefs._();

  // Everything is on until the parent turns it off.
  final Map<NotificationKind, bool> _enabled = {
    for (final kind in NotificationKind.values) kind: true,
  };

  bool isEnabled(NotificationKind kind) => _enabled[kind] ?? true;

  /// Restore the saved switches. Call once before `runApp`.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    for (final kind in NotificationKind.values) {
      _enabled[kind] = prefs.getBool(kind.prefsKey) ?? true;
    }
    notifyListeners();
  }

  Future<void> setEnabled(NotificationKind kind, bool value) async {
    if (_enabled[kind] == value) return;
    _enabled[kind] = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kind.prefsKey, value);
  }
}
