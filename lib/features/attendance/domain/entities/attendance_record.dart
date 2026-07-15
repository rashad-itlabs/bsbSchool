import 'package:equatable/equatable.dart';

/// One entry of the `data` array returned by `GET /attendance`.
class AttendanceRecord extends Equatable {
  final int id;

  /// The lesson day (`date`).
  final DateTime? date;

  /// All nullable on the server — a record may be logged without them.
  final String? subject;
  final String? section;
  final String? className;
  final String? teacher;

  /// Raw status text: `Present`, `Late`, `Absent`.
  final String status;

  /// Effort score the teacher logged (0 when not graded).
  final int effort;

  /// Free-text remark, when present.
  final String? note;

  const AttendanceRecord({
    required this.id,
    this.date,
    this.subject,
    this.section,
    this.className,
    this.teacher,
    this.status = 'Present',
    this.effort = 0,
    this.note,
  });

  /// Normalised status buckets so the UI never string-compares raw text.
  bool get isPresent => status.toLowerCase() == 'present';
  bool get isLate => status.toLowerCase() == 'late';
  bool get isAbsent => status.toLowerCase() == 'absent';

  @override
  List<Object?> get props =>
      [id, date, subject, section, className, teacher, status, effort, note];
}
