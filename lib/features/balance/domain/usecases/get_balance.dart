import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/balance.dart';
import '../repositories/balance_repository.dart';

class GetBalance implements UseCase<Balance, NoParams> {
  final BalanceRepository repository;
  const GetBalance(this.repository);

  @override
  Future<Either<Failure, Balance>> call(NoParams params) {
    return repository.getBalance();
  }
}
