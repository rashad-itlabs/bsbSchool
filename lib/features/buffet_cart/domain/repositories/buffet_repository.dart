import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/product.dart';

abstract class BuffetRepository {
  Future<Either<Failure, List<Product>>> getProducts();

  /// Places an order for [items], deducting the total from the user's
  /// balance. Returns the new balance amount on success.
  Future<Either<Failure, double>> placeOrder(List<CartItem> items);
}
