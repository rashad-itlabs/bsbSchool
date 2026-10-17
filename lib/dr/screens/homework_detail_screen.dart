import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/homework/domain/entities/homework.dart';
import '../../features/homework/domain/entities/homework_submission.dart';
import '../theme/dr_colors.dart';
import '../widgets/dr_widgets.dart';
import '../widgets/homework_status.dart';
import '../../core/l10n/l10n.dart';

/// Full view of a single homework, reached by tapping a card on the list.
/// Shows the whole (HTML-stripped) description, the key dates, and — when the
/// server attached a file — a button that opens/downloads it in the browser.
class HomeworkDetailScreen extends StatelessWidget {
  final Homework homework;

  const HomeworkDetailScreen({super.key, required this.homework});

  @override
  Widget build(BuildContext context) {
    final desc = _stripHtml(homework.description);
    // The server's status (`statuses` dictionary, 17.10.2026). The status
    // block shows with a teacher's mark, and for «teacher has not marked» —
    // there is no mark then, but the hint explains what that means.
    final badge = HomeworkStatusBadge.of(context, homework);
    final showStatus = homework.submission != null ||
        (badge != null && badge.key == 'teacher_missed');

    return DrScaffold(
      child: ListView(
        children: [
          DrBackHeader(title: context.l10n.hwDetailTitle),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DrEmojiBadge(
                emoji: _emojiFor(homework.subject),
                color: _colorFor(homework.subject),
                size: 56,
                radius: 18,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (homework.subject != null)
                      Text(
                        homework.subject!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.dr.textMuted,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      homework.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (showStatus) ...[
            _SubmissionSection(submission: homework.submission, badge: badge),
            const SizedBox(height: 24),
          ],
          if (desc.isNotEmpty) ...[
            DrSectionHeader(title: context.l10n.hwDetailDescription),
            DrCard(
              radius: 20,
              child: Text(
                desc,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: context.dr.textMain,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          DrSectionHeader(title: context.l10n.hwDetailInfo),
          DrCard(
            radius: 20,
            child: Column(
              children: [
                _InfoRow(label: context.l10n.hwSubject, value: homework.subject),
                _InfoRow(label: context.l10n.hwSection, value: homework.section),
                _InfoRow(label: context.l10n.hwTeacher, value: homework.teacher),
                _InfoRow(
                    label: context.l10n.hwGivenDate,
                    value: _formatDate(homework.homeworkDate)),
                _InfoRow(
                    label: context.l10n.hwPostedAt,
                    value: _formatDateTime(homework.createdAt)),
                _InfoRow(
                    label: context.l10n.hwDueDate,
                    value: _formatDate(homework.submitDate)),
                _InfoRow(
                    label: context.l10n.hwGrading,
                    value: _formatDate(homework.evaluationDate),
                    last: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (homework.documentUrl != null)
            _DownloadButton(url: homework.documentUrl!),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

/// The status and the teacher's mark: the server's status (17.10.2026 — it
/// used to say "submitted" for every mark, «not done» and «absent» too) plus
/// whatever of the date, notes, grade, comment and file the mark filled in.
/// A server without statuses falls back to "submitted".
class _SubmissionSection extends StatelessWidget {
  final HomeworkSubmission? submission;
  final HomeworkStatusBadge? badge;
  const _SubmissionSection({required this.submission, required this.badge});

  IconData get _icon => switch (badge?.key) {
        'not_submitted' => Icons.cancel_rounded,
        'absent' => Icons.person_off_rounded,
        'teacher_missed' => Icons.schedule_rounded,
        'assigned' => Icons.hourglass_empty_rounded,
        _ => Icons.check_circle_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final submission = this.submission;
    final markedAt = submission?.markedAt;
    final rows = <(String, String?)>[
      if (markedAt != null)
        (context.l10n.hwMarkedAt,
            DateFormat('dd MMM yyyy, HH:mm').format(markedAt)),
      (context.l10n.hwGrade, submission?.grade),
      (context.l10n.hwNotes, submission?.notes),
      (context.l10n.hwTeacherComment, submission?.teacherComment),
    ].where((r) => r.$2 != null && r.$2!.isNotEmpty).toList();
    final color = badge?.color ?? context.dr.accent;
    final hint = badge?.hint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DrSectionHeader(title: context.l10n.hwSubmission),
        DrCard(
          radius: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(context.l10n.hwStatus,
                        style: TextStyle(
                            fontSize: 13, color: context.dr.textMuted)),
                  ),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badge == null
                            ? context.dr.accentSoft
                            : color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_icon, size: 14, color: color),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              badge?.label ?? context.l10n.hwSubmitted,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (hint != null) ...[
                const SizedBox(height: 8),
                Text(hint,
                    style:
                        TextStyle(fontSize: 12, color: context.dr.textMuted)),
              ],
              if (rows.isNotEmpty) ...[
                const SizedBox(height: 10),
                Divider(color: context.dr.border, height: 1),
                const SizedBox(height: 10),
              ],
              for (var i = 0; i < rows.length; i++)
                _InfoRow(
                  label: rows[i].$1,
                  value: rows[i].$2,
                  last: i == rows.length - 1,
                ),
            ],
          ),
        ),
        if (submission?.documentUrl != null) ...[
          const SizedBox(height: 12),
          _DownloadButton(
            url: submission!.documentUrl!,
            label: submission.originalName ?? context.l10n.hwSubmissionFile,
          ),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final bool last;

  const _InfoRow({required this.label, required this.value, this.last = false});

  @override
  Widget build(BuildContext context) {
    // Nothing to show for a field the server left null.
    if (value == null || value!.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(label,
                  style: TextStyle(fontSize: 13, color: context.dr.textMuted)),
            ),
            Expanded(
              child: Text(
                value!,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        if (!last) ...[
          const SizedBox(height: 10),
          Divider(color: context.dr.border, height: 1),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _DownloadButton extends StatelessWidget {
  final String url;

  /// Defaults to the generic "download file" wording.
  final String? label;
  const _DownloadButton({required this.url, this.label});

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(url);
    // Hand the file to the system (browser / file handler), which downloads or
    // previews it. externalApplication so it leaves the app rather than an
    // embedded web view.
    final ok = uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.fileCouldNotOpen)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DrPrimaryButton(
      label: label ?? context.l10n.fileDownload,
      trailingIcon: Icons.download_rounded,
      onTap: () => _open(context),
    );
  }
}

String _formatDate(DateTime? date) =>
    date == null ? '' : DateFormat('dd MMM yyyy').format(date);

String _formatDateTime(DateTime? date) =>
    date == null ? '' : DateFormat('dd MMM yyyy, HH:mm').format(date);

/// The server sends rich text (`<p>...</p>`); the detail view shows plain text.
String _stripHtml(String html) => html
    .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
    .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
    .replaceAll(RegExp(r'<[^>]*>'), '')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll(RegExp(r'[ \t]+'), ' ')
    .replaceAll(RegExp(r'\n\s*\n+'), '\n\n')
    .trim();

/// A stable emoji per subject so cards stay visually varied without server art.
String _emojiFor(String? subject) {
  switch (subject?.toLowerCase()) {
    case 'english':
    case 'ingilis dili':
      return '🇬🇧';
    case 'riyaziyyat':
    case 'math':
    case 'mathematics':
      return '📐';
    case 'kimya':
    case 'chemistry':
      return '🧪';
    case 'fizika':
    case 'physics':
      return '🔬';
    case 'biologiya':
    case 'biology':
      return '🧬';
    case 'tarix':
    case 'history':
      return '📜';
    case 'ədəbiyyat':
    case 'literature':
      return '📖';
    default:
      return '📚';
  }
}

Color _colorFor(String? subject) {
  final palette = [
    DrColors.green,
    DrColors.teal,
    DrColors.purple,
    DrColors.red,
  ];
  if (subject == null || subject.isEmpty) return palette.first;
  return palette[subject.hashCode.abs() % palette.length];
}
