import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global, persisted light/dark theme controller.
///
/// Listen to it (e.g. via `AnimatedBuilder`) at the app root and drive
/// `MaterialApp.themeMode` from [mode]. The choice is saved to
/// `SharedPreferences` and restored on the next launch.
class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  static const _prefsKey = 'theme_mode';

  ThemeMode _mode = ThemeMode.dark;
  ThemeMode get mode => _mode;

  /// Restore the saved mode. Call once before `runApp`.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _mode = switch (prefs.getString(_prefsKey)) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
  }

  /// Flip between light and dark based on the currently resolved [current]
  /// brightness.
  Future<void> toggle(Brightness current) =>
      setMode(current == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
}
