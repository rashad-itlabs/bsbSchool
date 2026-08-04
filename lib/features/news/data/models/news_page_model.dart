import '../../domain/entities/news_page.dart';
import 'news_item_model.dart';

class NewsPageModel extends NewsPage {
  const NewsPageModel({
    super.items,
    super.currentPage,
    super.perPage,
    super.total,
    super.lastPage,
  });

  /// Takes the whole `GET /getNews` body:
  /// `{ "news": { "data": [...], "current_page": 1, "per_page": 20,
  ///    "total": 2, "last_page": 1 } }`
  ///
  /// The paginator is read from the `news` wrapper when present, otherwise
  /// from the body itself — so a flattened response still parses.
  factory NewsPageModel.fromJson(Map<String, dynamic> json) {
    final wrapper = json['news'];
    final page = wrapper is Map
        ? Map<String, dynamic>.from(wrapper)
        : json;

    final raw = page['data'];
    final items = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => NewsItemModel.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <NewsItemModel>[];

    return NewsPageModel(
      items: items,
      currentPage: _asInt(page['current_page'], 1),
      perPage: _asInt(page['per_page'], 0),
      total: _asInt(page['total'], items.length),
      lastPage: _asInt(page['last_page'], 1),
    );
  }

  static int _asInt(dynamic value, int fallback) =>
      value is int ? value : int.tryParse(value?.toString() ?? '') ?? fallback;
}
