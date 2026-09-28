import 'package:bsbschool/dr/theme/dr_theme.dart';
import 'package:bsbschool/dr/widgets/dr_bottom_nav.dart';
import 'package:bsbschool/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // iOS Settings → Accessibility → Larger Text at its maximum is about 3.1×.
  testWidgets('labels stay one line, cut with an ellipsis, at max text size',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      theme: DrTheme.dark,
      locale: const Locale('az'),
      localizationsDelegates: const [
        AppL10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppL10n.supportedLocales,
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(375, 812),
          textScaler: TextScaler.linear(3.1),
        ),
        child: Scaffold(
          bottomNavigationBar: DrBottomNav(currentIndex: 0, onTap: (_) {}),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Built the way the bar builds it ("Ana səhifə" → "ANA SƏHIFƏ").
    final home = lookupAppL10n(const Locale('az')).navHome.toUpperCase();
    final label = tester.widget<Text>(find.text(home));
    expect(label.maxLines, 1);
    expect(label.overflow, TextOverflow.ellipsis);

    // The label is drawn at 1.3×, not 3.1×, and on a single line.
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(
          of: find.text(home), matching: find.byType(RichText)),
    );
    expect(paragraph.textScaler.scale(9), closeTo(9 * 1.3, 0.01));
    expect(paragraph.size.height, lessThan(9 * 1.3 * 2));
  });
}
