import 'package:flutter/material.dart';

import '../../../../dr/screens/library_screen.dart';

/// Route entry for the library. The UI itself lives in [LibraryScreen] with
/// the rest of the `dr` design system; this keeps the feature's public entry
/// point where the other features have theirs.
class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) => const LibraryScreen();
}
