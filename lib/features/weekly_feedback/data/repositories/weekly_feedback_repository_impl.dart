import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/weekly_feedback_content.dart';
import '../../domain/repositories/weekly_feedback_repository.dart';
import '../services/weekly_feedback_service.dart';

class WeeklyFeedbackRepositoryImpl implements WeeklyFeedbackRepository {
  final WeeklyFeedbackService service;

  /// Source of the `student_id` — the child the parent has switched to.
  final AuthRepository authRepository;

  const WeeklyFeedbackRepositoryImpl({
    required this.service,
    required this.authRepository,
  });

  /// No `NetworkInfo` pre-flight, same as the other features: an offline
  /// device surfaces as a connection error the service already words.
  @override
  Future<Either<Failure, WeeklyFeedbackContent>> getWeeklyFeedback({
    int? week,
  }) async {
    try {
      final content = await service.getWeeklyFeedback(
        studentId: authRepository.activeStudentId,
        week: week,
      );
      return Right(content);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
