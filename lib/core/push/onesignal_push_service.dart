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

  /// How many times a binding that did not stick is re-applied. Three is
  /// enough to cover the SDK creating its user and registering the device;
  /// past that the id is missing for a reason no amount of retrying fixes.
  static const int bindAttempts = 3;

  /// How long to leave between them — long enough for the call to reach the
  /// server and come back. Injectable so the tests don't sit through it.
  final Duration bindRetryDelay;

  OneSignalPushService({this.bindRetryDelay = const Duration(seconds: 2)});

  /// The account this device *should* be addressed as, for as long as it
  /// stays signed in.
  ///
  /// Deliberately "wanted" rather than "bound": the field this replaces
  /// recorded that `OneSignal.login` had been *called* and skipped every
  /// later call for the same id. A registration is where that comes apart —
  /// the parent installs the app, signs up, and the identity is applied
  /// seconds later to an SDK user that has no push subscription yet, so the
  /// call can be swallowed and the account stays anonymous with nothing left
  /// to retry it. [_applyIdentity] reads the id back instead of assuming.
  String? _wantedExternalId;

  /// Guards [_applyIdentity]. The observers below fire *because* of the
  /// `login` it makes, so without this the first binding re-enters itself.
  bool _binding = false;

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

    // The two ways a binding silently disappears: the SDK replacing its user,
    // and the push subscription being created after the identity was applied.
    OneSignal.User.addObserver(_onUserChanged);
    OneSignal.User.pushSubscription.addObserver(_onSubscriptionChanged);

    // A language picked in the app has to reach OneSignal, which chooses the
    // version of a message by it — see [_syncLanguage].
    LocaleController.instance.addListener(_onLocaleChanged);
  }

  @override
  Future<void> signIn(
    AuthUser user, {
    ChildAccount? activeChild,
    bool promptPermission = false,
  }) async {
    _wantedExternalId = user.pushExternalId;

    if (_wantedExternalId == null) {
      // Worth shouting about: the device is reachable by tag but has no
      // address, so anything the backend sends to one parent misses it.
      debugPrint(
        '[push] ${user.role} "${user.email}" has no external id — the login '
        'response carried no push_external_id, no parent_ids and no user_id. '
        'This device stays anonymous.',
      );
    }

    await _applyIdentity();
    await _syncLanguage();

    // `canRequest` covers the parent who never signed in on this build: an
    // update installs over a session that is simply restored, and on Android
    // 13+ a device nobody ever asked shows nothing at all. It answers false
    // once the choice has been made either way, so this asks at most once.
    if (promptPermission || await OneSignal.Notifications.canRequest()) {
      // false: a parent who already said no is not bounced into the Settings
      // app behind their back. The profile screen is where they turn it on.
      await OneSignal.Notifications.requestPermission(false);
      // Saying yes is what creates the push subscription on a device that
      // never had one — the registration path, where the parent reaches this
      // line minutes after installing. The identity above was applied to a
      // user with nothing to hang it on, so assert it again now that there
      // is. A no-op when the first attempt already stuck.
      await _applyIdentity();
    }
  }

  @override
  Future<void> signOut() async {
    _wantedExternalId = null;
    // Drops the external id, leaving an anonymous subscription: on a shared
    // family device the next account to sign in starts clean instead of
    // inheriting the previous parent's messages.
    await OneSignal.logout();
  }

  /// Binds [_wantedExternalId], and checks that it stuck.
  ///
  /// `OneSignal.login` resolves as soon as the call is queued, not once the
  /// SDK holds an identified user, so the only honest answer comes from
  /// reading the id back. Re-reading the field on every pass also means a
  /// child switch that lands mid-retry converges on the newer id.
  Future<void> _applyIdentity() async {
    if (_binding) return;
    _binding = true;
    try {
      for (var attempt = 1; attempt <= bindAttempts; attempt++) {
        final wanted = _wantedExternalId;
        if (wanted == null) return;
        if (await _currentExternalId() == wanted) {
          // Attempt 2 is the ordinary verification pass after the first
          // `login`; anything past it means a call really was dropped.
          if (attempt > 2) {
            debugPrint('[push] external id "$wanted" bound on attempt $attempt');
          }
          return;
        }
        try {
          await OneSignal.login(wanted);
        } catch (e) {
          debugPrint('[push] login("$wanted") failed: $e');
        }
        await Future<void>.delayed(bindRetryDelay);
      }
      final wanted = _wantedExternalId;
      if (wanted != null && await _currentExternalId() != wanted) {
        debugPrint(
          '[push] external id "$wanted" did not stick after $bindAttempts '
          'attempts — the device is still anonymous.',
        );
      }
    } finally {
      _binding = false;
    }
  }

  /// What the SDK says this device is addressed as, with an empty string read
  /// as "nothing" — that is what an anonymous user answers.
  Future<String?> _currentExternalId() async {
    try {
      final id = await OneSignal.User.getExternalId();
      return (id == null || id.isEmpty) ? null : id;
    } catch (_) {
      // An SDK that cannot answer is treated as unbound: re-applying an
      // identity it already holds costs nothing, losing one costs the parent
      // every notification.
      return null;
    }
  }

  /// The SDK swapped its user out from under us — a registration finishing on
  /// a fresh install, an identity the server rolled back. Anything that
  /// leaves the device anonymous while an account is signed in has to be
  /// repaired, or the backend has no address for this parent.
  void _onUserChanged(OSUserChangedState state) {
    final wanted = _wantedExternalId;
    if (wanted == null || state.current.externalId == wanted) return;
    unawaited(_applyIdentity());
  }

  /// The push subscription appeared or was replaced. On a fresh install this
  /// is the first moment there is a subscription for an external id to hang
  /// on — before it, a `login` has nothing to identify.
  void _onSubscriptionChanged(OSPushSubscriptionChangedState state) {
    final id = state.current.id;
    if (id == null || id.isEmpty || id == state.previous.id) return;
    unawaited(_applyIdentity().then((_) => _syncLanguage()));
  }

  void _onLocaleChanged() => unawaited(_syncLanguage());

  /// Lets OneSignal pick the right language version of a message — on every
  /// binding, on a new subscription, and whenever the parent switches.
  ///
  /// The language goes out ALONE and the app sends no tags (10.10.2026). It
  /// used to ride with up to nine tags, and OneSignal's free plan keeps six
  /// per user, so that write was refused. The SDK sends everything queued for
  /// a user as ONE request (iOS 5.5.6 `OSPropertyOperationExecutor`, Android
  /// 5.9.9 `UpdateUserOperationExecutor`) and drops it on a 4xx, so the
  /// language was refused with the tags: parents got pushes in the phone's
  /// language — `tr` on a Turkish iPhone — instead of the app's. Nothing read
  /// those tags: the backend addresses an account by its external id. A tag
  /// added back would have to fit the plan's per-user limit, and never be
  /// sent beside the language.
  ///
  /// The language belongs to the OneSignal user, not to the device: a parent
  /// signed in on two phones gets the language of the one opened last.
  Future<void> _syncLanguage() {
    final locale = LocaleController.instance.resolve(
      WidgetsBinding.instance.platformDispatcher.locales,
    );
    return OneSignal.User.setLanguage(locale.languageCode);
  }

  void _onClick(OSNotificationClickEvent event) {
    PushRouter.instance.request(
      PushRouter.parse(event.notification.additionalData),
    );
  }

  void _onWillDisplay(OSNotificationWillDisplayEvent event) {
    // A kind the parent switched off must stay silent. The backend does not
    // know the switches — they live on this device — so this is where they
    // are honoured; the SDK only asks while the app is in the foreground.
    final kind = _kindOf(event.notification.additionalData);
    if (kind != null && !NotificationPrefs.instance.isEnabled(kind)) {
      event.preventDefault();
    }
  }

  NotificationKind? _kindOf(Map<String, dynamic>? data) {
    final raw = (data?['kind'] ?? data?['type'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    return switch (raw) {
      'attendance' => NotificationKind.attendance,
      'cafeteria' || 'buffet' || 'food_card' => NotificationKind.cafeteria,
      'exam' || 'examination' => NotificationKind.exam,
      'homework' || 'home_work' || 'assignment' => NotificationKind.homework,
      _ => null,
    };
  }
}
