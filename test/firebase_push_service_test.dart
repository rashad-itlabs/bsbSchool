import 'dart:async';

import 'package:bsbschool/core/push/firebase_push_service.dart';
import 'package:bsbschool/core/push/foreground_notifier.dart';
import 'package:bsbschool/core/push/push_messaging.dart';
import 'package:bsbschool/core/push/push_router.dart';
import 'package:bsbschool/core/push/push_token_api.dart';
import 'package:bsbschool/core/utils/app_info.dart';
import 'package:bsbschool/features/auth/domain/entities/auth_user.dart';
import 'package:bsbschool/features/notifications/presentation/notification_prefs.dart';
import 'package:bsbschool/features/notifications/presentation/notifications_feed_signal.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Firebase Messaging as the service sees it, with the platform taken out.
class _FakeMessaging implements PushMessaging {
  String? token = 'tok-1';
  bool undecided = false;
  int permissionRequests = 0;
  int deletes = 0;
  PushMessage? initial;

  final refresh = StreamController<String>.broadcast();
  final foreground = StreamController<PushMessage>.broadcast();
  final opened = StreamController<PushMessage>.broadcast();

  @override
  Future<bool> permissionUndecided() async => undecided;

  @override
  Future<void> requestPermission() async {
    permissionRequests++;
    undecided = false;
  }

  @override
  Future<String?> getToken() async => token;

  @override
  Future<void> deleteToken() async {
    deletes++;
    token = null;
  }

  @override
  Stream<String> get onTokenRefresh => refresh.stream;

  @override
  Stream<PushMessage> get onForegroundMessage => foreground.stream;

  @override
  Stream<PushMessage> get onOpened => opened.stream;

  @override
  Future<PushMessage?> initialMessage() async => initial;
}

/// The backend's `/pushToken`.
class _FakeApi implements PushTokenApi {
  bool accept = true;
  final List<Map<String, Object?>> registered = [];
  final List<String> unregistered = [];

  @override
  Future<bool> register({
    required String token,
    required String platform,
    required String locale,
    String? appVersion,
    List<String> muted = const [],
  }) async {
    registered.add({
      'token': token,
      'platform': platform,
      'locale': locale,
      'app_version': appVersion,
      'muted': muted,
    });
    return accept;
  }

  @override
  Future<bool> unregister(String token) async {
    unregistered.add(token);
    return accept;
  }
}

class _FakeNotifier implements ForegroundNotifier {
  String? channelName;
  void Function(Map<String, dynamic> data)? onTap;
  final List<PushMessage> shown = [];

  @override
  Future<void> init({
    required String channelName,
    required void Function(Map<String, dynamic> data) onTap,
  }) async {
    this.channelName = channelName;
    this.onTap = onTap;
  }

  @override
  Future<void> renameChannel(String name) async => channelName = name;

  @override
  Future<void> show(PushMessage message) async => shown.add(message);
}

class _FakeAppInfo implements AppInfo {
  @override
  Future<String> get version async => '2.0.11';

  @override
  String get platform => 'android';
}

const _parent = AuthUser(
  id: 2570,
  accountId: 66,
  pushId: '66',
  name: 'Ceyhun Alizade',
  childName: 'Fakhraddin Alizade',
  role: 'parent',
  email: 'Ceyhun@BSB.edu.az',
);

