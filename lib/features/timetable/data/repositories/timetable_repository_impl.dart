import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/timetable_content.dart';
import '../../domain/repositories/timetable_repository.dart';
import '../services/timetable_service.dart';

class TimetableRepositoryImpl implements TimetableRepository {
  final TimetableService service;

  /// Source of the logged-in student's `class_id` (from the login response).
  final AuthRepository authRepository;

  const TimetableRepositoryImpl({
    required this.service,
    required this.authRepository,
  });

  /// No `NetworkInfo` pre-flight here on purpose: that check pings a third
  /// party, so an unreachable probe would hide a perfectly reachable API.
  /// A genuinely offline device surfaces as a connection [DioException],
  /// which the service already maps to a message.
  @override
  Future<Either<Failure, TimetableContent>> getTimetable() async {
    try {
      final content = await service.getTimetable(
        classId: authRepository.currentUser?.classId,
      );
      return Right(content);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
