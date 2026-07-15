import 'package:flutter/material.dart';

import '../theme/dr_colors.dart';

class DrNavDestination {
  final IconData icon;
  final String label;
  const DrNavDestination(this.icon, this.label);
}

/// `.bottom-nav` — blurred dark bar with 5 destinations.
class DrBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const DrBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const destinations = <DrNavDestination>[
    DrNavDestination(Icons.home_rounded, 'Home'),
    DrNavDestination(Icons.badge_outlined, 'Food Card'),
    DrNavDestination(Icons.receipt_long_outlined, 'Tuition'),
    DrNavDestination(Icons.notifications_none_rounded, 'Notifs'),
    DrNavDestination(Icons.person_outline_rounded, 'Pass'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.dr.nav,
        border: Border(top: BorderSide(color: context.dr.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
          child: Row(
            children: List.generate(destinations.length, (i) {
              final active = i == currentIndex;
              final color = active ? context.dr.textMain : context.dr.textMuted;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(destinations[i].icon, size: 22, color: color),
                      const SizedBox(height: 5),
                      Text(
                        destinations[i].label.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 0.4,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
