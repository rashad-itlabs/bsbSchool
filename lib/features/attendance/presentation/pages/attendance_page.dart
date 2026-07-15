import 'package:flutter/material.dart';

import '../../../../dr/screens/attendance_screen.dart';

/// Route entry for the attendance history. The UI itself lives in
/// [AttendanceScreen] with the rest of the `dr` design system; this keeps the
/// feature's public entry point where the other features have theirs.
class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context) => const AttendanceScreen();
}
