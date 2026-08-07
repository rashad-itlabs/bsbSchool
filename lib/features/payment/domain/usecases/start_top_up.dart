import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/payment_session.dart';
import '../repositories/payment_repository.dart';

class StartTopUp implements UseCase<PaymentSession, double> {
  final PaymentRepository repository;
  const StartTopUp(this.repository);

  @override
  Future<Either<Failure, PaymentSession>> call(double amount) {
    return repository.startTopUp(amount);
  }
}
