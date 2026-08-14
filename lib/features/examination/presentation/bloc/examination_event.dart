part of 'examination_bloc.dart';

abstract class ExaminationEvent extends Equatable {
  const ExaminationEvent();

  @override
  List<Object?> get props => [];
}

/// First load of the screen.
class ExaminationFetched extends ExaminationEvent {
  const ExaminationFetched();
}

/// Pull-to-refresh / retry after an error.
class ExaminationRefreshed extends ExaminationEvent {
  const ExaminationRefreshed();
}

/// User tapped a subject chip ([ExaminationState.any] clears the filter).
class ExaminationSubjectSelected extends ExaminationEvent {
  final String subject;

  const ExaminationSubjectSelected(this.subject);

  @override
  List<Object?> get props => [subject];
}

/// User tapped an exam group chip ([ExaminationState.any] clears the filter).
class ExaminationGroupSelected extends ExaminationEvent {
  final String examGroup;

  const ExaminationGroupSelected(this.examGroup);

  @override
  List<Object?> get props => [examGroup];
}

/// User tapped an exam chip ([ExaminationState.any] clears the filter).
class ExaminationExamSelected extends ExaminationEvent {
  final String exam;

  const ExaminationExamSelected(this.exam);

  @override
  List<Object?> get props => [exam];
}

/// "Sıfırla" — drops every filter at once.
class ExaminationFiltersCleared extends ExaminationEvent {
  const ExaminationFiltersCleared();
}
