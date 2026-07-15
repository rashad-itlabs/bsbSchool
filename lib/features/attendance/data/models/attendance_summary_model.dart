import '../../domain/entities/attendance_summary.dart';

class AttendanceSummaryModel extends AttendanceSummary {
  const AttendanceSummaryModel({
    super.total,
    super.present,
    super.late,
    super.absent,
  });

  /// Matches the `summary` object of the `GET /attendance` body.
  factory AttendanceSummaryModel.fromJson(Map<String, dynamic> json) =>
      AttendanceSummaryModel(
        total: _asInt(json['total']),
        present: _asInt(json['present']),
        late: _asInt(json['late']),
        absent: _asInt(json['absent']),
      );

  static int _asInt(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;
}
