import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/l10n/l10n.dart';

/// One switchable notification kind.
///
/// The copy beside each switch is looked up on read rather than stored on the
/// enum: a const field would freeze whichever language was loaded first and
/// never follow a language switch.
enum NotificationKind {
  attendance('notify_attendance', '🏫', 'attendance'),
  cafeteria('notify_cafeteria', '☕', 'cafeteria'),
  exam('notify_exam', '📚', 'exam'),
  homework('notify_homework', '📝', 'homework');

  const NotificationKind(this.prefsKey, this.emoji, this.pushKind);

  final String prefsKey;
  final String emoji;

  /// What the backend calls the kind — a push's `data.kind`, and the name in
  /// the `muted` list sent with the push token. Spelled out rather than taken
  /// from [name], so renaming a case cannot quietly change the contract.
  final String pushKind;

  String get title => switch (this) {
    NotificationKind.attendance => L.s.notifPrefAttendance,
    NotificationKind.cafeteria => L.s.notifPrefBuffet,
    NotificationKind.exam => L.s.notifPrefExams,
    NotificationKind.homework => L.s.notifPrefHomework,
  };

  String get subtitle => switch (this) {
    NotificationKind.attendance => L.s.notifPrefAttendanceText,
    NotificationKind.cafeteria => L.s.notifPrefBuffetText,
    NotificationKind.exam => L.s.notifPrefExamsText,
    NotificationKind.homework => L.s.notifPrefHomeworkText,
  };
}

/// Global, persisted delivery preferences for notifications.
///
/// They decide what this phone is sent, not what the `GET /notifications` feed
/// lists: `FirebasePushService` hands the switched-off kinds to the server with
/// the push token, and the server leaves this device out of those pushes — so a
/// switch holds while the app is closed too (20.10.2026). Per device, like the
/// token: a parent's second phone keeps its own switches.
///
/// Held in one place so every screen that shows the switches (the
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
