import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/di/injection_container.dart';
import '../../features/attendance/presentation/bloc/attendance_bloc.dart';
import '../../features/attendance/presentation/widgets/attendance_week_overview.dart';
import '../../features/auth/domain/entities/auth_user.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/news/domain/entities/news_item.dart';
import '../../features/news/presentation/bloc/news_bloc.dart';
import '../theme/dr_colors.dart';
import '../widgets/dr_ring.dart';
import '../widgets/dr_widgets.dart';
import 'attendance_screen.dart';
import 'examinations_screen.dart';
import 'homework_screen.dart';
import 'library_screen.dart';
import 'live_lessons_screen.dart';
import 'timetable_screen.dart';

/// Port of `index.html` — the home dashboard.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _Exam {
  final String subject;
  final String emoji;
  final Color color;
  final String tag;
  final int score;
  final String grade;
  const _Exam(
      this.subject, this.emoji, this.color, this.tag, this.score, this.grade);
}

const _exams = <_Exam>[
  _Exam('Mathematics', '📐', DrColors.orange, 'KSQ-2', 92, 'A'),
  _Exam('Azerbaijani', '🇦🇿', DrColors.teal, 'BSQ-1', 88, 'B+'),
  _Exam('Geography', '🌍', DrColors.purple, 'KSQ-1', 75, 'C'),
];

/// Shown behind slides whose image is missing or fails to load, so a card is
/// never a blank rectangle.
const _newsFallbackGradient = <Color>[Color(0xFF1E3A8A), Color(0xFF172554)];

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
          _monthlyOverview(),
          const SizedBox(height: 30),
          DrSectionHeader(title: 'Exam Performance', action: 'See all',onAction: (){
            Navigator.push(context, MaterialPageRoute(builder: (_)=>ExaminationsScreen()));
          },),
          _examChart(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _header() {
    final name = context.select<AuthBloc, String>(
          (bloc) => bloc.state.user?.name ?? '',
    );
    final childName = context.select<AuthBloc, String>(
      (bloc) => bloc.state.user?.childName ?? '',
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$name 👋',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(childName == '' ? '$name' : '$childName',
                style: TextStyle(fontSize: 13, color: context.dr.textMuted)),
          ],
        ),
        /// bu hissede instagram terzi profil deyisdirme olacaq.
        ///
        ///
        ///
        ///
        /// 
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: DrColors.accentGreen,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: DrColors.accentGreen.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                color: Colors.black, shape: BoxShape.circle),
            child: Text(AuthUser.initialsOf(childName),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ),
        ),
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
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(DrColors.accentGreen),
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
          child: _NewsCard(item: items[i]),
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
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              'Yenidən cəhd et',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: DrColors.accentGreen,
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
            color: active ? DrColors.accentGreen : context.dr.border,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _actionsGrid() {
    return Row(
      children: [
        _action('Library', Icons.account_balance_outlined, true,
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

  Widget _examChart() {
    return DrGlowCard(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _exams.map((e) {
          return Expanded(
            child: Column(
              children: [
                DrRing(
                  progress: e.score / 100,
                  size: 80,
                  stroke: 5,
                  color: e.color,
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${e.score}%',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: context.dr.textMain)),
                      Text(e.grade,
                          style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: e.color)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text('${e.emoji} ${e.subject}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(e.tag,
                    style:
                        TextStyle(fontSize: 9, color: context.dr.textMuted)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _push(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}

/// One slide: the news image full-bleed, with the publish date on top and the
/// title / description over a scrim at the bottom.
class _NewsCard extends StatelessWidget {
  final NewsItem item;
  const _NewsCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Sits under the photo, so a slow or broken image still reads as a
          // card rather than a blank rectangle.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _newsFallbackGradient,
              ),
            ),
          ),
          if (item.hasImage)
            Image.network(
              item.image!,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white70),
                        ),
                      ),
                    ),
              // A dead URL just falls through to the gradient underneath.
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          item.description,
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
    );
  }
}
