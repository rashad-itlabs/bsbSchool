import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/domain/entities/auth_user.dart';
import '../../features/auth/domain/entities/child_account.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../theme/dr_colors.dart';

/// The dashboard avatar, doubling as the student picker for a parent with more
/// than one child. Tapping drops a menu of the account's students; choosing one
/// re-points every screen at them (see [AuthChildSelected]).
///
/// With a single student there is nothing to pick, so it stays a plain avatar.
class ChildSwitcher extends StatelessWidget {
  /// Active student's name — the initials come from it.
  final String name;

  /// False when the account has one student or none.
  final bool enabled;

  const ChildSwitcher({super.key, required this.name, this.enabled = false});

  @override
  Widget build(BuildContext context) {
    if (!enabled) return _Avatar(name: name);

    final children =
        context.select<AuthBloc, List<ChildAccount>>((b) => b.state.children);
    final activeId =
        context.select<AuthBloc, int?>((b) => b.state.activeChild?.childId);
    // `/selectChild` in flight — the avatar still shows the old student until
    // the backend confirms the new one.
    final switching =
        context.select<AuthBloc, bool>((b) => b.state.isSwitchingChild);

    if (switching) return _Avatar(name: name, busy: true);

    return PopupMenuButton<int>(
      // Drops the sheet under the avatar rather than over it.
      offset: const Offset(0, 52),
      tooltip: 'Şagird seç',
      padding: EdgeInsets.zero,
      color: context.dr.bgSurface,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: context.dr.border),
      ),
      onSelected: (childId) {
        if (childId == activeId) return;
        context.read<AuthBloc>().add(AuthChildSelected(childId));
      },
      itemBuilder: (menuContext) => [
        for (final child in children)
          PopupMenuItem<int>(
            // Students without an id can't be selected — nothing to scope the
            // requests with — so they'd silently no-op.
            enabled: child.childId != null,
            value: child.childId ?? -1,
            child: _ChildRow(
              child: child,
              active: child.childId == activeId,
            ),
          ),
      ],
      child: _Avatar(name: name, showChevron: true),
    );
  }
}

/// Green ring + black disc + initials — the dashboard's profile bubble.
class _Avatar extends StatelessWidget {
  final String name;
  final bool showChevron;

  /// Swaps the chevron badge for a spinner while the switch is in flight.
  final bool busy;

  const _Avatar({
    required this.name,
    this.showChevron = false,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
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
        decoration:
            const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
        child: Text(AuthUser.initialsOf(name),
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
      ),
    );

    if (!showChevron && !busy) return avatar;

    // The badge is the only hint that the avatar is tappable, so it sits proud
    // of the ring with a background-coloured rim to stay visible on both themes.
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(opacity: busy ? 0.5 : 1, child: avatar),
          Positioned(
            right: 0,
            bottom: 2,
            child: Container(
              width: 18,
              height: 18,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.dr.bgSurfaceLight,
                shape: BoxShape.circle,
                border: Border.all(color: context.dr.bgDark, width: 2),
              ),
              child: busy
                  ? SizedBox(
                      width: 9,
                      height: 9,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.6,
                        valueColor: AlwaysStoppedAnimation(context.dr.accent),
                      ),
                    )
                  : Icon(Icons.keyboard_arrow_down_rounded,
                      size: 12, color: context.dr.textMain),
            ),
          ),
        ],
      ),
    );
  }
}

/// One line of the dropdown: who the student is and whether they're the one
/// currently being shown.
class _ChildRow extends StatelessWidget {
  final ChildAccount child;
  final bool active;

  const _ChildRow({required this.child, required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? context.dr.accentSoft : context.dr.bgSurfaceLight,
            border: Border.all(
              color: active ? context.dr.accent : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            AuthUser.initialsOf(child.fullName),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: active ? context.dr.accent : context.dr.textMuted,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                child.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: context.dr.textMain,
                ),
              ),
              if (child.className.isNotEmpty)
                Text(
                  child.className,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: context.dr.textMuted),
                ),
            ],
          ),
        ),
        if (active) ...[
          const SizedBox(width: 8),
          Icon(Icons.check_rounded, size: 18, color: context.dr.accent),
        ],
      ],
    );
  }
}
