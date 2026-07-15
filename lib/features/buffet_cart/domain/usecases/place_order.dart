import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/product.dart';
import '../repositories/buffet_repository.dart';

class PlaceOrder implements UseCase<double, List<CartItem>> {
  final BuffetRepository repository;
  const PlaceOrder(this.repository);

  @override
  Future<Either<Failure, double>> call(List<CartItem> items) {
    if (items.isEmpty) {
      return Future.value(const Left(ValidationFailure('Səbət boşdur')));
    }
    return repository.placeOrder(items);
  }
}
