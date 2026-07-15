import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/notifications_content.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../services/notifications_service.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsService service;

  /// Source of the logged-in student's `class_id` (from the login response).
  final AuthRepository authRepository;

  const NotificationsRepositoryImpl({
    required this.service,
    required this.authRepository,
  });

  /// No `NetworkInfo` pre-flight here on purpose: that check pings a third
  /// party, so an unreachable probe would hide a perfectly reachable API.
  /// A genuinely offline device surfaces as a connection [DioException],
  /// which the service already maps to a message.
  @override
  Future<Either<Failure, NotificationsContent>> getNotifications() async {
    try {
      final content = await service.getNotifications(
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
