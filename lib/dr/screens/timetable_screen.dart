import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/injection_container.dart';
import '../../features/timetable/domain/entities/timetable_lesson.dart';
import '../../features/timetable/presentation/bloc/timetable_bloc.dart';
import '../theme/dr_colors.dart';
import '../widgets/dr_widgets.dart';

/// Port of `timetable.html`, backed by `GET /class-timetable` — a weekday tab
/// bar (Mon–Fri) and the lesson cards for the selected day.
class TimetableScreen extends StatelessWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TimetableBloc>()..add(const TimetableFetched()),
      child: const _TimetableView(),
    );
  }
}

class _TimetableView extends StatelessWidget {
  const _TimetableView();

  @override
  Widget build(BuildContext context) {
    return DrScaffold(
      child: BlocBuilder<TimetableBloc, TimetableState>(
        builder: (context, state) {
          final bloc = context.read<TimetableBloc>();
          final tabs = state.tabs;
          final selectedIndex =
              tabs.indexWhere((t) => t.dayOfWeek == state.selectedDay);

          return RefreshIndicator(
            onRefresh: () async => bloc.add(const TimetableRefreshed()),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                DrBackHeader(
                  title: state.className == null
                      ? 'Dərs cədvəli'
                      : 'Dərs cədvəli • ${state.className}',
                ),
                DrChipBar(
                  labels: [for (final t in tabs) t.name],
                  selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
                  onSelected: (i) =>
                      bloc.add(TimetableDaySelected(tabs[i].dayOfWeek)),
                ),
                const SizedBox(height: 20),
                _Body(state: state),
                const SizedBox(height: 4),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final TimetableState state;
  const _Body({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.days.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.status == TimetableStatus.error) {
      return _Message(
        text: state.errorMessage ?? 'Xəta baş verdi',
        onRetry: () =>
            context.read<TimetableBloc>().add(const TimetableRefreshed()),
      );
    }

    if (state.hasNoClass) {
      return const _Message(text: 'Sinif təyin edilməyib');
    }

    final lessons = state.selectedLessons;
    if (lessons.isEmpty) {
      return const _Message(text: 'Bu gün üçün dərs yoxdur');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final lesson in lessons) ...[
          _LessonCard(lesson: lesson),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _LessonCard extends StatelessWidget {
  final TimetableLesson lesson;
  const _LessonCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(lesson.subject);
    final time = lesson.timeRange;

    return DrCard(
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DrEmojiBadge(
                emoji: _emojiFor(lesson.subject),
                color: color,
                size: 48,
                radius: 16,
              ),
              if (time.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(time,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(lesson.subject.isEmpty ? 'Dərs' : lesson.subject,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          if (lesson.period != null) ...[
            const SizedBox(height: 4),
            Text(lesson.period!,
                style: TextStyle(fontSize: 12, color: context.dr.textMuted)),
          ],
          if (lesson.teacher != null) ...[
            const SizedBox(height: 4),
            Text('Müəllim: ${lesson.teacher!}',
                style: TextStyle(fontSize: 13, color: context.dr.textMuted)),
          ],
          if (lesson.section != null) ...[
            const SizedBox(height: 15),
            Divider(color: context.dr.border, height: 1),
            const SizedBox(height: 15),
            Row(
              children: [
                Text('Qrup: ',
                    style:
                        TextStyle(fontSize: 12, color: context.dr.textMuted)),
                Expanded(
                  child: Text(lesson.section!,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ],
        ],
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

/// A stable emoji per subject so cards stay visually varied without server art.
String _emojiFor(String subject) {
  switch (subject.toLowerCase()) {
    case 'english':
    case 'ingilis dili':
      return '🇬🇧';
    case 'math':
    case 'maths':
    case 'riyaziyyat':
    case 'mathematics':
      return '📐';
    case 'azer lang':
    case 'azerbaijani':
    case 'azərbaycan dili':
      return '📕';
    case 'kimya':
    case 'chemistry':
      return '🧪';
    case 'fizika':
    case 'physics':
      return '⚡';
    case 'biologiya':
    case 'biology':
      return '🌿';
    case 'tarix':
    case 'history':
      return '📜';
    case 'coğrafiya':
    case 'geography':
      return '🌍';
    case 'registration':
      return '📋';
    default:
      return '📚';
  }
}

Color _colorFor(String subject) {
  final palette = [
    DrColors.accentGreen,
    DrColors.teal,
    DrColors.purple,
    DrColors.orange,
    DrColors.red,
    DrColors.green,
  ];
  if (subject.isEmpty) return palette.first;
  return palette[subject.hashCode.abs() % palette.length];
}
