import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/news_page.dart';
import '../repositories/news_repository.dart';

class GetNews implements UseCase<NewsPage, NewsParams> {
  final NewsRepository repository;
  const GetNews(this.repository);

  @override
  Future<Either<Failure, NewsPage>> call(NewsParams params) {
    return repository.getNews(page: params.page);
  }
}

class NewsParams extends Equatable {
  /// 1-based page number. The dashboard slider only ever needs the first.
  final int page;

  const NewsParams({this.page = 1});

  @override
  List<Object?> get props => [page];
}
