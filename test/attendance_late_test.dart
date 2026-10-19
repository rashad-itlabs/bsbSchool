import 'package:bsbschool/core/di/injection_container.dart';
import 'package:bsbschool/core/error/failures.dart';
import 'package:bsbschool/dr/screens/attendance_screen.dart';
import 'package:bsbschool/dr/theme/dr_theme.dart';
import 'package:bsbschool/features/attendance/data/models/attendance_content_model.dart';
import 'package:bsbschool/features/attendance/data/models/attendance_record_model.dart';
import 'package:bsbschool/features/attendance/domain/entities/attendance_content.dart';
import 'package:bsbschool/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:bsbschool/features/attendance/domain/usecases/get_attendance.dart';
import 'package:bsbschool/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:bsbschool/l10n/app_localizations.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

/// A record as `ApiController::attendance` sends it since 19.10.2026.
Map<String, dynamic> _row(int id, String subject, String status, String start,
        {String? lateAt,
        int? lateMinutes,
        bool inOther = false,
        String? inOtherText}) =>
    {
      'id': id,
      'date': _day(_today),
      'subject': subject,
      'status': status,
      'start_time': start,
      'late_at': lateAt,
      'late_minutes': lateMinutes,
      'in_other_lesson': inOther,
      'in_other_lesson_text': inOtherText,
    };

Future<void> _pump(WidgetTester tester, List<Map<String, dynamic>> rows,
    {double width = 390}) async {
  SharedPreferences.setMockInitialValues({});
  await sl.reset();
  await initDependencies();
  sl.unregister<AttendanceBloc>();
  final content =
      AttendanceContentModel.fromJson({'student_id': 1, 'data': rows});
  sl.registerFactory<AttendanceBloc>(
    () => AttendanceBloc(getAttendance: GetAttendance(_FakeRepo(content))),
  );
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
  group('late time and "in another lesson" (server 19.10.2026, E-039)', () {
    test('parsed from the record', () {
      final late = AttendanceRecordModel.fromJson(
          _row(1, 'Math', 'Late', '09:10:00', lateAt: '09:45', lateMinutes: 35));
      expect(late.lateAt, '09:45');
      expect(late.lateMinutes, 35);
      expect(late.inOtherLesson, isFalse);

      final away = AttendanceRecordModel.fromJson(_row(2, 'Art', 'Absent',
          '10:00:00',
          inOther: true, inOtherText: 'bu saatda başqa dərsdə qeyd'));
      expect(away.inOtherLesson, isTrue);
      expect(away.inOtherLessonText, 'bu saatda başqa dərsdə qeyd');
    });

    test('an older server: no fields, nothing breaks', () {
      final r = AttendanceRecordModel.fromJson(
          {'id': 1, 'date': '2026-10-19', 'status': 'Late'});
      expect(r.lateAt, isNull);
      expect(r.lateMinutes, isNull);
      expect(r.inOtherLesson, isFalse);
      expect(r.inOtherLessonText, isNull);
    });

    testWidgets('late: minutes and arrival under the teacher', (tester) async {
      await _pump(tester, [
        _row(1, 'Mathematics', 'Late', '09:10:00',
            lateAt: '09:45', lateMinutes: 35),
        _row(2, 'Geography', 'Late', '10:00:00', lateAt: '10:12'),
        _row(3, 'History', 'Late', '11:00:00'), // logged before 19.10
      ]);
      expect(find.text('35 dəq gecikib · gəlmə saatı 09:45'), findsOneWidget);
      expect(find.text('gəlmə saatı 10:12'), findsOneWidget);
      expect(find.textContaining('gəlmə saatı'), findsNWidgets(2));
    });

    testWidgets('absent but in another lesson: the server text, or ours',
        (tester) async {
      await _pump(tester, [
        _row(1, 'Art', 'Absent', '08:40:00',
            inOther: true, inOtherText: 'SERVER: başqa dərsdə qeyd olunub'),
        _row(2, 'Music', 'Absent', '09:20:00', inOther: true),
        _row(3, 'PE', 'Absent', '10:00:00'),
      ]);
      expect(find.text('SERVER: başqa dərsdə qeyd olunub'), findsOneWidget);
      expect(find.text('bu saatda başqa dərsdə «iştirak» qeyd olunub'),
          findsOneWidget);
    });

    testWidgets('no overflow on a narrow phone', (tester) async {
      await _pump(
          tester,
          [
            _row(1, 'Mathematics', 'Late', '09:10:00',
                lateAt: '09:45', lateMinutes: 35),
            _row(2, 'Art', 'Absent', '10:00:00', inOther: true),
          ],
          width: 320);
      expect(tester.takeException(), isNull);
    });
  });
}
