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

/// The filter sheet was applied, a filter chip removed, or the filters reset:
/// the whole pick, by [HomeworkState.sectionKey] and status key. Empty sets
/// are "all".
class HomeworkFiltersChanged extends HomeworkEvent {
  final Set<String> sections;
  final Set<String> statuses;

  const HomeworkFiltersChanged({
    this.sections = const {},
    this.statuses = const {},
  });

  @override
  List<Object?> get props => [sections, statuses];
}

/// User switched between the "Aktiv" and "Deaktiv" tabs.
class HomeworkTabSelected extends HomeworkEvent {
  final HomeworkTab tab;

  const HomeworkTabSelected(this.tab);

  @override
  List<Object?> get props => [tab];
}
