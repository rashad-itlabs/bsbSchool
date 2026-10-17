part of 'attendance_bloc.dart';

enum AttendanceStatus { initial, loading, loaded, error }

class AttendanceState extends Equatable {
  final AttendanceStatus status;

  final int? studentId;
  final AttendanceSummary summary;

  /// Every session the API returned, newest first once sorted.
  final List<AttendanceRecord> records;

  final String? errorMessage;

  const AttendanceState({
    this.status = AttendanceStatus.initial,
    this.studentId,
    this.summary = const AttendanceSummary(),
    this.records = const [],
    this.errorMessage,
  });

  bool get isLoading => status == AttendanceStatus.loading;

  /// Records sorted newest day first and, within a day, by lesson time (first
  /// lesson on top; a record without a slot goes last). Ties keep the server's
  /// order explicitly — Dart's `sort` is not stable.
  List<AttendanceRecord> get recentRecords {
    final indexed = records.indexed.toList();
    indexed.sort((x, y) {
      final a = x.$2, b = y.$2;
      final ad = a.date, bd = b.date;
      if (ad == null && bd != null) return 1;
      if (ad != null && bd == null) return -1;
      if (ad != null && bd != null) {
        final byDay = bd.compareTo(ad);
        if (byDay != 0) return byDay;
      }
      final at = a.startTime, bt = b.startTime;
      if (at == null && bt != null) return 1;
      if (at != null && bt == null) return -1;
      if (at != null && bt != null) {
        final byTime = at.compareTo(bt);
        if (byTime != 0) return byTime;
      }
      return x.$1.compareTo(y.$1);
    });
    return [for (final e in indexed) e.$2];
  }

  AttendanceState copyWith({
    AttendanceStatus? status,
    int? studentId,
    AttendanceSummary? summary,
    List<AttendanceRecord>? records,
    String? errorMessage,
  }) {
    return AttendanceState(
      status: status ?? this.status,
      studentId: studentId ?? this.studentId,
      summary: summary ?? this.summary,
      records: records ?? this.records,
      // Intentionally not carried over: only the state that failed shows it.
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, studentId, summary, records, errorMessage];
}
