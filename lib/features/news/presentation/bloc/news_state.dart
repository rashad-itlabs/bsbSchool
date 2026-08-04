part of 'news_bloc.dart';

enum NewsStatus { initial, loading, loaded, error }

class NewsState extends Equatable {
  final NewsStatus status;

  /// The slides currently on screen, in the order the API returned them
  /// (newest first).
  final List<NewsItem> items;

  final int currentPage;
  final int lastPage;
  final int total;

  final String? errorMessage;

  const NewsState({
    this.status = NewsStatus.initial,
    this.items = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.errorMessage,
  });

  bool get isLoading => status == NewsStatus.loading;

  /// True only once a load finished and came back empty — an in-flight first
  /// load must not be mistaken for "no news".
  bool get isEmpty => status == NewsStatus.loaded && items.isEmpty;

  bool get hasMore => currentPage < lastPage;

  NewsState copyWith({
    NewsStatus? status,
    List<NewsItem>? items,
    int? currentPage,
    int? lastPage,
    int? total,
    String? errorMessage,
  }) {
    return NewsState(
      status: status ?? this.status,
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      // Intentionally not carried over: only the state that failed shows it.
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, items, currentPage, lastPage, total, errorMessage];
}
