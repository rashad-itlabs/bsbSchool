import 'package:bsbschool/core/di/injection_container.dart';
import 'package:bsbschool/core/l10n/app_dates.dart';
import 'package:bsbschool/core/error/failures.dart';
import 'package:bsbschool/dr/screens/attendance_screen.dart';
import 'package:bsbschool/dr/theme/dr_theme.dart';
import 'package:bsbschool/features/attendance/data/models/attendance_content_model.dart';
import 'package:bsbschool/features/attendance/domain/entities/attendance_content.dart';
import 'package:bsbschool/features/attendance/domain/entities/attendance_permission.dart';
import 'package:bsbschool/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:bsbschool/features/attendance/domain/usecases/get_attendance.dart';
import 'package:bsbschool/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:bsbschool/features/attendance/presentation/widgets/attendance_month_calendar.dart';
import 'package:bsbschool/l10n/app_localizations.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRepo implements AttendanceRepository {
  final AttendanceContent content;
  _FakeRepo(this.content);
  @override
  Future<Either<Failure, AttendanceContent>> getAttendance() async =>
      Right(content);
}

final _today = () {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}();

String _day(DateTime d) => d.toIso8601String().substring(0, 10);

/// The note as the screen writes it for [day] (19.10.2026: it names the day,
/// not the server's «bu günə»): «Şagird 20 oktyabr tarixinə icazəlidir».
String _note(DateTime day) =>
    'Şagird ${DateFormat.MMMMd('az').format(day)} tarixinə icazəlidir';

/// A permission as `ApiController::attendancePermissionsFor` sends it.
Map<String, dynamic> _perm(List<DateTime> days,
        {String kind = 'day', String? time}) =>
    {
      'id': 1,
      'date_from': _day(days.first),
      'date_to': _day(days.last),
      'kind': kind,
      'time': time,
      'dates': [for (final d in days) _day(d)],
      'label': 'Şagird bu günə icazəlidir',
      'labels': {
        'az': 'Şagird bu günə icazəlidir',
        'en': 'Excused for this day',
        'ru': 'Отпросился на этот день',
      },
    };

AttendanceContent _content(List<Map<String, dynamic>> data,
        List<Map<String, dynamic>> perms) =>
    AttendanceContentModel.fromJson(
        {'student_id': 3789, 'data': data, 'permissions': perms});

