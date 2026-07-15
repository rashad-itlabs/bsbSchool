import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection_container.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'dr/screens/home_shell.dart';
import 'dr/screens/login_screen.dart';
import 'dr/theme/dr_theme.dart';
import 'dr/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  await ThemeController.instance.load();
  runApp(const BsbSchoolApp());
}

class BsbSchoolApp extends StatelessWidget {
  const BsbSchoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (_) => sl<AuthBloc>()..add(const AuthCheckRequested()),
      child: AnimatedBuilder(
        animation: ThemeController.instance,
        builder: (context, _) {
          return MaterialApp(
            title: 'BSB School',
            debugShowCheckedModeBanner: false,
            theme: DrTheme.light,
            darkTheme: DrTheme.dark,
            themeMode: ThemeController.instance.mode,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

/// Switches between the login screen and the app based on [AuthBloc] state.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (p, c) => p.status != c.status,
      builder: (context, state) {
        switch (state.status) {
          case AuthStatus.authenticated:
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
