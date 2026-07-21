import 'package:flutter/material.dart';

import '../theme/dr_colors.dart';

/// Page scaffold that mimics the `.mobile-container` (dark bg + horizontal
/// padding). Content scrolls; an optional [bottomNav] is pinned to the bottom.
class DrScaffold extends StatelessWidget {
  final Widget child;
  final Widget? bottomNav;
  final EdgeInsetsGeometry padding;

  const DrScaffold({
    super.key,
    required this.child,
    this.bottomNav,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 24),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.dr.bgDark,
      body: SafeArea(
        bottom: false,
        child: Padding(padding: padding, child: child),
      ),
      bottomNavigationBar: bottomNav,
    );
  }
}

/// `.schedule-header` — circular green back button, centered title, spacer.
class DrBackHeader extends StatelessWidget {
  final String title;
  final bool showBack;
  const DrBackHeader({super.key, required this.title, this.showBack = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          if (showBack)
            _GreenCircleButton(
              icon: Icons.chevron_left_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            )
          else
            const SizedBox(width: 44),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.dr.textMain,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class _GreenCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GreenCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
        child: Icon(icon, color: Colors.black, size: 24),
      ),
    );
  }
}

/// `.section-header` — bold title + optional green "see all" link.
class DrSectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const DrSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
    this.fontSize = 18,
    this.padding = const EdgeInsets.only(bottom: 15),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: context.dr.textMain,
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                action!,
                style: const TextStyle(
                  fontSize: 13,
                  color: DrColors.accentGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// `.primary-btn` — full-width neon green call-to-action.
class DrPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? trailingIcon;
  final VoidCallback? onTap;

  /// When true a spinner replaces the label and taps are ignored.
  final bool loading;

  const DrPrimaryButton({
    super.key,
    required this.label,
    this.trailingIcon,
    this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = loading || onTap == null;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled && !loading ? 0.6 : 1,
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: DrColors.accentGreen,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: DrColors.accentGreen.withValues(alpha: 0.4),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: loading
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.black,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: 12),
                      Icon(trailingIcon, color: Colors.black, size: 20),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

/// A surface card (`.bg-surface` rounded container with border).
class DrCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Gradient? gradient;
  const DrCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 20,
    this.color,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? context.dr.bgSurface) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: context.dr.border),
      ),
      child: child,
    );
  }
}

/// `.limit-card` with the soft green corner glow.
class DrGlowCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  const DrGlowCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [context.dr.bgSurfaceLight, context.dr.bgSurface],
          ),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 30,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -75,
              right: -75,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: DrColors.accentGreen.withValues(alpha: 0.18),
                      blurRadius: 60,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

/// Rounded square icon badge with an emoji (or text) glyph and tinted bg.
class DrEmojiBadge extends StatelessWidget {
  final String emoji;
  final Color color;
  final double size;
  final double radius;
  const DrEmojiBadge({
    super.key,
    required this.emoji,
    required this.color,
    this.size = 44,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(emoji, style: TextStyle(fontSize: size * 0.45)),
    );
  }
}

/// `.transaction-item` row used by history, cafeteria, exams, etc.
class DrTransactionTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget trailing;
  final bool divider;
  const DrTransactionTile({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.divider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: divider
            ? Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
              )
            : null,
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.dr.textMain,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: context.dr.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

/// Container that groups [children] like `.transactions-list` / `.settings-list`.
class DrListCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  const DrListCard({
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

/// `.filter-chip` / `.genre-pill` — selectable rounded pill.
class DrFilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;
  const DrFilterChip({
    super.key,
    required this.label,
    required this.active,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 24),
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
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            color: active ? Colors.black : context.dr.textMuted,
          ),
        ),
      ),
    );
  }
}

/// Horizontal scroller of [DrFilterChip]s.
class DrChipBar extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  const DrChipBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) => DrFilterChip(
          label: labels[i],
          active: i == selectedIndex,
          onTap: () => onSelected(i),
        ),
      ),
    );
  }
}

/// `.setting-item` row with tinted leading icon + optional trailing widget.
class DrSettingItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool divider;
  final Color? titleColor;
  const DrSettingItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
    this.divider = true,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: divider
              ? Border(bottom: BorderSide(color: context.dr.border))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: titleColor ?? context.dr.textMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: context.dr.textMuted),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

/// `.input-wrapper` styled text field used by login / top-up forms.
class DrTextField extends StatelessWidget {
  final String? label;
  final String hint;
  final IconData? icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextAlign textAlign;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final bool enabled;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  const DrTextField({
    super.key,
    this.label,
    required this.hint,
    this.icon,
    this.obscure = false,
    this.keyboardType,
    this.textAlign = TextAlign.start,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.enabled = true,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(fontSize: 12, color: context.dr.textMuted),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: context.dr.bgDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.dr.border),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: context.dr.textMuted),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  textInputAction: textInputAction,
                  enabled: enabled,
                  autofocus: autofocus,
                  textCapitalization: textCapitalization,
                  obscureText: obscure,
                  keyboardType: keyboardType,
                  textAlign: textAlign,
                  style: TextStyle(
                    fontSize: 15,
                    color: context.dr.textMain,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: hint,
                    // Was hardcoded white@20%, which is invisible on the light
                    // palette's near-white field fill.
                    hintStyle: TextStyle(
                      color: context.dr.textMuted.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Pill toggle matching `.toggle-switch` (uses Material [Switch]).
class DrSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const DrSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.black,
      activeTrackColor: DrColors.accentGreen,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    );
  }
}
