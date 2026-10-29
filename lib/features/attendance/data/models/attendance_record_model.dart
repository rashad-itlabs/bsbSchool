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
    super.excused,
    super.excusedNotes,
    super.excusedNotesText,
    super.effort,
    super.note,
    super.period,
    super.startTime,
    super.endTime,
    super.lateAt,
    super.lateMinutes,
    super.inOtherLesson,
    super.inOtherLessonText,
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
        excused: _asBool(json['excused']),
        excusedNotes: _asStrings(json['excused_notes']),
        excusedNotesText: _asStrings(json['excused_notes_text']),
        effort: _asInt(json['effort']),
        note: _asString(json['note']),
        period: _asString(json['period']),
        startTime: _asString(json['start_time']),
        endTime: _asString(json['end_time']),
        lateAt: _asString(json['late_at']),
        lateMinutes: _asNullableInt(json['late_minutes']),
        inOtherLesson: _asBool(json['in_other_lesson']),
        inOtherLessonText: _asString(json['in_other_lesson_text']),
      );

  /// `late_minutes` — a number or null; anything unreadable is null, not 0
  /// (0 would print «0 min late»).
  static int? _asNullableInt(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '');

  static int _asInt(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

  /// `excused` is a JSON bool; `1` / `"true"` are tolerated, anything else
  /// (absent on an older server) is false.
  static bool _asBool(dynamic value) =>
      value == true ||
      value == 1 ||
      const ['true', '1'].contains(value?.toString().toLowerCase());

  /// The API sends `null` for missing values; empty strings mean the same.
  static String? _asString(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  /// A JSON list of texts, blanks dropped; anything else (absent on an older
  /// server, null) is empty.
  static List<String> _asStrings(dynamic value) => value is List
      ? [for (final v in value) ?_asString(v)]
      : const [];

  /// Dates come as `yyyy-MM-dd`; a bad value degrades to null, not a crash.
  static DateTime? _asDate(dynamic value) {
    final text = _asString(value);
    return text == null ? null : DateTime.tryParse(text);
  }
}
