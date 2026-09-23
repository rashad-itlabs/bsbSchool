import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../theme/dr_colors.dart';
import '../widgets/dr_widgets.dart';

/// Placeholder shown in place of the payment section while it is being built.
///
/// A section, not a page: it is dropped into the tuition screen's scroll view
/// under the usual header, so it has no scaffold and no scrolling of its own.
///
/// Rather than a bare "coming soon" line, it says what is being built and what
/// will land here — a parent who opened this tab wants to know whether to go on
/// paying at the office, and that answer is the whole content of the screen.
class UnderConstructor extends StatefulWidget {
  const UnderConstructor({super.key});

  @override
  State<UnderConstructor> createState() => _UnderConstructorState();
}

class _UnderConstructorState extends State<UnderConstructor>
    with TickerProviderStateMixin {
  /// Drives the chasing light around the outer ring and the counter-rotating
  /// inner arcs. Slow on purpose — this sits on screen indefinitely.
  late final AnimationController _orbit = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );

  /// Ripples leaving the badge.
  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  /// The badge's float and the tool chip's wobble, ping-ponged.
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  /// The indeterminate bar's sweep.
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  /// Everything here is decorative, so an OS "reduce motion" switch parks all
  /// of it rather than trading one animation for another. Re-read on every
  /// dependency change, and written so running it twice changes nothing.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final off = MediaQuery.disableAnimationsOf(context);

    for (final controller in [_orbit, _ripple, _bob, _sweep]) {
      if (off) {
        controller.stop();
      } else if (!controller.isAnimating) {
        controller.repeat(reverse: controller == _bob);
      }
    }
  }

  @override
  void dispose() {
    _orbit.dispose();
    _ripple.dispose();
    _bob.dispose();
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 26),
        _Hero(orbit: _orbit, ripple: _ripple, bob: _bob),
        const SizedBox(height: 26),
        Center(child: _SoonPill(label: context.l10n.underConstructionBadge)),
        const SizedBox(height: 14),
        Text(
          context.l10n.underConstructionTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: context.dr.textMain,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            context.l10n.underConstructionSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: context.dr.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 28),
        _Note(text: context.l10n.underConstructionNote),
      ],
    );
  }
}

/// The animated emblem: a card badge inside two rings, with a tool chip clipped
/// to its corner.
class _Hero extends StatelessWidget {
  final Animation<double> orbit;
  final Animation<double> ripple;
  final Animation<double> bob;

  const _Hero({required this.orbit, required this.ripple, required this.bob});

  @override
  Widget build(BuildContext context) {
    final accent = context.dr.accent;

    return SizedBox(
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // One painter for the glow, both rings and the ripples: they share a
          // centre, so splitting them would only cost extra layers.
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: Listenable.merge([orbit, ripple]),
              builder: (context, _) => CustomPaint(
                size: const Size.square(230),
                painter: _OrbitPainter(
                  orbit: orbit.value,
                  ripple: ripple.value,
                  accent: accent,
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: bob,
            builder: (context, child) {
              final t = Curves.easeInOut.transform(bob.value);
              return Transform.translate(
                offset: Offset(0, -5 + 10 * t),
                child: child,
              );
            },
            child: _CardBadge(bob: bob),
          ),
        ],
      ),
    );
  }
}

class _CardBadge extends StatelessWidget {
  final Animation<double> bob;

  const _CardBadge({required this.bob});

