import 'package:bsbschool/core/l10n/app_dates.dart';
import 'package:bsbschool/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs [read] with a context in [locale] and returns what it produced.
Future<String> _inLocale(
  WidgetTester tester,
  Locale locale,
  String Function(BuildContext) read,
) async {
  late String result;
  await tester.pumpWidget(MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppL10n.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppL10n.supportedLocales,
    home: Builder(builder: (context) {
      result = read(context);
      return const SizedBox();
    }),
  ));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  const az = Locale('az'), ru = Locale('ru'), en = Locale('en');
  final september = DateTime(2026, 9, 1);
  final june = DateTime(2026, 6, 1);

  testWidgets('calendar headings start with a capital letter', (tester) async {
    expect(await _inLocale(tester, az, (c) => AppDates.monthYear(c, september)),
        'Sentyabr 2026');
    expect(await _inLocale(tester, ru, (c) => AppDates.monthYear(c, september)),
        startsWith('Сентябрь 2026'));
    expect(await _inLocale(tester, en, (c) => AppDates.monthYear(c, september)),
        'September 2026');
    expect(await _inLocale(tester, az, (c) => AppDates.monthTitle(c, 9)),
        'Sentyabr');
  });

  testWidgets('Azerbaijani i capitalises to a dotted İ', (tester) async {
    expect(await _inLocale(tester, az, (c) => AppDates.monthYear(c, june)),
        'İyun 2026');
    expect(await _inLocale(tester, az, (c) => AppDates.monthTitle(c, 7)),
        'İyul');
  });

  testWidgets('month names inside a sentence keep the language\'s case',
      (tester) async {
    expect(await _inLocale(tester, ru, (c) => AppDates.month(c, 9)), 'сентябрь');
    expect(await _inLocale(tester, az, (c) => AppDates.month(c, 9)), 'sentyabr');
  });
}
