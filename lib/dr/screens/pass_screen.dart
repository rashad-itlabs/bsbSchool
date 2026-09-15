import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/injection_container.dart';
import '../../features/auth/domain/entities/auth_user.dart';
import '../../features/auth/domain/entities/child_account.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/cubit/profile_cubit.dart';
import '../../features/notifications/presentation/widgets/notification_settings_card.dart';
import '../../core/l10n/l10n.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/utils/az_phone.dart';
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

  /// The parent's own row — name, e-mail, phone.
  ///
  /// Takes the user it was built with rather than reading the bloc inside the
  /// sheet: the fields are seeded once, and a refresh landing mid-edit must
  /// not overwrite what is being typed.
  void _openEditProfile(AuthUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider(
        create: (_) => sl<ProfileCubit>(),
        child: _ProfileSheet(user: user),
      ),
    );
  }

  /// The account's own password. The parent is already signed in, so the
  /// proof is the password they have rather than a mailed code — that route
  /// stays on the login screen, for whoever cannot get in at all.
  void _openChangePassword() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider(
        create: (_) => sl<ProfileCubit>(),
        child: const _PasswordSheet(),
      ),
    );
  }

  /// Links another student to the account.
  ///
  /// Registration only takes one admission code, but the school issues one per
  /// child, so a parent with several of them has no way to reach the rest at
  /// sign-up time. This is that way.
  void _openAddChild() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddChildSheet(),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.dr.bgSurface,
        title: Text(context.l10n.settingsLogout),
        content: Text(context.l10n.settingsLogoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              context.l10n.commonCancel,
              style: TextStyle(color: context.dr.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              context.l10n.settingsLogout,
              style: TextStyle(color: dialogContext.dr.accent),
            ),
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
    final isParent = user?.isParent ?? false;
    // A parent keeps the section even with nothing linked yet — the add tile
    // is the way out of that state. Anyone else only gets it if the login
    // actually carried students.
    final showChildren = isParent || children.isNotEmpty;
    final activeChild = context.select<AuthBloc, ChildAccount?>(
      (bloc) => bloc.state.activeChild,
    );

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
          DrBackHeader(title: context.l10n.settingsTitle, showBack: false),
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
                    child: Text(
                      AuthUser.initialsOf(name),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: context.dr.accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: context.dr.textMuted),
                  ),
                ],
              ],
            ),
          ),
          if (showChildren) ...[
            const SizedBox(height: 24),
            DrSectionHeader(
              title: children.length > 1
                  ? context.l10n.settingsMyChildren(children.length)
                  : context.l10n.settingsMyChild,
            ),
            // Nothing to explain while there are no credentials on screen.
            if (children.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  context.l10n.settingsChildCredentials,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: context.dr.textMuted,
                  ),
                ),
              ),
            for (final child in children) ...[
              _ChildCredentialsCard(
                child: child,
                active:
                    child.childId != null &&
                    child.childId == activeChild?.childId,
                // Second way into the switch, for parents who come looking for
                // it in the profile rather than the dashboard avatar.
                onSelect: children.length > 1 && child.childId != null
                    ? () => context.read<AuthBloc>().add(
                        AuthChildSelected(child.childId!),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
            ],
            if (isParent) _AddChildTile(onTap: _openAddChild),
          ],
          const SizedBox(height: 24),
          DrListCard(
            children: [
              DrSettingItem(
                icon: Icons.badge_outlined,
                iconColor: DrColors.accentGreen,
                title: context.l10n.profileEdit,
                // The details themselves, not a description of them: what the
                // parent checks here is whether the address and number on the
                // account are still theirs.
                subtitle: context.l10n.profileEditSubtitle,   //_contactLine(context, user),
                onTap: user == null ? null : () => _openEditProfile(user),
                trailing: Icon(
                  Icons.chevron_right,
                  color: context.dr.textMuted,
                  size: 18,
                ),
              ),
              DrSettingItem(
                icon: Icons.lock_outline,
                iconColor: DrColors.accentGreen,
                title: context.l10n.profilePassword,
                subtitle: context.l10n.profilePasswordSubtitle,
                onTap: _openChangePassword,
                trailing: Icon(
                  Icons.chevron_right,
                  color: context.dr.textMuted,
                  size: 18,
                ),
              ),
              DrSettingItem(
                icon: Icons.light_mode_outlined,
                iconColor: DrColors.orange,
                title: context.l10n.settingsLightMode,
                subtitle: context.l10n.settingsLightModeSubtitle,
                trailing: DrSwitch(
                  value: Theme.of(context).brightness == Brightness.light,
                  onChanged: (v) => ThemeController.instance.setMode(
                    v ? ThemeMode.light : ThemeMode.dark,
                  ),
                ),
              ),
              DrSettingItem(
                icon: Icons.language,
                iconColor: const Color(0xFFA8A8A8),
                title: context.l10n.settingsLanguage,
                subtitle: _languageSubtitle(context),
                divider: false,
                trailing: _langDropdown(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          DrSectionHeader(title: context.l10n.settingsNotifications),
          // Same switches as the notifications tab, driven by the shared
          // NotificationPrefs, so both places stay in agreement.
          const NotificationSettingsCard(),
          const SizedBox(height: 10),
          DrListCard(
            children: [
              DrSettingItem(
                icon: Icons.logout,
                iconColor: DrColors.redStrong,
                title: context.l10n.settingsLogout,
                titleColor: DrColors.redStrong,
                subtitle: context.l10n.settingsLogoutSubtitle,
                divider: false,
                onTap: _logout,
                trailing: Icon(
                  Icons.chevron_right,
                  color: DrColors.redStrong,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// `resad@gmail.com · +994 55 669 12 48` — whichever halves the login
  /// response carried, falling back to naming the fields when it carried
  /// neither.
  String _contactLine(BuildContext context, AuthUser? user) {
    final parts = [
      if (user != null && user.email.isNotEmpty) user.email,
      if (user?.phone != null && AzPhone.format(user!.phone!).isNotEmpty)
        AzPhone.format(user.phone!),
    ];
    return parts.isEmpty ? context.l10n.profileEditSubtitle : parts.join(' · ');
  }

  /// Names the language actually in use, so "Sistem dili" still tells the
  /// parent which one that turned out to be.
  String _languageSubtitle(BuildContext context) {
    final l10n = context.l10n;
    final name = switch (Localizations.localeOf(context).languageCode) {
      'en' => l10n.languageEn,
      'ru' => l10n.languageRu,
      _ => l10n.languageAz,
    };
    return LocaleController.instance.isSystem
        ? '${l10n.languageSystem} · $name'
        : name;
  }

  Widget _langDropdown() {
    // The controller stores null for "follow the device"; the dropdown needs a
    // value it can compare, hence the sentinel.
    const system = 'system';
    final current = LocaleController.instance.locale?.languageCode ?? system;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: context.dr.bgSurfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.dr.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          isDense: true,
          dropdownColor: context.dr.bgSurfaceLight,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.dr.textMain,
          ),
          items: const [
            DropdownMenuItem(value: system, child: Text('Auto')),
            DropdownMenuItem(value: 'az', child: Text('AZ')),
            DropdownMenuItem(value: 'en', child: Text('EN')),
            DropdownMenuItem(value: 'ru', child: Text('RU')),
          ],
          onChanged: (value) => LocaleController.instance.setLocale(
            value == null || value == system ? null : Locale(value),
          ),
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

  /// The student's login address. The parent holds these credentials, so
  /// they are the one who corrects a typo in them.
  void _editEmail() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider(
        create: (_) => sl<ProfileCubit>(),
        child: _ChildEmailSheet(child: widget.child),
      ),
    );
  }

  Future<void> _copy(String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.l10n.copiedToClipboard(label)),
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
                      color: context.dr.accent,
                    ),
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
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                            ),
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
                          fontSize: 12.5,
                          color: context.dr.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (!active && widget.onSelect != null) ...[
            const SizedBox(height: 12),
            _switchButton(),
          ],
          const SizedBox(height: 14),
          if (child.username.isNotEmpty)
            _CredentialRow(
              icon: Icons.payment,
              label: 'Pay.ID:',
              value: child.paymentId,
              onCopy: () => _copy(child.paymentId, 'Pay ID'),
            ),
          const SizedBox(height: 14),
          if (child.email.isNotEmpty)
            _CredentialRow(
              icon: Icons.alternate_email,
              label: context.l10n.loginEmail,
              value: child.email,
              onCopy: () => _copy(child.email, context.l10n.loginEmail),
              // Only a student the response gave an id for can be named to
              // the endpoint.
              onEdit: child.childId == null ? null : _editEmail,
            ),
          const SizedBox(height: 14),
          if (child.username.isNotEmpty)
            _CredentialRow(
              icon: Icons.alternate_email,
              label: context.l10n.credentialUsername,
              value: child.username,
              onCopy: () =>
                  _copy(child.username, context.l10n.credentialUsername),
            ),
          if (child.email.isNotEmpty && child.password.isNotEmpty)
            const SizedBox(height: 10),
          if (child.password.isNotEmpty)
            _CredentialRow(
              icon: Icons.lock_outline,
              label: context.l10n.loginPassword,
              value: child.password,
              obscured: !_showPassword,
              onToggleVisibility: () =>
                  setState(() => _showPassword = !_showPassword),
              onCopy: () => _copy(child.password, context.l10n.loginPassword),
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
        context.l10n.credentialActive,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: context.dr.accent,
        ),
      ),
    );
  }

  /// Mirrors the dashboard avatar's dropdown: switches every screen over to
  /// this student.
  Widget _switchButton() {
    final switching = context.select<AuthBloc, bool>(
      (bloc) => bloc.state.isSwitchingChild,
    );

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
              Icon(
                Icons.swap_horiz_rounded,
                size: 16,
                color: context.dr.accent,
              ),
            const SizedBox(width: 8),
            Text(
              switching
                  ? context.l10n.credentialSwitching
                  : context.l10n.credentialSwitchTo,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.dr.accent,
              ),
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
      onTap: () => _copy(paymentId, context.l10n.credentialPaymentId),
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
                color: context.dr.textMain,
              ),
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

  /// Opens the sheet that changes this value. Absent on rows the school
  /// issues and the parent cannot alter.
  final VoidCallback? onEdit;

  const _CredentialRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onCopy,
    this.obscured = false,
    this.onToggleVisibility,
    this.onEdit,
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
                    color: context.dr.textMuted,
                  ),
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
              tooltip: obscured
                  ? context.l10n.commonShow
                  : context.l10n.commonHide,
              icon: Icon(
                obscured
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: context.dr.textMuted,
              ),
            ),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              visualDensity: VisualDensity.compact,
              tooltip: context.l10n.profileChildEmailTitle,
              icon: Icon(
                Icons.edit_outlined,
                size: 18,
                color: context.dr.textMuted,
              ),
            ),
          IconButton(
            onPressed: onCopy,
            visualDensity: VisualDensity.compact,
            tooltip: context.l10n.commonCopy,
            icon: Icon(Icons.copy_rounded, size: 18, color: context.dr.accent),
          ),
        ],
      ),
    );
  }
}

