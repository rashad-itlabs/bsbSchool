import 'package:flutter/material.dart';

import '../theme/dr_colors.dart';

/// `.profile-btn` — green circle wrapping a black disc with the user's initials.
class TeacherAvatar extends StatelessWidget {
  final String initials;
  final VoidCallback? onTap;
  const TeacherAvatar({super.key, required this.initials, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: DrColors.accentGreen,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: DrColors.accentGreen.withValues(alpha: 0.4),
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
            color: Colors.black,
            shape: BoxShape.circle,
          ),
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// `.header` on the sub-pages — green circle back button, title, profile avatar.
class TeacherPageHeader extends StatelessWidget {
  final String title;
  final String initials;
  final bool showBack;
  const TeacherPageHeader({
    super.key,
    required this.title,
    required this.initials,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          if (showBack) ...[
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 44,
                height: 44,
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
                child: const Icon(
                  Icons.chevron_left_rounded,
                  color: Colors.black,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 15),
          ],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.dr.textMain,
              ),
            ),
          ),
          const SizedBox(width: 12),
          TeacherAvatar(initials: initials),
        ],
      ),
    );
  }
}

/// `.form-group label` + `.form-control` wrapper.
class TeacherField extends StatelessWidget {
  final String label;
  final Widget child;
  const TeacherField({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: context.dr.textMuted),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

/// `select.form-control` — a styled dropdown.
class TeacherDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  const TeacherDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.dr.bgDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.dr.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(12),
          dropdownColor: context.dr.bgSurfaceLight,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: context.dr.textMuted,
          ),
          style: TextStyle(fontSize: 15, color: context.dr.textMain),
          items: items
              .map(
                (e) => DropdownMenuItem<T>(
                  value: e,
                  child: Text(labelOf(e), overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

/// `input.form-control` / `textarea.form-control`.
class TeacherInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int minLines;
  final TextInputType? keyboardType;

  const TeacherInput({
    super.key,
    required this.controller,
    required this.hint,
    this.minLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final multiline = minLines > 1;
    return Container(
      constraints: BoxConstraints(minHeight: multiline ? 100 : 50),
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: multiline ? 14 : 0,
      ),
      decoration: BoxDecoration(
        color: context.dr.bgDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.dr.border),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          minLines: minLines,
          maxLines: multiline ? null : 1,
          keyboardType:
              keyboardType ?? (multiline ? TextInputType.multiline : null),
          style: TextStyle(fontSize: 15, color: context.dr.textMain),
          decoration: InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
            hintText: hint,
            hintStyle: TextStyle(fontSize: 15, color: context.dr.textMuted),
          ),
        ),
      ),
    );
  }
}

/// `input[type=date].form-control` — opens the platform date picker.
class TeacherDatePicker extends StatelessWidget {
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  const TeacherDatePicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  /// `toLocaleDateString('en-US', {day, month, year})` — e.g. `16 July 2026`.
  static String format(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(value.year - 2),
          lastDate: DateTime(value.year + 2),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: context.dr.bgDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.dr.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                format(value),
                style: TextStyle(fontSize: 15, color: context.dr.textMain),
              ),
            ),
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: context.dr.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// `.student-avatar` — rounded square with initials.
class TeacherStudentAvatar extends StatelessWidget {
  final String initials;
  const TeacherStudentAvatar({super.key, required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.dr.bgSurfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.dr.border),
      ),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: context.dr.textMain,
        ),
      ),
    );
  }
}

/// `.student-row` — a divider-separated row inside a [TeacherListCard].
class TeacherRow extends StatelessWidget {
  final Widget child;
  final bool divider;
  final EdgeInsetsGeometry padding;
  const TeacherRow({
    super.key,
    required this.child,
    this.divider = true,
    this.padding = const EdgeInsets.symmetric(vertical: 15),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        border: divider
            ? Border(bottom: BorderSide(color: context.dr.border))
            : null,
      ),
      child: child,
    );
  }
}

