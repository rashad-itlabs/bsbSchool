import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/injection_container.dart';
import '../../features/attendance/presentation/bloc/attendance_bloc.dart';
import '../../features/attendance/presentation/widgets/attendance_week_overview.dart';
import '../../features/auth/domain/entities/auth_user.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
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

class _News {
  final String tag;
  final Color tagColor;
  final Color tagText;
  final String title;
  final String body;
  final List<Color> bg;
  const _News(
      this.tag, this.tagColor, this.tagText, this.title, this.body, this.bg);
}

const _news = <_News>[
  _News('Xəbər', DrColors.accentGreen, Colors.black, 'Yeni tədris ili başlayır!',
      'British School in Baku-da yeni tədris ilinə qeydiyyat davam edir.',
      [Color(0xFF1E3A8A), Color(0xFF172554)]),
  _News('Elan', Color(0xFF3B82F6), Colors.white, 'Kembric İmtahanları',
      'Qeydiyyat üçün son tarix: 25 May. Gecikməyin!',
      [Color(0xFF991B1B), Color(0xFF7F1D1D)]),
  _News('Tədbir', Color(0xFFF59E0B), Colors.white, 'Məktəblilərarası Turnir',
      'Bahar idman turniri bu həftəsonu məktəbin stadionunda keçiriləcək.',
      [Color(0xFF065F46), Color(0xFF064E3B)]),
];

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
          _newsSlider(),
          const SizedBox(height: 16),
          _dots(),
          const SizedBox(height: 30),
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
            // Text('Good morning,',
            //     style: TextStyle(fontSize: 13, color: context.dr.textMuted)),
            // const SizedBox(height: 4),
            Text(childName == '' ? '$name 👋' : '$childName 👋',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w600)),
          ],
        ),
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

  Widget _newsSlider() {
    return SizedBox(
      height: 180,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _news.length,
        onPageChanged: (i) => setState(() => _newsIndex = i),
        itemBuilder: (_, i) {
          final n = _news[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: n.bg,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: n.tagColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          n.tag.toUpperCase(),
                          style: TextStyle(
                            color: n.tagText,
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
                          Text(n.title,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                          const SizedBox(height: 6),
                          Text(n.body,
                              style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      Colors.white.withValues(alpha: 0.7))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _dots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_news.length, (i) {
        final active = i == _newsIndex;
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
