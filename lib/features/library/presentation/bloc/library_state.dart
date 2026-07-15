part of 'library_bloc.dart';

enum LibraryStatus { initial, loading, loaded, error }

class LibraryState extends Equatable {
  /// Sentinel for "no subject filter" — also the label of the first pill.
  static const String allSubjects = 'Hamısı';

  final LibraryStatus status;

  /// Everything the API returned, unfiltered.
  final List<Book> books;

  final int? classId;
  final String? className;

  final String query;
  final String subject;

  final String? errorMessage;

  const LibraryState({
    this.status = LibraryStatus.initial,
    this.books = const [],
    this.classId,
    this.className,
    this.query = '',
    this.subject = allSubjects,
    this.errorMessage,
  });

  bool get isLoading => status == LibraryStatus.loading;

  /// The student has no class session, so there is nothing to show.
  bool get hasNoClass => status == LibraryStatus.loaded && classId == null;

  /// Pill labels: "Hamısı" plus every subject present in [books].
  List<String> get subjects {
    final unique = <String>{
      for (final book in books)
        if (book.subject != null) book.subject!,
    }.toList()..sort();
    return [allSubjects, ...unique];
  }

  /// What the grid renders: [books] narrowed by [subject] then [query].
  List<Book> get visibleBooks {
    final needle = query.trim().toLowerCase();
    return books.where((book) {
      if (subject != allSubjects && book.subject != subject) return false;
      if (needle.isEmpty) return true;
      return book.title.toLowerCase().contains(needle) ||
          (book.author?.toLowerCase().contains(needle) ?? false);
    }).toList();
  }

  LibraryState copyWith({
    LibraryStatus? status,
    List<Book>? books,
    int? classId,
    String? className,
    String? query,
    String? subject,
    String? errorMessage,
  }) {
    return LibraryState(
      status: status ?? this.status,
      books: books ?? this.books,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      query: query ?? this.query,
      subject: subject ?? this.subject,
      // Intentionally not carried over: only the state that failed shows it.
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, books, classId, className, query, subject, errorMessage];
}
