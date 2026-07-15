import 'package:equatable/equatable.dart';

import 'attendance_record.dart';
import 'attendance_summary.dart';

/// The full `GET /attendance` payload: the student id, the pre-tallied
/// [summary], and the per-session [records].
class AttendanceContent extends Equatable {
  final int? studentId;
  final AttendanceSummary summary;
  final List<AttendanceRecord> records;

  const AttendanceContent({
    this.studentId,
    this.summary = const AttendanceSummary(),
    this.records = const [],
  });

  @override
  List<Object?> get props => [studentId, summary, records];
}
