import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/news_page.dart';
import '../../domain/repositories/news_repository.dart';
import '../services/news_service.dart';

class NewsRepositoryImpl implements NewsRepository {
  final NewsService service;

  const NewsRepositoryImpl({required this.service});

  /// No `NetworkInfo` pre-flight here on purpose: that check pings a third
  /// party, so an unreachable probe would hide a perfectly reachable API.
  /// A genuinely offline device surfaces as a connection [DioException],
  /// which the service already maps to a message.
  @override
  Future<Either<Failure, NewsPage>> getNews({int page = 1}) async {
    try {
      final result = await service.getNews(page: page);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
