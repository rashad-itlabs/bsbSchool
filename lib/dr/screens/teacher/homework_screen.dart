import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/auth/domain/entities/auth_user.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../theme/dr_colors.dart';
import '../../widgets/dr_widgets.dart';
import '../../widgets/teacher_widgets.dart';
import 'teacher_data.dart';

class _Homework {
  final String group;
  final String title;
  final String due;
  final String? attachment;
  const _Homework(this.group, this.title, this.due, this.attachment);
}

/// Port of `teacher_theme/homework.html` — assign a task, list active ones.
class TeacherHomeworkScreen extends StatefulWidget {
  const TeacherHomeworkScreen({super.key});

  @override
  State<TeacherHomeworkScreen> createState() => _TeacherHomeworkScreenState();
}

class _TeacherHomeworkScreenState extends State<TeacherHomeworkScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();

  TeacherClassGroup _group = teacherClassGroups.first;
  late DateTime _due = DateTime.now().add(const Duration(days: 1));
  String? _attachment;

  final _homeworks = <_Homework>[
    const _Homework(
      "Class 10 'A'",
      'Trigonometric Formulas Test Prep',
      '16 July 2026',
      'formulas_guide.pdf',
    ),
    const _Homework(
      "Class 11 'B'",
      'Limits and Derivatives Worksheet',
      '18 July 2026',
      null,
    ),
  ];

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (_title.text.trim().isEmpty) {
      showTeacherToast(context, 'Please enter homework title!');
      return;
    }

    setState(() {
      _homeworks.insert(
        0,
        _Homework(
          _group.label,
          _title.text.trim(),
          TeacherDatePicker.format(_due),
          _attachment,
        ),
      );
      _title.clear();
      _description.clear();
      _attachment = null;
    });

    showTeacherToast(context, 'Homework assigned successfully!');
  }

  @override
  Widget build(BuildContext context) {
    final name = context.select<AuthBloc, String>(
      (bloc) => bloc.state.user?.name ?? '',
    );

    return DrScaffold(
      child: ListView(
        children: [
          TeacherPageHeader(
            title: 'Assign Homework',
            initials: AuthUser.initialsOf(name),
            showBack: false,
          ),
          DrGlowCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TeacherField(
                  label: 'Class Group',
                  child: TeacherDropdown<TeacherClassGroup>(
                    value: _group,
                    items: teacherClassGroups,
                    labelOf: (g) => g.label,
                    onChanged: (g) => setState(() => _group = g),
                  ),
                ),
                const SizedBox(height: 20),
                TeacherField(
                  label: 'Homework Title',
                  child: TeacherInput(
                    controller: _title,
                    hint: 'e.g. Quadratic Equations Practice',
                  ),
                ),
                const SizedBox(height: 20),
                TeacherField(
                  label: 'Due Date',
                  child: TeacherDatePicker(
                    value: _due,
                    onChanged: (d) => setState(() => _due = d),
                  ),
                ),
                const SizedBox(height: 20),
                TeacherField(
                  label: 'Description / Tasks',
                  child: TeacherInput(
                    controller: _description,
                    hint: 'Details of the homework assignment...',
                    minLines: 4,
                  ),
                ),
                const SizedBox(height: 20),
                TeacherField(
                  label: 'Attachment File',
                  child: TeacherUploadZone(
                    emoji: '📁',
                    hint: 'Click to choose or drop PDF / Image',
                    fileName: _attachment,
                    onTap: () {
                      // No file picker wired up yet — stands in for the upload.
                      setState(() => _attachment = 'quadratic_practice.pdf');
                      showTeacherToast(context, 'Mock file attached successfully!');
                    },
                  ),
                ),
                const SizedBox(height: 20),
                DrPrimaryButton(label: 'Assign Homework Task', onTap: _submit),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Active Homeworks',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Currently Assigned',
                  style: TextStyle(fontSize: 13, color: context.dr.textMuted),
                ),
              ],
            ),
          ),
          TeacherListCard(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            children: [
              for (final hw in _homeworks)
                TeacherRow(
                  divider: hw != _homeworks.last,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hw.group.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: DrColors.accentGreen,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hw.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Due: ${hw.due}'
                              '${hw.attachment != null ? ' • 📎 ${hw.attachment}' : ''}',
                              style: TextStyle(
                                fontSize: 10,
                                color: context.dr.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() => _homeworks.remove(hw));
                          showTeacherToast(context, 'Homework deleted.');
                        },
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: DrColors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
