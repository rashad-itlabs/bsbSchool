import 'package:bsbschool/core/di/injection_container.dart';
import 'package:bsbschool/core/error/failures.dart';
import 'package:bsbschool/dr/screens/pass_screen.dart';
import 'package:bsbschool/dr/theme/dr_theme.dart';
import 'package:bsbschool/features/auth/domain/entities/auth_user.dart';
import 'package:bsbschool/features/auth/domain/entities/child_account.dart';
import 'package:bsbschool/features/auth/domain/repositories/auth_repository.dart';
import 'package:bsbschool/features/auth/domain/usecases/delete_account.dart';
import 'package:bsbschool/features/auth/domain/usecases/login_user.dart';
import 'package:bsbschool/features/auth/domain/usecases/logout_user.dart';
import 'package:bsbschool/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bsbschool/features/auth/presentation/bloc/delete_account_bloc.dart';
import 'package:bsbschool/l10n/app_localizations.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

const _rightPassword = 'secret123';
const _wrongPasswordMessage = 'Cari şifrə yanlışdır';
const _deletedMessage = 'Hesab silindi';

/// A restored session for [user], answering `POST /deleteAccount` the way the
/// Laravel endpoint does: a 422 on `password` unless it is [_rightPassword].
class _SignedInRepository implements AuthRepository {
  final AuthUser user;
  _SignedInRepository(this.user);

  final deleteAttempts = <String>[];
  var loggedOut = false;

  @override
  bool get isLoggedIn => !loggedOut;

  @override
  AuthUser? get currentUser => loggedOut ? null : user;

  @override
  ChildAccount? get activeChild => null;

  @override
  Future<Either<Failure, String?>> deleteAccount({
    required String password,
  }) async {
    deleteAttempts.add(password);
    if (password != _rightPassword) {
      return const Left(FieldValidationFailure(
        {'password': _wrongPasswordMessage},
        _wrongPasswordMessage,
      ));
    }
    return const Right(_deletedMessage);
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    loggedOut = true;
    return const Right(unit);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

_SignedInRepository _repository(String role) => _SignedInRepository(AuthUser(
      id: 3789,
      name: 'Rəşad Əliyev',
      childName: 'Said Aliyev',
      role: role,
      email: 'parent@bsb.edu.az',
    ));

Widget _profile(_SignedInRepository repository) {
  return BlocProvider<AuthBloc>(
    create: (_) => AuthBloc(
      loginUser: LoginUser(repository),
      logoutUser: LogoutUser(repository),
      repository: repository,
    )..add(const AuthCheckRequested()),
    child: MaterialApp(
      theme: DrTheme.dark,
      locale: const Locale('az'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: const PassScreen(),
    ),
  );
}

void main() {
  final l10n = lookupAppL10n(const Locale('az'));
  final link = find.text(l10n.settingsDeleteAccount);

  /// The password sheet takes its bloc from the service locator.
  Future<void> registerBloc(_SignedInRepository repository) async {
    await sl.reset();
    sl.registerFactory(
      () => DeleteAccountBloc(deleteAccount: DeleteAccount(repository)),
    );
  }

  Future<void> scrollToLink(WidgetTester tester) => tester.scrollUntilVisible(
        link,
        200,
        scrollable: find.byType(Scrollable).first,
      );

  /// Link → tick → confirm, leaving the password sheet on screen.
  Future<void> openPasswordStep(WidgetTester tester) async {
    await scrollToLink(tester);
    await tester.tap(link);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.settingsDeleteAccountCheck));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text(l10n.settingsDeleteAccount),
    ));
    await tester.pumpAndSettle();
  }

  // The sheet's red button — the last "Hesabı sil" on screen, below the
  // sheet title and the link underneath.
  Finder submit() => find.text(l10n.settingsDeleteAccount).last;

  testWidgets('a student has no delete-account link', (tester) async {
    await tester.pumpWidget(_profile(_repository('student')));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text(l10n.settingsLogout),
      find.byType(Scrollable).first,
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    expect(link, findsNothing);
  });

  testWidgets('a parent must tick the box before deleting is possible',
      (tester) async {
    await tester.pumpWidget(_profile(_repository('parent')));
    await tester.pumpAndSettle();

    await scrollToLink(tester);
    await tester.tap(link);
    await tester.pumpAndSettle();

    expect(find.text(l10n.settingsDeleteAccountTitle), findsOneWidget);

    // The dialog's own delete button: disabled until the box is ticked.
    final confirm = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(TextButton, l10n.settingsDeleteAccount),
    );
    expect(tester.widget<TextButton>(confirm).onPressed, isNull);

    await tester.tap(find.text(l10n.settingsDeleteAccountCheck));
    await tester.pumpAndSettle();
    expect(tester.widget<TextButton>(confirm).onPressed, isNotNull);

    // Cancel still backs out without deleting.
    await tester.tap(find.text(l10n.commonCancel));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('an empty or wrong password keeps the sheet open, unsent',
      (tester) async {
    final repository = _repository('parent');
    await registerBloc(repository);
    await tester.pumpWidget(_profile(repository));
    await tester.pumpAndSettle();
    await openPasswordStep(tester);

    // The dialog gave way to the password step.
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text(l10n.settingsDeleteAccountPasswordText), findsOneWidget);

    // Nothing typed: said so on the spot, nothing sent.
    await tester.tap(submit());
    await tester.pumpAndSettle();
    expect(find.text(l10n.profileCurrentPasswordRequired), findsOneWidget);
    expect(repository.deleteAttempts, isEmpty);

    // A wrong password: the server's message under the field, still here.
    await tester.enterText(find.byType(TextField).last, 'nope');
    await tester.pump();
    expect(find.text(l10n.profileCurrentPasswordRequired), findsNothing);
    await tester.tap(submit());
    await tester.pumpAndSettle();
    expect(repository.deleteAttempts, ['nope']);
    expect(find.text(_wrongPasswordMessage), findsOneWidget);
    expect(find.text(l10n.settingsDeleteAccountPasswordText), findsOneWidget);
    expect(repository.loggedOut, isFalse);

    // Editing clears the complaint.
    await tester.enterText(find.byType(TextField).last, 'nope2');
    await tester.pump();
    expect(find.text(_wrongPasswordMessage), findsNothing);
  });

  testWidgets('the right password deletes, signs out and says so',
      (tester) async {
    final repository = _repository('parent');
    await registerBloc(repository);
    await tester.pumpWidget(_profile(repository));
    await tester.pumpAndSettle();
    await openPasswordStep(tester);

    await tester.enterText(find.byType(TextField).last, _rightPassword);
    await tester.pump();
    await tester.tap(submit());
    await tester.pumpAndSettle();

    expect(repository.deleteAttempts, [_rightPassword]);
    expect(find.text(l10n.settingsDeleteAccountPasswordText), findsNothing);
    // Signed out through the usual logout, with the server's note on screen.
    expect(repository.loggedOut, isTrue);
    expect(find.text(_deletedMessage), findsOneWidget);
  });
}
