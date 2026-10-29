import 'package:bsbschool/core/di/injection_container.dart';
import 'package:bsbschool/core/error/failures.dart';
import 'package:bsbschool/dr/screens/attendance_screen.dart';
import 'package:bsbschool/dr/theme/dr_theme.dart';
import 'package:bsbschool/features/attendance/data/models/attendance_record_model.dart';
import 'package:bsbschool/features/attendance/domain/entities/attendance_content.dart';
import 'package:bsbschool/features/attendance/domain/entities/attendance_record.dart';
import 'package:bsbschool/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:bsbschool/features/attendance/domain/usecases/get_attendance.dart';
import 'package:bsbschool/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:bsbschool/l10n/app_localizations.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRepo implements AttendanceRepository {
  final List<AttendanceRecord> records;
  _FakeRepo(this.records);
  @override
  Future<Either<Failure, AttendanceContent>> getAttendance() async =>
      Right(AttendanceContent(records: records));
}

final _today = () {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}();

AttendanceRecord _rec(
  int id,
  String status,
  String start, {
  bool excused = false,
  List<String> notes = const [],
}) => AttendanceRecord(
  id: id,
  date: _today,
  subject: 'Lesson $id',
  status: status,
  excused: excused,
  excusedNotes: notes,
  excusedNotesText: [for (final n in notes) 'İcazə: $n'],
  startTime: start,
  endTime: start.replaceFirst(RegExp(r'^\d\d'), '11'),
);

Future<void> _pump(WidgetTester tester, List<AttendanceRecord> records) async {
  SharedPreferences.setMockInitialValues({});
  await sl.reset();
  await initDependencies();
  sl.unregister<AttendanceBloc>();
  sl.registerFactory<AttendanceBloc>(
    () => AttendanceBloc(getAttendance: GetAttendance(_FakeRepo(records))),
  );
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(390 * 3, 2400 * 3);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: DrTheme.dark,
      locale: const Locale('az'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: const AttendanceScreen(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Excused (QƏRAR-107, server 17.10.2026)', () {
    test('today: `Absent` + excused flag is excused, not absent', () {
      final r = AttendanceRecordModel.fromJson({
        'id': 1,
        'date': '2026-10-17',
        'status': 'Absent',
        'excused': true,
      });
      expect(r.isExcused, isTrue);
      expect(r.isAbsent, isFalse);
    });

    test('after E-038: the raw word `Excused` works the same', () {
      final r = AttendanceRecordModel.fromJson({
        'id': 1,
        'date': '2026-10-17',
        'status': 'Excused',
        'excused': true,
      });
      expect(r.isExcused, isTrue);
      expect(r.isAbsent, isFalse);
    });

    test('an older server (no flag): `Absent` stays an absence', () {
      final r = AttendanceRecordModel.fromJson({
        'id': 1,
        'date': '2026-10-17',
        'status': 'Absent',
      });
      expect(r.isExcused, isFalse);
      expect(r.isAbsent, isTrue);
    });

    testWidgets('pill, absent card and rate (P+L ÷ P+L+A+E)', (tester) async {
      await _pump(tester, [
        _rec(1, 'Present', '08:30:00'),
        _rec(2, 'Absent', '09:20:00'),
        _rec(3, 'Absent', '10:00:00', excused: true),
      ]);
      expect(find.text('İcazəli'), findsOneWidget); // the excused lesson's pill
      expect(find.text('33%'), findsOneWidget); // 1 ÷ 3 — QƏRAR-07
      // One real absence on the card, not two.
      final absentCard = find.ancestor(
        of: find.text('QAYIB'),
        matching: find.byType(Column),
      );
      expect(
        find.descendant(of: absentCard.first, matching: find.text('1')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a day excused from start to end gets its legend item', (
      tester,
    ) async {
      await _pump(tester, [
        _rec(1, 'Absent', '08:30:00', excused: true),
        _rec(2, 'Excused', '09:20:00'),
      ]);
      expect(find.text('İcazəli 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no excused day, no fifth legend item', (tester) async {
      await _pump(tester, [_rec(1, 'Present', '08:30:00')]);
      expect(find.textContaining('İcazəli'), findsNothing);
    });
  });

  group("the permission's note (server 20.10.2026)", () {
    test('both lists are read, blanks dropped', () {
      final r = AttendanceRecordModel.fromJson({
        'id': 1,
        'status': 'Absent',
        'excused': true,
        'excused_notes': ['Həkimə gedir', ' ', null],
        'excused_notes_text': ['İcazə: Həkimə gedir'],
      });
      expect(r.excusedNotes, ['Həkimə gedir']);
      expect(r.excusedNotesText, ['İcazə: Həkimə gedir']);
      expect(r.hasExcusedNote, isTrue);
    });

    test('an older server, or a lone string, is no note', () {
      final old = AttendanceRecordModel.fromJson({'id': 1, 'excused': true});
      final odd = AttendanceRecordModel.fromJson(
          {'id': 1, 'excused': true, 'excused_notes': 'Həkimə gedir'});
      expect(old.excusedNotes, isEmpty);
      expect(odd.excusedNotes, isEmpty);
      expect(old.hasExcusedNote, isFalse);
    });

    test('a note on a lesson that is not excused opens nothing', () {
      final r = AttendanceRecordModel.fromJson({
        'id': 1,
        'status': 'Present',
        'excused_notes': ['Həkimə gedir'],
      });
      expect(r.hasExcusedNote, isFalse);
    });

    testWidgets('the pill with a note carries an ⓘ and opens it', (
      tester,
    ) async {
      await _pump(tester, [
        _rec(1, 'Present', '08:30:00'),
        _rec(2, 'Excused', '09:20:00', notes: ['Həkimə gedir']),
        _rec(3, 'Excused', '10:00:00'),
      ]);
      // Two excused pills, only the one with a note is a button.
      expect(find.text('İcazəli'), findsNWidgets(2));
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.info_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.text('İcazə'), findsOneWidget);
      expect(find.text('Həkimə gedir'), findsOneWidget);
      expect(find.textContaining('Lesson 2 · '), findsOneWidget);
      expect(find.textContaining('09:20–11:20'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a screen reader hears the note on the pill', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, [
        _rec(1, 'Excused', '09:20:00', notes: ['Həkimə gedir']),
      ]);
      expect(
        find.bySemanticsLabel('İcazəli. İcazə: Həkimə gedir'),
        findsOneWidget,
      );
      semantics.dispose();
    });
  });
}
