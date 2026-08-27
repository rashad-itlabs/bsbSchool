import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/extra_fees_content.dart';
import '../repositories/extra_fees_repository.dart';

class GetExtraFees implements UseCase<ExtraFeesContent, NoParams> {
  final ExtraFeesRepository repository;
  const GetExtraFees(this.repository);

  @override
  Future<Either<Failure, ExtraFeesContent>> call(NoParams params) {
    return repository.getExtraFees();
  }
}
