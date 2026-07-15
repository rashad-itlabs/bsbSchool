import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/homework_content.dart';
import '../repositories/homework_repository.dart';

class GetHomeworks implements UseCase<HomeworkContent, NoParams> {
  final HomeworkRepository repository;
  const GetHomeworks(this.repository);

  @override
  Future<Either<Failure, HomeworkContent>> call(NoParams params) {
    return repository.getHomeworks();
  }
}
