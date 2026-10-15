import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
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
    on<AuthChildRemoved>(_onChildRemoved);
    on<AuthSessionRefreshed>(_onSessionRefreshed);
    on<AuthChildStatusCheckRequested>(_onChildStatusCheck);
    on<AuthUserReloadRequested>(_onUserReload);
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
    // only chance to re-bind the subscription and re-send the app's language
    // — the account's other phone may have written its own since, and a
    // reinstalled app has no external id at all. No permission prompt here:
    // the parent is looking at a launch screen, not at a reason to say yes.
    _bindPush();

    if (loggedIn) add(const AuthChildStatusCheckRequested());
  }


  ///
  bool _reloading = false;

  Future<void> _onUserReload(
      AuthUserReloadRequested event,
      Emitter<AuthState> emit,
      ) async {
    if (_reloading || state.status != AuthStatus.authenticated) return;
    _reloading = true;
    try {
      final result = await repository.refreshUser();
      result.fold(
            (_) {}, // şəbəkə xətası: mövcud state qalsın
            (_) {
          emit(state.copyWith(
            user: repository.currentUser,
            activeChild: repository.activeChild,
          ));
          // 2 uşaq varsa və seçilmiş deaktivdirsə, aktivə keçir
          add(const AuthChildStatusCheckRequested());
        },
      );
    } finally {
      _reloading = false;
    }
  }
  ///

  /// Cari uşaq `isActive == 'no'`-dursa, aktiv olan başqa uşağa keçir.
  /// Aktiv uşaq yoxdursa, heç nə etmir; UI bloklayıcı modal göstərir.
  Future<void> _onChildStatusCheck(
      AuthChildStatusCheckRequested event,
      Emitter<AuthState> emit,
      ) async {
    final current = state.activeChild;
    if (current == null || current.isActive != 'no') return;

    final children = state.user?.children ?? const <ChildAccount>[];
    final replacement = children.cast<ChildAccount?>().firstWhere(
          (c) => c!.isActive != 'no' && c.childId != null,
      orElse: () => null,
    );
    if (replacement == null) return;

    // Mövcud mexanizm: serverə /selectChild göndərir, push tag-ları yeniləyir
    add(AuthChildSelected(replacement.childId!));
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
        _bindPush(prompt: true);

        // Aktiv olmayan uşaq seçilibsə, aktiv olana keç
        add(const AuthChildStatusCheckRequested());
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
        // Same parent, different student: the external id stays put; this
        // only re-asserts it and the language.
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

  /// Unlinks a student once the backend has checked the parent's password.
  ///
  /// When the student removed is the one on screen, `/selectChild` moves the
  /// backend over to the next one before anything is emitted — same reason as
  /// in [_onChildSelected]: the screens refetch on the emit, and must not
  /// reload the student who is gone. With none left the account is
  /// [AuthUser.needsChild], and AuthGate swaps in `AddChildScreen` on its own.
  Future<void> _onChildRemoved(
    AuthChildRemoved event,
    Emitter<AuthState> emit,
  ) async {
    if (state.isRemovingChild) return;
    emit(state.copyWith(isRemovingChild: true));

    final wasActive = state.activeChild?.childId == event.childId;
    final result = await repository.detachChild(
      childId: event.childId,
      password: event.password,
    );

    final failure = result.fold((failure) => failure, (_) => null);
    if (failure != null) {
      emit(state.copyWith(
        isRemovingChild: false,
        // A wrong password comes back under its field, worded more precisely
        // than the form-wide message.
        removeChildError: failure is FieldValidationFailure
            ? failure.fieldErrors['password'] ?? failure.message
            : failure.message,
      ));
      return;
    }

    final nextId = repository.activeChild?.childId;
    if (wasActive && nextId != null) {
      // Best effort: the status poller's next `/selectChild` names the same
      // student, so a failure here only delays the move.
      await repository.selectChild(nextId);
    }

    // Built afresh: copyWith can't clear [AuthState.activeChild], and after
    // the last student it has to be null.
    emit(AuthState(
      status: state.status,
      user: repository.currentUser,
      activeChild: repository.activeChild,
      isSwitchingChild: state.isSwitchingChild,
      isAddingChild: state.isAddingChild,
    ));
    _bindPush();
    // The student moved to may be one the school has made inactive.
    add(const AuthChildStatusCheckRequested());
  }

  /// Re-reads the user the repository just cached. Nothing is fetched here —
  /// the write already happened, and the sheet that made it is waiting on its
  /// own cubit, not on this.
  void _onSessionRefreshed(
    AuthSessionRefreshed event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(
      user: repository.currentUser,
      activeChild: repository.activeChild,
    ));
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
    // Before the logout, not after: the backend forgets this device's push
    // token by the bearer token, which the logout clears. Awaited, not fired
    // off: whoever signs in next must not land on a device still registered
    // as this parent. Bounded by its own timeout, so a slow network delays
    // the logout by seconds, not indefinitely.
    await push.signOut();
    await logoutUser(const NoParams());
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
