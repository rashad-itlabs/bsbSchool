import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/logout_user.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUser loginUser;
  final LogoutUser logoutUser;
  final AuthRepository repository;

  AuthBloc({
    required this.loginUser,
    required this.logoutUser,
    required this.repository,
  }) : super(const AuthState()) {
    on<AuthCheckRequested>(_onCheck);
    on<AuthLoginRequested>(_onLogin);
    on<AuthLogoutRequested>(_onLogout);
  }

  void _onCheck(AuthCheckRequested event, Emitter<AuthState> emit) {
    final loggedIn = repository.isLoggedIn;
    emit(AuthState(
      status: loggedIn ? AuthStatus.authenticated : AuthStatus.unauthenticated,
      user: loggedIn ? repository.currentUser : null,
    ));
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    final result = await loginUser(
      LoginParams(email: event.email, password: event.password),
    );

    result.fold(
      (failure) => emit(AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: failure.message,
      )),
      (session) => emit(AuthState(
        status: AuthStatus.authenticated,
        user: session.user,
      )),
    );
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    await logoutUser(const NoParams());
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
