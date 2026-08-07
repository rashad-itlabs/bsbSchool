import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/school_event.dart';
import '../repositories/events_repository.dart';

class GetEvents implements UseCase<List<SchoolEvent>, NoParams> {
  final EventsRepository repository;
  const GetEvents(this.repository);

  @override
  Future<Either<Failure, List<SchoolEvent>>> call(NoParams params) {
    return repository.getEvents();
  }
}
