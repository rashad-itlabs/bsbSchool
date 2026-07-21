import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/auth/domain/entities/auth_user.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../theme/dr_colors.dart';
import '../../widgets/dr_widgets.dart';
import '../../widgets/teacher_widgets.dart';
import 'teacher_data.dart';

enum _Att { p, a, l }

/// Port of `teacher_theme/attendance.html` — mark P/A/L per student, then
/// save to lock the sheet.
class TeacherAttendanceScreen extends StatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  State<TeacherAttendanceScreen> createState() =>
      _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  TeacherClassGroup _group = teacherClassGroups.first;
  DateTime _date = DateTime.now();
  bool _saved = false;

  /// Marks for the selected class, keyed by student id.
  final _marks = <int, _Att>{};

  List<TeacherStudent> get _students => teacherStudents[_group.id] ?? const [];

  @override
  void initState() {
    super.initState();
    _resetMarks();
  }

  /// The mockup ships everyone as present except one absentee per class; here
  /// every student simply starts present until the teacher says otherwise.
  void _resetMarks() {
    _marks
      ..clear()
      ..addEntries(_students.map((s) => MapEntry(s.id, _Att.p)));
  }

  void _unlock() {
    _saved = false;
  }

  @override
  Widget build(BuildContext context) {
    final name = context.select<AuthBloc, String>(
      (bloc) => bloc.state.user?.name ?? '',
    );

    final present = _marks.values.where((v) => v == _Att.p).length;
    final absent = _marks.values.where((v) => v == _Att.a).length;
    final late = _marks.values.where((v) => v == _Att.l).length;

    return DrScaffold(
      child: ListView(
        children: [
          TeacherPageHeader(
            title: 'Student Attendance',
            initials: AuthUser.initialsOf(name),
            showBack: false,
          ),
          DrGlowCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TeacherField(
                  label: 'Class Group',
                  child: TeacherDropdown<TeacherClassGroup>(
                    value: _group,
                    items: teacherClassGroups,
                    labelOf: (g) => g.label,
                    onChanged: (g) => setState(() {
                      _group = g;
                      _resetMarks();
                      _unlock();
                    }),
                  ),
                ),
                const SizedBox(height: 12),
                TeacherField(
                  label: 'Date',
                  child: TeacherDatePicker(
                    value: _date,
                    onChanged: (d) => setState(() {
                      _date = d;
                      _resetMarks();
                      _unlock();
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Student List',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Present: $present | Absent: $absent | Late: $late',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DrColors.accentGreen,
                  ),
                ),
              ],
            ),
          ),
          TeacherListCard(
            children: [
              for (final student in _students)
                TeacherRow(
                  divider: student != _students.last,
                  child: Row(
                    children: [
                      TeacherStudentAvatar(initials: student.initials),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              student.code,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.dr.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _switch(student.id),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 30),
          DrPrimaryButton(
            label: _saved
                ? 'Edit Attendance Records'
                : 'Save Attendance Records',
            onTap: () {
              setState(() => _saved = !_saved);
              showTeacherToast(
                context,
                _saved
                    ? 'Attendance saved successfully!'
                    : 'Editing mode active.',
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// `.attendance-switch` — P / A / L segmented selector, dimmed once saved.
  Widget _switch(int studentId) {
    final selected = _marks[studentId];
    return Opacity(
      opacity: _saved ? 0.7 : 1,
      child: IgnorePointer(
        ignoring: _saved,
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.dr.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: _Att.values.map((att) {
              final active = att == selected;
              final (bg, fg) = switch (att) {
                _Att.p => (DrColors.accentGreen, Colors.black),
                _Att.a => (DrColors.red, Colors.white),
                _Att.l => (DrColors.orange, Colors.white),
              };
              return GestureDetector(
                onTap: () => setState(() => _marks[studentId] = att),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 34,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active ? bg : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: bg.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    att.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: active ? fg : context.dr.textMuted,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
