part of 'profile_cubit.dart';

enum ProfileStatus { initial, loading, success, error, otpSent }

class ProfileState extends Equatable {
  final ProfileStatus status;

  /// Form-wide error on failure, confirmation text on success. Null while a
  /// failure was specific enough to belong under a single field.
  final String? message;

  /// Backend field name (`name`, `email`, `phone`, `otp`) to its message.
  final Map<String, String> fieldErrors;

  /// The new login address a code was mailed to. Non-null while the sheet
  /// waits for that code — the address changes only once it is accepted.
  final String? pendingEmail;

  /// Seconds until another code may be asked for; ticks down to zero.
  final int resendSeconds;

  final bool isResending;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.message,
    this.fieldErrors = const {},
    this.pendingEmail,
    this.resendSeconds = 0,
    this.isResending = false,
  });

  bool get isLoading => status == ProfileStatus.loading;

  /// The sheet shows the code step rather than the form.
  bool get awaitingCode => pendingEmail != null;

  bool get canResend =>
      awaitingCode && resendSeconds <= 0 && !isResending && !isLoading;

  /// What to show under [field], if anything.
  String? errorFor(String field) => fieldErrors[field];

  /// The form-wide line only earns its place when no field claimed the
  /// message — otherwise the same text would be shown twice.
  String? get formError =>
      status == ProfileStatus.error && fieldErrors.isEmpty ? message : null;

  /// The code step has a single line for complaints, so whatever went wrong
  /// lands there: the code's own error first, then a field the backend named
  /// (the address was taken while the code was on its way), then the rest.
  String? get codeError {
    if (status != ProfileStatus.error) return null;
    return fieldErrors['otp'] ??
        (fieldErrors.isNotEmpty ? fieldErrors.values.first : message);
  }

  ProfileState copyWith({
    ProfileStatus? status,
    String? message,
    Map<String, String>? fieldErrors,
    String? pendingEmail,
    bool clearPendingEmail = false,
    int? resendSeconds,
    bool? isResending,
  }) =>
      ProfileState(
        status: status ?? this.status,
        // message and fieldErrors are intentionally not carried over: each
        // state sets them, so a stale failure can't resurface on the next
        // emit.
        message: message,
        fieldErrors: fieldErrors ?? const {},
        // The code step, on the other hand, outlives every emit until it is
        // left on purpose.
        pendingEmail:
            clearPendingEmail ? null : (pendingEmail ?? this.pendingEmail),
        resendSeconds: resendSeconds ?? this.resendSeconds,
        isResending: isResending ?? this.isResending,
      );

  @override
  List<Object?> get props => [
        status,
        message,
        fieldErrors,
        pendingEmail,
        resendSeconds,
        isResending,
      ];
}
