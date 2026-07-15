part of 'auth_bloc.dart';

enum AuthStatus {
  /// Startup — we don't yet know if there's a stored token.
  unknown,

  /// A request (login/logout/check) is in flight.
  loading,

  /// Token present — user is in.
  authenticated,

  /// No token — show the login screen.
  unauthenticated,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final AuthUser? user;

  /// Set when the last login attempt failed, so the UI can show it.
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.errorMessage,
  });

  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      // errorMessage is intentionally not carried over: each state sets it.
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage];
}
