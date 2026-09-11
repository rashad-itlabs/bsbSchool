import 'package:bsbschool/core/error/failures.dart';
import 'package:bsbschool/core/l10n/l10n.dart';
import 'package:bsbschool/core/l10n/locale_controller.dart';
import 'package:bsbschool/dr/screens/language_screen.dart';
import 'package:bsbschool/dr/screens/login_screen.dart';
import 'package:bsbschool/dr/theme/dr_theme.dart';
import 'package:bsbschool/features/auth/domain/entities/auth_session.dart';
import 'package:bsbschool/features/auth/domain/entities/auth_user.dart';
import 'package:bsbschool/features/auth/domain/entities/child_account.dart';
import 'package:bsbschool/features/auth/domain/repositories/auth_repository.dart';
import 'package:bsbschool/features/auth/domain/usecases/login_user.dart';
import 'package:bsbschool/features/auth/domain/usecases/logout_user.dart';
import 'package:bsbschool/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bsbschool/main.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A signed-out account: enough for [AuthGate] to reach its unauthenticated
/// branch, which is the only place the picker can appear.
class _SignedOutRepository implements AuthRepository {
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

/// The real app root minus `main()`'s bootstrapping: the locale is driven by
/// [LocaleController] exactly as it is in production, so the picker's live
/// preview is what the test sees.
Widget _app() {
  final repository = _SignedOutRepository();
  return BlocProvider<AuthBloc>(
    create: (_) => AuthBloc(
      loginUser: LoginUser(repository),
      logoutUser: LogoutUser(repository),
      repository: repository,
    )..add(const AuthCheckRequested()),
    child: AnimatedBuilder(
      animation: LocaleController.instance,
      builder: (context, _) => MaterialApp(
        theme: DrTheme.dark,
        locale: LocaleController.instance.locale,
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        localeResolutionCallback: (device, supported) =>
            LocaleController.instance.resolve([?device]),
        home: const AuthGate(),
      ),
    ),
  );
}

void main() {
  Future<void> boot(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    await LocaleController.instance.load();
  }

  testWidgets('a fresh install picks a language before it asks to sign in',
      (tester) async {
    await boot({});

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.byType(LanguageScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('every language the app ships is offered, named in itself',
      (tester) async {
    await boot({});

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // Endonyms, so the option is findable by someone who cannot read the
    // language the screen is currently in.
    expect(find.text('Azərbaycanca'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Русский'), findsOneWidget);
  });

  testWidgets('tapping a language applies it to the screen right away',
      (tester) async {
    await boot({});

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Русский'));
    await tester.pumpAndSettle();

    // Still the picker — tapping previews, it does not commit.
    expect(find.byType(LanguageScreen), findsOneWidget);
    expect(LocaleController.instance.locale, const Locale('ru'));
    expect(
      find.text(lookupAppL10n(const Locale('ru')).languagePickTitle),
      findsOneWidget,
    );
  });

  testWidgets('confirming reveals the login form in the chosen language',
      (tester) async {
    await boot({});

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    final en = lookupAppL10n(const Locale('en'));
    await tester.tap(find.text(en.commonContinue));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(LanguageScreen), findsNothing);
    expect(find.text(en.loginSubtitle), findsOneWidget);
  });

  testWidgets('an answered picker never comes back', (tester) async {
    await boot({'app_locale_chosen': true});

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(LanguageScreen), findsNothing);
  });

  // Upgrading from a build that predates the picker: someone who already set
  // a language in settings has answered the question, and interrupting them
  // with it would be a regression, not an onboarding step.
  testWidgets('an install that already carries a language is left alone',
      (tester) async {
    await boot({'app_locale': 'ru'});

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(LanguageScreen), findsNothing);
  });
}
