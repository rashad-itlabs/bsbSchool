part of 'weekly_feedback_bloc.dart';

enum WeeklyFeedbackStatus { initial, loading, loaded, error }

class WeeklyFeedbackState extends Equatable {
  final WeeklyFeedbackStatus status;

  /// False when the server has no school-year weeks to offer yet.
  final bool ready;

  final int? currentWeek;

  /// The highlighted week. Set the moment a week is tapped, so the grid
  /// answers the tap before its feedback has arrived.
  final int? selectedWeek;

  /// The grid; kept on screen while another week loads or fails.
  final List<FeedbackWeek> weeks;

  /// Feedback of [selectedWeek].
  final List<WeeklyFeedback> feedback;

  final String? errorMessage;

  const WeeklyFeedbackState({
    this.status = WeeklyFeedbackStatus.initial,
    this.ready = true,
    this.currentWeek,
    this.selectedWeek,
    this.weeks = const [],
    this.feedback = const [],
    this.errorMessage,
  });

  bool get isLoading => status == WeeklyFeedbackStatus.loading;

  /// Whether [week] can be picked: it exists and has started.
  bool canSelect(int week) =>
      weeks.any((w) => w.week == week && !w.isFuture);

  WeeklyFeedbackState copyWith({
    WeeklyFeedbackStatus? status,
    bool? ready,
    int? currentWeek,
    int? selectedWeek,
    List<FeedbackWeek>? weeks,
    List<WeeklyFeedback>? feedback,
    String? errorMessage,
  }) {
    return WeeklyFeedbackState(
      status: status ?? this.status,
      ready: ready ?? this.ready,
      currentWeek: currentWeek ?? this.currentWeek,
      selectedWeek: selectedWeek ?? this.selectedWeek,
      weeks: weeks ?? this.weeks,
      feedback: feedback ?? this.feedback,
      // Intentionally not carried over: only the state that failed shows it.
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        ready,
        currentWeek,
        selectedWeek,
        weeks,
        feedback,
        errorMessage,
      ];
}
