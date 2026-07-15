import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/day_plan.dart';
import '../repositories/weekly_plan_repository.dart';

class GetWeeklyPlan implements UseCase<List<DayPlan>, NoParams> {
  final WeeklyPlanRepository repository;
  const GetWeeklyPlan(this.repository);

  @override
  Future<Either<Failure, List<DayPlan>>> call(NoParams params) {
    return repository.getWeeklyPlan();
  }
}
