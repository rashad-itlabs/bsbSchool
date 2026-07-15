part of 'library_bloc.dart';

abstract class LibraryEvent extends Equatable {
  const LibraryEvent();

  @override
  List<Object?> get props => [];
}

/// First load of the screen.
class LibraryFetched extends LibraryEvent {
  const LibraryFetched();
}

/// Pull-to-refresh / retry after an error.
class LibraryRefreshed extends LibraryEvent {
  const LibraryRefreshed();
}

/// User typed in the search field. Filtering happens client-side — the
/// endpoint returns the whole class list in one shot.
class LibrarySearchChanged extends LibraryEvent {
  final String query;

  const LibrarySearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// User tapped a subject pill ([LibraryState.allSubjects] clears the filter).
class LibrarySubjectSelected extends LibraryEvent {
  final String subject;

  const LibrarySubjectSelected(this.subject);

  @override
  List<Object?> get props => [subject];
}
