import 'package:equatable/equatable.dart';

import 'book.dart';

/// The full `/library` payload: the student's class plus the books filtered
/// for it. [classId] is null when the student has no session yet.
class LibraryContent extends Equatable {
  final int? classId;
  final String? className;
  final List<Book> books;

  const LibraryContent({
    this.classId,
    this.className,
    this.books = const [],
  });

  @override
  List<Object?> get props => [classId, className, books];
}
