import 'package:bsbschool/core/di/injection_container.dart';
import 'package:bsbschool/core/error/failures.dart';
import 'package:bsbschool/dr/screens/homework_screen.dart';
import 'package:bsbschool/dr/theme/dr_theme.dart';
import 'package:bsbschool/features/homework/data/models/homework_content_model.dart';
import 'package:bsbschool/features/homework/domain/entities/homework_content.dart';
import 'package:bsbschool/features/homework/domain/repositories/homework_repository.dart';
import 'package:bsbschool/features/homework/domain/usecases/get_homeworks.dart';
import 'package:bsbschool/features/homework/presentation/bloc/homework_bloc.dart';
import 'package:bsbschool/l10n/app_localizations.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _status(int code, String key, String az, String color) => {
  'code': code,
  'key': key,
  'label': az,
  'labels': {'az': az, 'en': key, 'ru': key},
  'color': color,
};

/// The server's dictionary, in its order (`HomeworkStatuses::LIST`).
final _statuses = [
  _status(4, 'assigned', 'Tapşırıq verilib', '#25A194'),
  _status(1, 'submitted', 'Yerinə yetirilib', '#00C31D'),
  _status(3, 'not_submitted', 'Yerinə yetirilməyib', '#DC2626'),
  _status(5, 'teacher_missed', 'Müəllim qeyd etməyib', '#6C757D'),
  _status(6, 'absent', 'Qayıb', '#7C3AED'),
];

final _ahead = DateTime.now().add(const Duration(days: 3));
final _behind = DateTime.now().subtract(const Duration(days: 3));

Map<String, dynamic> _hw(
  int id,
  String name,
  String subject,
  String teacher,
  String status, {
  bool past = false,
}) {
  final due = past ? _behind : _ahead;
  return {
    'id': id,
    'homework_name': name,
    'subject': subject,
    // The section's auto-name, as the server sends it.
    'section': '$subject-8C2 $teacher',
    'teacher': teacher,
    'submit_date': due.toIso8601String().substring(0, 10),
    'archive_at': due.toIso8601String(),
    'status': status,
  };
}

/// Two sections of MFL (two teachers), one past homework.
final _body = {
  'class_id': 94,
  'class_name': '8C2',
  'statuses': _statuses,
  'data': [
    _hw(1, 'Quadratics', 'Mathematics', 'Ale X', 'assigned'),
    _hw(2, 'Speed', 'Physics', 'Diana Lopez', 'not_submitted'),
    _hw(3, 'Worksheet 2', 'Physics', 'Diana Lopez', 'assigned'),
    _hw(4, 'Verbs', 'MFL', 'Parvana Mammadova', 'assigned'),
    _hw(5, 'Les nombres', 'MFL', 'Anna Dupont', 'assigned'),
    _hw(6, 'Old revision', 'Mathematics', 'Ale X', 'not_submitted',
        past: true),
  ],
};

class _FakeRepo implements HomeworkRepository {
  final HomeworkContent content;
  _FakeRepo(this.content);

  @override
  Future<Either<Failure, HomeworkContent>> getHomeworks() async =>
      Right(content);
}

final _content = HomeworkContentModel.fromJson(_body);

List<int> _ids(HomeworkState state) =>
    [for (final hw in state.visibleHomeworks) hw.id];

Future<HomeworkBloc> _loadedBloc() async {
  final bloc = HomeworkBloc(getHomeworks: GetHomeworks(_FakeRepo(_content)));
  bloc.add(const HomeworkFetched());
  await bloc.stream.firstWhere((s) => s.status == HomeworkStatus.loaded);
  return bloc;
}

