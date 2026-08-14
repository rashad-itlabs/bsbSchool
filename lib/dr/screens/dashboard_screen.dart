import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/di/injection_container.dart';
import '../../core/utils/html_text.dart';
import '../../features/attendance/presentation/bloc/attendance_bloc.dart';
import '../../features/attendance/presentation/widgets/attendance_week_overview.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/events/presentation/bloc/events_bloc.dart';
import '../../features/events/presentation/widgets/events_calendar_card.dart';
import '../../features/news/domain/entities/news_item.dart';
import '../../features/news/presentation/bloc/news_bloc.dart';
import '../../features/news/presentation/widgets/news_image.dart';
import '../theme/dr_colors.dart';
import '../widgets/child_switcher.dart';
import '../widgets/dr_widgets.dart';
import 'attendance_screen.dart';
import 'examinations_screen.dart';
import 'homework_screen.dart';
import 'library_screen.dart';
import 'live_lessons_screen.dart';
import 'news_detail_screen.dart';
import 'timetable_screen.dart';

/// Port of `index.html` — the home dashboard.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

const _newsSliderHeight = 180.0;

class _DashboardScreenState extends State<DashboardScreen> {
  final _pageController = PageController();
  int _newsIndex = 0;
  bool _showExtra = true;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DrScaffold(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: ListView(
        children: [
          _header(),
          const SizedBox(height: 30),
          // Carries its own bottom spacing so it can vanish entirely when the
          // feed is empty.
          _newsSection(),
          _actionsGrid(),
          const SizedBox(height: 20),
          // Center(child: _moreButton()),
          if (_showExtra) ...[
            const SizedBox(height: 20),
            _extraGrid(),
          ],
          const SizedBox(height: 30),
          // _monthlyOverview(),
          const SizedBox(height: 30),
          const DrSectionHeader(title: 'Calendar'),
          _calendar(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _header() {
    final name = context.select<AuthBloc, String>(
          (bloc) => bloc.state.user?.name ?? '',
    );
    // The student every screen below is scoped to — the parent's pick in the
    // switcher, not necessarily the one the token belongs to.
    final childName = context.select<AuthBloc, String>(
      (bloc) => bloc.state.activeChildName,
    );
    final className = context.select<AuthBloc, String>(
      (bloc) => bloc.state.activeChild?.className ?? '',
    );
    final canSwitch =
        context.select<AuthBloc, bool>((bloc) => bloc.state.canSwitchChild);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$name 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                [
                  if (childName.isNotEmpty) childName else name,
                  if (className.isNotEmpty) className,
                ].join(' • '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: context.dr.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ChildSwitcher(name: childName, enabled: canSwitch),
      ],
    );
  }

  /// The slider plus its page dots, driven by `GET /getNews`.
  Widget _newsSection() {
    return BlocProvider(
      create: (_) => sl<NewsBloc>()..add(const NewsFetched()),
      child: BlocBuilder<NewsBloc, NewsState>(
        builder: (context, state) {
          // Nothing published yet — drop the whole block rather than leave a
          // hole between the greeting and the action grid.
          if (state.isEmpty) return const SizedBox.shrink();

          final Widget slider;
          if (state.items.isNotEmpty) {
            slider = _newsSlider(state.items);
          } else if (state.status == NewsStatus.error) {
            slider = _newsPlaceholder(
              child: _newsError(context, state.errorMessage),
            );
          } else {
            // initial / first load
            slider = _newsPlaceholder(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(context.dr.accent),
              ),
            );
          }

          return Column(
            children: [
              slider,
              if (state.items.length > 1) ...[
                const SizedBox(height: 16),
                _dots(state.items.length),
              ],
              const SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }

  Widget _newsSlider(List<NewsItem> items) {
    return SizedBox(
      height: _newsSliderHeight,
      child: PageView.builder(
        controller: _pageController,
        itemCount: items.length,
        onPageChanged: (i) => setState(() => _newsIndex = i),
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _NewsCard(
            item: items[i],
            onTap: () => _push(NewsDetailScreen(item: items[i])),
          ),
        ),
      ),
    );
  }

  /// A slide-sized card used while loading and on failure, so the dashboard
  /// doesn't jump once the feed arrives.
  Widget _newsPlaceholder({required Widget child}) {
    return Container(
      height: _newsSliderHeight,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.dr.bgSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.dr.border),
      ),
      child: child,
    );
  }

  Widget _newsError(BuildContext context, String? message) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.wifi_off_rounded, size: 24, color: context.dr.textMuted),
        const SizedBox(height: 10),
        Text(
          message ?? 'Xəbərlər yüklənmədi',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: context.dr.textMuted),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => context.read<NewsBloc>().add(const NewsRefreshed()),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              'Yenidən cəhd et',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.dr.accent,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dots(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        // The feed can shrink under the controller after a refresh, so the
        // stored index is clamped rather than trusted.
        final active = i == _newsIndex.clamp(0, count - 1);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? context.dr.accent : context.dr.border,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _actionsGrid() {
    return Row(
      children: [
        _action('Library', Icons.account_balance_outlined, false,
            () => _push(const LibraryScreen())),
        _action('Homework', Icons.menu_book_outlined, false,
            () => _push(const HomeworkScreen())),
        _action('Examinations', Icons.description_outlined, false,
            () => _push(const ExaminationsScreen())),
      ],
    );
  }

  Widget _extraGrid() {
    return Row(
      children: [
        _action('Attendance', Icons.how_to_reg_outlined, false,
            () => _push(const AttendanceScreen())),
        _action('Onlayn dərslər', Icons.video_camera_front_outlined, false,
            () => _push(const LiveLessonsScreen())),
        _action('Class Timetable', Icons.calendar_today_outlined, false,
            () => _push(const TimetableScreen())),
      ],
    );
  }

  Widget _action(String label, IconData icon, bool primary, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: primary ? DrColors.accentGreen : context.dr.bgSurface,
                borderRadius: BorderRadius.circular(18),
                border: primary ? null : Border.all(color: context.dr.border),
                boxShadow: primary
                    ? [
                        BoxShadow(
                          color: DrColors.accentGreen.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Icon(icon,
                  color: primary ? Colors.black : context.dr.textMain, size: 26),
            ),
            const SizedBox(height: 10),
            Text(label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _moreButton() {
    return GestureDetector(
      onTap: () => setState(() => _showExtra = !_showExtra),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: context.dr.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.dr.border),
        ),
        child: Text(
          _showExtra ? 'Bağla' : 'Hamısına bax',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _monthlyOverview() {
    return BlocProvider(
      create: (_) => sl<AttendanceBloc>()..add(const AttendanceFetched()),
      child: BlocBuilder<AttendanceBloc, AttendanceState>(
        builder: (context, state) =>
            AttendanceWeekOverview(records: state.records),
      ),
    );
  }

  /// The school calendar, driven by `GET /getEvent`. The whole year arrives in
  /// one call, so paging between months costs nothing.
  Widget _calendar() {
    return BlocProvider(
      create: (_) => sl<EventsBloc>()..add(const EventsFetched()),
      child: BlocBuilder<EventsBloc, EventsState>(
        builder: (context, state) => EventsCalendarCard(
          events: state.events,
          loading: state.isInitialLoading,
          errorMessage:
              state.status == EventsStatus.error ? state.errorMessage : null,
          onRetry: () => context.read<EventsBloc>().add(const EventsRefreshed()),
        ),
      ),
    );
  }

  void _push(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}

/// One slide: the news image full-bleed, with the publish date on top and the
/// title / description over a scrim at the bottom. Tapping it opens
/// [NewsDetailScreen], where the text isn't clipped to two lines.
class _NewsCard extends StatelessWidget {
  final NewsItem item;
  final VoidCallback onTap;
  const _NewsCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // The panel sends rich text; the preview shows the first lines of it as
    // plain text rather than raw `<p>` tags.
    final preview = stripHtmlTags(item.description).replaceAll('\n', ' ');

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            NewsImage(url: item.image),
            // Keeps the white text legible over bright photos.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                  stops: [0.3, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Stack(
                children: [
                  if (item.createdAt != null)
                    Align(
                      alignment: Alignment.topLeft,
                      child: _pill(
                        child: Text(
                          DateFormat('dd MMM yyyy').format(item.createdAt!),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  // Says out loud that the slide leads somewhere; without it a
                  // photo doesn't look tappable.
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        if (preview.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            preview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The translucent black chip both corner labels sit in.
  Widget _pill({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}
