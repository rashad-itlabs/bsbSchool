import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One switchable notification kind, with the copy shown next to its switch.
enum NotificationKind {
  attendance(
    'notify_attendance',
    '🏫',
    'Davamiyyət',
    'Uşağın məktəbə gəlişi və dərsdən çıxışı barədə bildirişlər.',
  ),
  cafeteria(
    'notify_cafeteria',
    '☕',
    'Bufet',
    'Uşağın bufetdə nəyə xərclədiyi barədə bildirişlər.',
  ),
  exam(
    'notify_exam',
    '📚',
    'İmtahanlar',
    'Uşağın imtahan nəticələri və imtahana girilməsi barədə bildirişlər.',
  );

  const NotificationKind(this.prefsKey, this.emoji, this.title, this.subtitle);

  final String prefsKey;
  final String emoji;
  final String title;
  final String subtitle;
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
