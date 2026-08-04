import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/news_page.dart';

abstract class NewsRepository {
  /// Fetches one page of the school news feed. [page] is 1-based.
  Future<Either<Failure, NewsPage>> getNews({int page});
}
