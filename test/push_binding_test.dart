import 'package:bsbschool/core/l10n/locale_controller.dart';
import 'package:bsbschool/core/push/onesignal_push_service.dart';
import 'package:bsbschool/features/auth/domain/entities/auth_user.dart';
import 'package:bsbschool/features/notifications/presentation/notification_prefs.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stands in for the native SDK, so the binding can be driven through the same
/// method channels `onesignal_flutter` talks over.
///
/// [swallowLogins] is the registration bug in miniature: on a device that has
/// just been installed the first `login` reaches a user with no push
/// subscription behind it and is dropped, leaving `getExternalId` empty.
class _FakeOneSignal {
  _FakeOneSignal({this.swallowLogins = 0});

  /// How many `login` calls are accepted and then forgotten.
  final int swallowLogins;

  String? externalId;
  final List<String> logins = [];
  final List<Map<String, dynamic>> tags = [];
  final List<String> languages = [];
  int permissionRequests = 0;
  bool canRequest = false;

  static const _core = MethodChannel('OneSignal');
  static const _user = MethodChannel('OneSignal#user');
  static const _notifications = MethodChannel('OneSignal#notifications');

  /// Only answered so `init()` can run; nothing on them is asserted.
  static const _quiet = [
    MethodChannel('OneSignal#debug'),
    MethodChannel('OneSignal#inappmessages'),
    MethodChannel('OneSignal#pushsubscription'),
  ];

  void install() {
    for (final channel in _quiet) {
      _handle(channel, (call) async => null);
    }

    _handle(_core, (call) async {
      switch (call.method) {
        case 'OneSignal#login':
          final id = (call.arguments as Map)['externalId'] as String;
          logins.add(id);
          if (logins.length > swallowLogins) externalId = id;
          return null;
        case 'OneSignal#logout':
          externalId = null;
          return null;
      }
      return null;
    });

    _handle(_user, (call) async {
      switch (call.method) {
        case 'OneSignal#getExternalId':
          return externalId;
        case 'OneSignal#addTags':
          tags.add(Map<String, dynamic>.from(call.arguments as Map));
          return null;
        case 'OneSignal#setLanguage':
          languages.add((call.arguments as Map)['language'] as String);
          return null;
      }
      return null;
    });

    _handle(_notifications, (call) async {
      switch (call.method) {
        case 'OneSignal#canRequest':
          return canRequest;
        case 'OneSignal#permission':
          return false;
        case 'OneSignal#requestPermission':
          permissionRequests++;
          return true;
      }
      return null;
    });
  }

  void remove() {
    for (final channel in [_core, _user, _notifications, ..._quiet]) {
      _handle(channel, null);
    }
  }

  void _handle(MethodChannel channel, Future<Object?> Function(MethodCall)? h) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, h);
  }
}

const _parent = AuthUser(
  id: 2570,
  accountId: 66,
  pushId: '66',
  name: 'Ceyhun Alizade',
  childName: 'Fakhraddin Alizade',
  role: 'parent',
  email: 'ceyhun@bsb.edu.az',
  classId: 96,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeOneSignal sdk;

  OneSignalPushService serviceFor(_FakeOneSignal fake) {
    sdk = fake..install();
    return OneSignalPushService(bindRetryDelay: Duration.zero);
  }

  tearDown(() => sdk.remove());

  test('a sign-in binds the account and sends only the language', () async {
    final service = serviceFor(_FakeOneSignal());

    await service.signIn(_parent);

    expect(sdk.externalId, '66');
    expect(sdk.logins, ['66']);
    expect(sdk.languages, ['en'], reason: 'the test device speaks en_US');
    // 10.10.2026: nine tags rode in the same SDK request as the language;
    // OneSignal's free plan keeps six per user, refused it, and the language
    // was lost with them.
    expect(sdk.tags, isEmpty);
  });

  test('a login the SDK swallows is retried until the id sticks', () async {
    // What a registration hits: the app is minutes old, the identity lands on
    // a user that has no push subscription yet, and the first call vanishes.
    final service = serviceFor(_FakeOneSignal(swallowLogins: 1));

    await service.signIn(_parent, promptPermission: true);

    expect(sdk.externalId, '66',
        reason: 'the parent must not be left anonymous after registering');
    expect(sdk.logins, ['66', '66']);
  });

  test('it gives up rather than looping forever', () async {
    final service = serviceFor(_FakeOneSignal(swallowLogins: 99));

    await service.signIn(_parent);

    expect(sdk.externalId, isNull);
    expect(sdk.logins.length, OneSignalPushService.bindAttempts);
  });

  test('an id already bound is left alone', () async {
    final service = serviceFor(_FakeOneSignal()..externalId = '66');

    await service.signIn(_parent);

    expect(sdk.logins, isEmpty, reason: 're-resolving the user costs a round trip');
    expect(sdk.languages, hasLength(1), reason: 'the language still refreshes');
  });

  test('granting permission re-asserts the identity', () async {
    // The subscription is created by the answer to the dialog, so the binding
    // that ran before it has to be checked again afterwards.
    final fake = _FakeOneSignal()..canRequest = true;
    final service = serviceFor(fake);

    await service.signIn(_parent);

    expect(sdk.permissionRequests, 1);
    expect(sdk.externalId, '66');
  });

  test('a parent with no address is not bound to the previous account',
      () async {
    final service = serviceFor(_FakeOneSignal());
    await service.signIn(_parent);

    const stranger = AuthUser(
      name: 'Yeni Valideyn',
      childName: '',
      role: 'parent',
      email: 'yeni@bsb.edu.az',
    );
    await service.signIn(stranger);

    expect(stranger.pushExternalId, isNull);
    expect(sdk.logins, ['66'], reason: 'nothing new to bind, and no re-bind');
  });

  test('signing out releases the id', () async {
    final service = serviceFor(_FakeOneSignal());
    await service.signIn(_parent);

    await service.signOut();

    expect(sdk.externalId, isNull);
  });

  test('a child switch keeps the id and re-sends the language', () async {
    final service = serviceFor(_FakeOneSignal());
    await service.signIn(_parent);
    await service.signIn(_parent);

    expect(sdk.logins, ['66'], reason: 'the same account is bound once');
    expect(sdk.languages, hasLength(2));
  });

  test('a language picked in the app reaches OneSignal alone', () async {
    SharedPreferences.setMockInitialValues({});
    final service = serviceFor(_FakeOneSignal());
    await service.init();
    await service.signIn(_parent);

    await LocaleController.instance.setLocale(const Locale('ru'));
    // The switches sit on the same screen as the language: a flip must not
    // put a tag into the request the language goes out in.
    await NotificationPrefs.instance
        .setEnabled(NotificationKind.cafeteria, false);
    await pumpEventQueue();

    expect(sdk.languages.last, 'ru');
    expect(sdk.tags, isEmpty);

    // Both are singletons — hand the next test the defaults back.
    await NotificationPrefs.instance.setEnabled(NotificationKind.cafeteria, true);
    await LocaleController.instance.setLocale(null);
    await pumpEventQueue();
  });
}
