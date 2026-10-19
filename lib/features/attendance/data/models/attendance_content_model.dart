import '../../domain/entities/attendance_content.dart';
import '../../domain/entities/attendance_permission.dart';
import 'attendance_record_model.dart';
import 'attendance_summary_model.dart';

class AttendanceContentModel extends AttendanceContent {
  const AttendanceContentModel({
    super.studentId,
    super.summary,
    super.records,
    super.permissions,
  });

  /// Matches the whole `GET /attendance` body:
  /// `{ "student_id": 3132, "summary": { ... }, "data": [ ... ],
  ///    "permissions": [ ... ] }` — `permissions` since 19.10.2026.
  factory AttendanceContentModel.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final records = raw is List
        ? raw
            .whereType<Map>()
            .map((e) =>
                AttendanceRecordModel.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <AttendanceRecordModel>[];

    final perms = json['permissions'];
    final permissions = perms is List
        ? perms
            .whereType<Map>()
            .map((e) => _permission(Map<String, dynamic>.from(e)))
            .whereType<AttendancePermission>()
            .toList()
        : <AttendancePermission>[];

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
      permissions: permissions,
    );
  }

  /// One `permissions` entry; one without usable dates is dropped — it would
  /// colour nothing and say nothing.
  static AttendancePermission? _permission(Map<String, dynamic> json) {
    final raw = json['dates'];
    final dates = [
      for (final d in (raw is List ? raw : const []))
        DateTime.tryParse(d?.toString() ?? ''),
    ].whereType<DateTime>().toList();
    if (dates.isEmpty) return null;

    final labels = json['labels'];
    return AttendancePermission(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      dateFrom: DateTime.tryParse(json['date_from']?.toString() ?? ''),
      dateTo: DateTime.tryParse(json['date_to']?.toString() ?? ''),
      kind: _text(json['kind']) ?? 'day',
      time: _text(json['time']),
      dates: dates,
      label: _text(json['label']) ?? '',
      labels: {
        if (labels is Map)
          for (final e in labels.entries)
            if (_text(e.value) != null) e.key.toString(): _text(e.value)!,
      },
    );
  }

  static String? _text(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }
}