/// `.list-container` — surface card that holds [TeacherRow]s.
class TeacherListCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  const TeacherListCard({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: context.dr.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.dr.border),
      ),
      child: Column(children: children),
    );
  }
}

/// `.day-tabs` — a row of equal-width day pills (Mon–Fri).
class TeacherDayTabs extends StatelessWidget {
  final List<String> days;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const TeacherDayTabs({
    super.key,
    required this.days,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(days.length, (i) {
        final active = i == selectedIndex;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == days.length - 1 ? 0 : 10),
            child: GestureDetector(
              onTap: () => onSelected(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? DrColors.accentGreen : context.dr.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: active ? DrColors.accentGreen : context.dr.border,
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: DrColors.accentGreen.withValues(alpha: 0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  days[i],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color: active ? Colors.black : context.dr.textMuted,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// `.report-tab-selector` — segmented control inside a rounded track.
class TeacherSegmented extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const TeacherSegmented({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.dr.bgSurfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.dr.border),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final active = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? DrColors.accentGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: DrColors.accentGreen.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.black : context.dr.textMuted,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// `.upload-zone` — dashed drop target that reveals `.file-selected-badge`
/// once [fileName] is set.
class TeacherUploadZone extends StatelessWidget {
  final String emoji;
  final String hint;
  final String? fileName;
  final VoidCallback onTap;

  const TeacherUploadZone({
    super.key,
    required this.emoji,
    required this.hint,
    required this.fileName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: DottedBorderBox(
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: context.dr.textMuted,
              ),
            ),
            if (fileName != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: DrColors.accentGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: DrColors.accentGreen),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: DrColors.accentGreen,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        fileName!,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: DrColors.accentGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Rounded rectangle with a 2px dashed stroke (`border: 2px dashed`).
class DottedBorderBox extends StatelessWidget {
  final Widget child;
  const DottedBorderBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(context.dr.border),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: child,
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  _DashedRectPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(14),
    );

    const dash = 6.0;
    const gap = 4.0;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter old) => old.color != color;
}

/// `.class-card` — time column, subject details, absolute status badge.
class TeacherClassCard extends StatelessWidget {
  final String time;
  final String duration;
  final String subject;
  final String group;
  final String room;
  final TeacherLessonStatus status;

  const TeacherClassCard({
    super.key,
    required this.time,
    required this.duration,
    required this.subject,
    required this.group,
    required this.room,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final ongoing = status == TeacherLessonStatus.ongoing;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.dr.bgSurfaceLight, context.dr.bgSurface],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.dr.border),
      ),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                constraints: const BoxConstraints(minWidth: 75),
                padding: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: context.dr.border),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.dr.textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      duration,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.dr.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      // Keep the title clear of the absolute status badge.
                      padding: const EdgeInsets.only(right: 70),
                      child: Text(
                        subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: context.dr.textMain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            group,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.dr.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          room,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.dr.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: ongoing
                    ? DrColors.accentGreen.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: ongoing ? DrColors.accentGreen : context.dr.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum TeacherLessonStatus { completed, ongoing, upcoming }

/// `.toast` — slides down from the top, auto-dismisses after 2.5s.
void showTeacherToast(BuildContext context, String text) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;

  final palette = context.dr;
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _Toast(
      text: text,
      palette: palette,
      onDismissed: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _Toast extends StatefulWidget {
  final String text;
  final DrPalette palette;
  final VoidCallback onDismissed;
  const _Toast({
    required this.text,
    required this.palette,
    required this.onDismissed,
  });

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    await _controller.forward();
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    await _controller.reverse();
    if (!mounted) return;
    widget.onDismissed();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 20,
      right: 20,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _controller,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, -0.4),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
            ),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: widget.palette.bgSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: DrColors.accentGreen),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x4D000000),
                        blurRadius: 30,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: widget.palette.textMain,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
