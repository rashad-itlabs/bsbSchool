import 'package:flutter/material.dart';

import '../../widgets/dr_bottom_nav.dart';
import 'attendance_screen.dart';
import 'dashboard.dart';
import 'homework_screen.dart';
import 'settings_screen.dart';
import 'timetable_screen.dart';

/// Teacher counterpart of `HomeShell` — hosts the 5 tabs of the teacher portal
/// behind the persistent [DrBottomNav]. Mounted by `AuthGate` when the signed-in
/// user's role is `teacher`.
class TeacherShell extends StatefulWidget {
  const TeacherShell({super.key});

  @override
  State<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends State<TeacherShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      TeacherDashboardScreen(onNavigate: (i) => setState(() => _index = i)),
      const TeacherTimetableScreen(),
      const TeacherAttendanceScreen(),
      const TeacherHomeworkScreen(),
      const TeacherSettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: DrBottomNav(
        currentIndex: _index,
        items: DrBottomNav.teacherDestinations,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
