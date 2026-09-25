import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/weekly_feedback_content.dart';

abstract class WeeklyFeedbackRepository {
  /// The school-year grid plus the feedback of [week]; the server picks the
  /// current week when [week] is null.
  Future<Either<Failure, WeeklyFeedbackContent>> getWeeklyFeedback({int? week});
}
