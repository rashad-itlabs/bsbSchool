import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../features/auth/domain/entities/auth_user.dart';
import '../../features/auth/domain/entities/child_account.dart';
import '../../features/notifications/presentation/notification_prefs.dart';
import '../../features/notifications/presentation/notifications_feed_signal.dart';
import '../../l10n/app_localizations.dart';
import '../l10n/locale_controller.dart';
import '../utils/app_info.dart';
import 'foreground_notifier.dart';
import 'push_messaging.dart';
import 'push_router.dart';
import 'push_service.dart';
import 'push_token_api.dart';

/// The live [PushService] — Firebase Cloud Messaging (replaced OneSignal,
/// 12.10.2026).
///
/// The backend keeps one row per device in `push_tokens` and picks the
/// language of a message itself, so this class has two jobs: keep that row
/// current (token, app language), and turn a message or a tap into something
/// the parent sees.
///
/// A device whose account has a row here is no longer sent anything through
/// OneSignal; an account without one still is, so a parent on a phone that
/// has not updated keeps getting notifications.
class FirebasePushService implements PushService {
  /// How long a sign-out waits for the server before letting the parent go.
  /// The token is deleted on the device either way, so a row the server did
  /// not hear about stops working and is cleaned up on the next send.
  static const Duration signOutTimeout = Duration(seconds: 5);

  final PushMessaging messaging;
  final PushTokenApi api;
  final ForegroundNotifier notifier;
  final AppInfo appInfo;

  /// The language the app renders in — what the server writes to this device
  /// in. Injectable, with [localeChanges], so the tests need no preferences.
  final Locale Function() _locale;
  final Listenable _localeChanges;
  final bool Function(NotificationKind kind) _isEnabled;

  /// Where the notifications tab hears that its feed changed.
  final NotificationsFeedSignal _feed;

  FirebasePushService({
    required this.messaging,
    required this.api,
    required this.notifier,
    required this.appInfo,
    Locale Function()? locale,
    Listenable? localeChanges,
    bool Function(NotificationKind kind)? isEnabled,
    NotificationsFeedSignal? feed,
  })  : _locale = locale ?? _appLocale,
        _localeChanges = localeChanges ?? LocaleController.instance,
        _isEnabled = isEnabled ?? NotificationPrefs.instance.isEnabled,
        _feed = feed ?? NotificationsFeedSignal.instance;

  static Locale _appLocale() => LocaleController.instance.resolve(
        WidgetsBinding.instance.platformDispatcher.locales,
      );

  bool _started = false;

  /// Who is signed in; null once signed out. Only part of [_sent] — the
  /// server reads the account from the bearer token, never from us.
  String? _account;

  /// The last token this launch saw, so a sign-out can name it to the server
  /// without waiting on Firebase.
  String? _token;

  /// `account|token|language` the server last accepted. Every child switch
  /// and session reload calls [signIn]; this keeps that to one request per
  /// launch unless something actually changed. Not persisted on purpose: the
  /// request on each launch is what keeps `last_seen_at` fresh.
  String? _sent;

  /// Registrations run one at a time, so a sign-out never races one that is
  /// still on its way.
  Future<void> _queue = Future.value();

  @override
  Future<void> init() async {
    if (_started) return;
    _started = true;

    // Nothing in here may stop the app from starting: a device without Play
    // services, or a broken Firebase config, just goes without notifications.
    try {
      messaging.onTokenRefresh.listen((_) => _enqueue());
      messaging.onForegroundMessage.listen(_onForeground);
      messaging.onOpened.listen((message) => _route(message.data));

      await notifier.init(channelName: _channelName(), onTap: _route);

      // A tap that cold-started the app. The router holds it until the shell
      // is built.
      final initial = await messaging.initialMessage();
      if (initial != null) _route(initial.data);

      _localeChanges.addListener(_onLocaleChanged);
    } catch (e) {
      debugPrint('[push] init failed — no notifications this launch: $e');
    }
  }

