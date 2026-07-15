import 'package:equatable/equatable.dart';

class Book extends Equatable {
  final int id;
  final String title;

  /// Nullable on the server — books are sometimes catalogued without them.
  final String? author;
  final String? subject;

  /// Absolute URLs already resolved by the backend (`asset('storage/...')`).
  final String? coverUrl;
  final String? fileUrl;

  const Book({
    required this.id,
    required this.title,
    this.author,
    this.subject,
    this.coverUrl,
    this.fileUrl,
  });

  @override
  List<Object?> get props => [id, title, author, subject, coverUrl, fileUrl];
}
