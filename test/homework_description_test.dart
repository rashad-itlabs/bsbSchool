import 'package:bsbschool/dr/screens/homework_detail_screen.dart';
import 'package:bsbschool/dr/theme/dr_theme.dart';
import 'package:bsbschool/features/homework/domain/entities/homework.dart';
import 'package:bsbschool/l10n/app_localizations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, String description) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(390 * 3, 2400 * 3);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    theme: DrTheme.dark,
    locale: const Locale('az'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: HomeworkDetailScreen(
      homework: Homework(
        id: 1,
        name: 'Alphabet',
        subject: 'English',
        description: description,
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

/// The span of [text] inside the description, if it is a link.
TextSpan? _linkSpan(WidgetTester tester, String text) {
  TextSpan? found;
  for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
    rich.text.visitChildren((span) {
      if (span is TextSpan && span.text == text && span.recognizer != null) {
        found = span;
      }
      return found == null;
    });
  }
  return found;
}

void main() {
  testWidgets("the editor's video block shows as a card, not as nothing",
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester,
        '<p>Learn this video by heart.</p><figure class="media"><oembed url="https://youtu.be/ChqnN3cKzXQ?si=ggy3wMQscc"></oembed></figure>');

    expect(find.text('Təsvir'), findsOneWidget);
    expect(find.textContaining('Learn this video by heart.'), findsOneWidget);
    expect(find.text('Videonu izlə'), findsOneWidget);
    // A screen reader hears it as a button.
    expect(find.bySemanticsLabel('Videonu izlə'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('a link in a sentence is tappable; the words around it stay',
      (tester) async {
    await _pump(tester,
        '<p>Read <a href="https://example.com/x">this page</a> tonight.</p>');

    final link = _linkSpan(tester, 'this page');
    expect(link, isNotNull);
    expect(link!.recognizer, isA<TapGestureRecognizer>());
    expect(link.style?.decoration, TextDecoration.underline);
    expect(find.textContaining('Read this page tonight.'), findsOneWidget);
    // Not a video: no card.
    expect(find.text('Videonu izlə'), findsNothing);
  });

  testWidgets('a bare YouTube URL: a link and one card', (tester) async {
    const url = 'https://www.youtube.com/watch?v=7cRgK0qG00E';
    await _pump(tester,
        '<p>$url</p><figure class="media"><oembed url="$url"></oembed></figure>');

    expect(_linkSpan(tester, url), isNotNull);
    expect(find.text('Videonu izlə'), findsOneWidget);
  });

  testWidgets('a description of blanks only hides the section',
      (tester) async {
    await _pump(tester, '<p>&nbsp;</p><p>&nbsp;</p>');
    expect(find.text('Təsvir'), findsNothing);
  });
}
