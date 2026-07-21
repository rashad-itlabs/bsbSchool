import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/auth/domain/entities/auth_user.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../theme/dr_colors.dart';
import '../../widgets/dr_ring.dart';
import '../../widgets/dr_widgets.dart';
import '../../widgets/teacher_widgets.dart';
import 'grades_screen.dart';
import 'reports_screen.dart';

/// Port of `teacher_theme/index.html` — the teacher home dashboard.
class TeacherDashboardScreen extends StatelessWidget {
  /// Switches [TeacherShell]'s tab for the grid items that are also tabs.
  final ValueChanged<int> onNavigate;

  const TeacherDashboardScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return DrScaffold(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: ListView(
        children: [
          _header(context),
          const SizedBox(height: 30),
          _overview(context),
          const SizedBox(height: 30),
          const DrSectionHeader(title: 'Task Management', fontSize: 16),
          _actionsGrid(context),
          const SizedBox(height: 30),
          DrSectionHeader(
            title: 'Next Lesson',
            action: 'See all',
            fontSize: 16,
            onAction: () => onNavigate(1),
          ),
          const TeacherClassCard(
            time: '10:00',
            duration: '45 Mins',
            subject: 'Algebra & Calculus',
            group: 'Class 10 "A"',
            room: 'Room 402',
            status: TeacherLessonStatus.ongoing,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final name = context.select<AuthBloc, String>(
      (bloc) => bloc.state.user?.name ?? '',
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: TextStyle(fontSize: 13, color: context.dr.textMuted),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        TeacherAvatar(initials: AuthUser.initialsOf(name)),
      ],
    );
  }

  Widget _overview(BuildContext context) {
    return DrGlowCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "TODAY'S OVERVIEW",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: DrColors.accentGreen,
                ),
              ),
              Text(
                'Active Day',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.dr.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _stat(context, 0.96, '96%', 'Attendance', DrColors.accentGreen),
              _stat(
                context,
                0.40,
                '40%',
                'KSQ Grades',
                DrColors.accentGreen.withValues(alpha: 0.6),
              ),
              _stat(context, 0.50, '50%', 'Reports', DrColors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(
    BuildContext context,
    double progress,
    String value,
    String label,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          DrRing(
            progress: progress,
            size: 68,
            stroke: 4,
            color: color,
            center: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.dr.textMain,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: context.dr.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionsGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _action(context, '📅', 'Attendance', () => onNavigate(2)),
            _action(context, '📊', 'Grades', () => _push(context, const TeacherGradesScreen())),
            _action(context, '📚', 'Homework', () => onNavigate(3)),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            _action(context, '📄', 'Reports', () => _push(context, const TeacherReportsScreen())),
            _action(context, '🕒', 'Timetable', () => onNavigate(1)),
            _action(context, '⚙️', 'Settings', () => onNavigate(4)),
          ],
        ),
      ],
    );
  }

  Widget _action(
    BuildContext context,
    String emoji,
    String label,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.dr.bgSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.dr.border),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}
