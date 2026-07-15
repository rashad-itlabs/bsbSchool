part of 'timetable_bloc.dart';

abstract class TimetableEvent extends Equatable {
  const TimetableEvent();

  @override
  List<Object?> get props => [];
}

/// First load of the screen.
class TimetableFetched extends TimetableEvent {
  const TimetableFetched();
}

/// Pull-to-refresh / retry after an error.
class TimetableRefreshed extends TimetableEvent {
  const TimetableRefreshed();
}

/// User tapped a weekday tab. [dayOfWeek] is 1 (Mon) … 5 (Fri).
class TimetableDaySelected extends TimetableEvent {
  final int dayOfWeek;

  const TimetableDaySelected(this.dayOfWeek);

  @override
  List<Object?> get props => [dayOfWeek];
}
