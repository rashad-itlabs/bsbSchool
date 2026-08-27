import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/payment_result.dart';
import '../entities/payment_session.dart';

abstract class PaymentRepository {
  /// `POST /payment/topup` — asks the server for a checkout link.
  Future<Either<Failure, PaymentSession>> startTopUp(double amount);

  /// `POST /pay/{id}` — a checkout link for one extra fee, identified by its
  /// own row id (`fees[].id` of `GET /extra_fees`).
  Future<Either<Failure, PaymentSession>> startFeePayment({
    required int feeId,
    required double amount,
  });

  /// `GET /payment/status` — the only source of truth for an outcome. Safe to
  /// call repeatedly: the balance is credited once, server side.
  Future<Either<Failure, PaymentResult>> getStatus(String reference);
}