  @override
  Future<void> signIn(
    AuthUser user, {
    ChildAccount? activeChild,
    bool promptPermission = false,
  }) async {
    _account = user.pushExternalId ?? '${user.role}:${user.id}';

    // `permissionUndecided` covers the parent who never signed in on this
    // build: an update installs over a session that is simply restored, and
    // on Android 13+ a device nobody ever asked shows nothing at all. Once
    // the choice is made either way it answers false, so this asks at most
    // once; a parent who said no turns it on in the system settings.
    try {
      if (promptPermission || await messaging.permissionUndecided()) {
        await messaging.requestPermission();
      }
    } catch (e) {
      debugPrint('[push] permission request failed: $e');
    }

    // Registered even without permission: the system drops what it may not
    // show, and the row is already there the day the parent says yes.
    await _enqueue();
  }

  @override
  Future<void> signOut() async {
    _account = null;
    _sent = null;

    try {
      await _queue.timeout(signOutTimeout);
    } catch (_) {
      // A registration still hanging; the deleted token below makes it moot.
    }

    final token = _token;
    _token = null;
    if (token != null) {
      await api
          .unregister(token)
          .timeout(signOutTimeout, onTimeout: () => false);
    }
    // On a shared family phone the next account must not inherit this one's
    // messages, even if the server never heard about the sign-out.
    await messaging.deleteToken();
  }

  Future<void> _enqueue() => _queue = _queue.then((_) => _register());

  Future<void> _register() async {
    try {
      final account = _account;
      if (account == null) return;

      final token = await messaging.getToken();
      if (token == null) return;
      _token = token;

      final locale = _locale().languageCode;
      final key = '$account|$token|$locale';
      if (key == _sent) return;

      final ok = await api.register(
        token: token,
        platform: appInfo.platform,
        locale: locale,
        appVersion: await appInfo.version,
      );
      // Signed out while the request was out: leave nothing marked as sent.
      if (ok && _account == account) _sent = key;
    } catch (e) {
      debugPrint('[push] registration failed: $e');
    }
  }

  /// A language picked in the app changes what the server writes in, and
  /// what Android calls the channel.
  void _onLocaleChanged() {
    unawaited(notifier.renameChannel(_channelName()).catchError((Object e) {
      debugPrint('[push] channel rename failed: $e');
    }));
    unawaited(_enqueue());
  }

  String _channelName() => lookupAppL10n(_locale()).navNotifications;

  void _onForeground(PushMessage message) {
    // The feed is asked for again even for a kind kept silent below: the
    // message is on the server either way (a homework entry, a school
    // announcement), and the open tab should list it.
    _feed.pushReceived();

    // A kind the parent switched off must stay silent. The backend does not
    // know the switches — they live on this device — so this is where they
    // are honoured; the system shows background messages without asking us.
    final kind = _kindOf(message.data);
    if (kind != null && !_isEnabled(kind)) return;
    if (message.title == null && message.body == null) return;

    unawaited(notifier.show(message).catchError((Object e) {
      debugPrint('[push] could not show a foreground message: $e');
    }));
  }

  void _route(Map<String, dynamic> data) {
    PushRouter.instance.request(PushRouter.parse(data));
    // A tapped announcement lands on the notifications tab (its `type` is not
    // a tab); the tab refetches and opens that very entry.
    _feed.pushReceived(openPushId: adminPushId(data));
  }

  /// The id of an admin push — `{"type": "admin_push", "notification_id": "21"}`
  /// (backend `PushChannel`); null for every other message. FCM delivers
  /// every `data` value as a string.
  @visibleForTesting
  static int? adminPushId(Map<String, dynamic> data) {
    final type = (data['type'] ?? '').toString().trim().toLowerCase();
    if (type != 'admin_push') return null;
    return int.tryParse((data['notification_id'] ?? '').toString().trim());
  }

  NotificationKind? _kindOf(Map<String, dynamic> data) {
    final raw = (data['kind'] ?? data['type'] ?? '')
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
