import 'dart:convert';
import 'dart:typed_data';

import 'package:bsbschool/core/error/failures.dart';
import 'package:bsbschool/core/utils/az_phone.dart';
import 'package:bsbschool/core/network/network_info.dart';
import 'package:bsbschool/core/storage/selected_child_storage.dart';
import 'package:bsbschool/core/storage/token_storage.dart';
import 'package:bsbschool/core/storage/user_storage.dart';
import 'package:bsbschool/features/auth/data/models/auth_user_model.dart';
import 'package:bsbschool/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bsbschool/features/auth/data/services/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The signed-in parent, as the login response leaves it in the cache.
final _cachedUser = AuthUserModel.fromJson(
  jsonDecode('''
{
  "name": "Ceyhun Alizade",
  "child_name": "Rashad Ali",
  "role": "parent",
  "email": "ceyhun@bsb.edu.az",
  "phone": "0501234567",
  "user_id": 3139,
  "parent_ids": 66,
  "class_id": 94,
  "class_name": "Class Group 7",
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
      "email": "std_2570@bsb.edu.az",
      "password": "UXns5B6a",
      "payment_id": "FA2570"
    }
  ]
}
''') as Map<String, dynamic>,
);

/// Records what was asked, so the tests can pin the payload each endpoint is
/// actually handed. Same harness as `register_payload_test.dart`.
class _RecordingAdapter implements HttpClientAdapter {
  final String body;
  final int statusCode;

  RequestOptions? request;

  _RecordingAdapter({required this.body, this.statusCode = 200});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

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

class _OnlineNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;
}

/// The real service and repository over a stubbed transport: everything the
/// app does to a response is exercised, only the wire is fake.
(AuthRepositoryImpl, _RecordingAdapter, _FakeUserStorage) _repository({
  String body = '{"success": true, "message": "Məlumatlar yeniləndi"}',
  int statusCode = 200,
}) {
  final adapter = _RecordingAdapter(body: body, statusCode: statusCode);
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://online.bsb.edu.az/api/v1',
      validateStatus: (status) => status != null && status < 500,
    ),
  )..httpClientAdapter = adapter;

  final userStorage = _FakeUserStorage(_cachedUser);
  final repository = AuthRepositoryImpl(
    service: AuthServiceImpl(dio),
    tokenStorage: _FakeTokenStorage(),
    userStorage: userStorage,
    selectedChildStorage: SelectedChildStorageImpl(_prefs),
    networkInfo: _OnlineNetworkInfo(),
  );
  return (repository, adapter, userStorage);
}

late SharedPreferences _prefs;

