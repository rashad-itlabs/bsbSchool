import 'dart:convert';

import 'package:bsbschool/core/error/exceptions.dart';
import 'package:bsbschool/core/network/network_info.dart';
import 'package:bsbschool/core/storage/selected_child_storage.dart';
import 'package:bsbschool/core/storage/token_storage.dart';
import 'package:bsbschool/core/storage/user_storage.dart';
import 'package:bsbschool/features/auth/data/models/auth_session_model.dart';
import 'package:bsbschool/features/auth/data/models/auth_user_model.dart';
import 'package:bsbschool/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bsbschool/features/auth/data/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The two students of the parent account, `info` verbatim from the API.
const _parentBody = '''
{
  "name": "Ceyhun Alizade",
  "child_name": "Fakhraddin Alizade",
  "role": "parent",
  "user_id": 2570,
  "class_id": 97,
  "class_name": "Class Group 10",
  "token": "73|abc",
  "info": [
    {
      "child_id": 3139,
      "class_id": 94,
      "class_name": "Class Group 7",
      "child_name": "Rashad",
      "child_surname": "Ali",
      "email": "std_3139@bsb.edu.az",
      "password": "7QXVi9ir",
      "payment_id": "RA3139"
    },
    {
      "child_id": 2570,
      "class_id": 97,
      "class_name": "Class Group 10",
      "child_name": "Fakhraddin",
      "child_surname": "Alizade",
      "email": "std_3140@bsb.edu.az",
      "password": "UXns5B6a",
      "payment_id": "FA2570"
    }
  ]
}
''';

class _FakeUserStorage implements UserStorage {
  AuthUserModel? _user;

  _FakeUserStorage(this._user);

  @override
  AuthUserModel? get cachedUser => _user;

  @override
  Future<void> saveUser(AuthUserModel user) async => _user = user;

  @override
  Future<void> clear() async => _user = null;
}

class _FakeTokenStorage implements TokenStorage {
  String? _token = '73|abc';

  @override
  String? get cachedToken => _token;

  @override
  bool get hasToken => _token != null;

  @override
  Future<void> saveToken(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}

class _FakeAuthService implements AuthService {
  /// Every `/selectChild` call the repository made, in order.
  final List<int> selectCalls = [];

  /// Thrown instead of answering, to stand in for a rejected switch.
  final Exception? selectChildError;

  /// What `/selectChild` echoes back — null models an endpoint that only
  /// reports success.
  final AuthUserModel? selectChildResponse;

  /// Every `/attachChild` call the repository made, by admission number.
  final List<String> attachCalls = [];

  /// What `/attachChild` echoes back — null models an endpoint that only
  /// reports success.
  final AuthUserModel? attachChildResponse;

  /// Thrown instead of answering, to stand in for a rejected admission code.
  Exception? attachError;

  _FakeAuthService({
    this.selectChildError,
    this.selectChildResponse,
    this.attachChildResponse,
  });

  @override
  Future<AuthSessionModel> login({
    required String email,
    required String password,
    required String deviceName,
  }) async =>
      AuthSessionModel.fromJson(jsonDecode(_parentBody) as Map<String, dynamic>);

  @override
  Future<void> logout() async {}

  @override
  Future<AuthUserModel?> selectChild(int childId) async {
    selectCalls.add(childId);
    if (selectChildError != null) throw selectChildError!;
    return selectChildResponse;
  }

