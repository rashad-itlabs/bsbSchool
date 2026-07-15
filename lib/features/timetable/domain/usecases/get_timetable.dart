import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/timetable_content.dart';
import '../repositories/timetable_repository.dart';

class GetTimetable implements UseCase<TimetableContent, NoParams> {
  final TimetableRepository repository;
  const GetTimetable(this.repository);

  @override
  Future<Either<Failure, TimetableContent>> call(NoParams params) {
    return repository.getTimetable();
  }
}
