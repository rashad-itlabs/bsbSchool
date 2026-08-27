import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/auth/domain/entities/auth_user.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../theme/dr_colors.dart';
import '../../widgets/dr_widgets.dart';
import '../../widgets/teacher_widgets.dart';
import 'teacher_data.dart';
import '../../../core/l10n/l10n.dart';

class _Report {
  final String type;
  final String title;
  final String date;
  final String details;
  final String? file;
  const _Report(this.type, this.title, this.date, this.details, this.file);
}

/// Port of `teacher_theme/reports.html` — submit a weekly or per-student
/// report and review the submission history.
class TeacherReportsScreen extends StatefulWidget {
  const TeacherReportsScreen({super.key});

  @override
  State<TeacherReportsScreen> createState() => _TeacherReportsScreenState();
}

class _TeacherReportsScreenState extends State<TeacherReportsScreen> {
  final _title = TextEditingController();
  final _comments = TextEditingController();

  /// 0 = weekly, 1 = per-student.
  int _tab = 0;
  TeacherClassGroup _group = teacherClassGroups.first;
  late TeacherStudent _student = _students.first;
  String? _file;

  final _reports = <_Report>[
    const _Report(
      'weekly',
      "Class 10 'A' Weekly Progress - Math",
      '12 July 2026',
      'Average attendance 95%, exam scores are high.',
      'weekly_math_10a.pdf',
    ),
    const _Report(
      'student',
      'Student report for Samir Aliyev',
      '10 July 2026',
      'Excellent mathematical thinking shown this week.',
      'feedback_samir.pdf',
    ),
  ];

  List<TeacherStudent> get _students => teacherStudents[_group.id] ?? [];

  @override
  void dispose() {
    _title.dispose();
    _comments.dispose();
    super.dispose();
  }

  void _submit() {
    if (_title.text.trim().isEmpty) {
      showTeacherToast(context, context.l10n.tEnterReportTitle);
      return;
    }

    final perStudent = _tab == 1;
    setState(() {
      _reports.insert(
        0,
        _Report(
          perStudent ? 'student' : 'weekly',
          perStudent
              ? context.l10n.tStudentReportFor(_student.name)
              : _title.text.trim(),
          TeacherDatePicker.format(context, DateTime.now()),
          perStudent
              ? '[${_group.label}] ${_title.text.trim()}. ${_comments.text}'
              : (_comments.text.trim().isEmpty
                  ? context.l10n.tDocUploaded
                  : _comments.text.trim()),
          _file,
        ),
      );
      _title.clear();
      _comments.clear();
      _file = null;
    });

    showTeacherToast(context, context.l10n.tReportSubmitted);
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
            title: context.l10n.tUploadReports,
            initials: AuthUser.initialsOf(name),
          ),
          TeacherSegmented(
            labels: [context.l10n.tWeeklyReports, context.l10n.tStudentReports],
            selectedIndex: _tab,
            onSelected: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: 20),
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
                    onChanged: (g) => setState(() {
                      _group = g;
                      // Students are per-class, so re-anchor the selection.
                      _student = _students.first;
                    }),
                  ),
                ),
                if (_tab == 1) ...[
                  const SizedBox(height: 20),
                  TeacherField(
                    label: context.l10n.tTargetStudent,
                    child: TeacherDropdown<TeacherStudent>(
                      value: _student,
                      items: _students,
                      labelOf: (s) => s.name,
                      onChanged: (s) => setState(() => _student = s),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                TeacherField(
                  label: context.l10n.tReportTitle,
                  child: TeacherInput(
                    controller: _title,
                    hint: _tab == 1
                        ? context.l10n.tReportHintStudent
                        : context.l10n.tReportHintWeekly,
                  ),
                ),
                const SizedBox(height: 20),
                TeacherField(
                  label: context.l10n.tComments,
                  child: TeacherInput(
                    controller: _comments,
                    hint: context.l10n.tCommentsHint,
                    minLines: 4,
                  ),
                ),
                const SizedBox(height: 20),
                TeacherField(
                  label: context.l10n.tReportDocument,
                  child: TeacherUploadZone(
                    emoji: '📄',
                    hint: context.l10n.tAttachDoc,
                    fileName: _file,
                    onTap: () {
                      // No file picker wired up yet — stands in for the upload.
                      setState(() => _file = 'report_doc.pdf');
                      showTeacherToast(context, context.l10n.tDocAttached);
                    },
                  ),
                ),
                const SizedBox(height: 20),
                DrPrimaryButton(label: context.l10n.tSubmitReport, onTap: _submit),
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
                  context.l10n.tSubmissionHistory,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                Text(
                  context.l10n.tRecentUploads,
                  style: TextStyle(fontSize: 13, color: context.dr.textMuted),
                ),
              ],
            ),
          ),
          TeacherListCard(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            children: [
              for (final report in _reports)
                TeacherRow(
                  divider: report != _reports.last,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: context.dr.accentSoft,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              report.type.toUpperCase(),
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: context.dr.accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            report.date,
                            style: TextStyle(
                              fontSize: 10,
                              color: context.dr.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        report.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report.details,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.3,
                          color: context.dr.textMuted,
                        ),
                      ),
                      if (report.file != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '📎 ${report.file}',
                          style: TextStyle(
                            fontSize: 10,
                            color: context.dr.accent,
                          ),
                        ),
                      ],
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
