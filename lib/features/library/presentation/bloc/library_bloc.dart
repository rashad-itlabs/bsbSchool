import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/book.dart';
import '../../domain/usecases/get_books.dart';

part 'library_event.dart';
part 'library_state.dart';

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  final GetBooks getBooks;

  LibraryBloc({required this.getBooks}) : super(const LibraryState()) {
    on<LibraryFetched>(_onFetched);
    on<LibraryRefreshed>(_onFetched);
    on<LibrarySearchChanged>(_onSearchChanged);
    on<LibrarySubjectSelected>(_onSubjectSelected);
  }

  Future<void> _onFetched(LibraryEvent event, Emitter<LibraryState> emit) async {
    // A pull-to-refresh keeps the current list on screen; the first load has
    // nothing to keep, so both paths just flip the status.
    emit(state.copyWith(status: LibraryStatus.loading));

    final result = await getBooks(const NoParams());

    result.fold(
      (failure) => emit(state.copyWith(
        status: LibraryStatus.error,
        errorMessage: failure.message,
      )),
      // Built fresh rather than via copyWith so a null class_id (student with
      // no session) actually clears the previous one. The typed query stays.
      (content) => emit(LibraryState(
        status: LibraryStatus.loaded,
        classId: content.classId,
        className: content.className,
        books: content.books,
        query: state.query,
      )),
    );
  }

  void _onSearchChanged(LibrarySearchChanged event, Emitter<LibraryState> emit) {
    emit(state.copyWith(query: event.query));
  }

  void _onSubjectSelected(
    LibrarySubjectSelected event,
    Emitter<LibraryState> emit,
  ) {
    emit(state.copyWith(subject: event.subject));
  }
}
