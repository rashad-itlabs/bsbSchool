import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/day_plan.dart';

abstract class WeeklyPlanRepository {
  Future<Either<Failure, List<DayPlan>>> getWeeklyPlan();
}
