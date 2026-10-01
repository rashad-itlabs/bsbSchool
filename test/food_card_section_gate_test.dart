import 'package:bsbschool/core/di/injection_container.dart';
import 'package:bsbschool/dr/screens/food_card_screen.dart';
import 'package:bsbschool/dr/theme/dr_theme.dart';
import 'package:bsbschool/features/auth/data/models/auth_user_model.dart';
import 'package:bsbschool/features/auth/data/models/child_account_model.dart';
import 'package:bsbschool/features/auth/domain/entities/auth_user.dart';
import 'package:bsbschool/features/auth/domain/entities/child_account.dart';
import 'package:bsbschool/features/auth/domain/repositories/auth_repository.dart';
import 'package:bsbschool/features/auth/domain/usecases/login_user.dart';
import 'package:bsbschool/features/auth/domain/usecases/logout_user.dart';
import 'package:bsbschool/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bsbschool/features/buffet_cart/data/models/buffet_card_content_model.dart';
import 'package:bsbschool/features/buffet_cart/data/services/buffet_card_service.dart';
import 'package:bsbschool/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CountingCardService implements BuffetCardService {
  var calls = 0;

  @override
  Future<BuffetCardContentModel> getBuffetCard({int? studentId}) async {
    calls++;
    return BuffetCardContentModel.fromJson({'card': []});
  }
}

/// A parent signed in with [child] as the active student.
class _ParentRepository implements AuthRepository {
  final ChildAccount child;
  _ParentRepository(this.child);

  @override
  bool get isLoggedIn => true;

  @override
  AuthUser? get currentUser => AuthUser(
        id: child.childId,
        name: 'Rəşad Əliyev',
        childName: child.fullName,
        role: 'parent',
        email: 'parent@bsb.edu.az',
        children: [child],
      );

  @override
  ChildAccount? get activeChild => child;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A student signed in on their own: no children list, their own section.
class _StudentRepository implements AuthRepository {
  final String categories;
  _StudentRepository(this.categories);

  @override
  bool get isLoggedIn => true;

  @override
  AuthUser? get currentUser => AuthUser(
        id: 3789,
        name: 'Said Aliyev',
        childName: 'Said Aliyev',
        role: 'student',
        email: 'std_3789@bsb.edu.az',
        categories: categories,
      );

  @override
  ChildAccount? get activeChild => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The tab as the app reaches it: AuthGate only shows the home shell once
/// the session is restored, so the active child is already known.
Future<Widget> _tab(String categories, {bool student = false}) async {
  final AuthRepository repository = student
      ? _StudentRepository(categories)
      : _ParentRepository(ChildAccount(
          childId: 3789,
          childName: 'Said',
          categories: categories,
        ));
  final auth = AuthBloc(
    loginUser: LoginUser(repository),
    logoutUser: LogoutUser(repository),
    repository: repository,
  )..add(const AuthCheckRequested());
  await auth.stream.first;

  return BlocProvider<AuthBloc>.value(
    value: auth,
    child: MaterialApp(
      theme: DrTheme.dark,
      locale: const Locale('az'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: const FoodCardScreen(),
    ),
  );
}

void main() {
  group('categories', () {
    test('is read from an info entry and kept with the saved session', () {
      final child = ChildAccountModel.fromJson({
        'child_id': 3789,
        'child_name': 'Said',
        'categories': 'secondary',
      });
      expect(child.categories, 'secondary');

      // Saved and restored the way the session storage does it.
      final user = AuthUserModel.fromJson(AuthUserModel(
        id: 3789,
        name: 'Rəşad',
        childName: 'Said',
        role: 'parent',
        email: 'p@bsb.edu.az',
        children: [child],
      ).toJson());
      expect(user.children.single.categories, 'secondary');
    });

    test('a student login carries its own, at the top level', () {
      final user = AuthUserModel.fromJson({
        'user_id': 3789,
        'name': 'Said Aliyev',
        'role': 'student',
        'class_name': 'Year 3',
        'categories': 'primary',
      });
      expect(user.categories, 'primary');
      expect(user.isBelowBuffetAge, isTrue);

      // Kept with the saved session.
      expect(AuthUserModel.fromJson(user.toJson()).categories, 'primary');
    });

    test('only a known section other than secondary is below buffet age', () {
      bool below(String c) => ChildAccount(categories: c).isBelowBuffetAge;
      expect(below('secondary'), isFalse);
      expect(below(' Secondary '), isFalse);
      expect(below('primary'), isTrue);
      expect(below('early_years'), isTrue);
      // Unknown — a session saved before the field existed.
      expect(below(''), isFalse);
    });
  });

  group('the food card tab', () {
    late _CountingCardService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await sl.reset();
      await initDependencies();
      service = _CountingCardService();
      sl.unregister<BuffetCardService>();
      sl.registerLazySingleton<BuffetCardService>(() => service);
    });

    final l10n = lookupAppL10n(const Locale('az'));

    testWidgets('tells a younger child it opens in the upper grades',
        (tester) async {
      await tester.pumpWidget(await _tab('primary'));
      await tester.pumpAndSettle();

      expect(find.text(l10n.foodCardUpperGradesOnly), findsOneWidget);
      // No card to show, so nothing is asked of the server.
      expect(service.calls, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('loads the card as before for a secondary child',
        (tester) async {
      await tester.pumpWidget(await _tab('secondary'));
      await tester.pumpAndSettle();

      expect(service.calls, 1);
      expect(find.text(l10n.foodCardUpperGradesOnly), findsNothing);
    });

    testWidgets('a younger student on their own login gets the same note',
        (tester) async {
      await tester.pumpWidget(await _tab('primary', student: true));
      await tester.pumpAndSettle();

      expect(find.text(l10n.foodCardUpperGradesOnly), findsOneWidget);
      expect(service.calls, 0);
    });

    testWidgets('a secondary student on their own login gets the card',
        (tester) async {
      await tester.pumpWidget(await _tab('secondary', student: true));
      await tester.pumpAndSettle();

      expect(service.calls, 1);
      expect(find.text(l10n.foodCardUpperGradesOnly), findsNothing);
    });

    testWidgets('loads the card when the section is unknown', (tester) async {
      await tester.pumpWidget(await _tab(''));
      await tester.pumpAndSettle();

      expect(service.calls, 1);
      expect(find.text(l10n.foodCardUpperGradesOnly), findsNothing);
    });
  });
}
