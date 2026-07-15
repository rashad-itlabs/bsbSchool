import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/di/injection_container.dart';
import '../../features/homework/domain/entities/homework.dart';
import '../../features/homework/presentation/bloc/homework_bloc.dart';
import '../theme/dr_colors.dart';
import '../widgets/dr_widgets.dart';
import 'homework_detail_screen.dart';

/// Port of `homework.html`, backed by `GET /homework` — subject pills and
/// homework cards for the student's class.
class HomeworkScreen extends StatelessWidget {
  const HomeworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<HomeworkBloc>()..add(const HomeworkFetched()),
      child: const _HomeworkView(),
    );
  }
}

class _HomeworkView extends StatelessWidget {
  const _HomeworkView();

  @override
  Widget build(BuildContext context) {
    return DrScaffold(
      child: BlocBuilder<HomeworkBloc, HomeworkState>(
        builder: (context, state) {
          final bloc = context.read<HomeworkBloc>();

          return RefreshIndicator(
            onRefresh: () async => bloc.add(const HomeworkRefreshed()),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                DrBackHeader(
                  title: state.className == null
                      ? 'Tapşırıqlar'
                      : 'Tapşırıqlar • ${state.className}',
                ),
                if (state.subjects.length > 1) ...[
                  DrChipBar(
                    labels: state.subjects,
                    selectedIndex: state.subjects.indexOf(state.subject),
                    onSelected: (i) =>
                        bloc.add(HomeworkSubjectSelected(state.subjects[i])),
                  ),
                  const SizedBox(height: 24),
                ],
                _Body(state: state),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final HomeworkState state;
  const _Body({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.homeworks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.status == HomeworkStatus.error) {
      return _Message(
        text: state.errorMessage ?? 'Xəta baş verdi',
        onRetry: () =>
            context.read<HomeworkBloc>().add(const HomeworkRefreshed()),
      );
    }

    if (state.hasNoClass) {
      return const _Message(text: 'Sinif təyin edilməyib');
    }

    final items = state.visibleHomeworks;
    if (items.isEmpty) {
      return const _Message(text: 'Tapşırıq tapılmadı');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DrSectionHeader(title: 'Tapşırıqlar'),
        for (final hw in items) ...[
          _HomeworkCard(homework: hw),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _HomeworkCard extends StatelessWidget {
  final Homework homework;
  const _HomeworkCard({required this.homework});

  void _open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HomeworkDetailScreen(homework: homework),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final desc = _stripHtml(homework.description);
    final tag = _deadlineTag(homework.submitDate);

    return GestureDetector(
      onTap: () => _open(context),
      child: DrCard(
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DrEmojiBadge(
                emoji: _emojiFor(homework.subject),
                color: _colorFor(homework.subject),
                size: 48,
                radius: 16,
              ),
              if (tag != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tag.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tag.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: tag.color,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            homework.subject == null
                ? homework.name
                : '${homework.subject}: ${homework.name}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(desc,
                style: TextStyle(fontSize: 13, color: context.dr.textMuted)),
          ],
          if (homework.section != null) ...[
            const SizedBox(height: 6),
            Text(homework.section!,
                style: TextStyle(fontSize: 12, color: context.dr.textMuted)),
          ],
          const SizedBox(height: 15),
          Divider(color: context.dr.border, height: 1),
          const SizedBox(height: 15),
          Row(
            children: [
              Text('Son tarix: ',
                  style: TextStyle(fontSize: 12, color: context.dr.textMuted)),
              Text(
                _formatDate(homework.submitDate),
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  final VoidCallback? onRetry;
  const _Message({required this.text, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: context.dr.textMuted)),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: const Text('Yenidən cəhd et')),
          ],
        ],
      ),
    );
  }
}

/// A small deadline badge derived from the submit date.
class _DeadlineTag {
  final String label;
  final Color color;
  const _DeadlineTag(this.label, this.color);
}

_DeadlineTag? _deadlineTag(DateTime? submitDate) {
  if (submitDate == null) return null;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final due = DateTime(submitDate.year, submitDate.month, submitDate.day);
  final days = due.difference(today).inDays;

  if (days < 0) return const _DeadlineTag('Gecikmiş', DrColors.red);
  if (days == 0) return const _DeadlineTag('Bu gün', DrColors.red);
  if (days == 1) return const _DeadlineTag('Sabah', DrColors.teal);
  return _DeadlineTag('$days gün qalıb', DrColors.accentGreen);
}

String _formatDate(DateTime? date) =>
    date == null ? '—' : DateFormat('dd MMM yyyy').format(date);

/// The server sends rich text (`<p>...</p>`); the card shows plain text.
String _stripHtml(String html) => html
    .replaceAll(RegExp(r'<[^>]*>'), ' ')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll(RegExp(r'\s+'), ' ')
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