  @override
  Widget build(BuildContext context) {
    final accent = context.dr.accent;

    return SizedBox(
      // Room for the tool chip hanging off the bottom-right corner.
      width: 116,
      height: 116,
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [context.dr.bgSurfaceLight, context.dr.bgSurface],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.18),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(Icons.credit_card_rounded, size: 42, color: accent),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: bob,
              builder: (context, child) => Transform.rotate(
                // Tips back and forth like a tool being swung.
                angle: (Curves.easeInOut.transform(bob.value) - 0.5) * 0.5,
                child: child,
              ),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DrColors.accentGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.dr.bgDark, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: DrColors.accentGreen.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                // Black on the neon lime, as everywhere else it is used as a
                // fill.
                child: const Icon(
                  Icons.handyman_rounded,
                  size: 19,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Two concentric rings and the ripples between them.
///
/// The outer ring is a track of dots whose brightness falls away behind a
/// moving head, so the rotation reads without the dots themselves moving.
class _OrbitPainter extends CustomPainter {
  /// 0..1 — one full turn.
  final double orbit;

  /// 0..1 — one ripple's life.
  final double ripple;

  final Color accent;

  const _OrbitPainter({
    required this.orbit,
    required this.ripple,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final base = math.min(size.width, size.height) / 2;
    final head = orbit * 2 * math.pi;

    // Ambient glow. A radial gradient rather than a blurred circle: a blur of
    // this radius holds its colour most of the way out and lands as a flat
    // olive disc on the dark theme, where this fades the whole way.
    canvas.drawCircle(
      center,
      base,
      Paint()
        ..shader = RadialGradient(
          colors: [
            accent.withValues(alpha: 0.16),
            accent.withValues(alpha: 0.05),
            accent.withValues(alpha: 0),
          ],
          stops: const [0, 0.55, 1],
        ).createShader(Rect.fromCircle(center: center, radius: base)),
    );

    // Two ripples half a cycle apart, so the emblem never goes quiet.
    for (final phase in const [0.0, 0.5]) {
      final t = (ripple + phase) % 1.0;
      final radius = base * (0.46 + 0.44 * Curves.easeOut.transform(t));
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = accent.withValues(alpha: 0.38 * (1 - t)),
      );
    }

    // Outer dotted track.
    const dots = 44;
    final outer = base * 0.92;
    for (var i = 0; i < dots; i++) {
      final angle = head + i * 2 * math.pi / dots;
      // Distance behind the head, 1 at the head itself.
      final trail = 1 - i / dots;
      canvas.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * outer,
        1.8,
        Paint()..color = accent.withValues(alpha: 0.14 + 0.55 * trail * trail),
      );
    }

    // The head itself, carried a little brighter and larger.
    canvas.drawCircle(
      center + Offset(math.cos(head), math.sin(head)) * outer,
      3.6,
      Paint()
        ..color = accent
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3),
    );

    // Inner arcs, turning the other way so the two rings never lock together.
    final inner = base * 0.72;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: 0.5);
    for (final offset in const [0.0, math.pi]) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: inner),
        -head * 1.6 + offset,
        math.pi * 0.38,
        false,
        arc,
      );
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter old) =>
      old.orbit != orbit || old.ripple != ripple || old.accent != accent;
}

/// Says work is under way without inventing a percentage: there is no build
/// progress to read from anywhere, so the bar is deliberately indeterminate.
class _ProgressCard extends StatelessWidget {
  final Animation<double> sweep;

  const _ProgressCard({required this.sweep});

  @override
  Widget build(BuildContext context) {
    final accent = context.dr.accent;

    return DrCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Text(
                context.l10n.underConstructionProgress,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: context.dr.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final band = width * 0.4;

                  return RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: sweep,
                      builder: (context, child) {
                        final t = Curves.easeInOut.transform(sweep.value);
                        return Stack(
                          children: [
                            Positioned.fill(
                              child: ColoredBox(color: context.dr.bgSurfaceLight),
                            ),
                            Positioned(
                              left: -band + (width + band) * t,
                              width: band,
                              top: 0,
                              bottom: 0,
                              child: child!,
                            ),
                          ],
                        );
                      },
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accent.withValues(alpha: 0),
                              accent,
                              accent.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The badge over the title.
class _SoonPill extends StatelessWidget {
  final String label;

  const _SoonPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: context.dr.accentSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.dr.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 15, color: context.dr.accent),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: context.dr.accent,
            ),
          ),
        ],
      ),
    );
  }
}

/// Trailing marker on a feature row. A clock rather than a chevron: none of
/// these rows leads anywhere yet, and it says so without repeating the "coming
/// soon" wording on every line.
class _StepDot extends StatelessWidget {
  const _StepDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.dr.bgSurfaceLight,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.schedule_rounded,
        size: 15,
        color: context.dr.textMuted,
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final String text;

  const _Note({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.dr.accentSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dr.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: context.dr.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: context.dr.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
