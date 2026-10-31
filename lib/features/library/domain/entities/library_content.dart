import 'package:equatable/equatable.dart';

import 'book.dart';

/// The full `/library` payload: the student's class plus the books filtered
/// for it. [classId] is null when the student has no session yet.
class LibraryContent extends Equatable {
  final int? classId;
  final String? className;
  final List<Book> books;

  /// The school closed this child's library over an unpaid balance
  /// («Library closed» in Student Information). [books] is empty then and
  /// [lockedText] / [lockedNote] carry the server's message in the request
  /// language.
  final bool locked;
  final String? lockedText;
  final String? lockedNote;

  const LibraryContent({
    this.classId,
    this.className,
    this.books = const [],
    this.locked = false,
    this.lockedText,
    this.lockedNote,
  });

  @override
  List<Object?> get props =>
      [classId, className, books, locked, lockedText, lockedNote];
}
