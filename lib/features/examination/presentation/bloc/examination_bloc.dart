import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/exam_group.dart';
import '../../domain/entities/exam_result.dart';
import '../../domain/usecases/get_examinations.dart';
import '../../../../core/l10n/l10n.dart';

part 'examination_event.dart';
part 'examination_state.dart';

class ExaminationBloc extends Bloc<ExaminationEvent, ExaminationState> {
  final GetExaminations getExaminations;

  ExaminationBloc({required this.getExaminations})
      : super(const ExaminationState()) {
    on<ExaminationFetched>(_onFetched);
    on<ExaminationRefreshed>(_onFetched);
    on<ExaminationSubjectSelected>(_onSubjectSelected);
    on<ExaminationGroupSelected>(_onGroupSelected);
    on<ExaminationExamSelected>(_onExamSelected);
    on<ExaminationFiltersCleared>(_onFiltersCleared);
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
        examGroup: state.examGroup,
        exam: state.exam,
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

  void _onGroupSelected(
    ExaminationGroupSelected event,
    Emitter<ExaminationState> emit,
  ) {
    emit(_pruned(state.copyWith(examGroup: event.examGroup)));
  }

  void _onExamSelected(
    ExaminationExamSelected event,
    Emitter<ExaminationState> emit,
  ) {
    emit(_pruned(state.copyWith(exam: event.exam)));
  }

  void _onFiltersCleared(
    ExaminationFiltersCleared event,
    Emitter<ExaminationState> emit,
  ) {
    emit(state.copyWith(
      examGroup: ExaminationState.any,
      exam: ExaminationState.any,
      subject: ExaminationState.any,
    ));
  }

  /// The exam and subject chips are scoped to the filters above them, so
  /// narrowing an outer filter can strand an inner one on a value that no
  /// longer exists — drop those back to "Hamısı" instead of showing nothing.
  ExaminationState _pruned(ExaminationState next) {
    var pruned = next;
    if (!pruned.examOptions.contains(pruned.exam)) {
      pruned = pruned.copyWith(exam: ExaminationState.any);
    }
    if (!pruned.subjects.contains(pruned.subject)) {
      pruned = pruned.copyWith(subject: ExaminationState.any);
    }
    return pruned;
  }
}
