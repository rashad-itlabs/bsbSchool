import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import '../../../features/auth/domain/entities/auth_user.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../theme/dr_colors.dart';
import '../../widgets/dr_widgets.dart';
import '../../widgets/teacher_widgets.dart';
import 'teacher_data.dart';

/// Port of `teacher_theme/grades.html` — score / behaviour / effort sheet.
class TeacherGradesScreen extends StatefulWidget {
  const TeacherGradesScreen({super.key});

  @override
  State<TeacherGradesScreen> createState() => _TeacherGradesScreenState();
}

/// One editable row of the sheet.
class _Entry {
  int? score;
  int? behavior;
  int? effort;
  _Entry(this.score, this.behavior, this.effort);
}

class _TeacherGradesScreenState extends State<TeacherGradesScreen> {
  TeacherClassGroup _group = teacherClassGroups.first;
  TeacherExamType _exam = teacherExamTypes.first;

  var _entries = <_Entry>[];

  List<TeacherStudent> get _students => teacherStudents[_group.id] ?? const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final rows = teacherGrades[_group.id]?[_exam.id] ?? const <List<int>>[];
    _entries = rows.map((r) => _Entry(r[0], r[1], r[2])).toList();
  }

  static String _letterOf(int? score) {
    if (score == null) return '-';
    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    return 'F';
  }

  static Color _colorOf(String letter, BuildContext context) => switch (letter) {
        'A' => DrColors.accentGreen,
        'B' => DrColors.teal,
        'C' => DrColors.orange,
        'D' => DrColors.purple,
        'F' => DrColors.red,
        _ => context.dr.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    final name = context.select<AuthBloc, String>(
      (bloc) => bloc.state.user?.name ?? '',
    );

    final scored = _entries.where((e) => e.score != null).toList();
    final average = scored.isEmpty
        ? 0
        : (scored.fold<int>(0, (sum, e) => sum + e.score!) / scored.length)
            .round();

    return DrScaffold(
      child: ListView(
        children: [
          TeacherPageHeader(
            title: 'Post Exam Grades',
            initials: AuthUser.initialsOf(name),
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
                      _load();
                    }),
                  ),
                ),
                const SizedBox(height: 12),
                TeacherField(
                  label: 'Exam Type',
                  child: TeacherDropdown<TeacherExamType>(
                    value: _exam,
                    items: teacherExamTypes,
                    labelOf: (e) => e.label,
                    onChanged: (e) => setState(() {
                      _exam = e;
                      _load();
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _statTile(context, '$average%', 'Average Score'),
              const SizedBox(width: 12),
              _statTile(
                context,
                '${scored.length}/${_entries.length}',
                'Graded Status',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Student Grades',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Max: 100 points',
                  style: TextStyle(fontSize: 13, color: context.dr.textMuted),
                ),
              ],
            ),
          ),
          TeacherListCard(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _columnTitles(context),
              for (var i = 0; i < _entries.length; i++)
                _gradeRow(context, i, divider: i != _entries.length - 1),
            ],
          ),
          const SizedBox(height: 30),
          DrPrimaryButton(
            label: 'Publish Student Grades',
            onTap: () =>
                showTeacherToast(context, 'Grades published successfully!'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _statTile(BuildContext context, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.dr.bgSurfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.dr.border),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: DrColors.accentGreen,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: context.dr.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _columnTitles(BuildContext context) {
    final style = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: context.dr.textMuted,
    );
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.dr.border)),
      ),
      child: Row(
        children: [
          Expanded(child: Text('STUDENT INFO', style: style)),
          SizedBox(width: 68, child: Text('GRADE', style: style)),
          const SizedBox(width: 12),
          SizedBox(
            width: 50,
            child: Text('BEH.', style: style, textAlign: TextAlign.center),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 50,
            child: Text('EFF.', style: style, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _gradeRow(BuildContext context, int index, {required bool divider}) {
    final student = _students[index];
    final entry = _entries[index];
    final letter = _letterOf(entry.score);

    return TeacherRow(
      divider: divider,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                TeacherStudentAvatar(initials: student.initials),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        student.code,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.dr.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 68,
            child: Row(
              children: [
                _numberInput(
                  slot: 'score-$index',
                  value: entry.score,
                  color: DrColors.accentGreen,
                  onChanged: (v) => setState(() => entry.score = v),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 14,
                  child: Text(
                    letter,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _colorOf(letter, context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _numberInput(
            slot: 'behavior-$index',
            value: entry.behavior,
            color: DrColors.orange,
            onChanged: (v) => setState(() => entry.behavior = v),
          ),
          const SizedBox(width: 12),
          _numberInput(
            slot: 'effort-$index',
            value: entry.effort,
            color: DrColors.teal,
            onChanged: (v) => setState(() => entry.effort = v),
          ),
        ],
      ),
    );
  }

  /// `.grade-input` — 0-100 numeric field. [slot] identifies the cell so the
  /// field survives rebuilds while typing but is re-seeded when the sheet
  /// switches to another class or exam.
  Widget _numberInput({
    required String slot,
    required int? value,
    required Color color,
    required ValueChanged<int?> onChanged,
  }) {
    return Container(
      width: 50,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.dr.border),
      ),
      child: TextFormField(
        key: ValueKey('${_group.id}-${_exam.id}-$slot'),
        initialValue: value?.toString() ?? '',
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
        ),
        decoration: const InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 4),
        ),
        onChanged: (text) => onChanged(int.tryParse(text)?.clamp(0, 100)),
      ),
    );
  }
}
