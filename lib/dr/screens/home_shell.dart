import 'package:flutter/material.dart';

import '../widgets/dr_bottom_nav.dart';
import 'dashboard_screen.dart';
import 'food_card_screen.dart';
import 'notifications_screen.dart';
import 'pass_screen.dart';
import 'tuition_screen.dart';

/// Hosts the 5 primary tabs behind the persistent [DrBottomNav].
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = <Widget>[
    DashboardScreen(),
    FoodCardScreen(),
    TuitionScreen(),
    NotificationsScreen(),
    PassScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: DrBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
