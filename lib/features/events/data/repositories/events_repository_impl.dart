import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/school_event.dart';
import '../../domain/repositories/events_repository.dart';
import '../services/events_service.dart';

class EventsRepositoryImpl implements EventsRepository {
  final EventsService service;

  const EventsRepositoryImpl({required this.service});

  /// No `NetworkInfo` pre-flight here on purpose: that check pings a third
  /// party, so an unreachable probe would hide a perfectly reachable API.
  /// A genuinely offline device surfaces as a connection `DioException`,
  /// which the service already maps to a message.
  @override
  Future<Either<Failure, List<SchoolEvent>>> getEvents() async {
    try {
      final result = await service.getEvents();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
