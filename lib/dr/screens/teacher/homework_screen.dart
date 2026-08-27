import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/auth/domain/entities/auth_user.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../theme/dr_colors.dart';
import '../../widgets/dr_widgets.dart';
import '../../widgets/teacher_widgets.dart';
import 'teacher_data.dart';
import '../../../core/l10n/l10n.dart';

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
      showTeacherToast(context, context.l10n.tEnterHomeworkTitle);
      return;
    }

    setState(() {
      _homeworks.insert(
        0,
        _Homework(
          _group.label,
          _title.text.trim(),
          TeacherDatePicker.format(context, _due),
          _attachment,
        ),
      );
      _title.clear();
      _description.clear();
      _attachment = null;
    });

    showTeacherToast(context, context.l10n.tHomeworkAssigned);
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
            title: context.l10n.tAssignHomework,
            initials: AuthUser.initialsOf(name),
            showBack: false,
          ),
          DrGlowCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TeacherField(
                  label: context.l10n.tClassGroup,
                  child: TeacherDropdown<TeacherClassGroup>(
                    value: _group,
                    items: teacherClassGroups,
                    labelOf: (g) => g.label,
                    onChanged: (g) => setState(() => _group = g),
                  ),
                ),
                const SizedBox(height: 20),
                TeacherField(
                  label: context.l10n.tHomeworkTitle,
                  child: TeacherInput(
                    controller: _title,
                    hint: context.l10n.tHomeworkTitleHint,
                  ),
                ),
                const SizedBox(height: 20),
                TeacherField(
                  label: context.l10n.tDueDate,
                  child: TeacherDatePicker(
                    value: _due,
                    onChanged: (d) => setState(() => _due = d),
                  ),
                ),
                const SizedBox(height: 20),
                TeacherField(
                  label: context.l10n.tDescriptionTasks,
                  child: TeacherInput(
                    controller: _description,
                    hint: context.l10n.tDescriptionHint,
                    minLines: 4,
                  ),
                ),
                const SizedBox(height: 20),
                TeacherField(
                  label: context.l10n.tAttachmentFile,
                  child: TeacherUploadZone(
                    emoji: '📁',
                    hint: context.l10n.tChoosePdf,
                    fileName: _attachment,
                    onTap: () {
                      // No file picker wired up yet — stands in for the upload.
                      setState(() => _attachment = 'quadratic_practice.pdf');
                      showTeacherToast(context, context.l10n.tFileAttached);
                    },
                  ),
                ),
                const SizedBox(height: 20),
                DrPrimaryButton(label: context.l10n.tAssignTask, onTap: _submit),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.tActiveHomeworks,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                Text(
                  context.l10n.tCurrentlyAssigned,
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
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: context.dr.accent,
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
                              context.l10n.tDueLabel(hw.due) +
                                  (hw.attachment != null
                                      ? ' • 📎 ${hw.attachment}'
                                      : ''),
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
                          showTeacherToast(context, context.l10n.tHomeworkDeleted);
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
