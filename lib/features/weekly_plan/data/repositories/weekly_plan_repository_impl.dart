import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/day_plan.dart';
import '../../domain/repositories/weekly_plan_repository.dart';
import '../datasources/weekly_plan_remote_data_source.dart';

class WeeklyPlanRepositoryImpl implements WeeklyPlanRepository {
  final WeeklyPlanRemoteDataSource remoteDataSource;
  const WeeklyPlanRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<DayPlan>>> getWeeklyPlan() async {
    try {
      return Right(await remoteDataSource.getWeeklyPlan());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
