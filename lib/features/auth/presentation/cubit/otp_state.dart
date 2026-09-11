part of 'otp_cubit.dart';

enum OtpStatus { initial, loading, success, error }

class OtpState extends Equatable {
  final OtpStatus status;

  /// Error text on failure, confirmation text on success.
  final String? message;

  /// Kept apart from [status] so a resend in flight never puts the verify
  /// button into its loading state.
  final bool isResending;

  /// Seconds left before another code may be asked for.
  final int resendSeconds;

  const OtpState({
    this.status = OtpStatus.initial,
    this.message,
    this.isResending = false,
    this.resendSeconds = 0,
  });

  bool get isLoading => status == OtpStatus.loading;

  bool get canResend => resendSeconds == 0 && !isResending && !isLoading;

  OtpState copyWith({
    OtpStatus? status,
    String? message,
    bool? isResending,
    int? resendSeconds,
  }) =>
      OtpState(
        status: status ?? this.status,
        // message is intentionally not carried over: each state sets it, so a
        // stale failure can't resurface on the next emit.
        message: message,
        isResending: isResending ?? this.isResending,
        resendSeconds: resendSeconds ?? this.resendSeconds,
      );

  @override
  List<Object?> get props => [status, message, isResending, resendSeconds];
}
