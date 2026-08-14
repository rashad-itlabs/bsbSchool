import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/domain/entities/auth_user.dart';
import '../../features/auth/domain/entities/child_account.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/notifications/presentation/widgets/notification_settings_card.dart';
import '../theme/dr_colors.dart';
import '../theme/theme_controller.dart';
import '../widgets/dr_widgets.dart';

/// Port of `pass.html` — student photo + settings list.
class PassScreen extends StatefulWidget {
  const PassScreen({super.key});

  @override
  State<PassScreen> createState() => _PassScreenState();
}

class _PassScreenState extends State<PassScreen> {
  bool _freeze = false;
  String _lang = 'AZ';

  void _changePin() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.dr.bgSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Şifrəni dəyiş',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.close, color: context.dr.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const DrTextField(
                  label: 'Yeni Şifrə',
                  hint: '••••',
                  obscure: true,
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              DrPrimaryButton(
                  label: 'Təsdiqlə',
                  onTap: () => Navigator.of(context).pop()),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.dr.bgSurface,
        title: const Text('Çıxış'),
        content: const Text('Hesabdan çıxmaq istədiyinizə əminsiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Ləğv et',
                style: TextStyle(color: context.dr.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Çıxış',
                style: TextStyle(color: dialogContext.dr.accent)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Clears the token; AuthGate reacts to `unauthenticated` and shows login.
    context.read<AuthBloc>().add(const AuthLogoutRequested());
  }

  @override
  Widget build(BuildContext context) {
    // The profile shows the account holder, not the child.
    final user = context.select<AuthBloc, AuthUser?>((bloc) => bloc.state.user);
    final name = user?.name ?? '';

    // Only a parent login carries the students' own credentials (`info`).
    final children = user?.children ?? const <ChildAccount>[];
    final activeChild =
        context.select<AuthBloc, ChildAccount?>((bloc) => bloc.state.activeChild);

    // "Class Group 7 • ID: 94" — of the student currently being shown, since
    // that's the one every other screen is scoped to. Either half is dropped
    // when the login response left it out.
    final className = activeChild?.className ?? user?.className;
    final classId = activeChild?.classId ?? user?.classId;
    final subtitle = [
      if (className != null && className.isNotEmpty) className,
      if (classId != null) 'ID: $classId',
    ].join(' • ');

    return DrScaffold(
      child: ListView(
        children: [
          const DrBackHeader(title: 'Tənzimləmələr', showBack: false),
          const SizedBox(height: 8),
          Center(
            child: Column(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.dr.accentSoft,
                    border: Border.all(color: context.dr.bgSurface, width: 4),
                  ),
                  child: Center(
                    child: Text(AuthUser.initialsOf(name),
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: context.dr.accent)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style:
                          TextStyle(fontSize: 13, color: context.dr.textMuted)),
                ],
              ],
            ),
          ),
          if (children.isNotEmpty) ...[
            const SizedBox(height: 24),
            DrSectionHeader(
              title: children.length > 1
                  ? 'Övladlarım (${children.length})'
                  : 'Övladımın məlumatları',
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                'Bu e-mail və şifrə ilə övladınız tətbiqə öz hesabı ilə '
                'daxil ola bilər. Kopyalayıb ona göndərə bilərsiniz.',
                style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: context.dr.textMuted),
              ),
            ),
            for (final child in children) ...[
              _ChildCredentialsCard(
                child: child,
                active: child.childId != null &&
                    child.childId == activeChild?.childId,
                // Second way into the switch, for parents who come looking for
                // it in the profile rather than the dashboard avatar.
                onSelect: children.length > 1 && child.childId != null
                    ? () => context
                        .read<AuthBloc>()
                        .add(AuthChildSelected(child.childId!))
                    : null,
              ),
              const SizedBox(height: 12),
            ],
          ],
          const SizedBox(height: 24),
          DrListCard(
            children: [
              // DrSettingItem(
              //   icon: Icons.lock_outline,
              //   iconColor: DrColors.accentGreen,
              //   title: 'Şifrəni dəyiş',
              //   subtitle: 'Turniket və yeməkxana üçün',
              //   onTap: _changePin,
              //   trailing: Icon(Icons.chevron_right,
              //       color: context.dr.textMuted, size: 18),
              // ),
              DrSettingItem(
                icon: Icons.light_mode_outlined,
                iconColor: DrColors.orange,
                title: 'Gündüz rejimi',
                subtitle: 'Açıq rəngli interfeys',
                trailing: DrSwitch(
                    value: Theme.of(context).brightness == Brightness.light,
                    onChanged: (v) => ThemeController.instance
                        .setMode(v ? ThemeMode.light : ThemeMode.dark)),
              ),
              DrSettingItem(
                icon: Icons.language,
                iconColor: const Color(0xFFA8A8A8),
                title: 'Dil / Language',
                subtitle: 'Azərbaycan, English, Русский',
                divider: false,
                trailing: _langDropdown(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const DrSectionHeader(title: 'Bildiriş parametrləri'),
          // Same switches as the notifications tab, driven by the shared
          // NotificationPrefs, so both places stay in agreement.
          const NotificationSettingsCard(),
          const SizedBox(height: 10),
          DrListCard(
            children: [
              DrSettingItem(
                icon: Icons.logout,
                iconColor: DrColors.redStrong,
                title: 'Çıxış',
                titleColor: DrColors.redStrong,
                subtitle: 'Tətbiqdən çıxın',
                divider: false,
                onTap: _logout,
                trailing: Icon(Icons.chevron_right,
                    color: DrColors.redStrong, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _langDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: context.dr.bgSurfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _lang,
          isDense: true,
          dropdownColor: context.dr.bgSurfaceLight,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.dr.textMain),
          items: const ['AZ', 'EN', 'RU']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => setState(() => _lang = v ?? 'AZ'),
        ),
      ),
    );
  }
}

/// One student from the login response's `info`: who they are, plus the
/// credentials the parent passes on to them. The password starts hidden so the
/// card can be shown to someone without leaking it — copying works either way.
class _ChildCredentialsCard extends StatefulWidget {
  final ChildAccount child;

  /// True for the student the rest of the app is currently showing.
  final bool active;

  /// Switches the app to this student. Null when there's nothing to switch
  /// (a single student, or one the response gave no id).
  final VoidCallback? onSelect;

  const _ChildCredentialsCard({
    required this.child,
    this.active = false,
    this.onSelect,
  });

  @override
  State<_ChildCredentialsCard> createState() => _ChildCredentialsCardState();
}

class _ChildCredentialsCardState extends State<_ChildCredentialsCard> {
  bool _showPassword = false;

  Future<void> _copy(String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$label kopyalandı'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    final fullName = child.fullName;
    final active = widget.active;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.dr.bgSurface,
        borderRadius: BorderRadius.circular(20),
        // The active student's card is ringed in the accent, matching the
        // dashboard switcher's checkmark.
        border: Border.all(
          color: active ? context.dr.accent : context.dr.border,
          width: active ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.dr.accentSoft,
                ),
                child: Center(
                  child: Text(
                    AuthUser.initialsOf(fullName),
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.dr.accent),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 15.5, fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (active) ...[
                          const SizedBox(width: 8),
                          _activePill(),
                        ],
                      ],
                    ),
                    if (child.className.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        child.className,
                        style: TextStyle(
                            fontSize: 12.5, color: context.dr.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              if (child.paymentId.isNotEmpty) _paymentBadge(child.paymentId),
            ],
          ),
          if (!active && widget.onSelect != null) ...[
            const SizedBox(height: 12),
            _switchButton(),
          ],
          const SizedBox(height: 14),
          if (child.email.isNotEmpty)
            _CredentialRow(
              icon: Icons.alternate_email,
              label: 'E-mail',
              value: child.email,
              onCopy: () => _copy(child.email, 'E-mail'),
            ),
          if (child.email.isNotEmpty && child.password.isNotEmpty)
            const SizedBox(height: 10),
          if (child.password.isNotEmpty)
            _CredentialRow(
              icon: Icons.lock_outline,
              label: 'Şifrə',
              value: child.password,
              obscured: !_showPassword,
              onToggleVisibility: () =>
                  setState(() => _showPassword = !_showPassword),
              onCopy: () => _copy(child.password, 'Şifrə'),
            ),
        ],
      ),
    );
  }

  Widget _activePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.dr.accentSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Aktiv',
        style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: context.dr.accent),
      ),
    );
  }

  /// Mirrors the dashboard avatar's dropdown: switches every screen over to
  /// this student.
  Widget _switchButton() {
    final switching =
        context.select<AuthBloc, bool>((bloc) => bloc.state.isSwitchingChild);

    return GestureDetector(
      onTap: switching ? null : widget.onSelect,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: context.dr.accentSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (switching)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  valueColor: AlwaysStoppedAnimation(context.dr.accent),
                ),
              )
            else
              Icon(Icons.swap_horiz_rounded,
                  size: 16, color: context.dr.accent),
            const SizedBox(width: 8),
            Text(
              switching ? 'Dəyişdirilir…' : 'Bu şagirdə keç',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.dr.accent),
            ),
          ],
        ),
      ),
    );
  }

  /// The payment reference is read out loud more often than it is typed, so it
  /// sits as a tappable badge rather than a full credential row.
  Widget _paymentBadge(String paymentId) {
    return GestureDetector(
      onTap: () => _copy(paymentId, 'Ödəniş ID'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: context.dr.bgSurfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.dr.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pay.ID: $paymentId',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.dr.textMain),
            ),
            const SizedBox(width: 6),
            Icon(Icons.copy_rounded, size: 13, color: context.dr.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Label + value on a tinted strip, with a copy button (and an eye toggle when
/// the value is a password).
class _CredentialRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool obscured;
  final VoidCallback? onToggleVisibility;
  final VoidCallback onCopy;

  const _CredentialRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onCopy,
    this.obscured = false,
    this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: context.dr.bgSurfaceLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: context.dr.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.dr.textMuted),
                ),
                const SizedBox(height: 3),
                Text(
                  obscured ? '•' * value.length : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: context.dr.textMain,
                    letterSpacing: obscured ? 2 : 0.1,
                  ),
                ),
              ],
            ),
          ),
          if (onToggleVisibility != null)
            IconButton(
              onPressed: onToggleVisibility,
              visualDensity: VisualDensity.compact,
              tooltip: obscured ? 'Göstər' : 'Gizlət',
              icon: Icon(
                obscured
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: context.dr.textMuted,
              ),
            ),
          IconButton(
            onPressed: onCopy,
            visualDensity: VisualDensity.compact,
            tooltip: 'Kopyala',
            icon: Icon(Icons.copy_rounded, size: 18, color: context.dr.accent),
          ),
        ],
      ),
    );
  }
}
