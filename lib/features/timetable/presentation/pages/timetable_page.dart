import 'package:flutter/material.dart';

import '../../../../dr/screens/timetable_screen.dart';

/// Route entry for the class timetable. The UI itself lives in
/// [TimetableScreen] with the rest of the `dr` design system; this keeps the
/// feature's public entry point where the other features have theirs.
class TimetablePage extends StatelessWidget {
  const TimetablePage({super.key});

  @override
  Widget build(BuildContext context) => const TimetableScreen();
}
