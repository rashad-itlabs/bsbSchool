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
                if (state.subjects.length > 1) ...[
                  DrChipBar(
                    labels: state.subjects,
                    selectedIndex: state.subjects.indexOf(state.subject),
                    onSelected: (i) => bloc
                        .add(ExaminationSubjectSelected(state.subjects[i])),
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
    if (state.isEmpty || groups.isEmpty) {
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
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: DrColors.accentGreen,
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
    DrColors.accentGreen,
    DrColors.teal,
    DrColors.purple,
    DrColors.orange,
    DrColors.red,
  ];
  if (subject == null || subject.isEmpty) return palette.first;
  return palette[subject.hashCode.abs() % palette.length];
}
