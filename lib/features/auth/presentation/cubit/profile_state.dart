part of 'profile_cubit.dart';

enum ProfileStatus { initial, loading, success, error }

class ProfileState extends Equatable {
  final ProfileStatus status;

  /// Form-wide error on failure, confirmation text on success. Null while a
  /// failure was specific enough to belong under a single field.
  final String? message;

  /// Backend field name (`name`, `email`, `phone`) to its message.
  final Map<String, String> fieldErrors;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.message,
    this.fieldErrors = const {},
  });

  bool get isLoading => status == ProfileStatus.loading;

  /// What to show under [field], if anything.
  String? errorFor(String field) => fieldErrors[field];

  /// The form-wide line only earns its place when no field claimed the
  /// message — otherwise the same text would be shown twice.
  String? get formError =>
      status == ProfileStatus.error && fieldErrors.isEmpty ? message : null;

  ProfileState copyWith({
    ProfileStatus? status,
    String? message,
    Map<String, String>? fieldErrors,
  }) =>
      ProfileState(
        status: status ?? this.status,
        // message and fieldErrors are intentionally not carried over: each
        // state sets them, so a stale failure can't resurface on the next
        // emit.
        message: message,
        fieldErrors: fieldErrors ?? const {},
      );

  @override
  List<Object?> get props => [status, message, fieldErrors];
}
