import 'package:equatable/equatable.dart';

/// One entry of a day's `lessons` array returned by `GET /class-timetable`.
class TimetableLesson extends Equatable {
  final int id;
  final String subject;

  /// All nullable on the server — a lesson may be catalogued without them.
  final String? section;
  final String? teacher;
  final String? period;

  /// Raw `HH:mm:ss` clock times; the UI trims them to `HH:mm`.
  final String? startTime;
  final String? endTime;

  const TimetableLesson({
    required this.id,
    this.subject = '',
    this.section,
    this.teacher,
    this.period,
    this.startTime,
    this.endTime,
  });

  /// `08:30:00` + `08:40:00` -> `08:30 - 08:40`; falls back to whichever end
  /// is present, or an empty string when neither is.
  String get timeRange {
    final start = _short(startTime);
    final end = _short(endTime);
    if (start != null && end != null) return '$start - $end';
    return start ?? end ?? '';
  }

  static String? _short(String? clock) {
    if (clock == null || clock.length < 5) return clock;
    return clock.substring(0, 5);
  }

  @override
  List<Object?> get props =>
      [id, subject, section, teacher, period, startTime, endTime];
}
