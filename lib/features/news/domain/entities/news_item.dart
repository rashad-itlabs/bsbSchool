import 'package:equatable/equatable.dart';

/// Title and text of a news entry in one language.
class NewsText extends Equatable {
  final String title;
  final String description;

  const NewsText({this.title = '', this.description = ''});

  @override
  List<Object?> get props => [title, description];
}

/// One entry of the `news.data` array returned by `GET /getNews`.
class NewsItem extends Equatable {
  final int id;

  /// In the language the request was made in (`lang`).
  final String title;
  final String description;

  /// Every language the backend sent (`az`, `en`, `ru`), keyed by language
  /// code. The backend already fills a missing translation with the
  /// Azerbaijani text. Kept so a language switch re-renders the entry without
  /// reloading it; empty when talking to a backend that predates it.
  final Map<String, NewsText> translations;

  /// Absolute URL of the slider image; null when the entry has none.
  final String? image;

  /// When the entry was published.
  final DateTime? createdAt;

  const NewsItem({
    required this.id,
    this.title = '',
    this.description = '',
    this.translations = const {},
    this.image,
    this.createdAt,
  });

  bool get hasImage => image != null && image!.isNotEmpty;

  /// [title] in [languageCode]; falls back to the request language.
  String titleIn(String languageCode) {
    final text = translations[languageCode]?.title ?? '';
    return text.isEmpty ? title : text;
  }

  /// [description] in [languageCode]; falls back to the request language.
  String descriptionIn(String languageCode) {
    final text = translations[languageCode]?.description ?? '';
    return text.isEmpty ? description : text;
  }

  @override
  List<Object?> get props =>
      [id, title, description, translations, image, createdAt];
}
