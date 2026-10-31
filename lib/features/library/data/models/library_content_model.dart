import '../../../../core/utils/json_coerce.dart';
import '../../domain/entities/library_content.dart';
import 'book_model.dart';

class LibraryContentModel extends LibraryContent {
  const LibraryContentModel({
    super.classId,
    super.className,
    super.books,
    super.locked,
    super.lockedText,
    super.lockedNote,
  });

  /// Matches the whole `GET /library` body:
  /// `{ "class_id": 7, "class": "7A", "data": [ ...books ] }`
  ///
  /// A closed library adds `"locked": true, "locked_text": "…",
  /// "locked_note": "…"` next to an empty `data`; an open one omits the keys.
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
      locked: asBool(json['locked']),
      lockedText: asString(json['locked_text']),
      lockedNote: asString(json['locked_note']),
    );
  }
}
