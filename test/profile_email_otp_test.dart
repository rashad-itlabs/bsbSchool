import 'package:bsbschool/core/error/failures.dart';
import 'package:bsbschool/features/auth/domain/repositories/auth_repository.dart';
import 'package:bsbschool/features/auth/domain/usecases/send_email_change_otp.dart';
import 'package:bsbschool/features/auth/domain/usecases/update_child_email.dart';
import 'package:bsbschool/features/auth/domain/usecases/update_password.dart';
import 'package:bsbschool/features/auth/domain/usecases/update_profile.dart';
import 'package:bsbschool/features/auth/presentation/cubit/profile_cubit.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

/// The backend's side of an e-mail change, kept just real enough: a code is
/// "mailed" per address, and a save with a new address lands only with it.
class _FakeAuthRepository implements AuthRepository {
  static const validCode = '123456';

  final codesSent = <({String email, int? childId})>[];
  final profileSaves = <({String name, String email, String phone, String? otp})>[];
  final childSaves = <({int childId, String email, String? otp})>[];

  /// What `/sendEmailChangeOtp` answers with, when it refuses.
  Failure? sendFailure;

  @override
  Future<Either<Failure, int>> sendEmailChangeOtp({
    required String email,
    int? childId,
  }) async {
    if (sendFailure != null) return Left(sendFailure!);
    codesSent.add((email: email, childId: childId));
    return const Right(60);
  }

  @override
  Future<Either<Failure, Unit>> updateProfile({
    required String name,
    required String email,
    required String phone,
    String? otp,
  }) async {
    profileSaves.add((name: name, email: email, phone: phone, otp: otp));
    return _checked(otp);
  }

  @override
  Future<Either<Failure, Unit>> updateChildEmail({
    required int childId,
    required String email,
    String? otp,
  }) async {
    childSaves.add((childId: childId, email: email, otp: otp));
    return _checked(otp);
  }

  /// No code means an unchanged address; a code has to be the right one.
  Either<Failure, Unit> _checked(String? otp) {
    if (otp == null || otp == validCode) return const Right(unit);
    return const Left(FieldValidationFailure(
      {'otp': 'Təsdiq kodu yanlışdır.'},
      'Məlumatlar yenilənmədi',
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeAuthRepository repository;
  late ProfileCubit cubit;

  setUp(() {
    repository = _FakeAuthRepository();
    cubit = ProfileCubit(
      updateProfile: UpdateProfile(repository),
      updateChildEmail: UpdateChildEmail(repository),
      updatePassword: UpdatePassword(repository),
      sendEmailChangeOtp: SendEmailChangeOtp(repository),
    );
  });

  tearDown(() => cubit.close());

  Future<void> saveProfile(String email) => cubit.saveProfile(
        name: 'Ceyhun Alizade',
        email: email,
        phone: '',
        currentEmail: 'ceyhun@bsb.edu.az',
      );

  group("the parent's own address", () {
    test('an unchanged address saves at once, no code asked for', () async {
      await saveProfile('ceyhun@bsb.edu.az');

      expect(repository.codesSent, isEmpty);
      expect(repository.profileSaves.single.otp, isNull);
      expect(cubit.state.status, ProfileStatus.success);
    });

    test('a change of case alone is not a new address', () async {
      await saveProfile('  Ceyhun@BSB.edu.az ');

      expect(repository.codesSent, isEmpty);
      expect(cubit.state.status, ProfileStatus.success);
    });

    test('a new address is mailed a code and nothing is saved yet', () async {
      await saveProfile('yeni@bsb.edu.az');

      expect(repository.codesSent.single.email, 'yeni@bsb.edu.az');
      expect(repository.codesSent.single.childId, isNull);
      expect(repository.profileSaves, isEmpty);
      expect(cubit.state.status, ProfileStatus.otpSent);
      expect(cubit.state.awaitingCode, isTrue);
      expect(cubit.state.pendingEmail, 'yeni@bsb.edu.az');
      expect(cubit.state.resendSeconds, 60);
    });

    test('a wrong code keeps the sheet on the code, the address unchanged',
        () async {
      await saveProfile('yeni@bsb.edu.az');
      await cubit.confirmCode('000000');

      expect(cubit.state.status, ProfileStatus.error);
      expect(cubit.state.awaitingCode, isTrue);
      expect(cubit.state.codeError, 'Təsdiq kodu yanlışdır.');
      // The one save that went out was refused — the fake backend, like the
      // real one, writes nothing on a wrong code.
      expect(repository.profileSaves.single.otp, '000000');
    });

    test('the right code sends the form as it was submitted', () async {
      await saveProfile('yeni@bsb.edu.az');
      await cubit.confirmCode(_FakeAuthRepository.validCode);

      final save = repository.profileSaves.single;
      expect(save.name, 'Ceyhun Alizade');
      expect(save.email, 'yeni@bsb.edu.az');
      expect(save.otp, _FakeAuthRepository.validCode);
      expect(cubit.state.status, ProfileStatus.success);
    });

    test('a short code never leaves the app', () async {
      await saveProfile('yeni@bsb.edu.az');
      await cubit.confirmCode('123');

      expect(repository.profileSaves, isEmpty);
      expect(cubit.state.errorFor('otp'), isNotNull);
      expect(cubit.state.awaitingCode, isTrue);
    });

    test('a refused address stays on the form, under the e-mail field',
        () async {
      repository.sendFailure = const FieldValidationFailure(
        {'email': 'Bu email artıq istifadə olunur.'},
      );

      await saveProfile('artiq@bsb.edu.az');

      expect(cubit.state.awaitingCode, isFalse);
      expect(cubit.state.errorFor('email'), 'Bu email artıq istifadə olunur.');
      expect(repository.profileSaves, isEmpty);
    });

    test('going back to fix the address drops the held save', () async {
      await saveProfile('yanlis@bsb.edu.az');
      cubit.backToForm();

      expect(cubit.state.awaitingCode, isFalse);
      await cubit.confirmCode(_FakeAuthRepository.validCode);
      expect(repository.profileSaves, isEmpty);
    });

    test('editing the code clears its error but not the step', () async {
      await saveProfile('yeni@bsb.edu.az');
      await cubit.confirmCode('000000');
      cubit.inputChanged();

      expect(cubit.state.codeError, isNull);
      expect(cubit.state.awaitingCode, isTrue);
    });
  });

  group("a student's address", () {
    test('a new address is confirmed by its code before it is saved',
        () async {
      await cubit.saveChildEmail(
        childId: 3139,
        email: 'resad@bsb.edu.az',
        currentEmail: 'std_3139@bsb.edu.az',
      );

      expect(repository.codesSent.single.childId, 3139);
      expect(repository.childSaves, isEmpty);

      await cubit.confirmCode(_FakeAuthRepository.validCode);

      final save = repository.childSaves.single;
      expect(save.childId, 3139);
      expect(save.email, 'resad@bsb.edu.az');
      expect(save.otp, _FakeAuthRepository.validCode);
      expect(cubit.state.status, ProfileStatus.success);
    });

    test('the same address needs neither a code nor a request', () async {
      await cubit.saveChildEmail(
        childId: 3139,
        email: 'std_3139@bsb.edu.az',
        currentEmail: 'std_3139@bsb.edu.az',
      );

      expect(repository.codesSent, isEmpty);
      expect(repository.childSaves, isEmpty);
      expect(cubit.state.status, ProfileStatus.success);
    });
  });
}
