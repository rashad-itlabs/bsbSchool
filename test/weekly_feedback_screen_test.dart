import 'package:bsbschool/core/di/injection_container.dart';
import 'package:bsbschool/dr/screens/weekly_feedback.dart';
import 'package:bsbschool/dr/theme/dr_theme.dart';
import 'package:bsbschool/features/weekly_feedback/data/models/weekly_feedback_content_model.dart';
import 'package:bsbschool/features/weekly_feedback/data/services/weekly_feedback_service.dart';
import 'package:bsbschool/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Answers like the real endpoint for a Year 6 student in week 2 of 40: only
/// week 2 has feedback, weeks 3+ haven't started.
class _FakeService implements WeeklyFeedbackService {
  final requestedWeeks = <int?>[];

  @override
  Future<WeeklyFeedbackContentModel> getWeeklyFeedback({
    int? studentId,
    int? week,
  }) async {
    requestedWeeks.add(week);
    final selected = week ?? 2;
    return WeeklyFeedbackContentModel.fromJson({
      'success': true,
      'ready': true,
      'total_weeks': 40,
      'current_week': 2,
      'selected_week': selected,
      'weeks': [
        for (var w = 1; w <= 40; w++)
          {
            'week': w,
            'count': w == 2 ? 1 : 0,
            'has_feedback': w == 2,
            'is_current': w == 2,
            'is_future': w > 2,
          },
      ],
      'data': [
        if (selected == 2)
          {
            'kind': 'student',
            'kind_label': 'About your child',
            'teacher': 'Felipe Caceres',
            'subjects': 'Mindfulness, Literacy, Numeracy',
            'text': 'Said has a satisfactory behavior in class.',
            'files': [],
            'date': '2026-09-24',
          },
      ],
    });
  }
}

Widget _app(Locale locale) => MaterialApp(
      theme: DrTheme.dark,
      locale: locale,
      localizationsDelegates: const [
        AppL10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppL10n.supportedLocales,
      home: const WeeklyFeedbackScreen(),
    );

void main() {
  late _FakeService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
    await initDependencies();
    service = _FakeService();
    sl.unregister<WeeklyFeedbackService>();
    sl.registerLazySingleton<WeeklyFeedbackService>(() => service);
  });

  for (final locale in AppL10n.supportedLocales) {
    testWidgets('weeks grid and feedback render on a phone in $locale',
        (tester) async {
      tester.view.physicalSize = const Size(360, 780) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(locale));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final l10n = lookupAppL10n(locale);

      // Opens on whatever week the server calls current.
      expect(service.requestedWeeks, [null]);
      expect(find.text(l10n.weeklyFeedbackWeek(2)), findsOneWidget);
      expect(find.text('About your child'), findsOneWidget);
      expect(find.text('Felipe Caceres'), findsOneWidget);

      // A past week without feedback is fetched and says so.
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();
      expect(service.requestedWeeks, [null, 1]);
      expect(find.text('About your child'), findsNothing);
      expect(find.text(l10n.weeklyFeedbackNoneForWeek), findsOneWidget);

      // A future week can't be picked, so nothing is requested.
      await tester.tap(find.text('10'));
      await tester.pumpAndSettle();
      expect(service.requestedWeeks, [null, 1]);
      expect(tester.takeException(), isNull);
    });
  }
}
