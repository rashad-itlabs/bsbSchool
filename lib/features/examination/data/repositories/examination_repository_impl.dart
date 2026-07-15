import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/examination_content.dart';
import '../../domain/repositories/examination_repository.dart';
import '../services/examination_service.dart';

class ExaminationRepositoryImpl implements ExaminationRepository {
  final ExaminationService service;

  const ExaminationRepositoryImpl({required this.service});

  /// No `NetworkInfo` pre-flight here on purpose: that check pings a third
  /// party, so an unreachable probe would hide a perfectly reachable API.
  /// A genuinely offline device surfaces as a connection [DioException],
  /// which the service already maps to a message.
  @override
  Future<Either<Failure, ExaminationContent>> getExaminations() async {
    try {
      final content = await service.getExaminations();
      return Right(content);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
