import '../../domain/entities/timetable_day.dart';
import 'timetable_lesson_model.dart';

class TimetableDayModel extends TimetableDay {
  const TimetableDayModel({
    required super.dayOfWeek,
    super.dayName,
    super.lessons,
  });

  /// Matches one entry of the `data` array.
  factory TimetableDayModel.fromJson(Map<String, dynamic> json) {
    final raw = json['lessons'];
    final lessons = raw is List
        ? raw
            .whereType<Map>()
            .map((e) =>
                TimetableLessonModel.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <TimetableLessonModel>[];

    return TimetableDayModel(
      dayOfWeek: _asInt(json['day_of_week']),
      dayName: _asString(json['day_name']) ?? '',
      lessons: lessons,
    );
  }

  static int _asInt(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

  static String? _asString(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }
}
