import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/library_content.dart';
import '../../domain/repositories/library_repository.dart';
import '../services/library_service.dart';

class LibraryRepositoryImpl implements LibraryRepository {
  final LibraryService service;

  /// Source of the logged-in student's `class_id` (from the login response).
  final AuthRepository authRepository;

  const LibraryRepositoryImpl({
    required this.service,
    required this.authRepository,
  });

  /// No `NetworkInfo` pre-flight here on purpose: that check pings a third
  /// party, so an unreachable probe would hide a perfectly reachable API.
  /// A genuinely offline device surfaces as a connection [DioException],
  /// which the service already maps to a message.
  @override
  Future<Either<Failure, LibraryContent>> getLibrary() async {
    try {
      final content = await service.getLibrary(
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
