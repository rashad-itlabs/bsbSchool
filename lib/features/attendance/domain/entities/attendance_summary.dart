import 'package:equatable/equatable.dart';

/// The `summary` object of the `GET /attendance` payload: session counts the
/// server has already tallied so the UI never has to recompute them.
class AttendanceSummary extends Equatable {
  final int total;
  final int present;
  final int late;
  final int absent;

  const AttendanceSummary({
    this.total = 0,
    this.present = 0,
    this.late = 0,
    this.absent = 0,
  });

  /// Attendance rate as a whole percent (present + late count as attended).
  /// Zero sessions reads as 100% rather than a divide-by-zero.
  int get attendanceRate {
    if (total == 0) return 100;
    return (((present + late) / total) * 100).round();
  }

  @override
  List<Object?> get props => [total, present, late, absent];
}
