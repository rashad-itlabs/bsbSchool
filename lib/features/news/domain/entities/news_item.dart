import 'package:equatable/equatable.dart';

/// One entry of the `news.data` array returned by `GET /getNews`.
class NewsItem extends Equatable {
  final int id;
  final String title;
  final String description;

  /// Absolute URL of the slider image; null when the entry has none.
  final String? image;

  /// When the entry was published.
  final DateTime? createdAt;

  const NewsItem({
    required this.id,
    this.title = '',
    this.description = '',
    this.image,
    this.createdAt,
  });

  bool get hasImage => image != null && image!.isNotEmpty;

  @override
  List<Object?> get props => [id, title, description, image, createdAt];
}
