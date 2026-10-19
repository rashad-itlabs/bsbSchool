import 'package:equatable/equatable.dart';

import 'attendance_permission.dart';
import 'attendance_record.dart';
import 'attendance_summary.dart';

/// The full `GET /attendance` payload: the student id, the pre-tallied
/// [summary], the per-session [records], and the child's [permissions]
/// (server 19.10.2026; empty on an older one).
class AttendanceContent extends Equatable {
  final int? studentId;
  final AttendanceSummary summary;
  final List<AttendanceRecord> records;
  final List<AttendancePermission> permissions;

  const AttendanceContent({
    this.studentId,
    this.summary = const AttendanceSummary(),
    this.records = const [],
    this.permissions = const [],
  });

  @override
  List<Object?> get props => [studentId, summary, records, permissions];
}
