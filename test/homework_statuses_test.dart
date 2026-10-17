import 'package:bsbschool/core/di/injection_container.dart';
import 'package:bsbschool/core/error/failures.dart';
import 'package:bsbschool/dr/screens/homework_detail_screen.dart';
import 'package:bsbschool/dr/screens/homework_screen.dart';
import 'package:bsbschool/dr/theme/dr_theme.dart';
import 'package:bsbschool/features/homework/data/models/homework_content_model.dart';
import 'package:bsbschool/features/homework/domain/entities/homework.dart';
import 'package:bsbschool/features/homework/domain/entities/homework_content.dart';
import 'package:bsbschool/features/homework/domain/repositories/homework_repository.dart';
import 'package:bsbschool/features/homework/domain/usecases/get_homeworks.dart';
import 'package:bsbschool/features/homework/presentation/bloc/homework_bloc.dart';
import 'package:bsbschool/l10n/app_localizations.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The server's `statuses` as `HomeworkStatuses::forApi()` sent it on
/// 17.10.2026 (trimmed to what the app reads).
const _statuses = [
  {
    'code': 4,
    'key': 'assigned',
    'label': 'Tapşırıq verilib',
    'labels': {'az': 'Tapşırıq verilib', 'en': 'Assigned', 'ru': 'Задано'},
    'color': '#25A194',
    'hint': null,
    'hints': {'az': null, 'en': null, 'ru': null},
  },
  {
    'code': 1,
    'key': 'submitted',
    'label': 'Yerinə yetirilib',
    'labels': {'az': 'Yerinə yetirilib', 'en': 'Completed', 'ru': 'Выполнено'},
    'color': '#00C31D',
    'hint': null,
    'hints': {'az': null, 'en': null, 'ru': null},
  },
  {
    'code': 3,
    'key': 'not_submitted',
    'label': 'Yerinə yetirilməyib',
    'labels': {
      'az': 'Yerinə yetirilməyib',
      'en': 'Not completed',
      'ru': 'Не выполнено',
    },
    'color': '#DC2626',
    'hint': null,
    'hints': {'az': null, 'en': null, 'ru': null},
  },
  {
    'code': 5,
    'key': 'teacher_missed',
    'label': 'Müəllim qeyd etməyib',
    'labels': {
      'az': 'Müəllim qeyd etməyib',
      'en': 'Not marked by teacher',
      'ru': 'Учитель не отметил',
    },
    'color': '#6C757D',
    'hint': 'Təhvil tarixi keçib, amma müəllim qeyd etməyib.',
    'hints': {
      'az': 'Təhvil tarixi keçib, amma müəllim qeyd etməyib.',
      'en': 'The due date has passed.',
      'ru': 'Срок прошёл.',
    },
  },
  {
    'code': 6,
    'key': 'absent',
    'label': 'Qayıb',
    'labels': {'az': 'Qayıb', 'en': 'Absent', 'ru': 'Отсутствовал'},
    'color': '#7C3AED',
    'hint': null,
    'hints': {'az': null, 'en': null, 'ru': null},
  },
];

final _future = DateTime.now().add(const Duration(days: 3));
String _day(DateTime d) => d.toIso8601String().substring(0, 10);

Map<String, dynamic> _hw(
  int id,
  String name, {
  String? status,
  int? code,
  bool marked = false,
}) => {
  'id': id,
  'homework_name': name,
  'subject': 'Riyaziyyat',
  'submit_date': _day(_future),
  'archive_at': _future.toIso8601String(),
  'status': ?status,
  'status_code': ?code,
  if (status != null) 'status_label': 'server:$status',
  'submission': marked ? {'marked_at': '2026-10-16 10:00:00'} : null,
};

/// One of each status, plus a homework from a server with no statuses.
final _body = {
  'class_id': 94,
  'class_name': 'Class Group 7',
  'statuses': _statuses,
  'data': [
    _hw(1, 'Done', status: 'submitted', code: 1, marked: true),
    _hw(3, 'NotDone', status: 'not_submitted', code: 3, marked: true),
    _hw(6, 'Away', status: 'absent', code: 6, marked: true),
    _hw(5, 'Unmarked', status: 'teacher_missed', code: 5),
    _hw(4, 'Open', status: 'assigned', code: 4),
  ],
};

Homework _byName(List<Homework> list, String name) =>
    list.firstWhere((h) => h.name == name);

class _FakeRepo implements HomeworkRepository {
  final HomeworkContent content;
  _FakeRepo(this.content);
  @override
  Future<Either<Failure, HomeworkContent>> getHomeworks() async =>
      Right(content);
}

