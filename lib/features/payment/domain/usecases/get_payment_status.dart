import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/payment_result.dart';
import '../repositories/payment_repository.dart';

class GetPaymentStatus implements UseCase<PaymentResult, String> {
  final PaymentRepository repository;
  const GetPaymentStatus(this.repository);

  @override
  Future<Either<Failure, PaymentResult>> call(String reference) {
    return repository.getStatus(reference);
  }
}