/// The empty slot at the end of the student list: tapping it opens
/// [_AddChildSheet] to link one more.
///
/// Deliberately not a [_ChildCredentialsCard] look-alike — same radius and
/// fill so it sits in the same column, but outlined in the accent rather than
/// the neutral border, so it reads as an action and not as a student whose
/// details failed to load.
class _AddChildTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AddChildTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.dr.bgSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.dr.accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.dr.accentSoft,
              ),
              child: Icon(
                Icons.add_rounded,
                size: 22,
                color: context.dr.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.settingsAddChild,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.settingsAddChildSubtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: context.dr.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: context.dr.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Links one more student to the signed-in parent account, by admission
/// number — the same code registration asks for, since it is the only thing a
/// parent holds that names a student without exposing the school's ids.
///
/// A sheet rather than a route: the parent came here to look at their
/// students, and lands back on that list with the new one in it.
///
/// The request runs on [AuthBloc], not here, because its result changes the
/// signed-in session — the sheet only reads `isAddingChild` / `addChildError`
/// back out.
class _AddChildSheet extends StatefulWidget {
  const _AddChildSheet();

  @override
  State<_AddChildSheet> createState() => _AddChildSheetState();
}

class _AddChildSheetState extends State<_AddChildSheet> {
  final _admissionController = TextEditingController();

  /// What the field is currently being told off for: the empty-input check
  /// below, or the message `/attachChild` came back with.
  String? _error;

  @override
  void dispose() {
    _admissionController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final admissionNo = _admissionController.text.trim();
    if (admissionNo.isEmpty) {
      setState(() => _error = context.l10n.addChildEnterNumber);
      return;
    }

    setState(() => _error = null);
    context.read<AuthBloc>().add(AuthChildAdded(admissionNo));
  }

  /// Fires once the request settles. A rejected code keeps the sheet open with
  /// the server's wording under the field — the parent's next move is to
  /// correct the number, and closing would make them start over.
  void _onSettled(BuildContext context, AuthState state) {
    final failure = state.addChildError;
    if (failure != null) {
      setState(() => _error = failure);
      return;
    }

    // Both are read before the pop, which deactivates this context.
    final messenger = ScaffoldMessenger.of(context);
    final addedMessage = context.l10n.addChildAdded;

    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(addedMessage)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.isAddingChild && !current.isAddingChild,
      listener: _onSettled,
      child: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final submitting = context.select<AuthBloc, bool>(
      (bloc) => bloc.state.isAddingChild,
    );

    return Padding(
      // Keeps the field above the keyboard the autofocus just raised.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.dr.bgSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: context.dr.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.dr.accentSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 20,
                        color: context.dr.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.l10n.addChildTitle,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    // Closing mid-flight would leave the request running with
                    // nowhere to report back to.
                    GestureDetector(
                      onTap: submitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Icon(Icons.close, color: context.dr.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  context.l10n.addChildAnotherText,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: context.dr.textMuted,
                  ),
                ),
                const SizedBox(height: 20),
                DrTextField(
                  label: context.l10n.addChildField,
                  hint: context.l10n.addChildHint,
                  icon: Icons.badge_outlined,
                  controller: _admissionController,
                  enabled: !submitting,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  // Codes are alphanumeric: keep iOS from capitalising the
                  // first character on the parent's behalf.
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  onSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 16,
                        color: DrColors.redStrong,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: DrColors.redStrong,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                const _WhereToFindHint(),
                const SizedBox(height: 20),
                DrPrimaryButton(
                  label: context.l10n.addChildSubmit,
                  trailingIcon: Icons.arrow_forward_rounded,
                  loading: submitting,
                  onTap: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Where the admission number lives, so an unknown code is a lookup rather
/// than a call to the school. Compact twin of `AddChildScreen`'s card — the
/// sheet has a keyboard to share the screen with.
class _WhereToFindHint extends StatelessWidget {
  const _WhereToFindHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.dr.bgSurfaceLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline_rounded,
                size: 16,
                color: context.dr.accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.addChildWhereTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final line in [
            context.l10n.addChildWhere1,
            context.l10n.addChildWhere2,
            context.l10n.addChildWhere3,
          ])
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.dr.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      line,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: context.dr.textMuted,
                      ),
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

/// Chrome the two edit sheets share: grab handle, tinted icon, title, and a
/// close control that is disabled while a save is in flight — closing then
/// would leave the request running with nowhere to report back to.
class _EditSheetFrame extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool busy;
  final List<Widget> children;

  const _EditSheetFrame({
    required this.icon,
    required this.title,
    required this.busy,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Keeps the fields above the keyboard the autofocus just raised.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.dr.bgSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: context.dr.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.dr.accentSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, size: 20, color: context.dr.accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: busy ? null : () => Navigator.of(context).pop(),
                      child: Icon(Icons.close, color: context.dr.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One rejected input, under the field that caused it.
class _FieldError extends StatelessWidget {
  final String message;

  const _FieldError(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 15, color: DrColors.redStrong),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: DrColors.redStrong),
            ),
          ),
        ],
      ),
    );
  }
}

/// The parent's own details. Seeded from the cached user, saved through
/// [ProfileCubit]; `AuthBloc` is told to re-read the cache once it lands, so
/// the profile behind the sheet shows the new values immediately.
class _ProfileSheet extends StatefulWidget {
  final AuthUser user;

  const _ProfileSheet({required this.user});

  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> {
  late final _nameController = TextEditingController(text: widget.user.name);
  late final _emailController = TextEditingController(text: widget.user.email);
  // Whatever shape the backend stored it in, the field shows the one format.
  late final _phoneController = TextEditingController(
    text: AzPhone.format(widget.user.phone ?? ''),
  );

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<ProfileCubit>().saveProfile(
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status != ProfileStatus.success) return;

        // Read before the pop, which deactivates this context.
        final messenger = ScaffoldMessenger.of(context);
        final saved = state.message ?? context.l10n.profileSaved;

        // The repository has already cached the new user; this is what puts it
        // on screen.
        context.read<AuthBloc>().add(const AuthSessionRefreshed());
        Navigator.of(context).pop();
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(saved)));
      },
      builder: (context, state) {
        final busy = state.isLoading;
        final formError = state.formError;

        return _EditSheetFrame(
          icon: Icons.badge_outlined,
          title: context.l10n.profileTitle,
          busy: busy,
          children: [
            DrTextField(
              label: context.l10n.profileName,
              hint: context.l10n.profileName,
              icon: Icons.person_outline,
              controller: _nameController,
              enabled: !busy,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              onChanged: (_) => context.read<ProfileCubit>().inputChanged(),
            ),
            if (state.errorFor('name') != null)
              _FieldError(state.errorFor('name')!),
            const SizedBox(height: 16),
            DrTextField(
              label: context.l10n.forgotEmailField,
              hint: 'example@bsb.edu.az',
              icon: Icons.mail_outline,
              controller: _emailController,
              enabled: !busy,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onChanged: (_) => context.read<ProfileCubit>().inputChanged(),
            ),
            if (state.errorFor('email') != null)
              _FieldError(state.errorFor('email')!),
            const SizedBox(height: 16),
            DrPhoneField(
              label: context.l10n.profilePhone,
              hint: '+994 50 123 45 67',
              controller: _phoneController,
              enabled: !busy,
              textInputAction: TextInputAction.done,
              onChanged: (_) => context.read<ProfileCubit>().inputChanged(),
              onSubmitted: (_) => _submit(),
            ),
            if (state.errorFor('phone') != null)
              _FieldError(state.errorFor('phone')!),
            const SizedBox(height: 12),
            Text(
              context.l10n.profileEmailNote,
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: context.dr.textMuted,
              ),
            ),
            if (formError != null) _FieldError(formError),
            const SizedBox(height: 20),
            DrPrimaryButton(
              label: context.l10n.commonSave,
              trailingIcon: Icons.check_rounded,
              loading: busy,
              onTap: _submit,
            ),
          ],
        );
      },
    );
  }
}

