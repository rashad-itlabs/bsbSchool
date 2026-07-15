import 'package:equatable/equatable.dart';

import 'timetable_day.dart';

/// The full `GET /class-timetable` payload: the student's class plus the
/// per-day schedule scoped to it.
class TimetableContent extends Equatable {
  final int? classId;
  final String? className;
  final List<TimetableDay> days;

  const TimetableContent({
    this.classId,
    this.className,
    this.days = const [],
  });

  @override
  List<Object?> get props => [classId, className, days];
}
