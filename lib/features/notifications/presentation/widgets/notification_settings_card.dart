import 'package:flutter/material.dart';

import '../../../../dr/theme/dr_colors.dart';
import '../../../../dr/widgets/dr_widgets.dart';
import '../notification_prefs.dart';

/// The "Bildiriş parametrləri" card — one row per [NotificationKind]. Shared by
/// the notifications tab and the profile screen, both of which drive the same
/// [NotificationPrefs], so a switch flipped on one is already flipped on the
/// other. The section header stays at the call site.
class NotificationSettingsCard extends StatelessWidget {
  const NotificationSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final kinds = NotificationKind.values;

    return AnimatedBuilder(
      animation: NotificationPrefs.instance,
      builder: (context, _) => DrListCard(
        children: [
          for (var i = 0; i < kinds.length; i++)
            _SettingRow(kind: kinds[i], last: i == kinds.length - 1),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final NotificationKind kind;
  final bool last;

  const _SettingRow({required this.kind, required this.last});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border:
            last ? null : Border(bottom: BorderSide(color: context.dr.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(kind.emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kind.title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(kind.subtitle,
                    style: TextStyle(fontSize: 12, color: context.dr.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          DrSwitch(
            value: NotificationPrefs.instance.isEnabled(kind),
            onChanged: (v) => NotificationPrefs.instance.setEnabled(kind, v),
          ),
        ],
      ),
    );
  }
}
