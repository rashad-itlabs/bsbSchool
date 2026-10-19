import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/di/injection_container.dart';
import '../../features/homework/domain/entities/homework.dart';
import '../../features/homework/presentation/bloc/homework_bloc.dart';
import '../theme/dr_colors.dart';
import '../widgets/dr_widgets.dart';
import '../widgets/homework_status.dart';
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
                // Once there is a list to narrow: hidden while the first load
                // runs, on an error and for a student without a class.
                if (state.status == HomeworkStatus.loaded &&
                    !state.hasNoClass &&
                    state.homeworks.isNotEmpty) ...[
                  _FilterBar(state: state),
                  const SizedBox(height: 20),
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
        // Nothing left after filtering: the way out is right here.
        actionLabel: state.isFiltered ? context.l10n.hwFilterReset : null,
        onAction: state.isFiltered
            ? () => context
                .read<HomeworkBloc>()
                .add(const HomeworkFiltersChanged())
            : null,
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
    // The server's status (17.10.2026: its `statuses` dictionary — the
    // website's words and colours). «Assigned» keeps the deadline countdown,
    // which says more; a server without statuses keeps the old rule.
    final badge = HomeworkStatusBadge.of(context, homework);
    final tag = badge != null && !badge.isAssigned
        ? _DeadlineTag(badge.label, badge.color)
        : badge == null && homework.isSubmitted
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
              if (tag != null) ...[
                const SizedBox(width: 8),
                // Flexible: a server label («Учитель не отметил») is longer
                // than the old countdown words and wraps instead of overflowing.
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: tag.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _upper(context, tag.label),
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: tag.color,
                      ),
                    ),
                  ),
                ),
              ],
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
          if (homework.createdAt != null) ...[
            const SizedBox(height: 6),
            // One Text with spans, so a large font wraps instead of overflowing.
            Text.rich(
              TextSpan(
                text: '${context.l10n.hwPostedAt}: ',
                style: TextStyle(fontSize: 12, color: context.dr.textMuted),
                children: [
                  TextSpan(
                    text: DateFormat('dd MMM yyyy, HH:mm')
                        .format(homework.createdAt!),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: context.dr.textMain,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  final VoidCallback? onRetry;

  /// Another button in place of "retry" — the filters' reset.
  final String? actionLabel;
  final VoidCallback? onAction;

  const _Message({
    required this.text,
    this.onRetry,
    this.actionLabel,
    this.onAction,
  });

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
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 16),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// The tab's count and the filter button; under them, while any filter is
/// on, each one as a chip that removes it, and a reset.
class _FilterBar extends StatelessWidget {
  final HomeworkState state;
  const _FilterBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<HomeworkBloc>();
    final total = state.tabHomeworks.length;

    void apply({Set<String>? sections, Set<String>? statuses}) =>
        bloc.add(HomeworkFiltersChanged(
          sections: sections ?? state.sections,
          statuses: statuses ?? state.statuses,
        ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                state.isFiltered
                    ? l10n.hwFilterCountOf(state.visibleHomeworks.length, total)
                    : l10n.hwFilterCount(total),
                style: TextStyle(fontSize: 13, color: context.dr.textMuted),
              ),
            ),
            _FilterButton(
              count: state.filterCount,
              onTap: () => _showFilterSheet(context),
            ),
          ],
        ),
        if (state.isFiltered) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final option in state.sectionOptions)
                if (state.sections.contains(option.key))
                  _AppliedChip(
                    label: option.label,
                    onRemove: () =>
                        apply(sections: {...state.sections}..remove(option.key)),
                  ),
              for (final info in state.statusOptions)
                if (state.statuses.contains(info.key))
                  _AppliedChip(
                    label: HomeworkStatusBadge.ofInfo(context, info).label,
                    onRemove: () =>
                        apply(statuses: {...state.statuses}..remove(info.key)),
                  ),
              TextButton(
                onPressed: () => bloc.add(const HomeworkFiltersChanged()),
                child: Text(l10n.hwFilterReset),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// «Filtr», with the number of filters on in a badge once there are any.
class _FilterButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _FilterButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final on = count > 0;
    final color = on ? context.dr.accent : context.dr.textMain;

    return Material(
      color: on ? context.dr.accentSoft : context.dr.bgSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: on ? context.dr.accent : context.dr.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tune_rounded, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  context.l10n.commonFilter,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                if (on) ...[
                  const SizedBox(width: 8),
                  Container(
                    constraints:
                        const BoxConstraints(minWidth: 20, minHeight: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: DrColors.accentGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One filter that is on, under the button; the cross takes it off.
class _AppliedChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _AppliedChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.hwFilterRemove(label),
      excludeSemantics: true,
      child: Material(
        color: context.dr.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: context.dr.border),
        ),
        child: InkWell(
          onTap: onRemove,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.close_rounded,
                    size: 14, color: context.dr.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens the filter sheet over the screen. The sheet is its own route, above
/// this screen's [BlocProvider], so the bloc is handed in.
Future<void> _showFilterSheet(BuildContext context) {
  final bloc = context.read<HomeworkBloc>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: const _FilterSheet(),
    ),
  );
}

/// Sections and statuses, several of each; nothing changes until «show
/// results», whose count follows the picks as they are made.
class _FilterSheet extends StatefulWidget {
  const _FilterSheet();

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final Set<String> _sections;
  late final Set<String> _statuses;

  @override
  void initState() {
    super.initState();
    final state = context.read<HomeworkBloc>().state;
    _sections = {...state.sections};
    _statuses = {...state.statuses};
  }

  void _toggle(Set<String> set, String key) => setState(
        () => set.contains(key) ? set.remove(key) : set.add(key),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<HomeworkBloc>().state;
    final sectionOptions = state.sectionOptions;
    final statusOptions = state.statusOptions;
    final shown =
        state.filtered(sections: _sections, statuses: _statuses).length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: context.dr.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: context.dr.border),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.dr.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.commonFilter,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: _sections.isEmpty && _statuses.isEmpty
                    ? null
                    : () => setState(() {
                          _sections.clear();
                          _statuses.clear();
                        }),
                child: Text(l10n.hwFilterReset),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (sectionOptions.isNotEmpty)
                    _ChoiceGroup(
                      title: l10n.hwFilterSubjects,
                      picked: _sections.length,
                      children: [
                        for (final option in sectionOptions)
                          _Choice(
                            label: option.label,
                            selected: _sections.contains(option.key),
                            onTap: () => _toggle(_sections, option.key),
                          ),
                      ],
                    ),
                  if (sectionOptions.isNotEmpty && statusOptions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Divider(color: context.dr.border, height: 1),
                    ),
                  if (statusOptions.isNotEmpty)
                    _ChoiceGroup(
                      title: l10n.hwStatus,
                      picked: _statuses.length,
                      children: [
                        for (final info in statusOptions)
                          Builder(builder: (context) {
                            final badge =
                                HomeworkStatusBadge.ofInfo(context, info);
                            return _Choice(
                              label: badge.label,
                              dot: badge.color,
                              selected: _statuses.contains(info.key),
                              onTap: () => _toggle(_statuses, info.key),
                            );
                          }),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          DrPrimaryButton(
            label: l10n.hwFilterShow(shown),
            onTap: () {
              context.read<HomeworkBloc>().add(HomeworkFiltersChanged(
                    sections: {..._sections},
                    statuses: {..._statuses},
                  ));
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

/// A titled group of choices, with how many are picked.
class _ChoiceGroup extends StatelessWidget {
  final String title;
  final int picked;
  final List<Widget> children;
  const _ChoiceGroup({
    required this.title,
    required this.picked,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _upper(context, title),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: context.dr.textMuted,
                ),
              ),
            ),
            if (picked > 0)
              Text(
                context.l10n.hwFilterSelected(picked),
                style: TextStyle(fontSize: 12, color: context.dr.textMuted),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: children),
      ],
    );
  }
}

/// One pickable option: lime with a tick when picked; a status shows its
/// colour as a dot while not.
class _Choice extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? dot;
  final VoidCallback onTap;
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dot,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? DrColors.accentGreen : context.dr.bgSurfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? DrColors.accentGreen : context.dr.border,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected)
                    const Icon(Icons.check_rounded,
                        size: 16, color: Colors.black)
                  else if (dot != null)
                    Container(
                      width: 8,
                      height: 8,
                      decoration:
                          BoxDecoration(color: dot, shape: BoxShape.circle),
                    ),
                  if (selected || dot != null) const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                        color: selected ? Colors.black : context.dr.textMain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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

/// Dart's `toUpperCase` has no locale: Azerbaijani `i` becomes `I`, not `İ`,
/// so «Yerinə yetirilib» read «YERINƏ YETIRILIB». Dotted `i` is mapped first.
String _upper(BuildContext context, String text) =>
    Localizations.localeOf(context).languageCode == 'az'
        ? text.replaceAll('i', 'İ').toUpperCase()
        : text.toUpperCase();

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
