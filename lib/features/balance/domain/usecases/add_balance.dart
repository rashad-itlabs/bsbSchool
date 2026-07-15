import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/balance.dart';
import '../repositories/balance_repository.dart';

class AddBalance implements UseCase<Balance, double> {
  final BalanceRepository repository;
  const AddBalance(this.repository);

  @override
  Future<Either<Failure, Balance>> call(double amount) {
    if (amount <= 0) {
      return Future.value(
          const Left(ValidationFailure('Məbləğ 0-dan böyük olmalıdır')));
    }
    return repository.addBalance(amount);
  }
}
