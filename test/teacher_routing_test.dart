import 'dart:convert';

import 'package:bsbschool/core/error/failures.dart';
import 'package:bsbschool/core/storage/user_storage.dart';
import 'package:bsbschool/dr/screens/add_child_screen.dart';
import 'package:bsbschool/dr/screens/home_shell.dart';
import 'package:bsbschool/dr/screens/login_screen.dart';
import 'package:bsbschool/dr/screens/teacher/teacher_shell.dart';
import 'package:bsbschool/dr/theme/dr_theme.dart';
import 'package:bsbschool/features/auth/domain/entities/auth_session.dart';
import 'package:bsbschool/features/auth/domain/entities/auth_user.dart';
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

/// Stands in for the network: [cached] is the restored session (null = logged
/// out) and [loginResult] is who the login endpoint hands back.
class _FakeAuthRepository implements AuthRepository {
  AuthUser? _user;
  final AuthUser? loginResult;

  _FakeAuthRepository({AuthUser? cached, this.loginResult}) : _user = cached;

  @override
  bool get isLoggedIn => _user != null;

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<Either<Failure, AuthSession>> login({
    required String email,
    required String password,
  }) async {
    _user = loginResult;
    return Right(AuthSession(token: '1|abc', user: loginResult!));
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    _user = null;
    return const Right(unit);
  }
}

AuthUser _user({required String role, int? id = 4108}) => AuthUser(
      id: id,
      name: 'Elena Borisovna',
      childName: '',
      role: role,
      email: 'teacher@bsb.edu.az',
    );

Widget _gate(_FakeAuthRepository repository) {
  return BlocProvider<AuthBloc>(
    create: (_) => AuthBloc(
      loginUser: LoginUser(repository),
      logoutUser: LogoutUser(repository),
      repository: repository,
    )..add(const AuthCheckRequested()),
    child: MaterialApp(theme: DrTheme.dark, home: const AuthGate()),
  );
}

/// The teacher portal is on screen: its own nav, and its own pages.
void _expectTeacherPortal() {
  expect(find.byType(TeacherShell), findsOneWidget);

  // The teacher's bottom nav, not the student's.
  expect(find.text('TIMETABLE'), findsOneWidget);
  expect(find.text('ATTENDANCE'), findsOneWidget);
  expect(find.text('FOOD CARD'), findsNothing);
  expect(find.text('TUITION'), findsNothing);

  // The teacher's dashboard, not the student's.
  expect(find.text('Welcome back,'), findsOneWidget);
  expect(find.text('Task Management'), findsOneWidget);
  expect(find.text('Good morning,'), findsNothing);
}

