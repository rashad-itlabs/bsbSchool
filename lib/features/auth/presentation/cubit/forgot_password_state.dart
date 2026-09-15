part of 'forgot_password_cubit.dart';

/// Where the sheet is: the address, the code mailed to it, then the password.
enum ForgotPasswordStep { email, code, password }

enum ForgotPasswordStatus { initial, loading, success, error }

class ForgotPasswordState extends Equatable {
  final ForgotPasswordStep step;

  final ForgotPasswordStatus status;

  /// Error text on failure, confirmation text on success.
  final String? message;

  /// The address the code was mailed to — every later step carries it, and
  /// the login screen is handed it back once the password is replaced.
  final String email;

  /// The six digits typed at the code step. The backend checks them only
  /// when the new password is sent, so they have to be carried across the
  /// step in between.
  final String otp;

  /// Kept apart from [status] so a resend in flight never puts the verify
  /// button into its loading state.
  final bool isResending;

  /// Seconds left before another code may be asked for.
  final int resendSeconds;

  const ForgotPasswordState({
    this.step = ForgotPasswordStep.email,
    this.status = ForgotPasswordStatus.initial,
    this.message,
    this.email = '',
    this.otp = '',
    this.isResending = false,
    this.resendSeconds = 0,
  });

  bool get isLoading => status == ForgotPasswordStatus.loading;

  bool get canResend => resendSeconds <= 0 && !isResending && !isLoading;

  ForgotPasswordState copyWith({
    ForgotPasswordStep? step,
    ForgotPasswordStatus? status,
    String? message,
    String? email,
    String? otp,
    bool? isResending,
    int? resendSeconds,
  }) =>
      ForgotPasswordState(
        step: step ?? this.step,
        status: status ?? this.status,
        // message is intentionally not carried over: each state sets it, so a
        // stale failure can't resurface on the next emit.
        message: message,
        email: email ?? this.email,
        otp: otp ?? this.otp,
        isResending: isResending ?? this.isResending,
        resendSeconds: resendSeconds ?? this.resendSeconds,
      );

  @override
  List<Object?> get props =>
      [step, status, message, email, otp, isResending, resendSeconds];
}
