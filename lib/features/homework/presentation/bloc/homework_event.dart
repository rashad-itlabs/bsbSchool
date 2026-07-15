part of 'homework_bloc.dart';

abstract class HomeworkEvent extends Equatable {
  const HomeworkEvent();

  @override
  List<Object?> get props => [];
}

/// First load of the screen.
class HomeworkFetched extends HomeworkEvent {
  const HomeworkFetched();
}

/// Pull-to-refresh / retry after an error.
class HomeworkRefreshed extends HomeworkEvent {
  const HomeworkRefreshed();
}

/// User tapped a subject pill ([HomeworkState.allSubjects] clears the filter).
class HomeworkSubjectSelected extends HomeworkEvent {
  final String subject;

  const HomeworkSubjectSelected(this.subject);

  @override
  List<Object?> get props => [subject];
}
