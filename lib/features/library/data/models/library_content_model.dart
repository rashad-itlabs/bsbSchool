import '../../domain/entities/library_content.dart';
import 'book_model.dart';

class LibraryContentModel extends LibraryContent {
  const LibraryContentModel({
    super.classId,
    super.className,
    super.books,
  });

  /// Matches the whole `GET /library` body:
  /// `{ "class_id": 7, "class": "7A", "data": [ ...books ] }`
  factory LibraryContentModel.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final books = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => BookModel.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <BookModel>[];

    final classId = json['class_id'];

    return LibraryContentModel(
      classId: classId is int
          ? classId
          : int.tryParse(classId?.toString() ?? ''),
      className: json['class']?.toString(),
      books: books,
    );
  }
}