Future<void> _pump(WidgetTester tester) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(390 * 3, 2400 * 3);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    theme: DrTheme.dark,
    locale: const Locale('az'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: const HomeworkScreen(),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('the options', () {
    test('the server dictionary is kept, in its order', () {
      expect([for (final s in _content.statuses) s.key], [
        'assigned',
        'submitted',
        'not_submitted',
        'teacher_missed',
        'absent',
      ]);
    });

    test('a section shows as its subject; two of one subject add the teacher',
        () async {
      final bloc = await _loadedBloc();
      expect([for (final o in bloc.state.sectionOptions) o.label], [
        'Mathematics',
        'MFL · Anna Dupont',
        'MFL · Parvana Mammadova',
        'Physics',
      ]);
      await bloc.close();
    });

    test('a server without a dictionary: the statuses the homeworks carry',
        () {
      final old = HomeworkContentModel.fromJson({
        ..._body,
        'statuses': null,
      });
      final state = HomeworkState(
        status: HomeworkStatus.loaded,
        classId: 94,
        homeworks: old.homeworks,
      );
      expect([for (final s in state.statusOptions) s.key],
          ['assigned', 'not_submitted']);
    });
  });

  group('filtering', () {
    test('sections and statuses narrow together; empty is "all"', () async {
      final bloc = await _loadedBloc();
      expect(_ids(bloc.state), [1, 2, 3, 4, 5]);

      bloc.add(const HomeworkFiltersChanged(
        sections: {'Physics-8C2 Diana Lopez'},
      ));
      await pumpEventQueue();
      expect(_ids(bloc.state), [2, 3]);

      bloc.add(const HomeworkFiltersChanged(
        sections: {'Physics-8C2 Diana Lopez', 'Mathematics-8C2 Ale X'},
        statuses: {'not_submitted'},
      ));
      await pumpEventQueue();
      expect(_ids(bloc.state), [2]);
      expect(bloc.state.filterCount, 3);
      await bloc.close();
    });

    test('the filters hold when the tab changes', () async {
      final bloc = await _loadedBloc();
      bloc.add(const HomeworkFiltersChanged(
        sections: {'Mathematics-8C2 Ale X'},
      ));
      bloc.add(const HomeworkTabSelected(HomeworkTab.past));
      await pumpEventQueue();

      expect(bloc.state.sections, {'Mathematics-8C2 Ale X'});
      expect(_ids(bloc.state), [6]);
      await bloc.close();
    });

    test('a refresh keeps the filters', () async {
      final bloc = await _loadedBloc();
      bloc.add(const HomeworkFiltersChanged(statuses: {'not_submitted'}));
      bloc.add(const HomeworkRefreshed());
      await bloc.stream.firstWhere((s) => s.status == HomeworkStatus.loaded);

      expect(bloc.state.statuses, {'not_submitted'});
      expect(_ids(bloc.state), [2]);
      await bloc.close();
    });
  });

  group('the screen', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await sl.reset();
      await initDependencies();
      sl.unregister<HomeworkBloc>();
      sl.registerFactory<HomeworkBloc>(
        () => HomeworkBloc(getHomeworks: GetHomeworks(_FakeRepo(_content))),
      );
    });

    testWidgets('a count and the filter button; no subject pills any more',
        (tester) async {
      await _pump(tester);

      expect(find.text('5 tapşırıq'), findsOneWidget);
      expect(find.text('Filtr'), findsOneWidget);
      expect(find.text('Hamısı'), findsNothing);
    });

    testWidgets('the sheet: pick, see the count, apply, then remove a chip',
        (tester) async {
      await _pump(tester);

      await tester.tap(find.text('Filtr'));
      await tester.pumpAndSettle();
      expect(find.text('FƏNLƏR'), findsOneWidget);
      expect(find.text('STATUS'), findsOneWidget);
      expect(find.text('MFL · Anna Dupont'), findsOneWidget);
      expect(find.text('Qayıb'), findsOneWidget); // every server status
      expect(find.text('Nəticəni göstər (5)'), findsOneWidget);

      await tester.tap(find.text('Physics'));
      await tester.pumpAndSettle();
      expect(find.text('Nəticəni göstər (2)'), findsOneWidget);

      await tester.tap(find.text('Yerinə yetirilməyib'));
      await tester.pumpAndSettle();
      expect(find.text('Nəticəni göstər (1)'), findsOneWidget);
      expect(find.text('1 seçilib'), findsNWidgets(2));

      await tester.tap(find.text('Nəticəni göstər (1)'));
      await tester.pumpAndSettle();

      expect(find.text('FƏNLƏR'), findsNothing); // the sheet closed
      expect(find.text('5 tapşırıqdan 1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // the button's badge
      expect(find.text('Physics: Speed'), findsOneWidget);
      expect(find.text('Mathematics: Quadratics'), findsNothing);

      // The status chip's cross: back to every Physics homework.
      await tester.tap(find.text('Yerinə yetirilməyib'));
      await tester.pumpAndSettle();
      expect(find.text('5 tapşırıqdan 2'), findsOneWidget);
      expect(find.text('Physics: Worksheet 2'), findsOneWidget);
    });

    testWidgets('reset clears every filter', (tester) async {
      await _pump(tester);

      await tester.tap(find.text('Filtr'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mathematics'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nəticəni göstər (1)'));
      await tester.pumpAndSettle();
      expect(find.text('5 tapşırıqdan 1'), findsOneWidget);

      await tester.tap(find.text('Sıfırla'));
      await tester.pumpAndSettle();
      expect(find.text('5 tapşırıq'), findsOneWidget);
      expect(find.text('Mathematics: Quadratics'), findsOneWidget);
      expect(find.text('Physics: Speed'), findsOneWidget);
    });

    testWidgets('nothing left after filtering offers the reset', (tester) async {
      await _pump(tester);

      await tester.tap(find.text('Filtr'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Qayıb'));
      await tester.pumpAndSettle();
      expect(find.text('Nəticəni göstər (0)'), findsOneWidget);
      await tester.tap(find.text('Nəticəni göstər (0)'));
      await tester.pumpAndSettle();

      // One reset under the button, one under the empty message.
      expect(find.text('Sıfırla'), findsNWidgets(2));
    });
  });
}
