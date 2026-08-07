import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/school_event.dart';

abstract class EventsRepository {
  /// Fetches every calendar entry the school has published.
  Future<Either<Failure, List<SchoolEvent>>> getEvents();
}
