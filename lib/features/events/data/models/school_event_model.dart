import '../../domain/entities/school_event.dart';

class SchoolEventModel extends SchoolEvent {
  const SchoolEventModel({
    required super.id,
    super.title,
    super.description,
    super.time,
    super.colorHex,
    super.date,
    super.endDate,
    super.classId,
  });

  /// Matches one entry of the `data` array returned by `GET /getEvent`.
  factory SchoolEventModel.fromJson(Map<String, dynamic> json) =>
      SchoolEventModel(
        id: _asInt(json['id']),
        title: _asString(json['title']) ?? '',
        description: _asString(json['description']) ?? '',
        time: _asTime(json['event_time']),
        colorHex: _asString(json['color']),
        date: _asDate(json['event_date']),
        endDate: _asDate(json['end_date']),
        classId: _asNullableInt(json['class_id']),
      );

  static int _asInt(dynamic value) => _asNullableInt(value) ?? 0;

  static int? _asNullableInt(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '');

  /// The API sends `null` for missing values; empty strings mean the same.
  static String? _asString(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  /// Dates arrive as `2026-09-01`. They are stored at midnight so day-level
  /// comparisons in the calendar never trip over a stray time component.
  static DateTime? _asDate(dynamic value) {
    final text = _asString(value);
    if (text == null) return null;
    final parsed = DateTime.tryParse(text);
    return parsed == null
        ? null
        : DateTime(parsed.year, parsed.month, parsed.day);
  }

  /// `10:00` normally, but a `10:00:00` would render as noise next to the
  /// title, so the seconds are dropped.
  static String? _asTime(dynamic value) {
    final text = _asString(value);
    if (text == null) return null;
    final parts = text.split(':');
    return parts.length >= 2
        ? '${parts[0].padLeft(2, '0')}:${parts[1]}'
        : text;
  }
}
