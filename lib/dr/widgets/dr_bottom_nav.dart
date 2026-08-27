import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../theme/dr_colors.dart';

/// Which tab a destination is. The label itself is looked up at build time so
/// the bar follows a language switch — a `String` here would freeze whatever
/// language was loaded when the const list was created.
enum DrNavLabel {
  home,
  foodCard,
  tuition,
  notifications,
  profile,
  timetable,
  attendance,
  homework,
  settings;

  String of(AppL10n l10n) => switch (this) {
    DrNavLabel.home => l10n.navHome,
    DrNavLabel.foodCard => l10n.navFoodCard,
    DrNavLabel.tuition => l10n.navTuition,
    DrNavLabel.notifications => l10n.navNotifications,
    DrNavLabel.profile => l10n.navProfile,
    DrNavLabel.timetable => l10n.navTimetable,
    DrNavLabel.attendance => l10n.navAttendance,
    DrNavLabel.homework => l10n.navHomework,
    DrNavLabel.settings => l10n.navSettings,
  };
}

class DrNavDestination {
  final IconData icon;
  final DrNavLabel label;
  const DrNavDestination(this.icon, this.label);
}

/// `.bottom-nav` — blurred dark bar with 5 destinations.
class DrBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Defaults to the student/parent tabs; the teacher shell passes its own.
  final List<DrNavDestination> items;

  const DrBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items = destinations,
  });

  static const destinations = <DrNavDestination>[
    DrNavDestination(Icons.home_rounded, DrNavLabel.home),
    DrNavDestination(Icons.badge_outlined, DrNavLabel.foodCard),
    DrNavDestination(Icons.receipt_long_outlined, DrNavLabel.tuition),
    DrNavDestination(Icons.notifications_none_rounded, DrNavLabel.notifications),
    DrNavDestination(Icons.person_outline_rounded, DrNavLabel.profile),
  ];

  static const teacherDestinations = <DrNavDestination>[
    DrNavDestination(Icons.home_rounded, DrNavLabel.home),
    DrNavDestination(Icons.calendar_today_outlined, DrNavLabel.timetable),
    DrNavDestination(Icons.how_to_reg_outlined, DrNavLabel.attendance),
    DrNavDestination(Icons.menu_book_outlined, DrNavLabel.homework),
    DrNavDestination(Icons.settings_outlined, DrNavLabel.settings),
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
            children: List.generate(items.length, (i) {
              final active = i == currentIndex;
              final color = active ? context.dr.textMain : context.dr.textMuted;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(items[i].icon, size: 22, color: color),
                      const SizedBox(height: 5),
                      Text(
                        items[i].label.of(context.l10n).toUpperCase(),
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
