import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../dr/theme/dr_colors.dart';

/// What the buffet card screen shows in place of a card: a faded, dashed
/// outline of the card — same crest strip, blank bars where the number and
/// balance go — with a "no card" mark on it, a heading, an optional line under
/// it, and an optional refresh.
///
/// By default it says the card hasn't been issued yet, worded for either
/// account type: a student can open this tab too, so it says "this student",
/// not "your child".
class NoBuffetCardView extends StatelessWidget {
  /// Asks the server again — the card may have been issued since. No button
  /// when null.
  final VoidCallback? onRefresh;

  /// Override the default "not issued yet" heading and line. A null [message]
  /// with a [title] given shows the heading alone.
  final String? title;
  final String? message;

  const NoBuffetCardView({
    super.key,
    this.onRefresh,
    this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final heading = title ?? context.l10n.foodCardNoneTitle;
    final line = title == null ? context.l10n.foodCardNoneText : message;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ExcludeSemantics(child: _GhostCard()),
          const SizedBox(height: 32),
          Text(
            heading,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: context.dr.textMain,
            ),
          ),
          if (line != null) ...[
            const SizedBox(height: 10),
            Text(
              line,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: context.dr.textMuted,
              ),
            ),
          ],
          if (onRefresh != null) ...[
            const SizedBox(height: 28),
            Center(child: _RefreshButton(onTap: onRefresh!)),
          ],
        ],
      ),
    );
  }
}

/// The card's silhouette. Sized like the real card's slot on the screen so
/// the page keeps its shape the day a card arrives.
class _GhostCard extends StatelessWidget {
  const _GhostCard();

  static const _radius = 24.0;

  @override
  Widget build(BuildContext context) {
    final bar = context.dr.border;

    return SizedBox(
      height: 200,
      child: CustomPaint(
        foregroundPainter: _DashedBorderPainter(
          color: context.dr.accent.withValues(alpha: 0.5),
          radius: _radius,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.dr.bgSurfaceLight.withValues(alpha: 0.6),
                context.dr.bgSurface.withValues(alpha: 0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(_radius),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The issuer strip, faded: the card is known, just not
                    // issued.
                    Opacity(
                      opacity: 0.35,
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(150),
                            child: Image.asset(
                              'assets/appIcon/app_logo_foreground.png',
                              width: 35,
                              height: 35,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'BRITISH SCHOOL IN BAKU',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                                color: context.dr.textMain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Where the card number and balance will be.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _Bar(width: 120, height: 14, color: bar),
                        _Bar(width: 70, height: 14, color: bar),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _Bar(width: 150, height: 10, color: bar),
                  ],
                ),
              ),
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    // Filled lime with black keeps the mark legible on both
                    // themes.
                    color: DrColors.accentGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: DrColors.accentGreen.withValues(alpha: 0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.credit_card_off_rounded,
                    size: 30,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A blank placeholder line.
class _Bar extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const _Bar({required this.width, required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RefreshButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.dr.accent, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.refresh_rounded, size: 20, color: context.dr.accent),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  context.l10n.foodCardNoneRefresh,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.dr.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dashed rounded-rectangle outline — the "not there yet" edge of the card.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedBorderPainter({required this.color, required this.radius});

  static const _dash = 7.0;
  static const _gap = 5.0;
  static const _stroke = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;

    final rect = (Offset.zero & size).deflate(_stroke / 2);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += _dash + _gap) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
