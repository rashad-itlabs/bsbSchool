import 'package:bsbschool/dr/screens/under_constructor.dart';
import 'package:bsbschool/dr/theme/dr_theme.dart';
import 'package:bsbschool/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host({
  required ThemeData theme,
  required Locale locale,
  double width = 375,
  bool reduceMotion = false,
}) {
  return MaterialApp(
    theme: theme,
    locale: locale,
    localizationsDelegates: const [
      AppL10n.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppL10n.supportedLocales,
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          size: Size(width, 800),
          disableAnimations: reduceMotion,
        ),
        child: Scaffold(
          body: SizedBox(
            width: width,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: const [UnderConstructor()],
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  for (final locale in const [Locale('az'), Locale('en'), Locale('ru')]) {
    for (final theme in {'dark': DrTheme.dark, 'light': DrTheme.light}.entries) {
      testWidgets('${locale.languageCode}/${theme.key} renders', (tester) async {
        await tester.pumpWidget(
          _host(theme: theme.value, locale: locale),
        );
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(seconds: 3));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('narrow phone has no overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(theme: DrTheme.dark, locale: const Locale('az'), width: 320));
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduce motion parks the animations', (tester) async {
    await tester.pumpWidget(
      _host(theme: DrTheme.dark, locale: const Locale('az'), reduceMotion: true),
    );
    await tester.pump(const Duration(milliseconds: 600));
    // Nothing scheduled: with every controller stopped the test framework can
    // settle, which it cannot while a repeating controller is running.
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
