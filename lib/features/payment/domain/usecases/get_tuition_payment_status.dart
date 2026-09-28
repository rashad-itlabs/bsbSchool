import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/payment_result.dart';
import '../repositories/payment_repository.dart';

/// Reads a tuition checkout's outcome (`GET /tuition/payment/status`).
class GetTuitionPaymentStatus implements UseCase<PaymentResult, String> {
  final PaymentRepository repository;
  const GetTuitionPaymentStatus(this.repository);

  @override
  Future<Either<Failure, PaymentResult>> call(String reference) {
    return repository.getTuitionStatus(reference);
  }
}
