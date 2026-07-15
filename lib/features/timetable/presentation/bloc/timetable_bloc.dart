import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/timetable_day.dart';
import '../../domain/entities/timetable_lesson.dart';
import '../../domain/usecases/get_timetable.dart';

part 'timetable_event.dart';
part 'timetable_state.dart';

class TimetableBloc extends Bloc<TimetableEvent, TimetableState> {
  final GetTimetable getTimetable;

  TimetableBloc({required this.getTimetable})
      : super(TimetableState(selectedDay: _todayWeekday())) {
    on<TimetableFetched>(_onFetched);
    on<TimetableRefreshed>(_onFetched);
    on<TimetableDaySelected>(_onDaySelected);
  }

  /// The Mon–Fri tab to open on: today when it is a weekday, else Monday.
  static int _todayWeekday() {
    final weekday = DateTime.now().weekday; // 1 = Mon … 7 = Sun
    return weekday >= 1 && weekday <= 5 ? weekday : 1;
  }

  Future<void> _onFetched(
    TimetableEvent event,
    Emitter<TimetableState> emit,
  ) async {
    // A pull-to-refresh keeps the current schedule on screen; the first load
    // has nothing to keep, so both paths just flip the status.
    emit(state.copyWith(status: TimetableStatus.loading));

    final result = await getTimetable(const NoParams());

    result.fold(
      (failure) => emit(state.copyWith(
        status: TimetableStatus.error,
        errorMessage: failure.message,
      )),
      // Built fresh rather than via copyWith so a null class_id (student with
      // no session) actually clears the previous one.
      (content) => emit(TimetableState(
        status: TimetableStatus.loaded,
        classId: content.classId,
        className: content.className,
        days: content.days,
        selectedDay: state.selectedDay,
      )),
    );
  }

  void _onDaySelected(
    TimetableDaySelected event,
    Emitter<TimetableState> emit,
  ) {
    emit(state.copyWith(selectedDay: event.dayOfWeek));
  }
}
