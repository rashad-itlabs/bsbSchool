import '../../domain/entities/attendance_record.dart';

class AttendanceRecordModel extends AttendanceRecord {
  const AttendanceRecordModel({
    required super.id,
    super.date,
    super.subject,
    super.section,
    super.className,
    super.teacher,
    super.status,
    super.effort,
    super.note,
    super.period,
    super.startTime,
    super.endTime,
  });

  /// Matches one entry of the `data` array returned by `GET /attendance`.
  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) =>
      AttendanceRecordModel(
        id: _asInt(json['id']),
        date: _asDate(json['date']),
        subject: _asString(json['subject']),
        section: _asString(json['section']),
        className: _asString(json['class']),
        teacher: _asString(json['teacher']),
        status: _asString(json['status']) ?? 'Present',
        effort: _asInt(json['effort']),
        note: _asString(json['note']),
        period: _asString(json['period']),
        startTime: _asString(json['start_time']),
        endTime: _asString(json['end_time']),
      );

  static int _asInt(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

  /// The API sends `null` for missing values; empty strings mean the same.
  static String? _asString(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  /// Dates come as `yyyy-MM-dd`; a bad value degrades to null, not a crash.
  static DateTime? _asDate(dynamic value) {
    final text = _asString(value);
    return text == null ? null : DateTime.tryParse(text);
  }
}
