import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/tuition_content.dart';
import '../repositories/tuition_repository.dart';

class GetTuition implements UseCase<TuitionContent, NoParams> {
  final TuitionRepository repository;
  const GetTuition(this.repository);

  @override
  Future<Either<Failure, TuitionContent>> call(NoParams params) {
    return repository.getTuition();
  }
}
