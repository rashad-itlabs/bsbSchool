import 'package:bsbschool/features/attendance/data/models/attendance_record_model.dart';
import 'package:bsbschool/features/attendance/domain/entities/attendance_record.dart';
import 'package:bsbschool/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

AttendanceRecord _rec(int id, String day, [String? start]) => AttendanceRecord(
      id: id,
      date: DateTime.parse(day),
      startTime: start,
    );

List<int> _ids(List<AttendanceRecord> list) => [for (final r in list) r.id];

void main() {
  group('AttendanceRecordModel.fromJson — lesson time (server 17.10.2026)', () {
    test('reads period, start_time and end_time; trims to HH:mm', () {
      final r = AttendanceRecordModel.fromJson({
        'id': 1,
        'date': '2026-10-16',
        'period': 'Period 3',
        'start_time': '09:20:00',
        'end_time': '10:00:00',
        'subject': 'Azeri History',
        'status': 'Present',
      });
      expect(r.period, 'Period 3');
      expect(r.startTime, '09:20:00');
      expect(r.startShort, '09:20');
      expect(r.endShort, '10:00');
    });

    test('record without a lesson slot, and an older server: all null', () {
      final noSlot = AttendanceRecordModel.fromJson({
        'id': 2,
        'date': '2026-10-16',
        'period': null,
        'start_time': null,
        'end_time': null,
      });
      final oldServer =
          AttendanceRecordModel.fromJson({'id': 3, 'date': '2026-10-16'});
      for (final r in [noSlot, oldServer]) {
        expect(r.startTime, isNull);
        expect(r.startShort, isNull);
        expect(r.endShort, isNull);
        expect(r.period, isNull);
      }
    });
  });

  group('AttendanceState.recentRecords', () {
    test('newest day first; within a day by lesson time; no slot last', () {
      // API order scrambled on purpose (the app must not rely on it).
      final state = AttendanceState(records: [
        _rec(10, '2026-10-15', '11:00:00'),
        _rec(1, '2026-10-16', '14:20:00'),
        _rec(2, '2026-10-16'),
        _rec(3, '2026-10-16', '08:30:00'),
        _rec(11, '2026-10-15', '08:40:00'),
        _rec(4, '2026-10-16', '09:20:00'),
      ]);
      expect(_ids(state.recentRecords), [3, 4, 1, 2, 11, 10]);
    });

    test('equal times keep the server order (stable on 40 records)', () {
      // Above 32 elements Dart's sort is not insertion sort, so stability
      // has to come from the comparator's own tie-break.
      final records = [
        for (var i = 0; i < 40; i++) _rec(i, '2026-10-16', '09:20:00'),
      ];
      final state = AttendanceState(records: records);
      expect(_ids(state.recentRecords), [for (var i = 0; i < 40; i++) i]);
    });
  });
}
