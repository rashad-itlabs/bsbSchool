import 'package:equatable/equatable.dart';

import 'news_item.dart';

/// One paginated page of `GET /getNews`, mirroring Laravel's paginator body.
class NewsPage extends Equatable {
  final List<NewsItem> items;
  final int currentPage;
  final int perPage;

  /// Total entries across every page, not just this one.
  final int total;
  final int lastPage;

  const NewsPage({
    this.items = const [],
    this.currentPage = 1,
    this.perPage = 0,
    this.total = 0,
    this.lastPage = 1,
  });

  /// True while further pages remain to be fetched.
  bool get hasMore => currentPage < lastPage;

  @override
  List<Object?> get props => [items, currentPage, perPage, total, lastPage];
}
