import '../../domain/entities/book.dart';

class BookModel extends Book {
  const BookModel({
    required super.id,
    required super.title,
    super.author,
    super.subject,
    super.coverUrl,
    super.fileUrl,
  });

  /// Matches one entry of the `data` array returned by `GET /library`.
  factory BookModel.fromJson(Map<String, dynamic> json) => BookModel(
        id: _asInt(json['id']),
        title: json['title']?.toString() ?? 'Adsız kitab',
        author: _asNullableString(json['author']),
        subject: _asNullableString(json['subject']),
        coverUrl: _asNullableString(json['cover']),
        fileUrl: _asNullableString(json['file_url']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'subject': subject,
        'cover': coverUrl,
        'file_url': fileUrl,
      };

  /// `id` arrives as an int, but a JSON-encoded string is cheap to tolerate.
  static int _asInt(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

  /// The API sends `null` for missing values; empty strings mean the same.
  static String? _asNullableString(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }
}
