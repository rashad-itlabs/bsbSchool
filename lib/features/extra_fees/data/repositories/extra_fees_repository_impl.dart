import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/extra_fees_content.dart';
import '../../domain/repositories/extra_fees_repository.dart';
import '../services/extra_fees_service.dart';

class ExtraFeesRepositoryImpl implements ExtraFeesRepository {
  final ExtraFeesService service;

  /// Source of the `student_id` — the child the parent has switched to.
  final AuthRepository authRepository;

  const ExtraFeesRepositoryImpl({
    required this.service,
    required this.authRepository,
  });

  /// No `NetworkInfo` pre-flight here on purpose: that check pings a third
  /// party, so an unreachable probe would hide a perfectly reachable API.
  /// A genuinely offline device surfaces as a connection [DioException],
  /// which the service already maps to a message.
  @override
  Future<Either<Failure, ExtraFeesContent>> getExtraFees() async {
    try {
      final content = await service.getExtraFees(
        studentId: authRepository.activeStudentId,
      );
      return Right(content);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
