import 'package:bsbschool/core/error/failures.dart';
import 'package:bsbschool/dr/theme/dr_theme.dart';
import 'package:bsbschool/dr/widgets/child_switcher.dart';
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

const _current = ChildAccount(
  childId: 3139,
  childName: 'Rashad',
  childSurname: 'Ali',
  className: 'Class Group 7',
  isActive: 'yes',
);

const _otherActive = ChildAccount(
  childId: 3158,
  childName: 'Melek',
  childSurname: 'Chalabi',
  className: 'Class Group 8',
  isActive: 'yes',
);

const _inactive = ChildAccount(
  childId: 2570,
  childName: 'Fakhraddin',
  childSurname: 'Alizade',
  className: 'Class Group 10',
  isActive: 'no',
);

/// A parent with three students, one of them made inactive by the school.
/// Records every `/selectChild` the switcher asks for.
class _ParentRepository implements AuthRepository {
  final selected = <int>[];

  @override
  bool get isLoggedIn => true;

  @override
  AuthUser? get currentUser => AuthUser(
        id: _current.childId,
        name: 'Ceyhun Alizade',
        childName: _current.fullName,
        role: 'parent',
        email: 'parent@bsb.edu.az',
        children: const [_current, _otherActive, _inactive],
      );

  @override
  ChildAccount? get activeChild => _current;

  @override
  Future<Either<Failure, Unit>> selectChild(int childId) async {
    selected.add(childId);
    return const Right(unit);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _ParentRepository repository;
  final l10n = lookupAppL10n(const Locale('az'));

  /// The dashboard header's avatar, as a signed-in parent sees it.
  Future<void> pumpSwitcher(WidgetTester tester) async {
    repository = _ParentRepository();
    final auth = AuthBloc(
      loginUser: LoginUser(repository),
      logoutUser: LogoutUser(repository),
      repository: repository,
    )..add(const AuthCheckRequested());
    await auth.stream.first;
    addTearDown(auth.close);

    await tester.pumpWidget(BlocProvider<AuthBloc>.value(
      value: auth,
      child: MaterialApp(
        theme: DrTheme.dark,
        locale: const Locale('az'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: Scaffold(
          body: Center(
            child: ChildSwitcher(name: _current.fullName, enabled: true),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> pick(WidgetTester tester, ChildAccount child) async {
    await tester.tap(find.byType(ChildSwitcher));
    await tester.pumpAndSettle();
    await tester.tap(find.text(child.fullName));
    await tester.pumpAndSettle();
  }

  testWidgets('an inactive student is not switched to — an alert says why',
      (tester) async {
    await pumpSwitcher(tester);

    await pick(tester, _inactive);

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(l10n.attention), findsOneWidget);
    expect(find.text(l10n.childIsNotActive), findsOneWidget);
    expect(repository.selected, isEmpty);

    await tester.tap(find.text(l10n.close));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(repository.selected, isEmpty);
  });

  testWidgets('an active student is switched to, as before', (tester) async {
    await pumpSwitcher(tester);

    await pick(tester, _otherActive);

    expect(find.byType(AlertDialog), findsNothing);
    expect(repository.selected, [_otherActive.childId]);
  });
}
