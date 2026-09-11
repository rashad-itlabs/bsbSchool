import 'dart:convert';

import 'package:bsbschool/core/push/push_router.dart';
import 'package:bsbschool/core/push/push_service.dart';
import 'package:bsbschool/core/error/failures.dart';
import 'package:bsbschool/features/auth/data/models/auth_user_model.dart';
import 'package:bsbschool/features/auth/domain/entities/auth_session.dart';
import 'package:bsbschool/features/auth/domain/entities/auth_user.dart';
import 'package:bsbschool/features/auth/domain/entities/child_account.dart';
import 'package:bsbschool/features/auth/domain/repositories/auth_repository.dart';
import 'package:bsbschool/features/auth/domain/usecases/login_user.dart';
import 'package:bsbschool/features/auth/domain/usecases/logout_user.dart';
import 'package:bsbschool/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records what the bloc asked of the push SDK, without one behind it.
class _SpyPushService implements PushService {
  final List<String?> signedIn = [];
  final List<int?> children = [];
  final List<bool> prompts = [];
  int signOuts = 0;

  @override
  Future<void> init() async {}

  @override
  Future<void> signIn(
    AuthUser user, {
    ChildAccount? activeChild,
    bool promptPermission = false,
  }) async {
    signedIn.add(user.pushExternalId);
    children.add(activeChild?.childId);
    prompts.add(promptPermission);
  }

  @override
  Future<void> signOut() async => signOuts++;
}

/// The bits of the repository [AuthBloc] reads. [user] is both the restored
/// session and what a login hands back.
class _FakeAuthRepository implements AuthRepository {
  AuthUser? user;
  int? selectedChildId;

  _FakeAuthRepository({this.user});

  @override
  bool get isLoggedIn => user != null;

  @override
  AuthUser? get currentUser => user;

  @override
  ChildAccount? get activeChild {
    final children = user?.children ?? const <ChildAccount>[];
    if (children.isEmpty) return null;
    for (final child in children) {
      if (child.childId == selectedChildId) return child;
    }
    return children.first;
  }

  @override
  int? get activeStudentId => activeChild?.childId ?? user?.id;

  @override
  int? get activeClassId => activeChild?.classId ?? user?.classId;

