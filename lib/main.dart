import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/di/injection_container.dart';
import 'core/l10n/l10n.dart';
import 'core/l10n/locale_controller.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/notifications/presentation/notification_prefs.dart';
import 'dr/screens/add_child_screen.dart';
import 'dr/screens/home_shell.dart';
import 'dr/screens/login_screen.dart';
import 'dr/screens/teacher/teacher_shell.dart';
import 'dr/theme/dr_theme.dart';
import 'dr/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Month and weekday names for every language the app ships.
  await initializeDateFormatting();
  await initDependencies();
  await ThemeController.instance.load();
  await LocaleController.instance.load();
  await NotificationPrefs.instance.load();
  runApp(const BsbSchoolApp());
}

class BsbSchoolApp extends StatelessWidget {
  const BsbSchoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (_) => sl<AuthBloc>()..add(const AuthCheckRequested()),
      child: AnimatedBuilder(
        animation: Listenable.merge([
          ThemeController.instance,
          LocaleController.instance,
        ]),
        builder: (context, _) {
          return MaterialApp(
            onGenerateTitle: (context) => context.l10n.appTitle,
            debugShowCheckedModeBanner: false,
            theme: DrTheme.light,
            darkTheme: DrTheme.dark,
            themeMode: ThemeController.instance.mode,
            // null hands the choice to the device; `localeResolutionCallback`
            // then closes the list with Azerbaijani rather than English.
            locale: LocaleController.instance.locale,
            supportedLocales: AppL10n.supportedLocales,
            localizationsDelegates: AppL10n.localizationsDelegates,
            localeResolutionCallback: (device, supported) {
              return LocaleController.instance.resolve([?device]);
            },
            home: const _L10nBridge(child: AuthGate()),
          );
        },
      ),
    );
  }
}

/// Keeps [L] pointed at the translations now on screen, so services and
/// repositories can word their errors in the language the parent chose.
class _L10nBridge extends StatelessWidget {
  final Widget child;

  const _L10nBridge({required this.child});

  @override
  Widget build(BuildContext context) {
    L.current = AppL10n.of(context);
    return child;
  }
}

/// Switches between the login screen and the app based on [AuthBloc] state.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (p, c) =>
          p.status != c.status ||
          p.user?.isTeacher != c.user?.isTeacher ||
          p.user?.needsChild != c.user?.needsChild,
      builder: (context, state) {
        switch (state.status) {
          case AuthStatus.authenticated:
            final user = state.user;
            if (user?.isTeacher ?? false) return const TeacherShell();
            // A parent with no student linked yet has nothing to show in the
            // dashboard — collect an admission number first.
            if (user?.needsChild ?? false) return const AddChildScreen();
            return const HomeShell();
          case AuthStatus.unknown:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          case AuthStatus.loading:
          case AuthStatus.unauthenticated:
            return const LoginScreen();
        }
      },
    );
  }
}
