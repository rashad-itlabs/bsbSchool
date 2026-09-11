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

  /// The student every screen is currently showing — the parent's pick in the
  /// dashboard switcher, or the account's own student. Null for a teacher, or
  /// when the login carried no `info`.
  final ChildAccount? activeChild;

  /// True while `/selectChild` is in flight. Deliberately not [AuthStatus] —
  /// `loading` puts the login screen back on top, and the parent must keep
  /// seeing the dashboard while the switch lands.
  final bool isSwitchingChild;

  /// Set when the last login attempt failed, so the UI can show it.
  final String? errorMessage;

  /// Set when a child switch was rejected — kept apart from [errorMessage] so
  /// the login form and the dashboard can't show each other's messages.
  final String? childSwitchError;

  /// True while `/attachChild` is in flight. Separate from
  /// [isSwitchingChild]: linking a student and switching to one are different
  /// requests, and the add sheet must not spin because the switcher is busy.
  final bool isAddingChild;

  /// Set when linking a student was rejected — "no such admission number",
  /// "already on this account". Its own field for the same reason as
  /// [childSwitchError]: one form's failure must not surface in another.
  final String? addChildError;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.activeChild,
    this.isSwitchingChild = false,
    this.errorMessage,
    this.childSwitchError,
    this.isAddingChild = false,
    this.addChildError,
  });

  bool get isLoading => status == AuthStatus.loading;

  /// Every student on the account — what the switcher lists.
  List<ChildAccount> get children => user?.children ?? const [];

  /// The switcher only earns its place when there's something to switch to.
  bool get canSwitchChild => children.length > 1;

  /// Name shown in the dashboard greeting: the active student, falling back to
  /// the `child_name` the login response put at the root.
  String get activeChildName {
    final name = activeChild?.fullName ?? '';
    return name.isNotEmpty ? name : (user?.childName ?? '');
  }

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    ChildAccount? activeChild,
    bool? isSwitchingChild,
    String? errorMessage,
    String? childSwitchError,
    bool? isAddingChild,
    String? addChildError,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      activeChild: activeChild ?? this.activeChild,
      isSwitchingChild: isSwitchingChild ?? this.isSwitchingChild,
      isAddingChild: isAddingChild ?? this.isAddingChild,
      // The messages are intentionally not carried over: each state sets
      // them, so a stale failure can't resurface on the next emit.
      errorMessage: errorMessage,
      childSwitchError: childSwitchError,
      addChildError: addChildError,
    );
  }

  @override
  List<Object?> get props => [
        status,
        user,
        activeChild,
        isSwitchingChild,
        errorMessage,
        childSwitchError,
        isAddingChild,
        addChildError,
      ];
}