/// The login address of one student. Same shape as [_ProfileSheet], one field
/// wide — the student keeps everything else the school issued.
class _ChildEmailSheet extends StatefulWidget {
  final ChildAccount child;

  const _ChildEmailSheet({required this.child});

  @override
  State<_ChildEmailSheet> createState() => _ChildEmailSheetState();
}

class _ChildEmailSheetState extends State<_ChildEmailSheet> {
  late final _emailController = TextEditingController(
    text: widget.child.email,
  );

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    final childId = widget.child.childId;
    if (childId == null) return;

    FocusScope.of(context).unfocus();
    context.read<ProfileCubit>().saveChildEmail(
      childId: childId,
      email: _emailController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status != ProfileStatus.success) return;

        final messenger = ScaffoldMessenger.of(context);
        final saved = state.message ?? context.l10n.profileChildEmailSaved;

        context.read<AuthBloc>().add(const AuthSessionRefreshed());
        Navigator.of(context).pop();
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(saved)));
      },
      builder: (context, state) {
        final busy = state.isLoading;
        final formError = state.formError;

        return _EditSheetFrame(
          icon: Icons.alternate_email,
          title: context.l10n.profileChildEmailTitle,
          busy: busy,
          children: [
            Text(
              context.l10n.profileChildEmailText(widget.child.fullName),
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: context.dr.textMuted,
              ),
            ),
            const SizedBox(height: 18),
            DrTextField(
              label: context.l10n.forgotEmailField,
              hint: 'std@bsb.edu.az',
              icon: Icons.mail_outline,
              controller: _emailController,
              enabled: !busy,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onChanged: (_) => context.read<ProfileCubit>().inputChanged(),
              onSubmitted: (_) => _submit(),
            ),
            if (state.errorFor('email') != null)
              _FieldError(state.errorFor('email')!),
            if (formError != null) _FieldError(formError),
            const SizedBox(height: 20),
            DrPrimaryButton(
              label: context.l10n.commonSave,
              trailingIcon: Icons.check_rounded,
              loading: busy,
              onTap: _submit,
            ),
          ],
        );
      },
    );
  }
}

