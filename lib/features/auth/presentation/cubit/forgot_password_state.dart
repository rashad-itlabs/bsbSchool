part of 'forgot_password_cubit.dart';

enum ForgotPasswordStatus { initial, loading, success, error }

class ForgotPasswordState extends Equatable {
  final ForgotPasswordStatus status;

  /// Error text on failure, confirmation text on success.
  final String? message;

  const ForgotPasswordState({
    this.status = ForgotPasswordStatus.initial,
    this.message,
  });

  bool get isLoading => status == ForgotPasswordStatus.loading;

  ForgotPasswordState copyWith({
    ForgotPasswordStatus? status,
    String? message,
  }) =>
      ForgotPasswordState(
        status: status ?? this.status,
        // message is intentionally not carried over: each state sets it.
        message: message,
      );

  @override
  List<Object?> get props => [status, message];
}
