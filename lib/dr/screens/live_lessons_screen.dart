import 'package:flutter/material.dart';

import '../theme/dr_colors.dart';
import '../widgets/dr_widgets.dart';

/// Port of `services.html` — live + upcoming online lessons.
class LiveLessonsScreen extends StatelessWidget {
  const LiveLessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DrScaffold(
      child: ListView(
        children: [
          const DrBackHeader(title: 'Canlı Dərslər'),
          DrSectionHeader(title: 'İndi başlayır', fontSize: 16),
          _meetingCard(
            context,
            emoji: '📐',
            color: DrColors.teal,
            subject: 'Riyaziyyat (Cəbr)',
            teacher: 'Müəllim: Elnur Həsənov',
            time: '14:00 - 14:45',
            live: true,
          ),
          const SizedBox(height: 30),
          DrSectionHeader(title: 'Gözlənilən dərslər', fontSize: 16),
          _meetingCard(
            context,
            emoji: '🇬🇧',
            color: DrColors.orange,
            subject: 'İngilis dili',
            teacher: 'Müəllim: Aygün Quliyeva',
            time: '15:00 - 15:45',
            live: false,
            badge: '15:00',
          ),
          const SizedBox(height: 20),
          _meetingCard(
            context,
            emoji: '🧪',
            color: DrColors.purple,
            subject: 'Kimya',
            teacher: 'Müəllim: Samirə Əliyeva',
            time: '16:00 - 16:45',
            live: false,
            badge: '16:00',
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _meetingCard(
    BuildContext context, {
    required String emoji,
    required Color color,
    required String subject,
    required String teacher,
    required String time,
    required bool live,
    String? badge,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.dr.bgSurfaceLight, context.dr.bgSurface],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: live
              ? DrColors.accentGreen.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
        ),
        boxShadow: live
            ? [
                BoxShadow(
                    color: DrColors.accentGreen.withValues(alpha: 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10))
              ]
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              DrEmojiBadge(emoji: emoji, color: color, size: 48, radius: 14),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subject,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(teacher,
                        style: TextStyle(
                            fontSize: 13, color: context.dr.textMuted)),
                  ],
                ),
              ),
              if (live)
                _statusBadge('Canlı', DrColors.accentGreen,
                    DrColors.accentGreen.withValues(alpha: 0.15),
                    showDot: true)
              else
                _statusBadge(badge ?? '', context.dr.textMuted,
                    Colors.white.withValues(alpha: 0.05)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 16, color: context.dr.textMuted),
                const SizedBox(width: 8),
                Text(time,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (live)
            Container(
              width: double.infinity,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: DrColors.accentGreen,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: DrColors.accentGreen.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.videocam, color: Colors.black, size: 20),
                  SizedBox(width: 8),
                  Text('Dərsə qoşul',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text('Otaq hələ açılmayıb',
                  style: TextStyle(
                      color: context.dr.textMuted,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _statusBadge(String label, Color fg, Color bg,
      {bool showDot = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: fg)),
        ],
      ),
    );
  }
}
