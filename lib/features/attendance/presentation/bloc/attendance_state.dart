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

  /// Records sorted newest first for the "recent logs" list.
  List<AttendanceRecord> get recentRecords {
    final sorted = [...records];
    sorted.sort((a, b) {
      final ad = a.date, bd = b.date;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });
    return sorted;
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