  @override
  Future<AuthUserModel?> attachChild({
    required String admissionNo,
    String? relation,
  }) async {
    attachCalls.add(admissionNo);
    if (attachError != null) throw attachError!;
    return attachChildResponse;
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> registerParent({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String admissionNo,
    String? relation,
  }) async {}

  @override
  Future<void> verifyOtp({
    required String email,
    required String otp,
  }) async {}

  @override
  Future<void> resendOtp({
    required String email,
  }) async {}
}

class _OfflineNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;
}

void main() {
  late AuthRepositoryImpl repository;
  late SelectedChildStorage childStorage;
  late _FakeUserStorage userStorage;
  late _FakeAuthService service;

  final parent = AuthUserModel.fromJson(
    jsonDecode(_parentBody) as Map<String, dynamic>,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> build({
    AuthUserModel? cached,
    Exception? selectChildError,
    AuthUserModel? selectChildResponse,
    AuthUserModel? attachChildResponse,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    childStorage = SelectedChildStorageImpl(prefs);
    userStorage = _FakeUserStorage(cached ?? parent);
    service = _FakeAuthService(
      selectChildError: selectChildError,
      selectChildResponse: selectChildResponse,
      attachChildResponse: attachChildResponse,
    );
    repository = AuthRepositoryImpl(
      service: service,
      tokenStorage: _FakeTokenStorage(),
      userStorage: userStorage,
      selectedChildStorage: childStorage,
      networkInfo: _OfflineNetworkInfo(),
    );
  }

  group('the active student', () {
    // Nothing picked yet: the app must agree with what the API would return on
    // its own, i.e. the student the token belongs to (`user_id`).
    test('defaults to the student the token belongs to', () async {
      await build();

      expect(repository.activeChild?.childId, 2570);
      expect(repository.activeStudentId, 2570);
      expect(repository.activeClassId, 97);
    });

    test('follows the parent\'s pick', () async {
      await build();

      await repository.selectChild(3139);

      expect(repository.activeChild?.fullName, 'Rashad Ali');
      expect(repository.activeStudentId, 3139);
      // The homework / timetable / library endpoints key off this one.
      expect(repository.activeClassId, 94);
    });

    test('survives a restart', () async {
      await build();
      await repository.selectChild(3139);

      // A fresh storage over the same prefs — what the next launch sees.
      final prefs = await SharedPreferences.getInstance();
      expect(SelectedChildStorageImpl(prefs).selectedChildId, 3139);
    });

    // A pick that isn't on the account would scope every request to a student
    // this parent has no claim to — and must not even reach the endpoint.
    test('ignores an id that belongs to no student on the account', () async {
      await build();

      final result = await repository.selectChild(9999);

      expect(result.isLeft(), isTrue);
      expect(service.selectCalls, isEmpty);
      expect(repository.activeStudentId, 2570);
    });

    test('is null when the login carried no `info`', () async {
      await build(
        cached: const AuthUserModel(
          id: 4108,
          name: 'Elena Borisovna',
          childName: '',
          role: 'teacher',
          email: 'teacher@bsb.edu.az',
        ),
      );

      expect(repository.activeChild, isNull);
      // Still scoped by the account itself, so a teacher/student login keeps
      // sending the same `student_id` it always did.
      expect(repository.activeStudentId, 4108);
    });

    test('is dropped on logout', () async {
      await build();
      await repository.selectChild(3139);

      await repository.logout();

      expect(childStorage.selectedChildId, isNull);
    });

    // Another parent signing in on the same device must not inherit the pick.
    test('is dropped when a different account logs in', () async {
      await build();
      await repository.selectChild(3139);

      await repository.login(email: 'x@y.z', password: 'secret');

      expect(childStorage.selectedChildId, isNull);
      expect(repository.activeStudentId, 2570);
    });
  });

  group('POST /selectChild', () {
    test('is told which student to move `users.user_id` to', () async {
      await build();

      await repository.selectChild(3139);

      expect(service.selectCalls, [3139]);
    });

    // The backend owns the selection now: if it refuses, the app must stay on
    // the student every endpoint still answers for.
    test('a rejected switch leaves the local pick untouched', () async {
      await build(
        selectChildError: const ValidationException('Şagird tapılmadı'),
      );

      final result = await repository.selectChild(3139);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.message, 'Şagird tapılmadı'),
        (_) => fail('the switch should not have succeeded'),
      );
      expect(childStorage.selectedChildId, isNull);
      expect(repository.activeStudentId, 2570);
    });

    test('an unreachable backend leaves the local pick untouched', () async {
      await build(selectChildError: const ServerException('Serverə qoşulmadı'));

      await repository.selectChild(3139);

      expect(childStorage.selectedChildId, isNull);
      expect(repository.activeStudentId, 2570);
    });

    test('caches the refreshed user the endpoint echoes back', () async {
      await build(
        selectChildResponse: AuthUserModel.fromJson({
          'user_id': 3139,
          'class_id': 94,
          'class_name': 'Class Group 7',
          'child_name': 'Rashad Ali',
        }),
      );

      await repository.selectChild(3139);

      expect(repository.currentUser?.id, 3139);
      expect(repository.currentUser?.classId, 94);
      expect(repository.currentUser?.childName, 'Rashad Ali');
    });

    // A trimmed response must not cost the session its role (the cache is
    // discarded without one — the account would land back on the login screen)
    // or its `info` (the switcher would vanish after one use).
    test('keeps role, name and `info` the response left out', () async {
      await build(
        selectChildResponse: AuthUserModel.fromJson({
          'user_id': 3139,
          'class_id': 94,
        }),
      );

      await repository.selectChild(3139);

      expect(repository.currentUser?.role, 'parent');
      expect(repository.currentUser?.name, 'Ceyhun Alizade');
      expect(repository.currentUser?.children, hasLength(2));
    });

    // An endpoint that answers `{"success": true}` still switched the student.
    test('a bodyless success still stores the pick', () async {
      await build();

      await repository.selectChild(3139);

      expect(childStorage.selectedChildId, 3139);
      expect(repository.activeStudentId, 3139);
    });
  });

  group('POST /attachChild', () {
    /// The roster the endpoint answers with once a third student is linked —
    /// the two the account already had plus the new one.
    AuthUserModel rosterOfThree() => AuthUserModel.fromJson({
          'info': [
            ...(jsonDecode(_parentBody) as Map<String, dynamic>)['info'] as List,
            {
              'child_id': 4021,
              'class_id': 91,
              'class_name': 'Class Group 4',
              'child_name': 'Nigar',
              'child_surname': 'Alizade',
              'email': 'std_4021@bsb.edu.az',
              'password': 'Kd83nQpz',
              'payment_id': 'NA4021',
            },
          ],
        });

    test('is told which admission number to link', () async {
      await build();

      await repository.attachChild(admissionNo: 'BSB-4021');

      expect(service.attachCalls, ['BSB-4021']);
    });

    // The bug this guards: a response carrying only the refreshed roster — no
    // `user_id`, no name, no role — used to leave the cache untouched, so the
    // new student stayed invisible until the next login.
    test('a roster-only response still lands the new student', () async {
      await build(attachChildResponse: rosterOfThree());

      await repository.attachChild(admissionNo: 'BSB-4021');

      expect(repository.currentUser?.children, hasLength(3));
      expect(
        repository.currentUser?.children.last.childId,
        4021,
      );
      // Everything the trimmed response left out survives, same as
      // `/selectChild`.
      expect(repository.currentUser?.role, 'parent');
      expect(repository.currentUser?.name, 'Ceyhun Alizade');
    });

    // Linking a student is not switching to one: the parent keeps looking at
    // whoever was on screen.
    test('leaves the active student where it was', () async {
      await build(attachChildResponse: rosterOfThree());
      await repository.selectChild(3139);

      await repository.attachChild(admissionNo: 'BSB-4021');

      expect(childStorage.selectedChildId, 3139);
      expect(repository.activeChild?.childId, 3139);
    });

    // An account the school had linked nothing to: `user_id` is null, which is
    // what sends the parent to AddChildScreen. Once they add a student the app
    // has to stop asking, even when the response carried no `user_id` of its
    // own.
    test('an account with no student adopts the one it just linked', () async {
      final unlinked = AuthUserModel.fromJson({
        'name': 'Ceyhun Alizade',
        'role': 'parent',
        'user_id': null,
      });
      await build(cached: unlinked, attachChildResponse: rosterOfThree());

      expect(unlinked.needsChild, isTrue);

      await repository.attachChild(admissionNo: 'BSB-4021');

      expect(repository.currentUser?.id, isNotNull);
      expect(repository.currentUser?.needsChild, isFalse);
    });

    // Nothing to fold in — the student is linked on the server and the next
    // login picks them up, but the cache must not be emptied in the meantime.
    test('an acknowledgement leaves the cached roster intact', () async {
      await build();

      final result = await repository.attachChild(admissionNo: 'BSB-4021');

      expect(result.isRight(), isTrue);
      expect(repository.currentUser?.children, hasLength(2));
    });

    test('a rejected code fails without touching the cache', () async {
      await build();
      service.attachError = ValidationException('Bu şagird artıq bağlıdır.');

      final result = await repository.attachChild(admissionNo: 'BSB-4021');

      expect(result.isLeft(), isTrue);
      expect(repository.currentUser?.children, hasLength(2));
    });
  });
}
