import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/payment_session.dart';
import '../repositories/payment_repository.dart';

/// Which fee to pay and how much of it.
class FeePaymentParams extends Equatable {
  /// `fees[].id` of `GET /extra_fees` — the row being settled.
  final int feeId;

  /// Usually the fee's `remaining`; less when the school allows part payment.
  final double amount;

  const FeePaymentParams({required this.feeId, required this.amount});

  @override
  List<Object?> get props => [feeId, amount];
}

/// Starts the checkout for one extra fee (`POST /pay/{id}`).
class StartFeePayment implements UseCase<PaymentSession, FeePaymentParams> {
  final PaymentRepository repository;
  const StartFeePayment(this.repository);

  @override
  Future<Either<Failure, PaymentSession>> call(FeePaymentParams params) {
    return repository.startFeePayment(
      feeId: params.feeId,
      amount: params.amount,
    );
  }
}
