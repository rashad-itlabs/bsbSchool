import 'package:flutter/material.dart';

import '../../../../dr/screens/homework_screen.dart';

/// Route entry for the homework list. The UI itself lives in [HomeworkScreen]
/// with the rest of the `dr` design system; this keeps the feature's public
/// entry point where the other features have theirs.
class HomeworkPage extends StatelessWidget {
  const HomeworkPage({super.key});

  @override
  Widget build(BuildContext context) => const HomeworkScreen();
}
