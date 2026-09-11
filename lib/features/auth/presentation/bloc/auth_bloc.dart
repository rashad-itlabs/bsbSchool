import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/push/push_service.dart';
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

  /// Where the device's push subscription is bound to the signed-in account.
  /// Every path that changes who is signed in has to tell it — this bloc is
  /// the only place that knows about all of them. Defaults to a no-op so the
  /// widget tests don't need a platform channel.
  final PushService push;

  AuthBloc({
    required this.loginUser,
    required this.logoutUser,
    required this.repository,
    this.push = const NoopPushService(),
  }) : super(const AuthState()) {
    on<AuthCheckRequested>(_onCheck);
    on<AuthLoginRequested>(_onLogin);
    on<AuthChildSelected>(_onChildSelected);
    on<AuthChildAdded>(_onChildAdded);
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

    // A restored session never passes through the login screen, so this is the
    // only chance to re-bind the subscription — the tags may be stale (a class
    // rolled over, a switch flipped while the app was closed), and a
    // reinstalled app has no external id at all. No permission prompt here:
    // the parent is looking at a launch screen, not at a reason to say yes.
    _bindPush();
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
      (session) {
        emit(AuthState(
          status: AuthStatus.authenticated,
          user: session.user,
          activeChild: repository.activeChild,
        ));
        // The one moment worth asking for the notification permission: the
        // parent has just signed in and the dashboard is about to appear, so
        // the system dialog arrives with something behind it.
        _bindPush(prompt: true);
      },
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
      (_) {
        emit(state.copyWith(
          isSwitchingChild: false,
          activeChild: repository.activeChild,
          // The endpoint may have handed back a refreshed user (new class, new
          // `child_name`); the repository cached it, so re-read it here.
          user: repository.currentUser,
        ));
        // Same parent, different student: the external id stays put and only
        // the `student_id` / `class_id` tags move.
        _bindPush();
      },
    );
  }

  /// Links one more student to the account.
  ///
  /// Unlike [_onChildSelected] this leaves [AuthState.activeChild] where it
  /// is — the parent asked to add a student, not to switch to them, and
  /// moving the whole app would reload every screen out from under them. The
  /// exception is an account that had none: [AuthRepository.activeChild] then
  /// resolves to the new student on its own, which is what gets the parent off
  /// `AddChildScreen` and into the app.
  Future<void> _onChildAdded(
    AuthChildAdded event,
    Emitter<AuthState> emit,
  ) async {
    if (state.isAddingChild) return;
    emit(state.copyWith(isAddingChild: true));

    final result = await repository.attachChild(
      admissionNo: event.admissionNo,
      relation: event.relation,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isAddingChild: false,
        addChildError: failure.message,
      )),
      (_) {
        emit(state.copyWith(
          isAddingChild: false,
          user: repository.currentUser,
          activeChild: repository.activeChild,
        ));
        // A new student means a new `student_id` / `class_id` to tag the
        // subscription with when this was the account's first one.
        _bindPush();
      },
    );
  }

  /// Points the push subscription at whoever is signed in now.
  ///
  /// Fire-and-forget: the SDK talks to the network and no screen waits on the
  /// answer, so a slow or offline registration never holds up the dashboard.
  void _bindPush({bool prompt = false}) {
    final user = repository.currentUser;
    if (user == null) return;
    unawaited(push.signIn(
      user,
      activeChild: repository.activeChild,
      promptPermission: prompt,
    ));
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    await logoutUser(const NoParams());
    // Awaited, not fired off: the login screen is one emit away, and whoever
    // signs in next must not land on a device still subscribed as this parent.
    await push.signOut();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
