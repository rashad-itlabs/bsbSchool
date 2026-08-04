import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/news_item.dart';
import '../../domain/usecases/get_news.dart';

part 'news_event.dart';
part 'news_state.dart';

class NewsBloc extends Bloc<NewsEvent, NewsState> {
  final GetNews getNews;

  NewsBloc({required this.getNews}) : super(const NewsState()) {
    on<NewsFetched>(_onFetched);
    on<NewsRefreshed>(_onFetched);
  }

  Future<void> _onFetched(NewsEvent event, Emitter<NewsState> emit) async {
    // A refresh always returns to page 1; only the initial fetch may target
    // another one.
    final requestedPage = event is NewsFetched ? event.page : 1;

    // The refresh keeps the current slide on screen while it reloads; the
    // first load has nothing to keep, so both paths just flip the status.
    emit(state.copyWith(status: NewsStatus.loading));

    final result = await getNews(NewsParams(page: requestedPage));

    result.fold(
      (failure) => emit(state.copyWith(
        status: NewsStatus.error,
        errorMessage: failure.message,
      )),
      // Built fresh rather than via copyWith so an emptied feed actually
      // clears the previous slides.
      (newsPage) => emit(NewsState(
        status: NewsStatus.loaded,
        items: newsPage.items,
        currentPage: newsPage.currentPage,
        lastPage: newsPage.lastPage,
        total: newsPage.total,
      )),
    );
  }
}
