import 'package:equatable/equatable.dart';

import 'timetable_lesson.dart';

/// One entry of the `data` array returned by `GET /class-timetable`: a weekday
/// and the lessons scheduled on it.
class TimetableDay extends Equatable {
  /// ISO weekday: 1 = Monday … 7 = Sunday.
  final int dayOfWeek;

  /// Localised weekday name straight from the server (`Bazar ertəsi`).
  final String dayName;

  final List<TimetableLesson> lessons;

  const TimetableDay({
    required this.dayOfWeek,
    this.dayName = '',
    this.lessons = const [],
  });

  @override
  List<Object?> get props => [dayOfWeek, dayName, lessons];
}
