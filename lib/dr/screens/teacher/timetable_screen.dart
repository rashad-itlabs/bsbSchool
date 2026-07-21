import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/auth/domain/entities/auth_user.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../theme/dr_colors.dart';
import '../../widgets/dr_widgets.dart';
import '../../widgets/teacher_widgets.dart';
import 'teacher_data.dart';

/// Port of `teacher_theme/timetable.html` — weekly schedule behind day tabs.
class TeacherTimetableScreen extends StatefulWidget {
  const TeacherTimetableScreen({super.key});

  @override
  State<TeacherTimetableScreen> createState() => _TeacherTimetableScreenState();
}

class _TeacherTimetableScreenState extends State<TeacherTimetableScreen> {
  /// Opens on today, falling back to Monday at the weekend.
  late int _day = () {
    // DateTime.weekday is 1=Mon..7=Sun; teacherWeekdays covers Mon..Fri.
    final index = DateTime.now().weekday - 1;
    return index >= teacherWeekdays.length ? 0 : index;
  }();

  @override
  Widget build(BuildContext context) {
    final name = context.select<AuthBloc, String>(
      (bloc) => bloc.state.user?.name ?? '',
    );
    final lessons = teacherTimetable[teacherWeekdays[_day]] ?? const [];

    return DrScaffold(
      child: ListView(
        children: [
          TeacherPageHeader(
            title: 'Weekly Timetable',
            initials: AuthUser.initialsOf(name),
            showBack: false,
          ),
          TeacherDayTabs(
            days: teacherWeekdays,
            selectedIndex: _day,
            onSelected: (i) => setState(() => _day = i),
          ),
          const SizedBox(height: 20),
          if (lessons.isEmpty)
            _empty(context)
          else
            for (final lesson in lessons) ...[
              TeacherClassCard(
                time: lesson.time,
                duration: lesson.duration,
                subject: lesson.subject,
                group: lesson.group,
                room: lesson.room,
                status: lesson.status,
              ),
              const SizedBox(height: 12),
            ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          const Text('☕', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 10),
          Text(
            'No lessons scheduled for today.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: context.dr.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
