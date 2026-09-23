import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/di/injection_container.dart';
import '../../features/homework/domain/entities/homework.dart';
import '../../features/homework/presentation/bloc/homework_bloc.dart';
import '../theme/dr_colors.dart';
import '../widgets/dr_widgets.dart';
import 'homework_detail_screen.dart';
import '../../core/l10n/l10n.dart';

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
                      ? context.l10n.homeworkTitle
                      : context.l10n.homeworkTitle,
                ),
                _StatusTabs(
                  tab: state.tab,
                  onSelected: (tab) => bloc.add(HomeworkTabSelected(tab)),
                ),
                const SizedBox(height: 20),
                if (state.subjects.length > 1) ...[
                  DrChipBar(
                    labels: [
                      for (final subject in state.subjects)
                        context.filterLabel(subject),
                    ],
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

/// Two-segment switch between homeworks whose deadline is still ahead and
/// those that have passed.
class _StatusTabs extends StatelessWidget {
  final HomeworkTab tab;
  final ValueChanged<HomeworkTab> onSelected;
  const _StatusTabs({required this.tab, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.dr.bgSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.dr.border),
      ),
      child: Row(
        children: [
          _Segment(
            label: context.l10n.homeworkActive,
            active: tab == HomeworkTab.active,
            onTap: () => onSelected(HomeworkTab.active),
          ),
          _Segment(
            label: context.l10n.homeworkInactive,
            active: tab == HomeworkTab.past,
            onTap: () => onSelected(HomeworkTab.past),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Segment({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? DrColors.accentGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              color: active ? Colors.black : context.dr.textMuted,
            ),
          ),
        ),
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
        text: state.errorMessage ?? context.l10n.commonError,
        onRetry: () =>
            context.read<HomeworkBloc>().add(const HomeworkRefreshed()),
      );
    }

    if (state.hasNoClass) {
      return _Message(text: context.l10n.homeworkNoClass);
    }

    final items = state.visibleHomeworks;
    if (items.isEmpty) {
      return _Message(
        text: state.tab == HomeworkTab.active
            ? context.l10n.homeworkNoActive
            : context.l10n.homeworkNoInactive,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
    // Handed-in work no longer counts down to its deadline.
    final tag = homework.isSubmitted
        ? _DeadlineTag(context.l10n.hwSubmitted, context.dr.accent)
        : _deadlineTag(context, homework.submitDate);

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
              Text(context.l10n.homeworkDuePrefix,
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
            TextButton(onPressed: onRetry, child: Text(context.l10n.commonRetry)),
          ],
        ],
      ),
    );
  }
}

/// A small badge on a card: "submitted", or how the deadline stands.
class _DeadlineTag {
  final String label;
  final Color color;
  const _DeadlineTag(this.label, this.color);
}

/// Takes a [context] because the "plenty of time left" tag paints the brand
/// accent as text, which needs the light theme's darker variant.
_DeadlineTag? _deadlineTag(BuildContext context, DateTime? submitDate) {
  if (submitDate == null) return null;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final due = DateTime(submitDate.year, submitDate.month, submitDate.day);
  final days = due.difference(today).inDays;

  if (days < 0) return _DeadlineTag(context.l10n.homeworkOverdue, DrColors.red);
  if (days == 0) return _DeadlineTag(context.l10n.homeworkToday, DrColors.red);
  if (days == 1) return _DeadlineTag(context.l10n.homeworkTomorrow, DrColors.teal);
  return _DeadlineTag(context.l10n.homeworkDaysLeft(days), context.dr.accent);
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
    DrColors.green,
    DrColors.teal,
    DrColors.purple,
    DrColors.red,
  ];
  if (subject == null || subject.isEmpty) return palette.first;
  return palette[subject.hashCode.abs() % palette.length];
}
