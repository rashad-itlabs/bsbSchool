part of 'news_bloc.dart';

abstract class NewsEvent extends Equatable {
  const NewsEvent();

  @override
  List<Object?> get props => [];
}

/// First load of the slider. [page] is 1-based.
class NewsFetched extends NewsEvent {
  final int page;

  const NewsFetched({this.page = 1});

  @override
  List<Object?> get props => [page];
}

/// Pull-to-refresh / retry after an error — always reloads the first page.
class NewsRefreshed extends NewsEvent {
  const NewsRefreshed();
}
