import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/forgot_password.dart';
import '../../domain/usecases/reset_password.dart';
import '../../../../core/l10n/l10n.dart';

part 'forgot_password_state.dart';

/// Drives the "Şifrənin bərpası" sheet through its three steps: the address,
/// the 6-digit code mailed to it, then the new password.
///
/// Kept apart from `AuthBloc` so a reset in flight never puts the login button
/// into its loading state.
///
/// The code has its own endpoint rather than registration's: `/resendOtp`
/// only serves accounts still waiting to confirm a sign-up, so it turns away
/// exactly the confirmed accounts that ask for a reset.
///
/// The middle step is the app's own: the digits are only carried, not checked,
/// because the backend checks them in the same request that sets the password.
/// A code that turns out to be wrong is therefore reported on the last step,
/// which is why that step can go back to the digits.
class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final ForgotPassword sendResetCode;
  final ResetPassword resetPassword;

  /// Matches the backend's `new_password => min:6` rule.
  static const int minPasswordLength = 6;

  /// Matches the length of the code the backend generates.
  static const int codeLength = 6;

  static const int resendCooldownSeconds = 60;

  static final _emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  Timer? _cooldownTimer;

  ForgotPasswordCubit({
    required this.sendResetCode,
    required this.resetPassword,
  }) : super(const ForgotPasswordState());

  /// Step 1 — mails a code to [email] and moves on to the digits.
  Future<void> requestCode(String email) async {
    if (state.isLoading) return;

    final trimmedEmail = email.trim();
    final validationError = _validateEmail(trimmedEmail);
    if (validationError != null) {
      emit(state.copyWith(
        status: ForgotPasswordStatus.error,
        message: validationError,
      ));
      return;
    }

    emit(state.copyWith(
      status: ForgotPasswordStatus.loading,
      email: trimmedEmail,
    ));

    final result = await sendResetCode(
      ForgotPasswordParams(email: trimmedEmail),
    );
    // The sheet can be dismissed while the request is in flight.
    if (isClosed) return;

    result.fold(
      // An unknown address fails here, which is the point of asking for the
      // code first: the old sheet only found out after the new password was
      // typed.
      (failure) => emit(state.copyWith(
        status: ForgotPasswordStatus.error,
        message: failure.message,
      )),
      (_) {
        emit(state.copyWith(
          step: ForgotPasswordStep.code,
          status: ForgotPasswordStatus.initial,
          resendSeconds: resendCooldownSeconds,
        ));
        _tickCooldown();
      },
    );
  }

  /// Step 2 — takes the mailed code through to the password step.
  ///
  /// Only the shape is checked here; whether the code is the right one is
  /// settled by [submit], which sends it with the new password. The cooldown
  /// keeps running, so a parent who comes back for a fresh code waits out
  /// whatever is left of it rather than starting over.
  void continueWithCode(String code) {
    if (state.isLoading) return;

    final otp = code.trim();
    if (otp.isEmpty) {
      emit(state.copyWith(
        status: ForgotPasswordStatus.error,
        message: L.s.otpRequired,
      ));
      return;
    }
    if (otp.length != codeLength) {
      emit(state.copyWith(
        status: ForgotPasswordStatus.error,
        message: L.s.otpIncomplete(codeLength),
      ));
      return;
    }

    emit(state.copyWith(
      step: ForgotPasswordStep.password,
      status: ForgotPasswordStatus.initial,
      otp: otp,
    ));
  }

  /// Back to the digits — the way out of a code the backend rejected on the
  /// last step.
  void backToCode() {
    if (state.step != ForgotPasswordStep.password || state.isLoading) return;
    emit(state.copyWith(
      step: ForgotPasswordStep.code,
      status: ForgotPasswordStatus.initial,
    ));
  }

  /// Step 3 — replaces the password of the address the code was mailed to.
  Future<void> submit({
    required String password,
    required String passwordConfirmation,
  }) async {
    if (state.step != ForgotPasswordStep.password || state.isLoading) return;

    final validationError = _validatePassword(
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
    if (validationError != null) {
      emit(state.copyWith(
        status: ForgotPasswordStatus.error,
        message: validationError,
      ));
      return;
    }

    emit(state.copyWith(status: ForgotPasswordStatus.loading));

    final result = await resetPassword(
      ResetPasswordParams(
        email: state.email,
        password: password,
        otp: state.otp,
      ),
    );
    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: ForgotPasswordStatus.error,
        message: failure.message,
      )),
      (_) => emit(state.copyWith(
        status: ForgotPasswordStatus.success,
        message: L.s.forgotDone,
      )),
    );
  }

  /// Mails a fresh code when the first one never arrived; the previous one
  /// stops working.
  Future<void> resendCode() async {
    if (state.step != ForgotPasswordStep.code || !state.canResend) return;

    emit(state.copyWith(isResending: true));

    final result = await sendResetCode(
      ForgotPasswordParams(email: state.email),
    );
    if (isClosed) return;

    result.fold(
      // No new mail went out, so the link stays available for another try.
      (failure) => emit(state.copyWith(
        isResending: false,
        status: ForgotPasswordStatus.error,
        message: failure.message,
      )),
      (_) {
        emit(state.copyWith(
          isResending: false,
          status: ForgotPasswordStatus.initial,
          message: L.s.otpResent,
          resendSeconds: resendCooldownSeconds,
        ));
        _tickCooldown();
      },
    );
  }

  /// Back to step 1 — the code went to a mistyped address, so the parent
  /// fixes it rather than waiting for a mail that cannot arrive.
  void backToEmail() {
    if (state.step != ForgotPasswordStep.code || state.isLoading) return;
    _cooldownTimer?.cancel();
    emit(state.copyWith(
      step: ForgotPasswordStep.email,
      status: ForgotPasswordStatus.initial,
      resendSeconds: 0,
      isResending: false,
    ));
  }

  /// Drops the complaint as soon as the input is edited, so a corrected digit
  /// stops shouting before it is submitted again.
  void inputChanged() {
    if (state.status != ForgotPasswordStatus.error) return;
    emit(state.copyWith(status: ForgotPasswordStatus.initial));
  }

  String? _validateEmail(String email) {
    if (email.isEmpty) return L.s.forgotEmailRequired;
    if (!_emailRegExp.hasMatch(email)) return L.s.forgotEmailInvalid;
    return null;
  }

  String? _validatePassword({
    required String password,
    required String passwordConfirmation,
  }) {
    if (password.isEmpty) return L.s.forgotPasswordRequired;
    if (password.length < minPasswordLength) {
      return L.s.forgotPasswordShort(minPasswordLength);
    }
    if (password != passwordConfirmation) return L.s.forgotPasswordMismatch;
    return null;
  }

  /// Counts [ForgotPasswordState.resendSeconds] down to zero, one second at a
  /// time.
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
