import '../../domain/entities/timetable_lesson.dart';

class TimetableLessonModel extends TimetableLesson {
  const TimetableLessonModel({
    required super.id,
    super.subject,
    super.section,
    super.teacher,
    super.period,
    super.startTime,
    super.endTime,
  });

  /// Matches one entry of a day's `lessons` array.
  factory TimetableLessonModel.fromJson(Map<String, dynamic> json) =>
      TimetableLessonModel(
        id: _asInt(json['id']),
        subject: _asString(json['subject']) ?? '',
        section: _asString(json['section']),
        teacher: _asString(json['teacher']),
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
}
