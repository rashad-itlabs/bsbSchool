import 'package:bsbschool/core/error/failures.dart';
import 'package:bsbschool/features/auth/domain/entities/auth_session.dart';
import 'package:bsbschool/features/auth/domain/entities/auth_user.dart';
import 'package:bsbschool/features/auth/domain/entities/child_account.dart';
import 'package:bsbschool/features/auth/domain/repositories/auth_repository.dart';
import 'package:bsbschool/features/auth/domain/usecases/resend_otp.dart';
import 'package:bsbschool/features/auth/domain/usecases/reset_password.dart';
import 'package:bsbschool/features/auth/domain/usecases/verify_otp.dart';
import 'package:bsbschool/features/auth/presentation/cubit/forgot_password_cubit.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records what the reset asked of the backend, and can be told to reject any
/// one of the three calls the flow makes.
class _RecordingRepository implements AuthRepository {
  final Failure? sendFailure;
  final Failure? verifyFailure;
  final Failure? resetFailure;

  final List<String> sentTo = [];
  final List<({String email, String otp})> verified = [];
  final List<({String email, String password})> reset = [];

  _RecordingRepository({
    this.sendFailure,
    this.verifyFailure,
    this.resetFailure,
  });

  @override
  Future<Either<Failure, Unit>> resendOtp({required String email}) async {
    sentTo.add(email);
    return sendFailure == null ? const Right(unit) : Left(sendFailure!);
  }

