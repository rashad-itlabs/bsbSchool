import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/app_version.dart';
import '../../domain/repositories/app_version_repository.dart';
import '../services/app_version_service.dart';

class AppVersionRepositoryImpl implements AppVersionRepository {
  final AppVersionService service;

  const AppVersionRepositoryImpl({required this.service});

  @override
  Future<Either<Failure, AppVersion>> fetch({required String platform}) async {
    // Deliberately no [NetworkInfo] gate: an offline launch fails here just
    // the same, and the caller treats both as "carry on".
    try {
      return Right(await service.fetch(platform: platform));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
