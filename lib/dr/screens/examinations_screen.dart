import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/injection_container.dart';
import '../../features/examination/domain/entities/exam_group.dart';
import '../../features/examination/domain/entities/exam_result.dart';
import '../../features/examination/presentation/bloc/examination_bloc.dart';
import '../theme/dr_colors.dart';
import '../widgets/dr_widgets.dart';

/// Port of `examinations.html`, backed by `GET /examinations` — the student's
/// exam results grouped by exam group, with a subject filter.
class ExaminationsScreen extends StatelessWidget {
  const ExaminationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ExaminationBloc>()..add(const ExaminationFetched()),
      child: const _ExaminationsView(),
    );
  }
}

class _ExaminationsView extends StatelessWidget {
  const _ExaminationsView();

  @override
  Widget build(BuildContext context) {
    return DrScaffold(
      child: BlocBuilder<ExaminationBloc, ExaminationState>(
        builder: (context, state) {
          final bloc = context.read<ExaminationBloc>();

          return RefreshIndicator(
            onRefresh: () async => bloc.add(const ExaminationRefreshed()),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const DrBackHeader(title: 'İmtahan nəticələri'),
                _FilterBar(state: state),
                const SizedBox(height: 24),
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

/// The filter row under the header: a "Filtr" button that opens the sheet,
/// followed by a removable chip per active filter.
class _FilterBar extends StatelessWidget {
  final ExaminationState state;
  const _FilterBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ExaminationBloc>();
    final active = state.activeFilters;

    return SizedBox(
      height: 44,
      child: Row(
        children: [
          _FilterButton(
            count: state.activeFilterCount,
            onTap: () => _showFilterSheet(context, bloc),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: active.isEmpty
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Bütün nəticələr',
                      style:
                          TextStyle(fontSize: 13, color: context.dr.textMuted),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: active.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => _ActiveFilterChip(
                      label: active[i].value,
                      onRemove: () => _clear(bloc, active[i].key),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _clear(ExaminationBloc bloc, String kind) {
    const any = ExaminationState.any;
    switch (kind) {
      case 'group':
        bloc.add(const ExaminationGroupSelected(any));
      case 'exam':
        bloc.add(const ExaminationExamSelected(any));
      case 'subject':
        bloc.add(const ExaminationSubjectSelected(any));
    }
  }
}

/// The sheet lives on its own route, so the bloc is handed down explicitly.
void _showFilterSheet(BuildContext context, ExaminationBloc bloc) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(value: bloc, child: const _FilterSheet()),
  );
}

class _FilterButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _FilterButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final on = count > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: on ? context.dr.accentSoft : context.dr.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: on ? context.dr.accent : context.dr.border),
        ),
        child: Row(
          // The button sits in a Row's unbounded main-axis slot.
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune_rounded,
                size: 18, color: on ? context.dr.accent : context.dr.textMain),
            const SizedBox(width: 8),
            Text(
              'Filtr',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: on ? context.dr.accent : context.dr.textMain,
              ),
            ),
            if (on) ...[
              const SizedBox(width: 8),
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DrColors.accentGreen,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _ActiveFilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRemove,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.dr.bgSurfaceLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          // Chips are laid out by a horizontal ListView — unbounded width.
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: context.dr.textMain,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.close_rounded, size: 14, color: context.dr.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet holding every filter. Taps apply immediately, so the button at
/// the bottom only reports the live result count and closes the sheet.
class _FilterSheet extends StatelessWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExaminationBloc, ExaminationState>(
      builder: (context, state) {
        final bloc = context.read<ExaminationBloc>();

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
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Filtrlər',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.dr.textMain,
                    ),
                  ),
                  const Spacer(),
                  if (state.activeFilterCount > 0)
                    GestureDetector(
                      onTap: () =>
                          bloc.add(const ExaminationFiltersCleared()),
                      child: Text(
                        'Sıfırla',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.dr.accent,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _FilterSection(
                        title: 'İmtahan qrupu',
                        options: state.examGroupOptions,
                        selected: state.examGroup,
                        onSelected: (v) =>
                            bloc.add(ExaminationGroupSelected(v)),
                      ),
                      _FilterSection(
                        title: 'İmtahan',
                        options: state.examOptions,
                        selected: state.exam,
                        onSelected: (v) => bloc.add(ExaminationExamSelected(v)),
                      ),
                      _FilterSection(
                        title: 'Fənn',
                        options: state.subjects,
                        selected: state.subject,
                        onSelected: (v) =>
                            bloc.add(ExaminationSubjectSelected(v)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              DrPrimaryButton(
                label: 'Nəticələri göstər (${state.visibleResultCount})',
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// One labelled group of chips. Hidden when the data offers nothing to pick —
/// the options list is then just the "Hamısı" sentinel.
class _FilterSection extends StatelessWidget {
  final String title;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;
  const _FilterSection({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (options.length <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: context.dr.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in options)
                _OptionChip(
                  label: option,
                  active: option == selected,
                  onTap: () => onSelected(option),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _OptionChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? DrColors.accentGreen : context.dr.bgSurfaceLight,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: active ? DrColors.accentGreen : context.dr.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            color: active ? Colors.black : context.dr.textMuted,
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final ExaminationState state;
  const _Body({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.groups.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.status == ExaminationStatus.error) {
      return _Message(
        text: state.errorMessage ?? 'Xəta baş verdi',
        onRetry: () =>
            context.read<ExaminationBloc>().add(const ExaminationRefreshed()),
      );
    }

    if (state.hasNoStudent) {
      return const _Message(text: 'Şagird təyin edilməyib');
    }

    final groups = state.visibleGroups;
    if (groups.isEmpty) {
      // With filters on, the list is empty because of them — offer the way out.
      if (state.activeFilterCount > 0) {
        return _Message(
          text: 'Seçilmiş filtrlərə uyğun nəticə yoxdur',
          actionLabel: 'Filtrləri sıfırla',
          onAction: () => context
              .read<ExaminationBloc>()
              .add(const ExaminationFiltersCleared()),
        );
      }
      return const _Message(text: 'İmtahan nəticəsi tapılmadı');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in groups) ...[
          _GroupSection(group: group),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}

class _GroupSection extends StatelessWidget {
  final ExamGroup group;
  const _GroupSection({required this.group});

  @override
  Widget build(BuildContext context) {
    final results = group.results;
    if (results.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DrSectionHeader(title: group.name ?? 'Nəticələr'),
        DrListCard(
          children: [
            for (var i = 0; i < results.length; i++)
              _ResultTile(
                result: results[i],
                divider: i != results.length - 1,
              ),
          ],
        ),
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  final ExamResult result;
  final bool divider;
  const _ResultTile({required this.result, required this.divider});

  @override
  Widget build(BuildContext context) {
    final subject = result.subject ?? 'Fənn';
    final subtitle = [
      if (result.exam != null) result.exam!,
      if (result.className != null) result.className!,
    ].join(' • ');

    return DrTransactionTile(
      leading: DrEmojiBadge(
        emoji: _emojiFor(result.subject),
        color: _colorFor(result.subject),
      ),
      title: subject,
      subtitle: subtitle.isEmpty ? '—' : subtitle,
      divider: divider,
      trailing: _Mark(result: result),
    );
  }
}

/// The right-hand side of a result row: the mark, or an "absent" / "not yet
/// graded" hint when there is no mark to show.
class _Mark extends StatelessWidget {
  final ExamResult result;
  const _Mark({required this.result});

  @override
  Widget build(BuildContext context) {
    if (result.absent) {
      return _Badge(label: 'Qayıb', color: DrColors.red);
    }

    if (!result.isGraded) {
      return Text(
        'Qiymətləndirilməyib',
        style: TextStyle(fontSize: 11, color: context.dr.textMuted),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _formatMark(result.mark!),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.dr.accent,
          ),
        ),
        if (result.grade != null)
          Text(
            'Grade: ${result.grade}',
            style: TextStyle(fontSize: 11, color: context.dr.textMuted),
          ),
        if (result.behaviour != null || result.effort != null)
          Text(
            [
              if (result.behaviour != null) 'Davranış: ${result.behaviour}',
              if (result.effort != null) 'Səy: ${result.effort}',
            ].join(' • '),
            style: TextStyle(fontSize: 11, color: context.dr.textMuted),
          ),
      ],
    );
  }
}

/// `"88.00"` -> `"88"`, `"88.50"` -> `"88.5"`; non-numeric marks pass through.
String _formatMark(String mark) {
  final value = num.tryParse(mark);
  if (value == null) return mark;
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  final VoidCallback? onRetry;

  /// An alternative to [onRetry] for messages that offer something other than
  /// a retry (clearing the filters, say).
  final String actionLabel;
  final VoidCallback? onAction;
  const _Message({
    required this.text,
    this.onRetry,
    this.actionLabel = 'Yenidən cəhd et',
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
          if (onRetry != null || onAction != null) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry ?? onAction,
              child: Text(onRetry != null ? 'Yenidən cəhd et' : actionLabel),
            ),
          ],
        ],
      ),
    );
  }
}

/// A stable emoji per subject so rows stay visually varied without server art.
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
    case 'coğrafiya':
    case 'geography':
      return '🌍';
    case 'ədəbiyyat':
    case 'literature':
      return '📖';
    case 'azərbaycan dili':
      return '🇦🇿';
    default:
      return '📚';
  }
}

Color _colorFor(String? subject) {
  final palette = [
    DrColors.green,
    DrColors.teal,
    DrColors.purple,
    DrColors.orange,
    DrColors.red,
  ];
  if (subject == null || subject.isEmpty) return palette.first;
  return palette[subject.hashCode.abs() % palette.length];
}
