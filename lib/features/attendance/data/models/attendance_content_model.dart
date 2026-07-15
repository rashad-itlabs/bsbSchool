import '../../domain/entities/attendance_content.dart';
import 'attendance_record_model.dart';
import 'attendance_summary_model.dart';

class AttendanceContentModel extends AttendanceContent {
  const AttendanceContentModel({
    super.studentId,
    super.summary,
    super.records,
  });

  /// Matches the whole `GET /attendance` body:
  /// `{ "student_id": 3132, "summary": { ... }, "data": [ ... ] }`
  factory AttendanceContentModel.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final records = raw is List
        ? raw
            .whereType<Map>()
            .map((e) =>
                AttendanceRecordModel.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <AttendanceRecordModel>[];

    final summary = json['summary'];
    final studentId = json['student_id'];

    return AttendanceContentModel(
      studentId: studentId is int
          ? studentId
          : int.tryParse(studentId?.toString() ?? ''),
      summary: summary is Map
          ? AttendanceSummaryModel.fromJson(Map<String, dynamic>.from(summary))
          : const AttendanceSummaryModel(),
      records: records,
    );
  }
}
