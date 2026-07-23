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
    _Tab(DrNavDestination(Icons.home_rounded, 'Home'), DashboardScreen()),
    _Tab(DrNavDestination(Icons.badge_outlined, 'Food Card'), FoodCardScreen()),
    _Tab(
      DrNavDestination(Icons.receipt_long_outlined, 'Tuition'),
      TuitionScreen(),
      parentOnly: true,
    ),
    _Tab(
      DrNavDestination(Icons.notifications_none_rounded, 'Notifs'),
      NotificationsScreen(),
    ),
    _Tab(DrNavDestination(Icons.person_outline_rounded, 'Pass'), PassScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final isParent = context.select<AuthBloc, bool>(
      (bloc) => bloc.state.user?.isParent ?? false,
    );
    final tabs = _allTabs.where((t) => isParent || !t.parentOnly).toList();
    // Role is stable within a session, but clamp so a shrunk tab list can never
    // leave `_index` pointing past the end.
    final index = _index.clamp(0, tabs.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: [for (final t in tabs) t.screen],
      ),
      bottomNavigationBar: DrBottomNav(
        currentIndex: index,
        items: [for (final t in tabs) t.destination],
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
