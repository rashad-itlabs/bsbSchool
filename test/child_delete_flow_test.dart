import 'package:bsbschool/core/error/failures.dart';
import 'package:bsbschool/dr/screens/pass_screen.dart';
import 'package:bsbschool/dr/theme/dr_theme.dart';
import 'package:bsbschool/dr/widgets/add_child_sheet.dart';
import 'package:bsbschool/features/auth/domain/entities/auth_user.dart';
import 'package:bsbschool/features/auth/domain/entities/child_account.dart';
import 'package:bsbschool/features/auth/domain/repositories/auth_repository.dart';
import 'package:bsbschool/features/auth/domain/usecases/login_user.dart';
import 'package:bsbschool/features/auth/domain/usecases/logout_user.dart';
import 'package:bsbschool/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bsbschool/l10n/app_localizations.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

const _rightPassword = 'secret123';
const _wrongPasswordMessage = 'Şifrə yanlışdır';

const _rashad = ChildAccount(
  childId: 3139,
  isActive: 'yes',
  childName: 'Rashad',
  childSurname: 'Ali',
);
const _fakhraddin = ChildAccount(
  childId: 2570,
  isActive: 'yes',
  childName: 'Fakhraddin',
  childSurname: 'Alizade',
);

AuthUser _parent({int? id, required List<ChildAccount> children}) => AuthUser(
      id: id,
      name: 'Ceyhun Alizade',
      childName: '',
      role: 'parent',
      email: 'parent@bsb.edu.az',
      children: children,
    );

/// A parent session answering `/detachChild` the way the backend does — a
/// 422 on `password` unless it is [_rightPassword] — and `/attachChild` by
/// linking one more student.
class _ParentRepository implements AuthRepository {
  AuthUser _user;
  _ParentRepository(this._user);

  final detachAttempts = <String>[];
  final attached = <String>[];

  @override
  bool get isLoggedIn => true;

  @override
  AuthUser? get currentUser => _user;

  @override
  ChildAccount? get activeChild {
    for (final child in _user.children) {
      if (child.childId == _user.id) return child;
    }
    return _user.children.isEmpty ? null : _user.children.first;
  }

  @override
  Future<Either<Failure, Unit>> detachChild({
    required int childId,
    required String password,
  }) async {
    detachAttempts.add(password);
    if (password != _rightPassword) {
      return const Left(FieldValidationFailure(
        {'password': _wrongPasswordMessage},
        _wrongPasswordMessage,
      ));
    }
    final remaining =
        _user.children.where((c) => c.childId != childId).toList();
    _user = _parent(
      id: remaining.isEmpty
          ? null
          : (_user.id == childId ? remaining.first.childId : _user.id),
      children: remaining,
    );
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> attachChild({
    required String admissionNo,
    String? relation,
  }) async {
    attached.add(admissionNo);
    const added = ChildAccount(
      childId: 4021,
      isActive: 'yes',
      childName: 'Nigar',
      childSurname: 'Alizade',
    );
    _user = _parent(
      id: _user.id ?? added.childId,
      children: [..._user.children, added],
    );
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> selectChild(int childId) async =>
      const Right(unit);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _profile(_ParentRepository repository) {
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

  /// The default test width (the test font's square glyphs overflow the
  /// section headers on anything narrower), tall enough for the sheets to fit
  /// without scrolling.
  void useTallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Finder inSheet(Finder matching) =>
      find.descendant(of: find.byType(BottomSheet), matching: matching);

  /// Trash icon on [name]'s card → password → "Sil".
  Future<void> deleteWithPassword(
    WidgetTester tester, {
    required String name,
    required String password,
  }) async {
    await tester.tap(find.byTooltip(l10n.childDeleteTitle).first);
    await tester.pumpAndSettle();
    expect(find.text(l10n.childDeleteText(name)), findsOneWidget);

    await tester.enterText(inSheet(find.byType(TextField)), password);
    await tester.tap(find.text(l10n.commonDelete));
    await tester.pumpAndSettle();
  }

  testWidgets('a wrong password keeps the student and the sheet',
      (tester) async {
    useTallScreen(tester);
    final repository = _ParentRepository(
      _parent(id: 2570, children: [_rashad, _fakhraddin]),
    );
    await tester.pumpWidget(_profile(repository));
    await tester.pumpAndSettle();

    await deleteWithPassword(tester, name: 'Rashad Ali', password: 'wrong');

    expect(repository.detachAttempts, ['wrong']);
    expect(find.text(_wrongPasswordMessage), findsOneWidget);
    expect(find.text(l10n.childDeleteText('Rashad Ali')), findsOneWidget);
    expect(find.byType(AddChildSheet), findsNothing);
    expect(repository.currentUser?.children, hasLength(2));
  });

  testWidgets(
      'after a removal the add sheet stays up until a student is linked',
      (tester) async {
    useTallScreen(tester);
    final repository = _ParentRepository(
      _parent(id: 2570, children: [_rashad, _fakhraddin]),
    );
    await tester.pumpWidget(_profile(repository));
    await tester.pumpAndSettle();

    await deleteWithPassword(
      tester,
      name: 'Rashad Ali',
      password: _rightPassword,
    );

    expect(repository.currentUser?.children, [_fakhraddin]);
    expect(find.byType(AddChildSheet), findsOneWidget);
    expect(find.text(l10n.addChildRequiredText), findsOneWidget);

    // Neither a tap outside nor the back button takes it down.
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.byType(AddChildSheet), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(AddChildSheet), findsOneWidget);

    await tester.enterText(inSheet(find.byType(TextField)), 'BSB-4021');
    await tester.tap(find.text(l10n.addChildSubmit));
    await tester.pumpAndSettle();

    expect(repository.attached, ['BSB-4021']);
    expect(find.byType(AddChildSheet), findsNothing);
  });

  // With no student left, AuthGate swaps in AddChildScreen — the sheet is not
  // stacked on top of it.
  testWidgets('removing the last student opens no sheet of its own',
      (tester) async {
    useTallScreen(tester);
    final repository = _ParentRepository(
      _parent(id: 3139, children: [_rashad]),
    );
    await tester.pumpWidget(_profile(repository));
    await tester.pumpAndSettle();

    await deleteWithPassword(
      tester,
      name: 'Rashad Ali',
      password: _rightPassword,
    );

    expect(repository.currentUser?.needsChild, isTrue);
    expect(find.byType(AddChildSheet), findsNothing);
  });
}