/// The account's own password. Three fields, the current one first: the
/// backend checks it, and a wrong one comes back under that field alone.
class _PasswordSheet extends StatefulWidget {
  const _PasswordSheet();

  @override
  State<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends State<_PasswordSheet> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  /// One toggle for all three: they are being typed by the same person, in
  /// the same moment, and hiding one while showing another helps nobody.
  bool _obscured = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<ProfileCubit>().savePassword(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
      passwordConfirmation: _confirmController.text,
    );
  }

  Widget _revealButton(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _obscured = !_obscured),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 13),
        child: Semantics(
          button: true,
          label: _obscured
              ? context.l10n.registerPasswordShow
              : context.l10n.registerPasswordHide,
          child: Icon(
            _obscured
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 20,
            color: context.dr.textMuted,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status != ProfileStatus.success) return;

        // Read before the pop, which deactivates this context.
        final messenger = ScaffoldMessenger.of(context);
        final saved = state.message ?? context.l10n.profilePasswordSaved;

        // No session to refresh: the token outlives the password, so the
        // parent stays exactly where they were.
        Navigator.of(context).pop();
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(saved)));
      },
      builder: (context, state) {
        final busy = state.isLoading;
        final formError = state.formError;

        return _EditSheetFrame(
          icon: Icons.lock_outline,
          title: context.l10n.profilePassword,
          busy: busy,
          children: [
            Text(
              context.l10n.profilePasswordText,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: context.dr.textMuted,
              ),
            ),
            const SizedBox(height: 18),
            DrTextField(
              label: context.l10n.profileCurrentPassword,
              hint: '••••••••',
              icon: Icons.lock_outline,
              obscure: _obscured,
              controller: _currentController,
              enabled: !busy,
              autofocus: true,
              textInputAction: TextInputAction.next,
              onChanged: (_) => context.read<ProfileCubit>().inputChanged(),
              trailing: _revealButton(context),
            ),
            if (state.errorFor('current_password') != null)
              _FieldError(state.errorFor('current_password')!),
            const SizedBox(height: 16),
            DrTextField(
              label: context.l10n.forgotNewPassword,
              hint: '••••••••',
              icon: Icons.lock_reset_outlined,
              obscure: _obscured,
              controller: _newController,
              enabled: !busy,
              textInputAction: TextInputAction.next,
              onChanged: (_) => context.read<ProfileCubit>().inputChanged(),
            ),
            if (state.errorFor('new_password') != null)
              _FieldError(state.errorFor('new_password')!),
            const SizedBox(height: 16),
            DrTextField(
              label: context.l10n.forgotRepeatPassword,
              hint: '••••••••',
              icon: Icons.lock_reset_outlined,
              obscure: _obscured,
              controller: _confirmController,
              enabled: !busy,
              textInputAction: TextInputAction.done,
              onChanged: (_) => context.read<ProfileCubit>().inputChanged(),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.forgotMinLength(ProfileCubit.minPasswordLength),
              style: TextStyle(fontSize: 12, color: context.dr.textMuted),
            ),
            if (formError != null) _FieldError(formError),
            const SizedBox(height: 20),
            DrPrimaryButton(
              label: context.l10n.commonSave,
              trailingIcon: Icons.check_rounded,
              loading: busy,
              onTap: _submit,
            ),
          ],
        );
      },
    );
  }
}
