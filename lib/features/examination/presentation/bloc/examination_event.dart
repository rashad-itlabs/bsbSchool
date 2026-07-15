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

/// User tapped a subject pill ([ExaminationState.allSubjects] clears the filter).
class ExaminationSubjectSelected extends ExaminationEvent {
  final String subject;

  const ExaminationSubjectSelected(this.subject);

  @override
  List<Object?> get props => [subject];
}
