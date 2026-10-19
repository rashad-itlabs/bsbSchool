import 'package:bsbschool/core/di/injection_container.dart';
import 'package:bsbschool/core/error/failures.dart';
import 'package:bsbschool/dr/screens/attendance_screen.dart';
import 'package:bsbschool/dr/theme/dr_theme.dart';
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

/// A day as the server sends it (17.10.2026): sections carry their auto-name.
final _records = [
  AttendanceRecord(
    id: 1,
    date: _today,
    subject: 'Geography',
    section: 'Geography-Year 5 Tanco Jesus Tanco Jesus',
    teacher: 'Tanco Jesus',
    startTime: '08:30:00',
    endTime: '09:10:00',
  ),
  AttendanceRecord(
    id: 2,
    date: _today,
    subject: 'Numeracy Support',
    section: 'Numeracy Support-Year 5 Tanco Jesus Javahirkhanim Aliyeva',
    teacher: 'Javahirkhanim Aliyeva',
    status: 'Absent',
    startTime: '12:50:00',
    endTime: '13:30:00',
  ),
  AttendanceRecord(
    id: 3,
    date: _today,
    subject: 'Mindfulness',
    section: 'Mindfulness-Year 5 Tanco Jesus Tanco Jesus',
    status: 'Meeting',
    startTime: '08:20:00',
    endTime: '08:30:00',
  ),
  // The one section the school named itself.
  AttendanceRecord(
    id: 4,
    date: _today,
    subject: 'Chemistry',
    section: 'Year 8 Chemistry — lab group',
    teacher: 'Andres Moreno',
    status: 'Late',
    startTime: '14:10:00',
    endTime: '14:50:00',
  ),
];

Future<void> _pump(WidgetTester tester, {double width = 390}) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = Size(width * 3, 2400 * 3);
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
  group('lessonName', () {
    AttendanceRecord rec({String? subject, String? section}) =>
        AttendanceRecord(id: 1, subject: subject, section: section);

    test("an auto-named section shows as its subject", () {
      expect(
        rec(subject: 'Geography', section: 'Geography-Year 5 A B').lessonName,
        'Geography',
      );
    });

    test('a name the school gave the section is kept', () {
      expect(
        rec(subject: 'Chemistry', section: 'Year 8 Chemistry lab').lessonName,
        'Year 8 Chemistry lab',
      );
    });

    test('whichever of the two is there; null when neither', () {
      expect(rec(subject: 'Art').lessonName, 'Art');
      expect(rec(section: 'Art-Year 5 A B').lessonName, 'Art-Year 5 A B');
      expect(rec(subject: '  ', section: '').lessonName, isNull);
      expect(rec().lessonName, isNull);
    });
  });

  group('the day list', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await sl.reset();
      await initDependencies();
      sl.unregister<AttendanceBloc>();
      sl.registerFactory<AttendanceBloc>(
        () => AttendanceBloc(getAttendance: GetAttendance(_FakeRepo(_records))),
      );
    });

    testWidgets('names the subject, not the section auto-name', (tester) async {
      await _pump(tester);

      expect(find.text('Geography'), findsOneWidget);
      expect(find.text('Numeracy Support'), findsOneWidget);
      expect(find.textContaining('Year 5 Tanco Jesus'), findsNothing);
      expect(find.text('Year 8 Chemistry — lab group'), findsOneWidget);
    });

    testWidgets('the teacher alone under it — the header already has the day',
        (tester) async {
      await _pump(tester);

      expect(find.text('Tanco Jesus'), findsOneWidget);
      expect(find.text('Javahirkhanim Aliyeva'), findsOneWidget);
      expect(find.textContaining(' • '), findsNothing);
    });

    testWidgets('every status reads in the app language, "Meeting" too',
        (tester) async {
      await _pump(tester);

      expect(find.text('Gəlib'), findsOneWidget);
      expect(find.text('Qayıb'), findsWidgets); // the pill and a stat card
      expect(find.text('Gecikib'), findsOneWidget);
      expect(find.text('Görüşdə'), findsOneWidget);
      expect(find.text('Meeting'), findsNothing);
    });

    testWidgets('no overflow on a narrow phone', (tester) async {
      await _pump(tester, width: 320);
      expect(tester.takeException(), isNull);
      expect(find.text('Görüşdə'), findsOneWidget);
    });

    testWidgets('the month legend under the calendar sits two to a row',
        (tester) async {
      await _pump(tester, width: 320);

      // `Gəlib 3`, not the row's `Gəlib` pill.
      Finder legend(String label) => find.byWidgetPredicate((w) =>
          w is Text && RegExp('^$label \\d+\$').hasMatch(w.data ?? ''));
      Offset at(String label) => tester.getTopLeft(legend(label));

      expect(at('Gəlib').dy, at('Gecikib').dy);
      expect(at('Gəlib').dx, lessThan(at('Gecikib').dx));
      expect(at('Qayıb').dy, greaterThan(at('Gəlib').dy));
      expect(at('Qayıb').dy, at('Qarışıq').dy);
      expect(at('Qayıb').dx, at('Gəlib').dx);
      // Whether a label is cut short is not checked: the test font draws every
      // glyph a full em wide — `Gecikib 0` takes 108 px here, ~55 in Inter.
      expect(tester.takeException(), isNull);
    });
  });
}
