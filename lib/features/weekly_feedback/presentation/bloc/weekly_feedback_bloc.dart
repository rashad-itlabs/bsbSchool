import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/feedback_week.dart';
import '../../domain/entities/weekly_feedback.dart';
import '../../domain/entities/weekly_feedback_content.dart';
import '../../domain/usecases/get_weekly_feedback.dart';

part 'weekly_feedback_event.dart';
part 'weekly_feedback_state.dart';

class WeeklyFeedbackBloc
    extends Bloc<WeeklyFeedbackEvent, WeeklyFeedbackState> {
  final GetWeeklyFeedback getWeeklyFeedback;

  WeeklyFeedbackBloc({required this.getWeeklyFeedback})
      : super(const WeeklyFeedbackState()) {
    on<WeeklyFeedbackFetched>(_onFetched);
    on<WeeklyFeedbackRefreshed>(_onRefreshed);
    on<WeeklyFeedbackWeekSelected>(_onWeekSelected);
  }

  /// Opens on the latest week that has feedback. The server answers a request
  /// without a week with the current one, so when a newer-written week exists
  /// its feedback is fetched right after, with that week already highlighted.
  Future<void> _onFetched(
    WeeklyFeedbackFetched event,
    Emitter<WeeklyFeedbackState> emit,
  ) async {
    emit(state.copyWith(status: WeeklyFeedbackStatus.loading));

    final result = await getWeeklyFeedback(const WeeklyFeedbackParams());
    final content = result.fold((failure) {
      emit(state.copyWith(
        status: WeeklyFeedbackStatus.error,
        errorMessage: failure.message,
      ));
      return null;
    }, (content) => content);
    if (content == null) return;

    final loaded = _stateFrom(content);
    final latest = _latestWithFeedback(content.weeks);
    if (latest == null || latest == loaded.selectedWeek) {
      emit(loaded);
      return;
    }

    emit(loaded.copyWith(
      status: WeeklyFeedbackStatus.loading,
      selectedWeek: latest,
      feedback: const [],
    ));
    await _load(latest, emit);
  }

  /// The highest week number a teacher has written for, or null if none.
  static int? _latestWithFeedback(List<FeedbackWeek> weeks) {
    int? latest;
    for (final w in weeks) {
      if (w.hasFeedback && (latest == null || w.week > latest)) latest = w.week;
    }
    return latest;
  }

  /// Keeps the current week's feedback on screen while it reloads.
  Future<void> _onRefreshed(
    WeeklyFeedbackRefreshed event,
    Emitter<WeeklyFeedbackState> emit,
  ) async {
    emit(state.copyWith(status: WeeklyFeedbackStatus.loading));
    await _load(state.selectedWeek, emit);
  }

  Future<void> _onWeekSelected(
    WeeklyFeedbackWeekSelected event,
    Emitter<WeeklyFeedbackState> emit,
  ) async {
    if (!state.canSelect(event.week)) return;
    if (event.week == state.selectedWeek &&
        state.status == WeeklyFeedbackStatus.loaded) {
      return;
    }

    // Highlight the tapped week and clear the previous week's cards at once;
    // the grid stays as it is.
    emit(state.copyWith(
      status: WeeklyFeedbackStatus.loading,
      selectedWeek: event.week,
      feedback: const [],
    ));
    await _load(event.week, emit);
  }

  /// Fetches [week] (null: the current one) and applies it — unless the
  /// parent has tapped another week in the meantime, in which case this
  /// answer is stale and the newer request's answer will land instead.
  Future<void> _load(int? week, Emitter<WeeklyFeedbackState> emit) async {
    final result = await getWeeklyFeedback(WeeklyFeedbackParams(week: week));
    if (week != null && state.selectedWeek != week) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: WeeklyFeedbackStatus.error,
        errorMessage: failure.message,
      )),
      (content) => emit(_stateFrom(content)),
    );
  }

  /// Built fresh rather than via copyWith so a null week from the server
  /// (outside the school year) actually clears the previous one.
  static WeeklyFeedbackState _stateFrom(WeeklyFeedbackContent content) {
    return WeeklyFeedbackState(
      status: WeeklyFeedbackStatus.loaded,
      ready: content.ready,
      studentName: content.studentName,
      currentWeek: content.currentWeek,
      selectedWeek: content.selectedWeek ?? content.currentWeek,
      weeks: content.weeks,
      feedback: content.feedback,
    );
  }
}