Future<void> _pump(WidgetTester tester, AttendanceContent content) async {
  SharedPreferences.setMockInitialValues({});
  await sl.reset();
  await initDependencies();
  sl.unregister<AttendanceBloc>();
  sl.registerFactory<AttendanceBloc>(
    () => AttendanceBloc(getAttendance: GetAttendance(_FakeRepo(content))),
  );
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(390 * 3, 2400 * 3);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: DrTheme.dark,
    locale: const Locale('az'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: const AttendanceScreen(),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('az'));

  group('permissions (server 19.10.2026)', () {
    test('parsed from the response; one without dates is dropped', () {
      final c = _content([], [
        _perm([DateTime(2026, 10, 19), DateTime(2026, 10, 20)]),
        {'id': 2, 'kind': 'day', 'dates': []},
      ]);
      expect(c.permissions, hasLength(1));
      final p = c.permissions.single;
      expect(p.kind, 'day');
      expect(p.dates, [DateTime(2026, 10, 19), DateTime(2026, 10, 20)]);
      expect(p.labelFor('ru'), 'Отпросился на этот день');
      expect(p.covers(DateTime(2026, 10, 20, 15, 30)), isTrue);
      expect(p.covers(DateTime(2026, 10, 18)), isFalse);
    });

    test('an older server: no permissions, nothing breaks', () {
      final c = AttendanceContentModel.fromJson({'student_id': 1, 'data': []});
      expect(c.permissions, isEmpty);
      expect(const AttendanceState().permissionOn(_today), isNull);
    });

    testWidgets('today excused, no lesson logged yet: the note, no "empty"',
        (tester) async {
      await _pump(tester, _content([], [_perm([_today])]));
      expect(find.text(_note(_today)), findsOneWidget);
      expect(find.text('Qeyd tapılmadı'), findsNothing);
      // The calendar counts today as an excused day.
      expect(find.text('İcazəli 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('excused but came anyway: the note stays, the records decide',
        (tester) async {
      await _pump(
          tester,
          _content([
            {
              'id': 7,
              'date': _day(_today),
              'subject': 'Registration',
              'status': 'Present',
              'start_time': '08:30:00',
            },
          ], [
            _perm([_today])
          ]));
      expect(find.text(_note(_today)), findsOneWidget);
      expect(find.text('Registration'), findsOneWidget);
      expect(find.text('İcazəli 1'), findsNothing); // a present day, not excused
    });

    testWidgets('a future permission day can be opened', (tester) async {
      // A later weekday of this month; none left on the month's last days.
      final last = DateTime(_today.year, _today.month + 1, 0).day;
      final future = [
        for (var d = _today.day + 1; d <= last; d++)
          DateTime(_today.year, _today.month, d),
      ].where((d) => d.weekday <= 5).toList();
      if (future.isEmpty) {
        markTestSkipped('no weekday left in this month');
        return;
      }
      final day = future.first;

      await _pump(tester, _content([], [_perm([day])]));
      // Today is not covered: no note at all.
      expect(find.textContaining('icazəlidir'), findsNothing);
      await tester.tap(find.descendant(
          of: find.byType(AttendanceMonthCalendar),
          matching: find.text('${day.day}')));
      await tester.pumpAndSettle();
      // The picked day — by its own date, not «bu günə».
      expect(find.text(_note(day)), findsOneWidget);
    });

    testWidgets("a part day adds the time; the server's «bu günə» never shows",
        (tester) async {
      await _pump(tester,
          _content([], [_perm([_today], kind: 'leave', time: '12:30')]));
      expect(find.text('${_note(_today)} · çıxır: 12:30'), findsOneWidget);
      expect(find.textContaining('bu günə'), findsNothing);
    });

    test('state finds the permission of a day', () {
      final p = AttendancePermission(id: 1, dates: [_today], label: 'x');
      final s = AttendanceState(permissions: [p]);
      expect(s.permissionOn(_today.add(const Duration(hours: 9))), p);
      expect(s.permissionOn(_today.add(const Duration(days: 1))), isNull);
    });

    testWidgets('a permission of several days names the whole span',
        (tester) async {
      // Today and the next three calendar days (a weekend may sit inside;
      // the note names the span the school entered, not just school days).
      final to = _today.add(const Duration(days: 3));
      await _pump(tester, _content([], [_perm([_today, to])]));

      final span = AppDates.dayRangeIn('az', _today, to);
      expect(find.text('Şagird $span tarixlərinə icazəlidir'), findsOneWidget);
    });
  });

  group('AppDates.dayRangeIn', () {
    setUpAll(() async {
      await initializeDateFormatting('en');
      await initializeDateFormatting('ru');
    });

    final d = DateTime.new;

    test('one month: its name once, where each language puts it', () {
      expect(AppDates.dayRangeIn('az', d(2026, 10, 17), d(2026, 10, 20)),
          '17–20 oktyabr');
      expect(AppDates.dayRangeIn('ru', d(2026, 10, 17), d(2026, 10, 20)),
          '17–20 октября');
      expect(AppDates.dayRangeIn('en', d(2026, 10, 17), d(2026, 10, 20)),
          'October 17–20');
    });

    test('across months, across years, and one day', () {
      expect(AppDates.dayRangeIn('az', d(2026, 9, 30), d(2026, 10, 2)),
          '30 sentyabr – 2 oktyabr');
      expect(AppDates.dayRangeIn('en', d(2026, 12, 30), d(2027, 1, 2)),
          'December 30, 2026 – January 2, 2027');
      expect(AppDates.dayRangeIn('az', d(2026, 10, 20), d(2026, 10, 20)),
          '20 oktyabr');
    });
  });
}
