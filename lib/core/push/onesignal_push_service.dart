import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../../features/auth/domain/entities/auth_user.dart';
import '../../features/auth/domain/entities/child_account.dart';
import '../../features/notifications/presentation/notification_prefs.dart';
import '../l10n/locale_controller.dart';
import 'push_router.dart';
import 'push_service.dart';

/// The live [PushService] — OneSignal.
class OneSignalPushService implements PushService {
  /// The OneSignal app the school's Android and iOS platforms live under.
 /// static const String appId = '3c11785b-f239-4391-bb2c-31a65f381e55';
  static const String appId = 'd8a04805-2763-4b8b-bf14-4ae0758cfa41';

  /// The external id currently bound to this device. Kept so signing the same
  /// account in twice (a child switch, a relaunch) only refreshes the tags —
  /// `OneSignal.login` would otherwise re-resolve the user on every call.
  String? _externalId;

  bool _started = false;

  @override
  Future<void> init() async {
    if (_started) return;
    _started = true;

    OneSignal.Debug.setLogLevel(kDebugMode ? OSLogLevel.warn : OSLogLevel.none);
    OneSignal.initialize(appId);

    // Registered before the first frame on purpose: a tap that cold-starts the
    // app is buffered by the SDK and replayed as soon as a listener exists.
    OneSignal.Notifications.addClickListener(_onClick);
    OneSignal.Notifications.addForegroundWillDisplayListener(_onWillDisplay);

    // A switch flipped on the profile screen has to reach the backend, which
    // reads the choices as tags — see [NotificationPrefs].
    NotificationPrefs.instance.addListener(_onPrefsChanged);
    LocaleController.instance.addListener(_onLocaleChanged);
  }

  @override
  Future<void> signIn(
    AuthUser user, {
    ChildAccount? activeChild,
    bool promptPermission = false,
  }) async {
    final externalId = user.pushExternalId;
    if (externalId != null && externalId != _externalId) {
      await OneSignal.login(externalId);
      _externalId = externalId;
    }

    await OneSignal.User.addTags(_tagsFor(user, activeChild));
    await _syncLanguage();

    // `canRequest` covers the parent who never signed in on this build: an
    // update installs over a session that is simply restored, and on Android
    // 13+ a device nobody ever asked shows nothing at all. It answers false
    // once the choice has been made either way, so this asks at most once.
    if (promptPermission || await OneSignal.Notifications.canRequest()) {
      // false: a parent who already said no is not bounced into the Settings
      // app behind their back. The profile screen is where they turn it on.
      await OneSignal.Notifications.requestPermission(false);
    }
  }

  @override
  Future<void> signOut() async {
    _externalId = null;
    // Drops the external id and the tags with it, leaving an anonymous
    // subscription: on a shared family device the next account to sign in
    // starts clean instead of inheriting the previous parent's messages.
    await OneSignal.logout();
  }

  /// What the backend can segment on when it doesn't target one external id.
  ///
  /// `email` is here because it is the only field that is unique per *account*
  /// today: two parents of the same student share `user_id`, so until the
  /// login response carries `parent_id` this is what tells them apart. See
  /// [AuthUser.pushExternalId].
  Map<String, dynamic> _tagsFor(AuthUser user, ChildAccount? activeChild) => {
        'role': user.role.trim().toLowerCase(),
        'email': user.email.trim().toLowerCase(),
        'parent_id': user.accountId?.toString() ?? '',
        // Both describe what the app is *showing*, not who the parent is
        // responsible for: a switch moves them. Targeting a class through
        // `class_id` would skip every parent whose other child is selected —
        // address the account and let the backend name the student instead.
        'student_id': (activeChild?.childId ?? user.id)?.toString() ?? '',
        'class_id': (activeChild?.classId ?? user.classId)?.toString() ?? '',
        ..._prefTags(),
      };

  /// The three delivery switches, as `notify_attendance: "1" | "0"`.
  Map<String, String> _prefTags() => {
        for (final kind in NotificationKind.values)
          kind.prefsKey: NotificationPrefs.instance.isEnabled(kind) ? '1' : '0',
      };

  void _onPrefsChanged() => unawaited(OneSignal.User.addTags(_prefTags()));

  void _onLocaleChanged() => unawaited(_syncLanguage());

  /// Lets OneSignal pick the right language version of a message.
  Future<void> _syncLanguage() {
    final locale = LocaleController.instance
        .resolve(WidgetsBinding.instance.platformDispatcher.locales);
    return OneSignal.User.setLanguage(locale.languageCode);
  }

  void _onClick(OSNotificationClickEvent event) {
    PushRouter.instance.request(
      PushRouter.parse(event.notification.additionalData),
    );
  }

  void _onWillDisplay(OSNotificationWillDisplayEvent event) {
    // A kind the parent switched off must stay silent even when the backend
    // still sent it — the tags it filters on may not have reached OneSignal
    // yet, and the switch is the parent's answer either way.
    final kind = _kindOf(event.notification.additionalData);
    if (kind != null && !NotificationPrefs.instance.isEnabled(kind)) {
      event.preventDefault();
    }
  }

  NotificationKind? _kindOf(Map<String, dynamic>? data) {
    final raw =
        (data?['kind'] ?? data?['type'] ?? '').toString().trim().toLowerCase();

    return switch (raw) {
      'attendance' => NotificationKind.attendance,
      'cafeteria' || 'buffet' || 'food_card' => NotificationKind.cafeteria,
      'exam' || 'examination' => NotificationKind.exam,
      _ => null,
    };
  }
}
