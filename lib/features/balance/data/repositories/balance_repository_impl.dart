import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/balance.dart';
import '../../domain/repositories/balance_repository.dart';
import '../datasources/balance_local_data_source.dart';

class BalanceRepositoryImpl implements BalanceRepository {
  final BalanceLocalDataSource localDataSource;
  const BalanceRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, Balance>> getBalance() async {
    try {
      return Right(Balance(await localDataSource.getBalance()));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (_) {
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Balance>> addBalance(double amount) async {
    try {
      return Right(Balance(await localDataSource.addBalance(amount)));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (_) {
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Balance>> deduct(double amount) async {
    try {
      return Right(Balance(await localDataSource.deduct(amount)));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (_) {
      return const Left(CacheFailure());
    }
  }
}