  @override
  Future<Either<Failure, Unit>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    verified.add((email: email, otp: otp));
    return verifyFailure == null ? const Right(unit) : Left(verifyFailure!);
  }

  @override
  Future<Either<Failure, Unit>> resetPassword({
    required String email,
    required String password,
  }) async {
    reset.add((email: email, password: password));
    return resetFailure == null ? const Right(unit) : Left(resetFailure!);
  }

  // Nothing below is reachable from this sheet.
  @override
  bool get isLoggedIn => false;

  @override
  AuthUser? get currentUser => null;

  @override
  ChildAccount? get activeChild => null;

  @override
  int? get activeStudentId => null;

  @override
  int? get activeClassId => null;

  @override
  Future<Either<Failure, AuthSession>> login({
    required String email,
    required String password,
  }) async =>
      const Left(ValidationFailure('no'));

  @override
  Future<Either<Failure, Unit>> logout() async => const Right(unit);

  @override
  Future<Either<Failure, Unit>> selectChild(int childId) async =>
      const Right(unit);

  @override
  Future<Either<Failure, Unit>> attachChild({
    required String admissionNo,
    String? relation,
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
}

(ForgotPasswordCubit, _RecordingRepository) _cubit({
  Failure? sendFailure,
  Failure? verifyFailure,
  Failure? resetFailure,
}) {
  final repository = _RecordingRepository(
    sendFailure: sendFailure,
    verifyFailure: verifyFailure,
    resetFailure: resetFailure,
  );
  return (
    ForgotPasswordCubit(
      sendOtp: ResendOtp(repository),
      verifyOtp: VerifyOtp(repository),
      resetPassword: ResetPassword(repository),
    ),
    repository,
  );
}

void main() {
  test('the address, then the mailed code, then the password', () async {
    final (cubit, repository) = _cubit();
    addTearDown(cubit.close);

    await cubit.requestCode('  parent@bsb.edu.az ');
    expect(cubit.state.step, ForgotPasswordStep.code);
    // Trimmed once, here, and carried by every later step.
    expect(repository.sentTo, ['parent@bsb.edu.az']);
    expect(cubit.state.email, 'parent@bsb.edu.az');

    await cubit.verifyCode('123456');
    expect(cubit.state.step, ForgotPasswordStep.password);
    expect(repository.verified.single.otp, '123456');
    expect(repository.verified.single.email, 'parent@bsb.edu.az');
    // Nothing has touched the password yet.
    expect(repository.reset, isEmpty);

    await cubit.submit(password: 'yeniSifre1', passwordConfirmation: 'yeniSifre1');
    expect(cubit.state.status, ForgotPasswordStatus.success);
    expect(repository.reset.single.email, 'parent@bsb.edu.az');
    expect(repository.reset.single.password, 'yeniSifre1');
  });

  test('an unknown address never reaches the code step', () async {
    final (cubit, repository) = _cubit(
      sendFailure: const ValidationFailure('Bu email ilə istifadəçi tapılmadı.'),
    );
    addTearDown(cubit.close);

    await cubit.requestCode('yox@bsb.edu.az');

    expect(cubit.state.step, ForgotPasswordStep.email);
    expect(cubit.state.status, ForgotPasswordStatus.error);
    expect(cubit.state.message, 'Bu email ilə istifadəçi tapılmadı.');
    expect(repository.sentTo, ['yox@bsb.edu.az']);
  });

  test('a malformed address is caught before the request goes out', () async {
    final (cubit, repository) = _cubit();
    addTearDown(cubit.close);

    await cubit.requestCode('parent@bsb');

    expect(cubit.state.status, ForgotPasswordStatus.error);
    expect(cubit.state.step, ForgotPasswordStep.email);
    expect(repository.sentTo, isEmpty);
  });

  test('a rejected code leaves the password out of reach', () async {
    final (cubit, repository) = _cubit(
      verifyFailure: const ValidationFailure('Kod yanlışdır və ya vaxtı bitib'),
    );
    addTearDown(cubit.close);

    await cubit.requestCode('parent@bsb.edu.az');
    await cubit.verifyCode('000000');

    expect(cubit.state.step, ForgotPasswordStep.code);
    expect(cubit.state.status, ForgotPasswordStatus.error);
    expect(cubit.state.message, 'Kod yanlışdır və ya vaxtı bitib');

    // And the step guard holds even if a submit is somehow asked for.
    await cubit.submit(password: 'yeniSifre1', passwordConfirmation: 'yeniSifre1');
    expect(repository.reset, isEmpty);
  });

  test('a short code is not sent to the backend', () async {
    final (cubit, repository) = _cubit();
    addTearDown(cubit.close);

    await cubit.requestCode('parent@bsb.edu.az');
    await cubit.verifyCode('123');

    expect(repository.verified, isEmpty);
    expect(cubit.state.status, ForgotPasswordStatus.error);
    expect(cubit.state.step, ForgotPasswordStep.code);
  });

  test('mismatched passwords never leave the app', () async {
    final (cubit, repository) = _cubit();
    addTearDown(cubit.close);

    await cubit.requestCode('parent@bsb.edu.az');
    await cubit.verifyCode('123456');
    await cubit.submit(password: 'yeniSifre1', passwordConfirmation: 'yeniSifre2');

    expect(cubit.state.status, ForgotPasswordStatus.error);
    expect(repository.reset, isEmpty);

    // Too short is refused by the same rule the backend applies.
    await cubit.submit(password: 'qisa', passwordConfirmation: 'qisa');
    expect(repository.reset, isEmpty);
    expect(cubit.state.step, ForgotPasswordStep.password);
  });

  test('a resend waits out the cooldown, then mails a fresh code', () async {
    final (cubit, repository) = _cubit();
    addTearDown(cubit.close);

    await cubit.requestCode('parent@bsb.edu.az');
    expect(cubit.state.resendSeconds, ForgotPasswordCubit.resendCooldownSeconds);
    expect(cubit.state.canResend, isFalse);

    // Still inside the cooldown: no second mail goes out.
    await cubit.resendCode();
    expect(repository.sentTo, hasLength(1));
  });

  test('a mistyped address can be corrected from the code step', () async {
    final (cubit, repository) = _cubit();
    addTearDown(cubit.close);

    await cubit.requestCode('yanlis@bsb.edu.az');
    cubit.backToEmail();

    expect(cubit.state.step, ForgotPasswordStep.email);
    expect(cubit.state.resendSeconds, 0);

    await cubit.requestCode('duzgun@bsb.edu.az');
    expect(cubit.state.step, ForgotPasswordStep.code);
    expect(repository.sentTo, ['yanlis@bsb.edu.az', 'duzgun@bsb.edu.az']);
  });
}
