import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/examination_content.dart';
import '../repositories/examination_repository.dart';

class GetExaminations implements UseCase<ExaminationContent, NoParams> {
  final ExaminationRepository repository;
  const GetExaminations(this.repository);

  @override
  Future<Either<Failure, ExaminationContent>> call(NoParams params) {
    return repository.getExaminations();
  }
}