void main() {
  group('AuthUser.isTeacher', () {
    test('matches the teacher role regardless of case or padding', () {
      for (final role in ['teacher', 'Teacher', 'TEACHER', '  teacher ']) {
        expect(_user(role: role).isTeacher, isTrue, reason: role);
      }
    });

    test('treats every other role as a non-teacher account', () {
      for (final role in ['student', 'parent', 'admin', '', 'teachers']) {
        expect(_user(role: role).isTeacher, isFalse, reason: role);
      }
    });
  });

  testWidgets('logging in as a teacher swaps the nav and the pages', (
    tester,
  ) async {
    await tester.pumpWidget(
      _gate(_FakeAuthRepository(loginResult: _user(role: 'teacher'))),
    );
    await tester.pumpAndSettle();

    // Starts logged out.
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(TeacherShell), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'teacher@bsb.edu.az');
    await tester.enterText(find.byType(TextField).at(1), 'secret');
    await tester.tap(find.text('Daxil ol'));
    await tester.pumpAndSettle();

    _expectTeacherPortal();
  });

  testWidgets('a restored teacher session opens the teacher portal', (
    tester,
  ) async {
    await tester.pumpWidget(
      _gate(_FakeAuthRepository(cached: _user(role: 'teacher'))),
    );
    await tester.pumpAndSettle();

    _expectTeacherPortal();
  });

  testWidgets('every teacher tab renders', (tester) async {
    await tester.pumpWidget(
      _gate(_FakeAuthRepository(cached: _user(role: 'teacher'))),
    );
    await tester.pumpAndSettle();

    for (final (label, heading) in const [
      ('TIMETABLE', 'Weekly Timetable'),
      ('ATTENDANCE', 'Student Attendance'),
      ('HOMEWORK', 'Assign Homework'),
      ('SETTINGS', 'Settings'),
    ]) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(find.text(heading), findsWidgets, reason: heading);
    }
  });

  group('a parent with no student linked', () {
    testWidgets('logging in lands on AddChildScreen, not the dashboard', (
      tester,
    ) async {
      await tester.pumpWidget(
        _gate(
          _FakeAuthRepository(loginResult: _user(role: 'parent', id: null)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'parent@bsb.edu.az');
      await tester.enterText(find.byType(TextField).at(1), 'secret');
      await tester.tap(find.text('Daxil ol'));
      await tester.pumpAndSettle();

      expect(find.byType(AddChildScreen), findsOneWidget);
      expect(find.byType(HomeShell), findsNothing);
      expect(find.byType(TeacherShell), findsNothing);
      expect(find.text('Şagirdinizi əlavə edin'), findsOneWidget);
    });

    testWidgets('a restored unlinked session reopens AddChildScreen', (
      tester,
    ) async {
      await tester.pumpWidget(
        _gate(_FakeAuthRepository(cached: _user(role: 'parent', id: null))),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AddChildScreen), findsOneWidget);
    });

    testWidgets('submitting an empty admission number is rejected', (
      tester,
    ) async {
      await tester.pumpWidget(
        _gate(_FakeAuthRepository(cached: _user(role: 'parent', id: null))),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Əlavə et'));
      await tester.pumpAndSettle();

      expect(find.text('Qəbul nömrəsini daxil edin'), findsOneWidget);
    });

    testWidgets('the parent can sign out instead of being trapped', (
      tester,
    ) async {
      await tester.pumpWidget(
        _gate(_FakeAuthRepository(cached: _user(role: 'parent', id: null))),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Başqa hesabla daxil ol'));
      await tester.tap(find.text('Başqa hesabla daxil ol'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Çıxış'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(AddChildScreen), findsNothing);
    });
  });

  // Parent-only: everyone else keeps their existing shell. A linked parent
  // routes to HomeShell, which needs the DI container, so that half is covered
  // by the `needsChild` tests in auth_user_model_test.dart instead.
  testWidgets('a teacher without an id never sees AddChildScreen', (
    tester,
  ) async {
    await tester.pumpWidget(
      _gate(_FakeAuthRepository(cached: _user(role: 'teacher', id: null))),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AddChildScreen), findsNothing);
    _expectTeacherPortal();
  });

  group('cached session', () {
    Future<UserStorageImpl> storageWith(Map<String, dynamic> user) async {
      SharedPreferences.setMockInitialValues({'auth_user': jsonEncode(user)});
      return UserStorageImpl(await SharedPreferences.getInstance());
    }

    test('a cache written before role was persisted is discarded', () async {
      // Exactly what the old toJson() wrote — note the absent `role`.
      final storage = await storageWith({
        'id': 4108,
        'name': 'Elena Borisovna',
        'child_name': '',
        'email': 'teacher@bsb.edu.az',
        'class_id': null,
        'className': null,
      });

      // Null => AuthRepositoryImpl.isLoggedIn is false => sign in again,
      // rather than silently restoring a teacher into the student portal.
      expect(storage.cachedUser, isNull);
    });

    test('a cache holding a role is restored intact', () async {
      final storage = await storageWith({
        'id': 4108,
        'name': 'Elena Borisovna',
        'child_name': '',
        'role': 'teacher',
        'email': 'teacher@bsb.edu.az',
      });

      expect(storage.cachedUser?.isTeacher, isTrue);
    });
  });
}
