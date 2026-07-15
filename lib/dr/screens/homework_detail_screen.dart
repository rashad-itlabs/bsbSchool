import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/homework/domain/entities/homework.dart';
import '../theme/dr_colors.dart';
import '../widgets/dr_widgets.dart';

/// Full view of a single homework, reached by tapping a card on the list.
/// Shows the whole (HTML-stripped) description, the key dates, and — when the
/// server attached a file — a button that opens/downloads it in the browser.
class HomeworkDetailScreen extends StatelessWidget {
  final Homework homework;

  const HomeworkDetailScreen({super.key, required this.homework});

  @override
  Widget build(BuildContext context) {
    final desc = _stripHtml(homework.description);

    return DrScaffold(
      child: ListView(
        children: [
          const DrBackHeader(title: 'Tapşırıq'),
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
          if (desc.isNotEmpty) ...[
            const DrSectionHeader(title: 'Təsvir'),
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
          const DrSectionHeader(title: 'Məlumat'),
          DrCard(
            radius: 20,
            child: Column(
              children: [
                _InfoRow(label: 'Fənn', value: homework.subject),
                _InfoRow(label: 'Bölmə', value: homework.section),
                _InfoRow(label: 'Müəllim', value: homework.teacher),
                _InfoRow(
                    label: 'Verilmə tarixi',
                    value: _formatDate(homework.homeworkDate)),
                _InfoRow(
                    label: 'Son tarix',
                    value: _formatDate(homework.submitDate)),
                _InfoRow(
                    label: 'Qiymətləndirmə',
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
  const _DownloadButton({required this.url});

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(url);
    // Hand the file to the system (browser / file handler), which downloads or
    // previews it. externalApplication so it leaves the app rather than an
    // embedded web view.
    final ok = uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fayl açıla bilmədi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DrPrimaryButton(
      label: 'Faylı yüklə',
      trailingIcon: Icons.download_rounded,
      onTap: () => _open(context),
    );
  }
}

String _formatDate(DateTime? date) =>
    date == null ? '' : DateFormat('dd MMM yyyy').format(date);

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
    DrColors.accentGreen,
    DrColors.teal,
    DrColors.purple,
    DrColors.red,
  ];
  if (subject == null || subject.isEmpty) return palette.first;
  return palette[subject.hashCode.abs() % palette.length];
}
