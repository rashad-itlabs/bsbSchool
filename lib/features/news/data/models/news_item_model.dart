import '../../domain/entities/news_item.dart';

class NewsItemModel extends NewsItem {
  const NewsItemModel({
    required super.id,
    super.title,
    super.description,
    super.translations,
    super.image,
    super.createdAt,
  });

  /// Matches one entry of the `news.data` array returned by `GET /getNews`.
  factory NewsItemModel.fromJson(Map<String, dynamic> json) => NewsItemModel(
        id: _asInt(json['id']),
        title: _asString(json['title']) ?? '',
        description: _asString(json['description']) ?? '',
        translations: _asTranslations(json['translations']),
        image: _asString(json['image']),
        createdAt: _asDate(json['created_at']),
      );

  static int _asInt(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

  /// The API sends `null` for missing values; empty strings mean the same.
  static String? _asString(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  /// `{"az": {"title": …, "description": …}, "en": {…}, "ru": {…}}`; anything
  /// else (an older backend, a malformed entry) degrades to no translations.
  static Map<String, NewsText> _asTranslations(dynamic value) {
    if (value is! Map) return const {};

    final out = <String, NewsText>{};
    value.forEach((language, text) {
      if (text is Map) {
        out[language.toString()] = NewsText(
          title: _asString(text['title']) ?? '',
          description: _asString(text['description']) ?? '',
        );
      }
    });
    return out;
  }

  /// Dates come as `2026-07-23 12:54:33`, which [DateTime.tryParse] accepts;
  /// a bad value degrades to null, not a crash.
  static DateTime? _asDate(dynamic value) {
    final text = _asString(value);
    return text == null ? null : DateTime.tryParse(text);
  }
}