  @override
  Future<Either<Failure, AuthSession>> login({
    required String email,
    required String password,
  }) async {
    final signedIn = user;
    if (signedIn == null) return const Left(ValidationFailure('no user'));
    return Right(AuthSession(token: '1|abc', user: signedIn));
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    user = null;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> selectChild(int childId) async {
    selectedChildId = childId;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> attachChild({
    required String admissionNo,
    String? relation,
  }) async {
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> resetPassword({
    required String email,
    required String password,
  }) async =>
      const Right(unit);

  @override
  Future<Either<Failure, Unit>> registerParent({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String admissionNo,
    String? relation,
  }) async =>
      const Right(unit);

  @override
  Future<Either<Failure, Unit>> verifyOtp({
    required String email,
    required String otp,
  }) async =>
      const Right(unit);

  @override
  Future<Either<Failure, Unit>> resendOtp({required String email}) async =>
      const Right(unit);
}

/// The login response verbatim, trimmed to one student.
const _loginBody = '''
{
  "parent_ids": 66,
  "name": "Ceyhun Alizade",
  "child_name": "Fakhraddin Alizade",
  "role": "parent",
  "user_id": 2570,
  "class_id": 96,
  "class_name": "Class Group 9",
  "token": "124|4kfc9mhy7tRrMrDOwY0FEeGIeAzwcGBWlnL7xVid27e7323c",
  "info": [
    {
      "child_id": 2570,
      "class_id": 96,
      "class_name": "Class Group 9",
      "username": "user67",
      "child_name": "Fakhraddin",
      "child_surname": "Alizade",
      "email": "std_3140@bsb.edu.az",
      "password": "UXns5B6a",
      "payment_id": "FA2570"
    }
  ],
  "push_external_id": "66"
}
''';

const _children = [
  ChildAccount(childId: 3139, classId: 94, childName: 'Rashad'),
  ChildAccount(childId: 2570, classId: 97, childName: 'Fakhraddin'),
];

AuthUserModel _parent({int? accountId, int? userId = 2570, String? pushId}) =>
    AuthUserModel(
      id: userId,
      accountId: accountId,
      pushId: pushId,
      name: 'Ceyhun Alizade',
      childName: 'Fakhraddin Alizade',
      role: 'parent',
      email: 'Ceyhun@BSB.edu.az',
      classId: 97,
      children: _children,
    );

void main() {
  group('push external id', () {
    test('is whatever the backend called itself', () {
      expect(_parent(accountId: 66, pushId: '66').pushExternalId, '66');
    });

    test('follows the backend if it starts prefixing the role', () {
      expect(
        _parent(accountId: 66, pushId: 'parent_66').pushExternalId,
        'parent_66',
        reason: 'a server-side rename must not need an app release',
      );
    });

    test('is composed from `parent_ids` when the backend names no address', () {
      expect(_parent(accountId: 41).pushExternalId, 'parent_41');
    });

    test('falls back to `user_id` while the backend sends no `parent_id`', () {
      expect(_parent().pushExternalId, 'parent_2570');
    });

    test('a student and a teacher are addressed by their own row', () {
      const student = AuthUser(
        id: 3139,
        name: 'Rashad Ali',
        childName: 'Rashad Ali',
        role: 'student',
        email: 'std_3139@bsb.edu.az',
      );
      const teacher = AuthUser(
        id: 4108,
        name: 'Elena Borisovna',
        childName: '',
        role: 'teacher',
        email: 'teacher@bsb.edu.az',
      );

      expect(student.pushExternalId, 'student_3139');
      expect(teacher.pushExternalId, 'teacher_4108');
    });

    test('the role is part of the id, so two tables cannot collide', () {
      const student = AuthUser(
        id: 41,
        name: 'Someone',
        childName: 'Someone',
        role: 'student',
        email: 's@bsb.edu.az',
      );

      expect(_parent(accountId: 41).pushExternalId,
          isNot(student.pushExternalId));
    });

    test('a parent with no student linked has nothing stable to key on', () {
      expect(_parent(userId: null).pushExternalId, isNull);
    });

    test('the address survives the cache round trip', () {
      final cached = AuthUserModel.fromJson(
        _parent(accountId: 66, pushId: '66').toJson(),
      );

      expect(cached.accountId, 66);
      expect(cached.pushExternalId, '66');
    });

    test('reads the real login response', () {
      final user = AuthUserModel.fromJson(jsonDecode(_loginBody));

      expect(user.accountId, 66, reason: '`parent_ids`, plural on the wire');
      expect(user.id, 2570, reason: 'still the student every endpoint wants');
      expect(user.pushExternalId, '66');
    });

    test('a response without `push_external_id` still yields an address', () {
      final body = jsonDecode(_loginBody) as Map<String, dynamic>
        ..remove('push_external_id');

      expect(AuthUserModel.fromJson(body).pushExternalId, 'parent_66');
    });

    test('the backend\'s address and the composed one are the same string',
        () {
      // The invariant behind the `{role}_{id}` format the backend settled on:
      // if `push_external_id` ever goes missing from a response, the fallback
      // lands on the identical address instead of splitting the account into
      // a second OneSignal user. Losing this is how devices get orphaned.
      final withField = jsonDecode(_loginBody) as Map<String, dynamic>
        ..['push_external_id'] = 'parent_66';
      final withoutField = jsonDecode(_loginBody) as Map<String, dynamic>
        ..remove('push_external_id');

      expect(
        AuthUserModel.fromJson(withField).pushExternalId,
        AuthUserModel.fromJson(withoutField).pushExternalId,
      );
    });
  });

  group('AuthBloc binds the subscription', () {
    test('a restored session re-binds without prompting for permission',
        () async {
      final push = _SpyPushService();
      final repository =
          _FakeAuthRepository(user: _parent(accountId: 66, pushId: '66'));
      final bloc = AuthBloc(
        loginUser: LoginUser(repository),
        logoutUser: LogoutUser(repository),
        repository: repository,
        push: push,
      )..add(const AuthCheckRequested());

      await bloc.stream.first;

      expect(push.signedIn, ['66']);
      expect(push.prompts, [false]);
      await bloc.close();
    });

    test('a fresh sign-in is the one moment permission is asked for', () async {
      final push = _SpyPushService();
      final repository =
          _FakeAuthRepository(user: _parent(accountId: 66, pushId: '66'));
      final bloc = AuthBloc(
        loginUser: LoginUser(repository),
        logoutUser: LogoutUser(repository),
        repository: repository,
        push: push,
      );

      bloc.add(const AuthLoginRequested(email: 'a@b.c', password: 'x'));
      await bloc.stream
          .firstWhere((s) => s.status == AuthStatus.authenticated);
      // The bind is fired off, not awaited by the handler.
      await Future<void>.delayed(Duration.zero);

      expect(push.signedIn, ['66']);
      expect(push.prompts, [true]);
      await bloc.close();
    });

    test('switching child moves the tags but keeps the same external id',
        () async {
      final push = _SpyPushService();
      final repository =
          _FakeAuthRepository(user: _parent(accountId: 66, pushId: '66'));
      final bloc = AuthBloc(
        loginUser: LoginUser(repository),
        logoutUser: LogoutUser(repository),
        repository: repository,
        push: push,
      );

      bloc.add(const AuthChildSelected(2570));
      await bloc.stream.firstWhere((s) => !s.isSwitchingChild);
      await Future<void>.delayed(Duration.zero);

      expect(push.signedIn, ['66']);
      expect(push.children, [2570]);
      await bloc.close();
    });

    test('signing out releases the device for the next account', () async {
      final push = _SpyPushService();
      final repository =
          _FakeAuthRepository(user: _parent(accountId: 66, pushId: '66'));
      final bloc = AuthBloc(
        loginUser: LoginUser(repository),
        logoutUser: LogoutUser(repository),
        repository: repository,
        push: push,
      );

      bloc.add(const AuthLogoutRequested());
      await bloc.stream
          .firstWhere((s) => s.status == AuthStatus.unauthenticated);

      expect(push.signOuts, 1);
      await bloc.close();
    });
  });

  group('a tapped notification picks a tab', () {
    test('reads `type`, and `screen` as its alias', () {
      expect(PushRouter.parse({'type': 'tuition'}), PushTarget.tuition);
      expect(PushRouter.parse({'screen': 'cafeteria'}), PushTarget.foodCard);
      expect(PushRouter.parse({'type': 'dashboard'}), PushTarget.dashboard);
    });

    test('anything unknown lands on the feed that lists the message', () {
      expect(PushRouter.parse(null), PushTarget.notifications);
      expect(PushRouter.parse({}), PushTarget.notifications);
      expect(PushRouter.parse({'type': 'whatever'}), PushTarget.notifications);
    });

    test('one tap moves the app once', () {
      PushRouter.instance.request(PushTarget.tuition);
      expect(PushRouter.instance.hasPending, isTrue);
      expect(PushRouter.instance.take(), PushTarget.tuition);
      expect(PushRouter.instance.take(), isNull);
    });
  });
}
