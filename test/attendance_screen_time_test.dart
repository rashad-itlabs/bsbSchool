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

AttendanceRecord _rec(int id, String subject, [String? start, String? end]) =>
    AttendanceRecord(
      id: id,
      date: _today,
      subject: subject,
      startTime: start,
      endTime: end,
    );

/// Today's lessons in a scrambled API order, one logged without a slot.
final _records = [
  _rec(1, 'Art', '14:20:00', '15:00:00'),
  _rec(2, 'English Literature'),
  _rec(3, 'Registration', '08:30:00', '08:40:00'),
  _rec(4, 'Azeri History', '09:20:00', '10:00:00'),
];

Future<void> _pump(WidgetTester tester,
    {double width = 390, double textScale = 1}) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = Size(width * 3, 2400 * 3);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    theme: DrTheme.dark,
    locale: const Locale('az'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: const AttendanceScreen(),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
    await initDependencies();
    sl.unregister<AttendanceBloc>();
    sl.registerFactory<AttendanceBloc>(
      () => AttendanceBloc(getAttendance: GetAttendance(_FakeRepo(_records))),
    );
  });

  testWidgets('lesson time sits left of the lesson name', (tester) async {
    await _pump(tester);

    final time = tester.getTopLeft(find.text('09:20'));
    final name = tester.getTopLeft(find.text('Azeri History'));
    expect(time.dx, lessThan(name.dx));
    expect(find.text('10:00'), findsOneWidget); // end time under the start
  });

  testWidgets('the day lists lessons by time; a slotless one last with a dash',
      (tester) async {
    await _pump(tester);

    double y(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(y('Registration'), lessThan(y('Azeri History')));
    expect(y('Azeri History'), lessThan(y('Art')));
    expect(y('Art'), lessThan(y('English Literature')));
    expect(find.text('—'), findsWidgets);
  });

  // At text scale 1.3+ the screen already overflowed before the time column
  // (17.10.2026: same single overflow with and without it, 320–390 px wide —
  // not in the lesson rows), so this pins the default scale on a narrow phone.
  testWidgets('no overflow on a narrow phone', (tester) async {
    await _pump(tester, width: 320);
    expect(tester.takeException(), isNull);
    expect(find.text('08:30'), findsOneWidget);
  });
}
