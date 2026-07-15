import 'package:flutter/material.dart';

import '../../../../dr/screens/examinations_screen.dart';

/// Route entry for the exam results. The UI itself lives in
/// [ExaminationsScreen] with the rest of the `dr` design system; this keeps the
/// feature's public entry point where the other features have theirs.
class ExaminationPage extends StatelessWidget {
  const ExaminationPage({super.key});

  @override
  Widget build(BuildContext context) => const ExaminationsScreen();
}
