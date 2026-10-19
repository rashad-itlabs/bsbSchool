import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/homework.dart';
import '../../domain/entities/homework_status_info.dart';
import '../../domain/usecases/get_homeworks.dart';

part 'homework_event.dart';
part 'homework_state.dart';

class HomeworkBloc extends Bloc<HomeworkEvent, HomeworkState> {
  final GetHomeworks getHomeworks;

  HomeworkBloc({required this.getHomeworks}) : super(const HomeworkState()) {
    on<HomeworkFetched>(_onFetched);
    on<HomeworkRefreshed>(_onFetched);
    on<HomeworkFiltersChanged>(_onFiltersChanged);
    on<HomeworkTabSelected>(_onTabSelected);
  }

  Future<void> _onFetched(
    HomeworkEvent event,
    Emitter<HomeworkState> emit,
  ) async {
    // A pull-to-refresh keeps the current list on screen; the first load has
    // nothing to keep, so both paths just flip the status.
    emit(state.copyWith(status: HomeworkStatus.loading));

    final result = await getHomeworks(const NoParams());

    result.fold(
      (failure) => emit(state.copyWith(
        status: HomeworkStatus.error,
        errorMessage: failure.message,
      )),
      // Built fresh rather than via copyWith so a null class_id (student with
      // no session) actually clears the previous one.
      (content) {
        final next = HomeworkState(
          status: HomeworkStatus.loaded,
          classId: content.classId,
          className: content.className,
          homeworks: content.homeworks,
          statusDictionary: content.statuses,
          tab: state.tab,
        );
        // The filters survive a refresh, less any pick the new list no longer
        // offers — it would hide everything with nothing in the sheet to undo.
        final sections = {for (final o in next.sectionOptions) o.key};
        final statuses = {for (final s in next.statusOptions) s.key};
        emit(next.withFilters(
          sections: state.sections.intersection(sections),
          statuses: state.statuses.intersection(statuses),
        ));
      },
    );
  }

  void _onFiltersChanged(
    HomeworkFiltersChanged event,
    Emitter<HomeworkState> emit,
  ) {
    emit(state.withFilters(
      sections: event.sections,
      statuses: event.statuses,
    ));
  }

  /// The filters hold across the tabs: the parent picked a subject, not a tab.
  void _onTabSelected(
    HomeworkTabSelected event,
    Emitter<HomeworkState> emit,
  ) {
    emit(state.copyWith(tab: event.tab));
  }
}
