import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../widgets/dr_bottom_nav.dart';
import 'dashboard_screen.dart';
import 'food_card_screen.dart';
import 'notifications_screen.dart';
import 'pass_screen.dart';
import 'tuition_screen.dart';

/// One primary tab: its nav destination and the screen behind it.
class _Tab {
  final DrNavDestination destination;
  final Widget screen;

  /// Tuition is parent-only — a student account never sees it.
  final bool parentOnly;

  const _Tab(this.destination, this.screen, {this.parentOnly = false});
}

/// Hosts the primary tabs behind the persistent [DrBottomNav].
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _allTabs = <_Tab>[
    _Tab(DrNavDestination(Icons.home_rounded, DrNavLabel.home), DashboardScreen()),
    _Tab(
      DrNavDestination(Icons.badge_outlined, DrNavLabel.foodCard),
      FoodCardScreen(),
    ),
    _Tab(
      DrNavDestination(Icons.receipt_long_outlined, DrNavLabel.tuition),
      TuitionScreen(),
      parentOnly: true,
    ),
    _Tab(
      DrNavDestination(Icons.notifications_none_rounded, DrNavLabel.notifications),
      NotificationsScreen(),
    ),
    _Tab(
      DrNavDestination(Icons.person_outline_rounded, DrNavLabel.profile),
      PassScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isParent = context.select<AuthBloc, bool>(
      (bloc) => bloc.state.user?.isParent ?? false,
    );
    // Tabs sit in an IndexedStack, so they stay mounted with the blocs they
    // created on first build. Keying the stack by the active student throws
    // that state away when the parent switches — every screen remounts and
    // refetches, this time scoped to the new `student_id` / `class_id`.
    final activeChildId = context.select<AuthBloc, int?>(
      (bloc) => bloc.state.activeChild?.childId,
    );
    final tabs = _allTabs.where((t) => isParent || !t.parentOnly).toList();
    // Role is stable within a session, but clamp so a shrunk tab list can never
    // leave `_index` pointing past the end.
    final index = _index.clamp(0, tabs.length - 1);

    // A rejected switch (`/selectChild` refused the student, or the network
    // dropped) leaves the app on the student it already had — say so once,
    // here, rather than in each of the two places that can start a switch.
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (p, c) =>
          c.childSwitchError != null && c.childSwitchError != p.childSwitchError,
      listener: (context, state) => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(state.childSwitchError!))),
      child: Scaffold(
        body: IndexedStack(
          key: ValueKey(activeChildId),
          index: index,
          children: [for (final t in tabs) t.screen],
        ),
        bottomNavigationBar: DrBottomNav(
          currentIndex: index,
          items: [for (final t in tabs) t.destination],
          onTap: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}