/// Lets the stream listeners and the registration queue run.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeMessaging messaging;
  late _FakeApi api;
  late _FakeNotifier notifier;
  late ValueNotifier<Locale> locale;
  late ValueNotifier<Set<NotificationKind>> switchedOff;
  late FirebasePushService push;

  setUp(() async {
    messaging = _FakeMessaging();
    api = _FakeApi();
    notifier = _FakeNotifier();
    locale = ValueNotifier(const Locale('az'));
    switchedOff = ValueNotifier({});
    push = FirebasePushService(
      messaging: messaging,
      api: api,
      notifier: notifier,
      appInfo: _FakeAppInfo(),
      locale: () => locale.value,
      localeChanges: locale,
      isEnabled: (kind) => !switchedOff.value.contains(kind),
      prefsChanges: switchedOff,
    );
    PushRouter.instance.take();
    NotificationsFeedSignal.instance.takeOpenPushId();
    await push.init();
  });

  group('registration', () {
    test('a sign-in registers the token with the app language', () async {
      await push.signIn(_parent);

      expect(api.registered, [
        {
          'token': 'tok-1',
          'platform': 'android',
          'locale': 'az',
          'app_version': '2.0.11',
          'muted': <String>[],
        },
      ]);
    });

    test('a child switch or session reload sends nothing new', () async {
      await push.signIn(_parent);
      await push.signIn(_parent);
      await push.signIn(_parent);

      expect(api.registered, hasLength(1));
    });

    test('a language picked in the app re-registers and renames the channel',
        () async {
      await push.signIn(_parent);
      expect(notifier.channelName, 'Bildirişlər');

      locale.value = const Locale('ru');
      await _settle();
      await _settle();

      expect(api.registered.map((r) => r['locale']), ['az', 'ru']);
      expect(notifier.channelName, 'Уведомления');
    });

    test('a refreshed token is registered', () async {
      await push.signIn(_parent);

      messaging.token = 'tok-2';
      messaging.refresh.add('tok-2');
      await _settle();
      await _settle();

      expect(api.registered.map((r) => r['token']), ['tok-1', 'tok-2']);
    });

    test('a registration the server refused is tried again', () async {
      api.accept = false;
      await push.signIn(_parent);
      api.accept = true;
      await push.signIn(_parent);
      await push.signIn(_parent);

      expect(api.registered, hasLength(2));
    });

    test('no token yet — nothing is sent, nothing breaks', () async {
      messaging.token = null;
      await push.signIn(_parent);

      expect(api.registered, isEmpty);
    });

    test('a language change before any sign-in registers nothing', () async {
      locale.value = const Locale('en');
      await _settle();
      await _settle();

      expect(api.registered, isEmpty);
    });
  });

  group('switches', () {
    test('the kinds switched off go with the token', () async {
      switchedOff.value = {NotificationKind.homework, NotificationKind.exam};
      await push.signIn(_parent);

      // The enum's order, not the order they were flipped in.
      expect(api.registered.single['muted'], ['exam', 'homework']);
    });

    test('a flipped switch reaches the server at once', () async {
      await push.signIn(_parent);

      switchedOff.value = {NotificationKind.attendance};
      await _settle();
      await _settle();
      switchedOff.value = {};
      await _settle();
      await _settle();

      expect(api.registered.map((r) => r['muted']), [
        <String>[],
        ['attendance'],
        <String>[],
      ]);
    });

    test('flips that cancel out before the request leaves send nothing',
        () async {
      await push.signIn(_parent);

      switchedOff.value = {NotificationKind.cafeteria};
      switchedOff.value = {};
      await _settle();
      await _settle();

      expect(api.registered, hasLength(1));
    });

    test('one the server refused is sent again on the next sign-in',
        () async {
      await push.signIn(_parent);

      api.accept = false;
      switchedOff.value = {NotificationKind.homework};
      await _settle();
      await _settle();
      api.accept = true;
      await push.signIn(_parent);

      expect(api.registered.map((r) => r['muted']), [
        <String>[],
        ['homework'],
        ['homework'],
      ]);
    });

    test('a switch flipped while signed out sends nothing', () async {
      switchedOff.value = {NotificationKind.exam};
      await _settle();
      await _settle();

      expect(api.registered, isEmpty);
    });
  });

  group('permission', () {
    test('a fresh sign-in asks', () async {
      await push.signIn(_parent, promptPermission: true);
      expect(messaging.permissionRequests, 1);
    });

    test('a restored session asks only a device nobody asked yet', () async {
      await push.signIn(_parent);
      expect(messaging.permissionRequests, 0);

      messaging.undecided = true;
      await push.signIn(_parent);
      expect(messaging.permissionRequests, 1);
    });
  });

  group('sign-out', () {
    test('forgets the token on the server and on the device', () async {
      await push.signIn(_parent);
      await push.signOut();

      expect(api.unregistered, ['tok-1']);
      expect(messaging.deletes, 1);
    });

    test('a token refreshed after sign-out is not registered', () async {
      await push.signIn(_parent);
      await push.signOut();

      messaging.token = 'tok-2';
      messaging.refresh.add('tok-2');
      await _settle();
      await _settle();

      expect(api.registered.map((r) => r['token']), ['tok-1']);
    });

    test('the next account on the device registers afresh', () async {
      await push.signIn(_parent);
      await push.signOut();

      messaging.token = 'tok-2';
      await push.signIn(_parent);

      expect(api.registered.map((r) => r['token']), ['tok-1', 'tok-2']);
    });
  });

  group('messages', () {
    test('one that arrives in the foreground is shown', () async {
      messaging.foreground.add(const PushMessage(
        title: 'Yeni ev tapşırığı',
        body: 'Riyaziyyat',
        data: {'kind': 'homework', 'type': 'dashboard'},
      ));
      await _settle();

      expect(notifier.shown.single.title, 'Yeni ev tapşırığı');
    });

    test('a kind the parent switched off stays silent', () async {
      switchedOff.value = {NotificationKind.homework};
      messaging.foreground.add(const PushMessage(
        title: 'Yeni ev tapşırığı',
        data: {'kind': 'homework'},
      ));
      await _settle();

      expect(notifier.shown, isEmpty);
    });

    test('a tap in the background picks the tab', () async {
      messaging.opened.add(const PushMessage(data: {'type': 'tuition'}));
      await _settle();

      expect(PushRouter.instance.take(), PushTarget.tuition);
    });

    test('a tap on a foreground notification picks the tab', () async {
      notifier.onTap!({'type': 'cafeteria'});

      expect(PushRouter.instance.take(), PushTarget.foodCard);
    });

    test('the tap that started the app is held for the shell', () async {
      final cold = _FakeMessaging()
        ..initial = const PushMessage(data: {'type': 'profile'});
      await FirebasePushService(
        messaging: cold,
        api: api,
        notifier: _FakeNotifier(),
        appInfo: _FakeAppInfo(),
        locale: () => const Locale('az'),
        localeChanges: ValueNotifier(const Locale('az')),
      ).init();

      expect(PushRouter.instance.take(), PushTarget.profile);
    });
  });

  group('the notifications feed', () {
    late int pings;
    void count() => pings++;

    setUp(() {
      pings = 0;
      NotificationsFeedSignal.instance.addListener(count);
    });
    tearDown(() => NotificationsFeedSignal.instance.removeListener(count));

    test('a message in the foreground asks for the feed again', () async {
      messaging.foreground.add(const PushMessage(
        title: 'Valideyn iclası',
        body: 'Cümə, 18:00',
        data: {'type': 'admin_push', 'notification_id': '21'},
      ));
      await _settle();

      expect(pings, 1);
      // Arriving is not opening: only a tap opens the entry.
      expect(NotificationsFeedSignal.instance.hasPendingOpen, isFalse);
    });

    test('so does a kind the parent keeps silent', () async {
      switchedOff.value = {NotificationKind.homework};
      messaging.foreground
          .add(const PushMessage(title: 'Ev', data: {'kind': 'homework'}));
      await _settle();

      expect(notifier.shown, isEmpty);
      expect(pings, 1);
    });

    test('a tapped school announcement lands on the tab and is opened',
        () async {
      messaging.opened.add(const PushMessage(
          data: {'type': 'admin_push', 'notification_id': '21'}));
      await _settle();

      expect(PushRouter.instance.take(), PushTarget.notifications);
      expect(pings, 1);
      expect(NotificationsFeedSignal.instance.takeOpenPushId(), 21);
    });

    test('a tapped foreground announcement is opened too', () async {
      notifier.onTap!({'type': 'admin_push', 'notification_id': '27'});

      expect(NotificationsFeedSignal.instance.takeOpenPushId(), 27);
    });

    test('any other tap refreshes but opens nothing', () async {
      messaging.opened.add(const PushMessage(data: {'type': 'tuition'}));
      await _settle();

      expect(pings, 1);
      expect(NotificationsFeedSignal.instance.hasPendingOpen, isFalse);
    });

    test('the announcement that started the app waits for the tab', () async {
      final cold = _FakeMessaging()
        ..initial = const PushMessage(
            data: {'type': 'admin_push', 'notification_id': '12'});
      await FirebasePushService(
        messaging: cold,
        api: api,
        notifier: _FakeNotifier(),
        appInfo: _FakeAppInfo(),
        locale: () => const Locale('az'),
        localeChanges: ValueNotifier(const Locale('az')),
      ).init();

      expect(NotificationsFeedSignal.instance.takeOpenPushId(), 12);
    });

    test('the id is read only from an admin push', () {
      expect(
          FirebasePushService.adminPushId(
              {'type': ' Admin_Push ', 'notification_id': ' 5 '}),
          5);
      expect(FirebasePushService.adminPushId({'type': 'admin_push'}), isNull);
      expect(
          FirebasePushService.adminPushId(
              {'type': 'admin_push', 'notification_id': 'x'}),
          isNull);
      expect(
          FirebasePushService.adminPushId(
              {'type': 'homework', 'notification_id': '5'}),
          isNull);
    });
  });
}
