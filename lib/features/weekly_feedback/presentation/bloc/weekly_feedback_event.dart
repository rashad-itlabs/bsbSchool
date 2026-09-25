part of 'weekly_feedback_bloc.dart';

abstract class WeeklyFeedbackEvent extends Equatable {
  const WeeklyFeedbackEvent();

  @override
  List<Object?> get props => [];
}

/// First load of the screen — the server answers with the current week.
class WeeklyFeedbackFetched extends WeeklyFeedbackEvent {
  const WeeklyFeedbackFetched();
}

/// Pull-to-refresh / retry after an error: reloads the selected week.
class WeeklyFeedbackRefreshed extends WeeklyFeedbackEvent {
  const WeeklyFeedbackRefreshed();
}

/// The parent tapped a week on the grid.
class WeeklyFeedbackWeekSelected extends WeeklyFeedbackEvent {
  final int week;

  const WeeklyFeedbackWeekSelected(this.week);

  @override
  List<Object?> get props => [week];
}
