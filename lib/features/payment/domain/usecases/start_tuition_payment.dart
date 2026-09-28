import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/payment_session.dart';
import '../repositories/payment_repository.dart';

/// Starts the checkout for a tuition payment of the given amount in AZN
/// (`POST /tuition/pay`).
class StartTuitionPayment implements UseCase<PaymentSession, double> {
  final PaymentRepository repository;
  const StartTuitionPayment(this.repository);

  @override
  Future<Either<Failure, PaymentSession>> call(double amount) {
    return repository.startTuitionPayment(amount);
  }
}
