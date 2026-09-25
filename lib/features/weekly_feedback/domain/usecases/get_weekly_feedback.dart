import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/weekly_feedback_content.dart';
import '../repositories/weekly_feedback_repository.dart';

class GetWeeklyFeedback
    implements UseCase<WeeklyFeedbackContent, WeeklyFeedbackParams> {
  final WeeklyFeedbackRepository repository;
  const GetWeeklyFeedback(this.repository);

  @override
  Future<Either<Failure, WeeklyFeedbackContent>> call(
      WeeklyFeedbackParams params) {
    return repository.getWeeklyFeedback(week: params.week);
  }
}

class WeeklyFeedbackParams extends Equatable {
  /// Null asks for the current week.
  final int? week;

  const WeeklyFeedbackParams({this.week});

  @override
  List<Object?> get props => [week];
}
