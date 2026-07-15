import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/balance.dart';

abstract class BalanceRepository {
  Future<Either<Failure, Balance>> getBalance();

  /// Tops up the account by [amount] (must be > 0).
  Future<Either<Failure, Balance>> addBalance(double amount);

  /// Deducts [amount]; fails with [ValidationFailure] if funds are short.
  Future<Either<Failure, Balance>> deduct(double amount);
}
