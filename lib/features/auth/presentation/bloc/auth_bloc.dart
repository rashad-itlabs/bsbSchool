import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/child_account.dart';
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
    on<AuthChildSelected>(_onChildSelected);
    on<AuthLogoutRequested>(_onLogout);
  }

  void _onCheck(AuthCheckRequested event, Emitter<AuthState> emit) {
    final loggedIn = repository.isLoggedIn;
    emit(AuthState(
      status: loggedIn ? AuthStatus.authenticated : AuthStatus.unauthenticated,
      user: loggedIn ? repository.currentUser : null,
      // Restores the student the parent was last looking at.
      activeChild: loggedIn ? repository.activeChild : null,
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
        activeChild: repository.activeChild,
      )),
    );
  }

  /// Switching is a round trip: `/selectChild` moves `users.user_id` on the
  /// backend, and only then does [AuthRepository.activeChild] change. Emitting
  /// the new state is what makes the screens remount and refetch, so it must
  /// not happen until the call has landed — otherwise they'd reload the
  /// student the app is leaving.
  Future<void> _onChildSelected(
    AuthChildSelected event,
    Emitter<AuthState> emit,
  ) async {
    if (state.isSwitchingChild) return;
    emit(state.copyWith(isSwitchingChild: true));

    final result = await repository.selectChild(event.childId);

    result.fold(
      (failure) => emit(state.copyWith(
        isSwitchingChild: false,
        childSwitchError: failure.message,
      )),
      (_) => emit(state.copyWith(
        isSwitchingChild: false,
        activeChild: repository.activeChild,
        // The endpoint may have handed back a refreshed user (new class, new
        // `child_name`); the repository cached it, so re-read it here.
        user: repository.currentUser,
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
