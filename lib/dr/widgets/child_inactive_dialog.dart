import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';

/// Tells the parent why a student can't be switched to: the school has made
/// them inactive (`is_active == 'no'`).
///
/// Shared by both ways into the switch — the dashboard avatar's dropdown and
/// the student cards on the profile tab — so the two always say the same.
Future<void> showChildInactiveDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(dialogContext.l10n.attention),
      content: Text(dialogContext.l10n.childIsNotActive),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(dialogContext.l10n.close),
        ),
      ],
    ),
  );
}
