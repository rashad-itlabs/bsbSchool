import 'package:bsbschool/core/push/onesignal_push_service.dart';
import 'package:bsbschool/features/auth/domain/entities/auth_user.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

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
  int permissionRequests = 0;
  bool canRequest = false;

  static const _core = MethodChannel('OneSignal');
  static const _user = MethodChannel('OneSignal#user');
  static const _notifications = MethodChannel('OneSignal#notifications');

  void install() {
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
      }
      return null;
    });

    _handle(_notifications, (call) async {
      switch (call.method) {
        case 'OneSignal#canRequest':
          return canRequest;
        case 'OneSignal#requestPermission':
          permissionRequests++;
          return true;
      }
      return null;
    });
  }

  void remove() {
    for (final channel in [_core, _user, _notifications]) {
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

  test('a sign-in binds the account and tags it', () async {
    final service = serviceFor(_FakeOneSignal());

    await service.signIn(_parent);

    expect(sdk.externalId, '66');
    expect(sdk.logins, ['66']);
    expect(sdk.tags.single['parent_id'], '66');
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
    expect(sdk.tags, hasLength(1), reason: 'the tags still refresh');
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

  test('a child switch keeps the id and moves the tags', () async {
    final service = serviceFor(_FakeOneSignal());
    await service.signIn(_parent);
    await service.signIn(_parent);

    expect(sdk.logins, ['66'], reason: 'the same account is bound once');
    expect(sdk.tags, hasLength(2));
  });
}
