import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/homework.dart';
import '../../domain/usecases/get_homeworks.dart';

part 'homework_event.dart';
part 'homework_state.dart';

class HomeworkBloc extends Bloc<HomeworkEvent, HomeworkState> {
  final GetHomeworks getHomeworks;

  HomeworkBloc({required this.getHomeworks}) : super(const HomeworkState()) {
    on<HomeworkFetched>(_onFetched);
    on<HomeworkRefreshed>(_onFetched);
    on<HomeworkSubjectSelected>(_onSubjectSelected);
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
      (content) => emit(HomeworkState(
        status: HomeworkStatus.loaded,
        classId: content.classId,
        className: content.className,
        homeworks: content.homeworks,
        subject: state.subject,
      )),
    );
  }

  void _onSubjectSelected(
    HomeworkSubjectSelected event,
    Emitter<HomeworkState> emit,
  ) {
    emit(state.copyWith(subject: event.subject));
  }
}