Map<String, dynamic> _sent(_RecordingAdapter adapter) =>
    Map<String, dynamic>.from(adapter.request!.data as Map);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  group('what login leaves for the profile form', () {
    /// The live `/login` body, verbatim — the parent row now carries `phone`
    /// and `email`, and the profile form is seeded from exactly this.
    const loginBody = """
{
    "name": "Resad Alizade",
    "child_name": "Melek Chalabi",
    "role": "parent",
    "user_id": 3158,
    "email": "resad88aliyev@gmail.com",
    "phone": "+994556691248",
    "class_id": 95,
    "class_name": "Class Group 8",
    "token": "181|otx5nDL4PL5UWRCPaza1Yv8tkJYoHNdIkG6xPPnx23d4f6d6",
    "info": [
        {
            "child_id": 3158,
            "class_id": 95,
            "class_name": "Class Group 8",
            "username": "user88",
            "child_name": "Melek",
            "child_surname": "Chalabi",
            "email": "std_3158@bsb.edu.az",
            "password": "mwDAONaq",
            "payment_id": "MC3158"
        }
    ],
    "push_external_id": "parent_866"
}
""";

    test('the account details survive into the cache', () async {
      final (repository, _, storage) = _repository(body: loginBody);

      final result = await repository.login(
        email: 'resad88aliyev@gmail.com',
        password: 'sifre',
      );

      expect(result.isRight(), isTrue);
      final user = storage.cachedUser!;
      expect(user.name, 'Resad Alizade');
      expect(user.email, 'resad88aliyev@gmail.com');
      expect(user.phone, '+994556691248');
      // The response names the student `user_id` and the push identity
      // outright; both are what the rest of the session is addressed by.
      expect(user.id, 3158);
      expect(user.pushExternalId, 'parent_866');
      expect(user.className, 'Class Group 8');
      expect(user.children.single.email, 'std_3158@bsb.edu.az');
    });

    test('the edit form opens on the number as the parent knows it', () async {
      final (repository, _, storage) = _repository(body: loginBody);
      await repository.login(email: 'resad88aliyev@gmail.com', password: 'x');

      // What `_ProfileSheet` seeds its controllers with.
      expect(AzPhone.format(storage.cachedUser!.phone!), '+994 55 669 12 48');
      expect(storage.cachedUser!.email, 'resad88aliyev@gmail.com');
    });

    test('a restart reads both back out of storage', () async {
      final (repository, _, storage) = _repository(body: loginBody);
      await repository.login(email: 'resad88aliyev@gmail.com', password: 'x');

      // The cache round-trips through `toJson`/`fromJson`; a field missing
      // from either would come back null on the next launch.
      final restored = AuthUserModel.fromJson(storage.cachedUser!.toJson());
      expect(restored.phone, '+994556691248');
      expect(restored.email, 'resad88aliyev@gmail.com');
    });
  });

  group('the parent edits their own details', () {
    test('the payload is the three fields, by their plain names', () async {
      final (repository, adapter, _) = _repository();

      final result = await repository.updateProfile(
        name: 'Ceyhun Alizade',
        email: 'yeni@bsb.edu.az',
        phone: '0555555555',
      );

      expect(result.isRight(), isTrue);
      expect(adapter.request!.path, AuthServiceImpl.updateProfilePath);
      expect(_sent(adapter), {
        'name': 'Ceyhun Alizade',
        'email': 'yeni@bsb.edu.az',
        'phone': '0555555555',
      });
      // The repository takes the phone as given — the masking and the `+994`
      // are `ProfileCubit`'s job, covered in `az_phone_test.dart`.
    });

    test('an endpoint that only acknowledges still updates the cache',
        () async {
      final (repository, _, storage) = _repository();

      await repository.updateProfile(
        name: 'Ceyhun Əlizadə',
        email: 'yeni@bsb.edu.az',
        phone: '0555555555',
      );

      // What was sent is what the server now holds, so the profile shows it
      // without waiting for the next login.
      expect(storage.cachedUser!.name, 'Ceyhun Əlizadə');
      expect(storage.cachedUser!.email, 'yeni@bsb.edu.az');
      expect(storage.cachedUser!.phone, '0555555555');
      // And nothing else was lost on the way through.
      expect(storage.cachedUser!.role, 'parent');
      expect(storage.cachedUser!.accountId, 66);
      expect(storage.cachedUser!.children, hasLength(2));
    });

    test('an echoed user wins over what was sent', () async {
      final (repository, _, storage) = _repository(
        body: '''
{"success": true, "user": {"user_id": 3139, "name": "Ceyhun Alizade",
 "email": "server@bsb.edu.az", "phone": "0700000000", "role": "parent"}}
''',
      );

      await repository.updateProfile(
        name: 'Ceyhun Alizade',
        email: 'yeni@bsb.edu.az',
        phone: '0555555555',
      );

      expect(storage.cachedUser!.email, 'server@bsb.edu.az');
      expect(storage.cachedUser!.phone, '0700000000');
      // The trimmed body carried no `info`; the roster survives it.
      expect(storage.cachedUser!.children, hasLength(2));
    });

    test('a cleared phone is taken at face value', () async {
      final (repository, _, storage) = _repository();

      await repository.updateProfile(
        name: 'Ceyhun Alizade',
        email: 'ceyhun@bsb.edu.az',
        phone: '',
      );

      expect(storage.cachedUser!.phone, isNull);
    });

    test('a rejected field comes back under its own name', () async {
      final (repository, _, storage) = _repository(
        statusCode: 422,
        body: '''
{"success": false, "message": "Məlumatlar yenilənmədi",
 "errors": {"email": ["Bu email artıq istifadə olunur."]}}
''',
      );

      final result = await repository.updateProfile(
        name: 'Ceyhun Alizade',
        email: 'artiq@bsb.edu.az',
        phone: '0555555555',
      );

      final failure = result.fold((f) => f, (_) => null);
      expect(failure, isA<FieldValidationFailure>());
      expect(
        (failure as FieldValidationFailure).fieldErrors['email'],
        'Bu email artıq istifadə olunur.',
      );
      // A rejected save leaves the cache exactly as it was.
      expect(storage.cachedUser!.email, 'ceyhun@bsb.edu.az');
    });

    test('a new address goes out with the code mailed to it', () async {
      final (repository, adapter, _) = _repository();

      await repository.updateProfile(
        name: 'Ceyhun Alizade',
        email: 'yeni@bsb.edu.az',
        phone: '0555555555',
        otp: '123456',
      );

      expect(_sent(adapter), {
        'name': 'Ceyhun Alizade',
        'email': 'yeni@bsb.edu.az',
        'phone': '0555555555',
        'otp': '123456',
      });
    });

    test('a wrong code comes back under its own name, nothing cached',
        () async {
      final (repository, _, storage) = _repository(
        statusCode: 422,
        body: '''
{"success": false, "message": "Məlumatlar yenilənmədi",
 "errors": {"otp": ["Təsdiq kodu yanlışdır."]}}
''',
      );

      final result = await repository.updateProfile(
        name: 'Ceyhun Alizade',
        email: 'yeni@bsb.edu.az',
        phone: '0555555555',
        otp: '000000',
      );

      final failure = result.fold((f) => f, (_) => null);
      expect(failure, isA<FieldValidationFailure>());
      expect(
        (failure as FieldValidationFailure).fieldErrors['otp'],
        'Təsdiq kodu yanlışdır.',
      );
      expect(storage.cachedUser!.email, 'ceyhun@bsb.edu.az');
    });
  });

  group('the code for a new login address', () {
    test('goes to the new address, and the wait comes back', () async {
      final (repository, adapter, storage) = _repository(
        body: '{"success": true, "message": "Kod göndərildi", '
            '"seconds_left": 60, "expires_in": 600}',
      );

      final result = await repository.sendEmailChangeOtp(
        email: 'yeni@bsb.edu.az',
      );

      expect(result.fold((_) => null, (seconds) => seconds), 60);
      expect(adapter.request!.path, AuthServiceImpl.sendEmailChangeOtpPath);
      expect(_sent(adapter), {'email': 'yeni@bsb.edu.az'});
      // Asking for a code changes nothing yet.
      expect(storage.cachedUser!.email, 'ceyhun@bsb.edu.az');
    });

    test("names the student when it is the student's address", () async {
      final (repository, adapter, _) = _repository(
        body: '{"success": true, "seconds_left": 60}',
      );

      await repository.sendEmailChangeOtp(
        email: 'resad@bsb.edu.az',
        childId: 3139,
      );

      expect(_sent(adapter), {'email': 'resad@bsb.edu.az', 'child_id': 3139});
    });

    test('is never asked for a student on another account', () async {
      final (repository, adapter, _) = _repository();

      final result = await repository.sendEmailChangeOtp(
        email: 'resad@bsb.edu.az',
        childId: 999,
      );

      expect(result.isLeft(), isTrue);
      expect(adapter.request, isNull);
    });

    test('a refused address comes back under the e-mail field', () async {
      final (repository, _, _) = _repository(
        statusCode: 422,
        body: '{"success": false, '
            '"errors": {"email": ["Bu email artıq istifadə olunur."]}}',
      );

      final result = await repository.sendEmailChangeOtp(
        email: 'artiq@bsb.edu.az',
      );

      final failure = result.fold((f) => f, (_) => null);
      expect(failure, isA<FieldValidationFailure>());
      expect(
        (failure as FieldValidationFailure).fieldErrors['email'],
        'Bu email artıq istifadə olunur.',
      );
    });
  });

  group('the parent changes their own password', () {
    test('the payload carries the confirmation Laravel asks for', () async {
      final (repository, adapter, _) = _repository();

      final result = await repository.updatePassword(
        currentPassword: 'kohneSifre',
        newPassword: 'yeniSifre1',
      );

      expect(result.isRight(), isTrue);
      expect(adapter.request!.path, AuthServiceImpl.updatePasswordPath);
      expect(_sent(adapter), {
        'current_password': 'kohneSifre',
        'new_password': 'yeniSifre1',
        'new_password_confirmation': 'yeniSifre1',
      });
    });

    test('a wrong current password comes back under its own field', () async {
      final (repository, _, _) = _repository(
        statusCode: 422,
        body: '''
{"success": false, "message": "Şifrə yenilənmədi",
 "errors": {"current_password": ["Cari şifrə yanlışdır."]}}
''',
      );

      final result = await repository.updatePassword(
        currentPassword: 'yanlis',
        newPassword: 'yeniSifre1',
      );

      final failure = result.fold((f) => f, (_) => null);
      expect(failure, isA<FieldValidationFailure>());
      expect(
        (failure as FieldValidationFailure).fieldErrors['current_password'],
        'Cari şifrə yanlışdır.',
      );
    });

    test('the session is left alone — no token, no user is touched', () async {
      final (repository, _, storage) = _repository();
      final before = storage.cachedUser;

      await repository.updatePassword(
        currentPassword: 'kohneSifre',
        newPassword: 'yeniSifre1',
      );

      expect(storage.cachedUser, same(before));
    });
  });

  group("the parent edits a student's e-mail", () {
    test('the payload names the student by id', () async {
      final (repository, adapter, _) = _repository();

      final result = await repository.updateChildEmail(
        childId: 3139,
        email: 'resad@bsb.edu.az',
      );

      expect(result.isRight(), isTrue);
      expect(adapter.request!.path, AuthServiceImpl.updateChildEmailPath);
      expect(_sent(adapter), {'child_id': 3139, 'email': 'resad@bsb.edu.az'});
    });

    test('only that student moves, on a bare acknowledgement', () async {
      final (repository, _, storage) = _repository();

      await repository.updateChildEmail(
        childId: 3139,
        email: 'resad@bsb.edu.az',
      );

      final children = storage.cachedUser!.children;
      expect(children.firstWhere((c) => c.childId == 3139).email,
          'resad@bsb.edu.az');
      expect(children.firstWhere((c) => c.childId == 2570).email,
          'std_2570@bsb.edu.az');
      // The credentials the school issued are not the app's to touch.
      expect(children.firstWhere((c) => c.childId == 3139).password,
          '7QXVi9ir');
    });

    test('a roster-only response is folded in', () async {
      final (repository, _, storage) = _repository(
        body: '''
{"success": true, "info": [
  {"child_id": 3139, "child_name": "Rashad", "child_surname": "Ali",
   "email": "server@bsb.edu.az", "password": "7QXVi9ir", "payment_id": "RA3139"}
]}
''',
      );

      await repository.updateChildEmail(
        childId: 3139,
        email: 'resad@bsb.edu.az',
      );

      expect(storage.cachedUser!.children.single.email, 'server@bsb.edu.az');
      // The account itself is untouched by a children-only body.
      expect(storage.cachedUser!.name, 'Ceyhun Alizade');
      expect(storage.cachedUser!.role, 'parent');
    });

    test('a student on another account never leaves the app', () async {
      final (repository, adapter, _) = _repository();

      final result = await repository.updateChildEmail(
        childId: 999,
        email: 'resad@bsb.edu.az',
      );

      expect(result.isLeft(), isTrue);
      expect(adapter.request, isNull);
    });

    test("the backend's refusal is what the parent reads", () async {
      final (repository, _, storage) = _repository(
        statusCode: 403,
        body: '{"success": false, "message": "Bu şagird sizin deyil."}',
      );

      final result = await repository.updateChildEmail(
        childId: 3139,
        email: 'resad@bsb.edu.az',
      );

      expect(result.fold((f) => f.message, (_) => null), 'Bu şagird sizin deyil.');
      expect(storage.cachedUser!.children.first.email, 'std_3139@bsb.edu.az');
    });

    test('the code rides along with the new address', () async {
      final (repository, adapter, _) = _repository();

      await repository.updateChildEmail(
        childId: 3139,
        email: 'resad@bsb.edu.az',
        otp: '654321',
      );

      expect(_sent(adapter), {
        'child_id': 3139,
        'email': 'resad@bsb.edu.az',
        'otp': '654321',
      });
    });

    test('a wrong code is told apart from a refused address', () async {
      final (repository, _, storage) = _repository(
        statusCode: 422,
        body: '{"success": false, '
            '"errors": {"otp": ["Təsdiq kodu yanlışdır."]}}',
      );

      final result = await repository.updateChildEmail(
        childId: 3139,
        email: 'resad@bsb.edu.az',
        otp: '000000',
      );

      final failure = result.fold((f) => f, (_) => null);
      expect(failure, isA<FieldValidationFailure>());
      expect(
        (failure as FieldValidationFailure).fieldErrors['otp'],
        'Təsdiq kodu yanlışdır.',
      );
      expect(failure.message, 'Təsdiq kodu yanlışdır.');
      expect(storage.cachedUser!.children.first.email, 'std_3139@bsb.edu.az');
    });
  });
}
