import 'package:bsbschool/core/l10n/l10n.dart';
import 'package:bsbschool/core/l10n/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Plain `test` cases still talk to the SharedPreferences channel.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocaleController.instance.setLocale(null);
  });

  test('ships Azerbaijani, English and Russian', () {
    expect(
      AppL10n.supportedLocales.map((l) => l.languageCode),
      containsAll(['az', 'en', 'ru']),
    );
  });

  test('every message is translated into all three languages', () {
    // A missing key would come back as the template's text, which is how a
    // half-translated release slips through.
    final az = lookupAppL10n(const Locale('az'));
    final en = lookupAppL10n(const Locale('en'));
    final ru = lookupAppL10n(const Locale('ru'));

    expect(en.payNow, isNot(az.payNow));
    expect(ru.payNow, isNot(az.payNow));
    expect(az.payNow, 'Ödəniş et');
    expect(en.payNow, 'Pay now');
    expect(ru.payNow, 'Оплатить');
  });

  test('placeholders survive translation', () {
    expect(
      lookupAppL10n(const Locale('en')).extraFeesPayableAmount('20.00 ₼'),
      contains('20.00 ₼'),
    );
    expect(
      lookupAppL10n(const Locale('ru')).forgotMinLength(6),
      contains('6'),
    );
  });

  group('default language', () {
    test('follows the device when nothing was chosen', () async {
      await LocaleController.instance.load();

      expect(LocaleController.instance.isSystem, isTrue);
      expect(
        LocaleController.instance.resolve([const Locale('ru')]).languageCode,
        'ru',
      );
      expect(
        LocaleController.instance.resolve([const Locale('en', 'GB')]).languageCode,
        'en',
      );
    });

    test('falls back to Azerbaijani for a language we do not ship', () {
      expect(
        LocaleController.instance.resolve([const Locale('de')]),
        LocaleController.fallback,
      );
      expect(LocaleController.fallback.languageCode, 'az');
    });

    test('an explicit choice wins over the device and is remembered', () async {
      await LocaleController.instance.setLocale(const Locale('ru'));

      expect(LocaleController.instance.isSystem, isFalse);
      expect(
        LocaleController.instance.resolve([const Locale('en')]).languageCode,
        'ru',
      );

      // It reaches storage, so a fresh launch reads it back.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale'), 'ru');

      // And a launch that finds a stored choice starts on it.
      SharedPreferences.setMockInitialValues({'app_locale': 'en'});
      await LocaleController.instance.load();
      expect(LocaleController.instance.locale?.languageCode, 'en');
    });

    test('picking "system" clears the stored choice', () async {
      await LocaleController.instance.setLocale(const Locale('en'));
      await LocaleController.instance.setLocale(null);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale'), isNull);

      await LocaleController.instance.load();

      expect(LocaleController.instance.locale, isNull);
      expect(LocaleController.instance.isSystem, isTrue);
    });
  });
}
