import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/homework_content.dart';
import '../../domain/repositories/homework_repository.dart';
import '../services/homework_service.dart';

class HomeworkRepositoryImpl implements HomeworkRepository {
  final HomeworkService service;

  /// Source of the logged-in student's `class_id` (from the login response).
  final AuthRepository authRepository;

  const HomeworkRepositoryImpl({
    required this.service,
    required this.authRepository,
  });

  /// No `NetworkInfo` pre-flight here on purpose: that check pings a third
  /// party, so an unreachable probe would hide a perfectly reachable API.
  /// A genuinely offline device surfaces as a connection [DioException],
  /// which the service already maps to a message.
  @override
  Future<Either<Failure, HomeworkContent>> getHomeworks() async {
    try {
      final content = await service.getHomeworks(
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
