import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/payment_result.dart';
import '../../domain/entities/payment_session.dart';
import '../../domain/usecases/get_payment_status.dart';
import '../../domain/usecases/start_top_up.dart';

part 'payment_state.dart';

/// Drives one buffet top-up: mint a checkout link, then read the outcome back
/// from the API once the bank page is done.
///
/// The bank's return URL is only a hint — the balance is credited by the
/// gateway's server-to-server callback, which can land a moment after the
/// browser comes back. That is why [confirm] polls instead of trusting the
/// first answer.
class PaymentCubit extends Cubit<PaymentState> {
  final StartTopUp startTopUp;
  final GetPaymentStatus getPaymentStatus;

  PaymentCubit({required this.startTopUp, required this.getPaymentStatus})
      : super(const PaymentState());

  /// How long to keep asking while the gateway still says `pending`.
  static const _pollDelay = Duration(seconds: 2);
  static const _pollsAfterSuccess = 6;
  static const _pollsOtherwise = 2;

  /// Asks the server for a checkout link. Returns null on failure, with the
  /// reason in `state.errorMessage`.
  Future<PaymentSession?> start(double amount) async {
    emit(const PaymentState(stage: PaymentStage.starting));

    final result = await startTopUp(amount);

    return result.fold(
      (failure) {
        emit(PaymentState(errorMessage: failure.message));
        return null;
      },
      (session) {
        emit(PaymentState(stage: PaymentStage.atBank, session: session));
        return session;
      },
    );
  }

  /// Reads the real outcome of [reference] from the API.
  ///
  /// [bankSaidSuccess] is the signal the return URL carried: when the bank
  /// claims success we wait longer for the callback to settle, otherwise a
  /// couple of tries is enough to catch a payment that went through anyway
  /// (e.g. the parent closed the page after paying).
  ///
  /// Returns null when every attempt failed to reach the API.
  Future<PaymentResult?> confirm(
    String reference, {
    required bool bankSaidSuccess,
  }) async {
    emit(state.copyWithStage(PaymentStage.checking));

    final attempts = bankSaidSuccess ? _pollsAfterSuccess : _pollsOtherwise;
    String? lastError;

    for (var attempt = 0; attempt < attempts; attempt++) {
      if (attempt > 0) await Future.delayed(_pollDelay);
      if (isClosed) return null;

      final outcome = await getPaymentStatus(reference);
      if (isClosed) return null;

      final result = outcome.fold<PaymentResult?>(
        (failure) {
          lastError = failure.message;
          return null;
        },
        (value) => value,
      );

      // Settled either way — nothing left to wait for.
      if (result != null && !result.isPending) {
        emit(PaymentState(stage: PaymentStage.done, result: result));
        return result;
      }

      // Still pending on the last attempt: report it as pending rather than
      // pretending it failed.
      if (result != null && attempt == attempts - 1) {
        emit(PaymentState(stage: PaymentStage.done, result: result));
        return result;
      }
    }

    emit(PaymentState(errorMessage: lastError));
    return null;
  }

  /// Clears the last outcome so the screen starts from a clean slate.
  void reset() => emit(const PaymentState());
}

extension on PaymentState {
  PaymentState copyWithStage(PaymentStage stage) => PaymentState(
        stage: stage,
        session: session,
        result: result,
      );
}