Widget _app(Widget home) => MaterialApp(
  theme: DrTheme.dark,
  locale: const Locale('az'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: home,
);

void main() {
  final content = HomeworkContentModel.fromJson(_body);
  final hws = content.homeworks;

  group('statuses dictionary (server 16.10.2026)', () {
    test('each homework gets its status entry, by code', () {
      final notDone = _byName(hws, 'NotDone');
      expect(notDone.status, 'not_submitted');
      expect(notDone.statusCode, 3);
      expect(notDone.statusInfo?.key, 'not_submitted');
      expect(notDone.statusInfo?.labelFor('ru'), 'Не выполнено');
      expect(notDone.statusInfo?.labelFor('az'), 'Yerinə yetirilməyib');
      expect(notDone.statusInfo?.color, 0xFFDC2626);
      expect(
        _byName(hws, 'Unmarked').statusInfo?.hintFor('en'),
        'The due date has passed.',
      );
    });

    test('a mark is not "submitted": codes 3 and 6 also carry one', () {
      expect(_byName(hws, 'Done').isSubmitted, isTrue);
      expect(_byName(hws, 'NotDone').isSubmitted, isFalse);
      expect(_byName(hws, 'Away').isSubmitted, isFalse);
      expect(_byName(hws, 'NotDone').submission, isNotNull);
    });

    test('a server without statuses keeps the old rule', () {
      final old = HomeworkContentModel.fromJson({
        'data': [
          {
            'id': 9,
            'homework_name': 'Old',
            'submission': {'notes': 'x'},
          },
        ],
      }).homeworks.single;
      expect(old.status, isNull);
      expect(old.statusInfo, isNull);
      expect(old.isSubmitted, isTrue);
    });

    test('a bad colour or entry is dropped, not a crash', () {
      final c = HomeworkContentModel.fromJson({
        'statuses': [
          {'code': 1, 'key': 'submitted', 'label': 'x', 'color': 'green'},
          {'key': 'no-code'},
          'junk',
        ],
        'data': [
          {
            'id': 1,
            'homework_name': 'A',
            'status': 'submitted',
            'status_code': 1,
          },
        ],
      });
      expect(c.homeworks.single.statusInfo?.color, isNull);
      expect(c.homeworks.single.statusInfo?.label, 'x');
    });
  });

  group('detail screen', () {
    testWidgets('«not done» shows the server word, not "submitted"', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(HomeworkDetailScreen(homework: _byName(hws, 'NotDone'))),
      );
      expect(find.text('Yerinə yetirilməyib'), findsOneWidget);
      expect(find.text('Təhvil verilib'), findsNothing);
    });

    testWidgets(
      'light theme: the website green is darkened to read (≥ 4.5:1)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: DrTheme.light,
            locale: const Locale('az'),
            supportedLocales: AppL10n.supportedLocales,
            localizationsDelegates: AppL10n.localizationsDelegates,
            home: HomeworkDetailScreen(homework: _byName(hws, 'Done')),
          ),
        );
        final color = tester
            .widget<Text>(find.text('Yerinə yetirilib'))
            .style!
            .color!;
        double contrast(Color a, Color b) {
          final la = a.computeLuminance(), lb = b.computeLuminance();
          return ((la > lb ? la : lb) + 0.05) / ((la > lb ? lb : la) + 0.05);
        }

        // `#00C31D` itself is 2.3:1 on the white card.
        expect(contrast(const Color(0xFF00C31D), Colors.white), lessThan(3));
        expect(contrast(color, Colors.white), greaterThanOrEqualTo(4.5));
      },
    );

    testWidgets('«teacher has not marked» shows its status and hint', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(HomeworkDetailScreen(homework: _byName(hws, 'Unmarked'))),
      );
      expect(find.text('Müəllim qeyd etməyib'), findsOneWidget);
      expect(
        find.text('Təhvil tarixi keçib, amma müəllim qeyd etməyib.'),
        findsOneWidget,
      );
    });
  });

  group('list cards', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await sl.reset();
      await initDependencies();
      sl.unregister<HomeworkBloc>();
      sl.registerFactory<HomeworkBloc>(
        () => HomeworkBloc(getHomeworks: GetHomeworks(_FakeRepo(content))),
      );
    });

    testWidgets('server words, Azerbaijani capitals; «assigned» counts down', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = const Size(390 * 3, 4000 * 3);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(const HomeworkScreen()));
      await tester.pumpAndSettle();

      expect(find.text('YERİNƏ YETİRİLİB'), findsOneWidget);
      expect(find.text('YERİNƏ YETİRİLMƏYİB'), findsOneWidget);
      expect(find.text('QAYIB'), findsOneWidget);
      expect(find.text('MÜƏLLİM QEYD ETMƏYİB'), findsOneWidget);
      // «Assigned» keeps the deadline countdown instead of its own word.
      expect(find.text('TAPŞIRIQ VERİLİB'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
