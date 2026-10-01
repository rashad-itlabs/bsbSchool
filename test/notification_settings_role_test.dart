import 'package:bsbschool/dr/theme/dr_theme.dart';
import 'package:bsbschool/features/auth/domain/entities/auth_user.dart';
import 'package:bsbschool/features/auth/domain/entities/child_account.dart';
import 'package:bsbschool/features/auth/domain/repositories/auth_repository.dart';
import 'package:bsbschool/features/auth/domain/usecases/login_user.dart';
import 'package:bsbschool/features/auth/domain/usecases/logout_user.dart';
import 'package:bsbschool/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bsbschool/features/notifications/presentation/widgets/notification_settings_card.dart';
import 'package:bsbschool/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// A restored session for [user]. Restoring only reads these three members;
/// anything else the bloc touched would fail loudly through noSuchMethod.
class _SignedInRepository implements AuthRepository {
  final AuthUser user;
  _SignedInRepository(this.user);

  @override
  bool get isLoggedIn => true;

  @override
  AuthUser? get currentUser => user;

  @override
  ChildAccount? get activeChild => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _card(String role) {
  final repository = _SignedInRepository(AuthUser(
    id: 3789,
    name: 'Said Aliyev',
    childName: 'Said Aliyev',
    role: role,
    email: 'said@bsb.edu.az',
  ));
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
      home: const Scaffold(body: NotificationSettingsCard()),
    ),
  );
}

void main() {
  final l10n = lookupAppL10n(const Locale('az'));

  testWidgets('a student is offered the homework switch only', (tester) async {
    await tester.pumpWidget(_card('student'));
    await tester.pumpAndSettle();

    expect(find.text(l10n.notifPrefHomework), findsOneWidget);
    expect(find.text(l10n.notifPrefAttendance), findsNothing);
    expect(find.text(l10n.notifPrefBuffet), findsNothing);
    expect(find.text(l10n.notifPrefExams), findsNothing);
  });

  testWidgets('a parent gets every switch except homework', (tester) async {
    await tester.pumpWidget(_card('parent'));
    await tester.pumpAndSettle();

    expect(find.text(l10n.notifPrefAttendance), findsOneWidget);
    expect(find.text(l10n.notifPrefBuffet), findsOneWidget);
    expect(find.text(l10n.notifPrefExams), findsOneWidget);
    expect(find.text(l10n.notifPrefHomework), findsNothing);
  });
}
