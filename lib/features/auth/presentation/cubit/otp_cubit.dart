import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n.dart';
import '../../domain/usecases/resend_otp.dart';
import '../../domain/usecases/verify_otp.dart';

part 'otp_state.dart';

/// Drives the e-mail confirmation screen that now stands between sign-up and
/// login. The account already exists at this point; until the mailed code is
/// accepted the credentials are never handed back, so an unconfirmed parent
/// cannot be signed in.
class OtpCubit extends Cubit<OtpState> {
  final VerifyOtp verifyOtp;
  final ResendOtp resendOtp;

  /// The address `/register` mailed the code to — the screen only shows it,
  /// every request carries it.
  final String email;

  /// Matches the length of the code the backend generates.
  static const int codeLength = 6;

  static const int resendCooldownSeconds = 60;

  Timer? _cooldownTimer;

  /// `/register` has already sent the first code, so the wait starts here
  /// rather than after the first resend.
  OtpCubit({
    required this.verifyOtp,
    required this.resendOtp,
    required this.email,
  }) : super(const OtpState(resendSeconds: resendCooldownSeconds)) {
    _tickCooldown();
  }

  Future<void> submit(String code) async {
    if (state.isLoading) return;

    final otp = code.trim();
    if (otp.isEmpty) {
      emit(state.copyWith(status: OtpStatus.error, message: L.s.otpRequired));
      return;
    }
    if (otp.length != codeLength) {
      emit(state.copyWith(
        status: OtpStatus.error,
        message: L.s.otpIncomplete(codeLength),
      ));
      return;
    }

    emit(state.copyWith(status: OtpStatus.loading));

    final result = await verifyOtp(VerifyOtpParams(email: email, otp: otp));
    // The parent can leave the screen while the code is in flight.
    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: OtpStatus.error,
        message: failure.message,
      )),
      (_) => emit(state.copyWith(
        status: OtpStatus.success,
        message: L.s.otpVerified,
      )),
    );
  }

  Future<void> resendCode() async {
    if (!state.canResend) return;

    emit(state.copyWith(isResending: true));

    final result = await resendOtp(ResendOtpParams(email: email));
    if (isClosed) return;

    result.fold(
      // No new mail went out, so the link stays available for another try.
      (failure) => emit(state.copyWith(
        isResending: false,
        status: OtpStatus.error,
        message: failure.message,
      )),
      (_) {
        emit(state.copyWith(
          isResending: false,
          status: OtpStatus.initial,
          message: L.s.otpResent,
          resendSeconds: resendCooldownSeconds,
        ));
        _tickCooldown();
      },
    );
  }

  /// Drops the complaint as soon as the code is edited, so a corrected digit
  /// stops shouting before it is submitted again.
  void codeChanged() {
    if (state.status != OtpStatus.error) return;
    emit(state.copyWith(status: OtpStatus.initial));
  }

  /// Counts [OtpState.resendSeconds] down to zero, one second at a time.
  void _tickCooldown() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isClosed) {
        timer.cancel();
        return;
      }
      final remaining = state.resendSeconds - 1;
      if (remaining <= 0) timer.cancel();
      // `copyWith` drops `message` unless it is handed back, and this fires
      // every second while the code is being typed — without carrying it the
      // inline error would vanish a tick after the backend rejected the code.
      emit(state.copyWith(
        resendSeconds: remaining,
        message: state.message,
      ));
    });
  }

  @override
  Future<void> close() {
    _cooldownTimer?.cancel();
    return super.close();
  }
}
