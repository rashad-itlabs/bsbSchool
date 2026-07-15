import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/dr_colors.dart';

/// Animated circular progress ring (the exam score rings + tuition donut).
class DrRing extends StatelessWidget {
  final double progress; // 0..1
  final double size;
  final double stroke;
  final Color color;
  final Widget? center;

  const DrRing({
    super.key,
    required this.progress,
    required this.size,
    required this.stroke,
    required this.color,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(value, stroke, color),
            child: Center(child: center),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double stroke;
  final Color color;

  _RingPainter(this.progress, this.stroke, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = Colors.white.withValues(alpha: 0.06);
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

/// Soft radial glow (the `card-glow` / ambient accent behind headers).
class DrAccentGlow extends StatelessWidget {
  final double size;
  final Color? color;
  const DrAccentGlow({super.key, this.size = 200, this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (color ?? DrColors.accentGreen).withValues(alpha: 0.18),
              blurRadius: 70,
              spreadRadius: 20,
            ),
          ],
        ),
      ),
    );
  }
}
