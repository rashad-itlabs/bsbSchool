import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global, persisted language controller.
///
/// Listen to it (e.g. via `AnimatedBuilder`) at the app root and drive
/// `MaterialApp.locale` from [locale]. The choice is saved to
/// `SharedPreferences` and restored on the next launch — the same shape as
/// `ThemeController`, so the two settings behave alike.
class LocaleController extends ChangeNotifier {
  LocaleController._();

  static final LocaleController instance = LocaleController._();

  static const _prefsKey = 'app_locale';

  /// The language a device that asks for something we do not ship falls back
  /// to. The school's own language, not English.
  static const fallback = Locale('az');

  /// Every language the app ships, in the order the picker lists them.
  static const supported = <Locale>[Locale('az'), Locale('en'), Locale('ru')];

  Locale? _locale;

  /// null means "follow the device", which is the out-of-the-box default.
  Locale? get locale => _locale;

  /// True while the app follows the device language.
  bool get isSystem => _locale == null;

  /// Restore the saved choice. Call once before `runApp`.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    _locale = _parse(code);
    notifyListeners();
  }

  /// Pass null to hand the choice back to the device.
  Future<void> setLocale(Locale? locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, locale.languageCode);
    }
  }

  /// Which language is actually being rendered, device choice resolved.
  ///
  /// [deviceLocales] is `WidgetsBinding.instance.platformDispatcher.locales`;
  /// the first one the app ships wins, and [fallback] closes the list.
  Locale resolve(List<Locale> deviceLocales) {
    final chosen = _locale;
    if (chosen != null) return chosen;

    for (final device in deviceLocales) {
      for (final option in supported) {
        if (option.languageCode == device.languageCode) return option;
      }
    }
    return fallback;
  }

  static Locale? _parse(String? code) {
    if (code == null) return null;
    for (final option in supported) {
      if (option.languageCode == code) return option;
    }
    return null;
  }
}
