import '../../features/auth/domain/entities/auth_user.dart';
import '../../features/auth/domain/entities/child_account.dart';

/// Keeps this device's push subscription pointed at the account that is signed
/// in, so the backend can address one parent — or one student, or one teacher
/// — instead of broadcasting to everyone.
///
/// Behind an interface for the same reason the storages are: the widget tests
/// build the app without a platform channel behind it, and [NoopPushService]
/// lets them.
abstract class PushService {
  /// Boots the SDK and registers its listeners. Call once, before `runApp`.
  Future<void> init();

  /// Binds this device to [user]: the external id the backend targets, plus
  /// the tags it can segment on.
  ///
  /// Safe to call again for the same account — a repeat only refreshes the
  /// tags, which is what a child switch needs.
  ///
  /// [promptPermission] asks the OS for permission to show notifications. True
  /// only right after a sign-in, never on a cold start: the system dialog is
  /// shown once per install, and a parent staring at a launch screen has no
  /// idea what they are being asked.
  Future<void> signIn(
    AuthUser user, {
    ChildAccount? activeChild,
    bool promptPermission = false,
  });

  /// Releases the account, so the next person to sign in on this device does
  /// not inherit the previous one's notifications.
  Future<void> signOut();
}

/// Stands in wherever OneSignal must not run — unit and widget tests.
class NoopPushService implements PushService {
  const NoopPushService();

  @override
  Future<void> init() async {}

  @override
  Future<void> signIn(
    AuthUser user, {
    ChildAccount? activeChild,
    bool promptPermission = false,
  }) async {}

  @override
  Future<void> signOut() async {}
}
