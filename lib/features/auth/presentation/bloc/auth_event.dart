part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Fired at startup to decide between the login screen and the app.
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// User submitted the login form.
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// User tapped "log out".
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
