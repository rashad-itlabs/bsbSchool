import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/di/injection_container.dart';
import '../../core/l10n/app_dates.dart';
import '../../core/l10n/l10n.dart';
import '../../features/weekly_feedback/domain/entities/feedback_week.dart';
import '../../features/weekly_feedback/domain/entities/weekly_feedback.dart';
import '../../features/weekly_feedback/presentation/bloc/weekly_feedback_bloc.dart';
import '../theme/dr_colors.dart';
import '../widgets/dr_widgets.dart';

/// Teachers' weekly comments on the student, laid out as the school year's
/// weeks. A week with feedback is green; tapping a week loads its feedback,
/// with any files the teacher attached, under the grid.
class WeeklyFeedbackScreen extends StatelessWidget {
  const WeeklyFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<WeeklyFeedbackBloc>()..add(const WeeklyFeedbackFetched()),
      child: const _WeeklyFeedbackView(),
    );
  }
}

class _WeeklyFeedbackView extends StatelessWidget {
  const _WeeklyFeedbackView();

  @override
  Widget build(BuildContext context) {
    return DrScaffold(
      child: BlocBuilder<WeeklyFeedbackBloc, WeeklyFeedbackState>(
        builder: (context, state) {
          final bloc = context.read<WeeklyFeedbackBloc>();
          return RefreshIndicator(
            onRefresh: () async => bloc.add(const WeeklyFeedbackRefreshed()),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                DrBackHeader(title: context.l10n.weeklyFeedbackTitle),
                ..._body(context, state),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _body(BuildContext context, WeeklyFeedbackState state) {
    final bloc = context.read<WeeklyFeedbackBloc>();
    void retry() => bloc.add(const WeeklyFeedbackRefreshed());

    // Nothing to draw the grid from yet.
    if (state.weeks.isEmpty) {
      if (state.status == WeeklyFeedbackStatus.error) {
        return [
          _Message(
            text: state.errorMessage ?? context.l10n.errWeeklyFeedbackLoad,
            onRetry: retry,
          ),
        ];
      }
      if (state.status == WeeklyFeedbackStatus.loaded) {
        return [_Message(text: context.l10n.weeklyFeedbackUnavailable)];
      }
      return const [_Loading()];
    }

    final selectedWeek = state.selectedWeek;

    return [
      _WeekGrid(
        weeks: state.weeks,
        selectedWeek: selectedWeek,
        onSelected: (week) => bloc.add(WeeklyFeedbackWeekSelected(week)),
      ),
      const SizedBox(height: 30),
      if (selectedWeek != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Text(
            context.l10n.weeklyFeedbackWeek(selectedWeek),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.dr.textMain,
            ),
          ),
        ),
      // A pull-to-refresh keeps the cards up under the indicator; switching
      // weeks has already cleared them, so the spinner shows alone.
      if (state.isLoading && state.feedback.isEmpty)
        const _Loading()
      else if (state.status == WeeklyFeedbackStatus.error)
        _Message(
          text: state.errorMessage ?? context.l10n.errWeeklyFeedbackLoad,
          onRetry: retry,
        )
      else if (state.feedback.isEmpty)
        _Message(text: context.l10n.weeklyFeedbackNoneForWeek)
      else
        for (final item in state.feedback) ...[
          _FeedbackCard(feedback: item),
          const SizedBox(height: 15),
        ],
    ];
  }
}

/// The school-year weeks as a 5-column grid inside the glow card, with a
/// legend below. Colours and tappability come straight from the server's
/// flags for each week.
class _WeekGrid extends StatelessWidget {
  final List<FeedbackWeek> weeks;
  final int? selectedWeek;
  final ValueChanged<int> onSelected;

  const _WeekGrid({
    required this.weeks,
    required this.selectedWeek,
    required this.onSelected,
  });

  static const _columns = 5;
  static const _gap = 8.0;

  @override
  Widget build(BuildContext context) {
    final rows = (weeks.length / _columns).ceil();

    return DrGlowCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.weeklyFeedbackWeeks,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          for (var row = 0; row < rows; row++) ...[
            if (row > 0) const SizedBox(height: _gap),
            Row(
              children: [
                for (var col = 0; col < _columns; col++) ...[
                  if (col > 0) const SizedBox(width: _gap),
                  Expanded(
                    child: row * _columns + col < weeks.length
                        ? _cell(context, weeks[row * _columns + col])
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _legendSwatch(
                BoxDecoration(
                  color: DrColors.accentGreen,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                  child: _legendLabel(context, context.l10n.weeklyFeedbackHas)),
              const SizedBox(width: 16),
              _legendSwatch(
                BoxDecoration(
                  border: Border.all(color: context.dr.accent, width: 1.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                  child: _legendLabel(
                      context, context.l10n.weeklyFeedbackCurrent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cell(BuildContext context, FeedbackWeek week) {
    final isSelected = week.week == selectedWeek;

    final Color? border = isSelected
        ? context.dr.textMain
        : week.isCurrent
            ? context.dr.accent
            : week.hasFeedback
                ? null
                : context.dr.border;

    final cell = AspectRatio(
      aspectRatio: 1.25,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          // Filled lime keeps black text legible on both themes.
          color: week.hasFeedback ? DrColors.accentGreen : null,
          borderRadius: BorderRadius.circular(12),
          border: border == null
              ? null
              : Border.all(color: border, width: isSelected ? 2 : 1.5),
        ),
        child: Text(
          '${week.week}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: week.hasFeedback || week.isCurrent || isSelected
                ? FontWeight.w700
                : FontWeight.w500,
            color: week.hasFeedback
                ? Colors.black
                : week.isFuture
                    ? context.dr.textMuted.withValues(alpha: 0.5)
                    : context.dr.textMain,
          ),
        ),
      ),
    );

    // Nothing can have been written about a week that hasn't started.
    if (week.isFuture) return cell;
    return GestureDetector(
      onTap: () => onSelected(week.week),
      behavior: HitTestBehavior.opaque,
      child: cell,
    );
  }

  Widget _legendSwatch(BoxDecoration decoration) =>
      Container(width: 12, height: 12, decoration: decoration);

  Widget _legendLabel(BuildContext context, String text) => Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11, color: context.dr.textMuted),
      );
}

class _FeedbackCard extends StatelessWidget {
  final WeeklyFeedback feedback;
  const _FeedbackCard({required this.feedback});

  @override
  Widget build(BuildContext context) {
    final date = feedback.date;
    final title = feedback.kindLabel ?? feedback.teacher;

    return DrCard(
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DrEmojiBadge(
                emoji: feedback.kind == 'student' ? '🎓' : '💬',
                color: _colorFor(feedback.kind),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Text(
                        title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    // Under the heading, unless it already is the heading.
                    if (feedback.teacher != null &&
                        feedback.teacher != title) ...[
                      const SizedBox(height: 2),
                      Text(
                        feedback.teacher!,
                        style: TextStyle(
                            fontSize: 12, color: context.dr.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              if (date != null) ...[
                const SizedBox(width: 8),
                Text(
                  AppDates.short(context, date),
                  style: TextStyle(fontSize: 12, color: context.dr.textMuted),
                ),
              ],
            ],
          ),
          if (feedback.subjects != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(Icons.menu_book_outlined,
                      size: 14, color: context.dr.textMuted),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    feedback.subjects!,
                    style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: context.dr.textMuted),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Text(
            feedback.text,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: context.dr.textMain,
            ),
          ),
          if (feedback.files.isNotEmpty) ...[
            const SizedBox(height: 15),
            Divider(color: context.dr.border, height: 1),
            const SizedBox(height: 12),
            Text(
              context.l10n.weeklyFeedbackFiles,
              style: TextStyle(fontSize: 12, color: context.dr.textMuted),
            ),
            const SizedBox(height: 8),
            for (final file in feedback.files)
              _AttachmentTile(attachment: file),
          ],
        ],
      ),
    );
  }
}

/// One attached file: a type icon, its name, and a tap that hands the URL to
/// the system to download or preview.
class _AttachmentTile extends StatelessWidget {
  final FeedbackAttachment attachment;
  const _AttachmentTile({required this.attachment});

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(attachment.url);
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
    final (icon, color) = _iconFor(attachment.extension);

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: GestureDetector(
        onTap: () => _open(context),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: context.dr.bgSurfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.dr.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  attachment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.download_rounded,
                  size: 18, color: context.dr.accent),
            ],
          ),
        ),
      ),
    );
  }

  static (IconData, Color) _iconFor(String extension) => switch (extension) {
        'pdf' => (Icons.picture_as_pdf_outlined, DrColors.red),
        'doc' || 'docx' => (Icons.description_outlined, DrColors.teal),
        'xls' || 'xlsx' => (Icons.table_chart_outlined, DrColors.green),
        'png' || 'jpg' || 'jpeg' || 'heic' => (Icons.image_outlined, DrColors.purple),
        _ => (Icons.insert_drive_file_outlined, DrColors.orange),
      };
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(child: CircularProgressIndicator()),
      );
}

class _Message extends StatelessWidget {
  final String text;
  final VoidCallback? onRetry;
  const _Message({required this.text, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Column(
        children: [
          Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: context.dr.textMuted)),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            TextButton(
                onPressed: onRetry, child: Text(context.l10n.commonRetry)),
          ],
        ],
      ),
    );
  }
}

/// A stable colour per feedback kind so different kinds read apart.
Color _colorFor(String? kind) {
  const palette = [
    DrColors.green,
    DrColors.teal,
    DrColors.purple,
    DrColors.orange,
  ];
  if (kind == null || kind.isEmpty) return palette.first;
  return palette[kind.hashCode.abs() % palette.length];
}
