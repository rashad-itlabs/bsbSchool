import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../balance/domain/repositories/balance_repository.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/buffet_repository.dart';
import '../datasources/buffet_remote_data_source.dart';

class BuffetRepositoryImpl implements BuffetRepository {
  final BuffetRemoteDataSource remoteDataSource;
  final BalanceRepository balanceRepository;

  const BuffetRepositoryImpl({
    required this.remoteDataSource,
    required this.balanceRepository,
  });

  @override
  Future<Either<Failure, List<Product>>> getProducts() async {
    try {
      return Right(await remoteDataSource.getProducts());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, double>> placeOrder(List<CartItem> items) async {
    final total = items.fold<double>(0, (sum, item) => sum + item.total);

    // 1) Deduct from balance first — fails fast on insufficient funds.
    final deduction = await balanceRepository.deduct(total);
    return deduction.fold(
      (failure) async => Left<Failure, double>(failure),
      (newBalance) async {
        // 2) Balance ok → register the order on the backend.
        try {
          final qty = {for (final i in items) i.product.id: i.quantity};
          await remoteDataSource.submitOrder(qty);
          return Right<Failure, double>(newBalance.amount);
        } catch (_) {
          // Roll back the deduction if order submission fails.
          await balanceRepository.addBalance(total);
          return const Left<Failure, double>(
              ServerFailure('Sifariş göndərilə bilmədi'));
        }
      },
    );
  }
}
