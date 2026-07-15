import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/exam_group.dart';
import '../../domain/entities/exam_result.dart';
import '../../domain/usecases/get_examinations.dart';

part 'examination_event.dart';
part 'examination_state.dart';

class ExaminationBloc extends Bloc<ExaminationEvent, ExaminationState> {
  final GetExaminations getExaminations;

  ExaminationBloc({required this.getExaminations})
      : super(const ExaminationState()) {
    on<ExaminationFetched>(_onFetched);
    on<ExaminationRefreshed>(_onFetched);
    on<ExaminationSubjectSelected>(_onSubjectSelected);
  }

  Future<void> _onFetched(
    ExaminationEvent event,
    Emitter<ExaminationState> emit,
  ) async {
    // A pull-to-refresh keeps the current list on screen; the first load has
    // nothing to keep, so both paths just flip the status.
    emit(state.copyWith(status: ExaminationStatus.loading));

    final result = await getExaminations(const NoParams());

    result.fold(
      (failure) => emit(state.copyWith(
        status: ExaminationStatus.error,
        errorMessage: failure.message,
      )),
      // Built fresh rather than via copyWith so a null student_id (account with
      // no session) actually clears the previous one.
      (content) => emit(ExaminationState(
        status: ExaminationStatus.loaded,
        studentId: content.studentId,
        groups: content.groups,
        subject: state.subject,
      )),
    );
  }

  void _onSubjectSelected(
    ExaminationSubjectSelected event,
    Emitter<ExaminationState> emit,
  ) {
    emit(state.copyWith(subject: event.subject));
  }
}
