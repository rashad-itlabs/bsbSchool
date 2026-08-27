import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/auth/domain/entities/auth_user.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../theme/dr_colors.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/dr_widgets.dart';
import '../../widgets/teacher_widgets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/locale_controller.dart';

/// Port of `teacher_theme/settings.html` — profile, account and preferences.
class TeacherSettingsScreen extends StatefulWidget {
  const TeacherSettingsScreen({super.key});

  @override
  State<TeacherSettingsScreen> createState() => _TeacherSettingsScreenState();
}

class _TeacherSettingsScreenState extends State<TeacherSettingsScreen> {
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthBloc, AuthUser?>(
      (bloc) => bloc.state.user,
    );
    final name = user?.name ?? '';
    final isLight = Theme.of(context).brightness == Brightness.light;

    return DrScaffold(
      child: ListView(
        children: [
          TeacherPageHeader(
            title: context.l10n.navSettings,
            initials: AuthUser.initialsOf(name),
            showBack: false,
          ),
          _profile(context, name, user),
          const SizedBox(height: 25),
          _groupTitle(context.l10n.tAccountSettings),
          DrListCard(
            children: [
              DrSettingItem(
                icon: Icons.lock_outline_rounded,
                iconColor: context.dr.accent,
                title: context.l10n.tChangePin,
                subtitle: context.l10n.tPinSubtitle,
                trailing: _chevron(context),
                onTap: () =>
                    showTeacherToast(context, context.l10n.tPinLoading),
              ),
              DrSettingItem(
                icon: Icons.notifications_none_rounded,
                iconColor: DrColors.orange,
                title: context.l10n.tPushNotifications,
                subtitle: context.l10n.tPushSubtitle,
                divider: false,
                trailing: DrSwitch(
                  value: _notifications,
                  onChanged: (v) {
                    setState(() => _notifications = v);
                    showTeacherToast(context, context.l10n.tNotifUpdated);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          _groupTitle(context.l10n.tPreferences),
          DrListCard(
            children: [
              DrSettingItem(
                icon: Icons.light_mode_outlined,
                iconColor: DrColors.orange,
                title: context.l10n.tLightTheme,
                subtitle: context.l10n.settingsLightModeSubtitle,
                trailing: DrSwitch(
                  value: isLight,
                  onChanged: (_) => ThemeController.instance.toggle(
                    Theme.of(context).brightness,
                  ),
                ),
              ),
              DrSettingItem(
                icon: Icons.language_rounded,
                iconColor: DrColors.purple,
                title: context.l10n.tLanguageSelection,
                subtitle: context.l10n.tLanguageSubtitle,
                trailing: _languagePicker(context),
              ),
              DrSettingItem(
                icon: Icons.logout_rounded,
                iconColor: DrColors.red,
                title: context.l10n.settingsLogout,
                titleColor: DrColors.red,
                subtitle: context.l10n.tLogoutSubtitle,
                divider: false,
                trailing: _chevron(context),
                onTap: () => _confirmLogout(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _profile(BuildContext context, String name, AuthUser? user) {
    final subtitle = [
      if (user?.className != null) user!.className!,
      if (user?.id != null) 'ID: ${user!.id}',
    ].join(' • ');

    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: DrColors.accentGreen,
            shape: BoxShape.circle,
            border: Border.all(color: context.dr.bgSurfaceLight, width: 4),
            boxShadow: [
              BoxShadow(
                color: DrColors.accentGreen.withValues(alpha: 0.4),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Text(
            AuthUser.initialsOf(name),
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: context.dr.textMuted),
          ),
        ],
      ],
    );
  }

  Widget _groupTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: context.dr.accent,
        ),
      ),
    );
  }

  Widget _chevron(BuildContext context) {
    return Icon(
      Icons.chevron_right_rounded,
      size: 18,
      color: context.dr.textMuted,
    );
  }

  /// The controller stores null for "follow the device"; the dropdown needs a
  /// value it can compare, hence the sentinel.
  static const _system = 'system';

  Widget _languagePicker(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: context.dr.bgSurfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.dr.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: LocaleController.instance.locale?.languageCode ?? _system,
          isDense: true,
          borderRadius: BorderRadius.circular(8),
          dropdownColor: context.dr.bgSurfaceLight,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: context.dr.textMuted,
          ),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.dr.textMain,
          ),
          items: [
            DropdownMenuItem(
              value: _system,
              child: Text(context.l10n.languageSystem),
            ),
            DropdownMenuItem(value: 'az', child: Text(context.l10n.languageAz)),
            DropdownMenuItem(value: 'en', child: Text(context.l10n.languageEn)),
            DropdownMenuItem(value: 'ru', child: Text(context.l10n.languageRu)),
          ],
          onChanged: (value) {
            if (value == null) return;
            LocaleController.instance.setLocale(
              value == _system ? null : Locale(value),
            );
            showTeacherToast(context, context.l10n.tLanguageUpdated);
          },
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final bloc = context.read<AuthBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogContext.dr.bgSurface,
        title: Text(context.l10n.settingsLogout),
        content: Text(context.l10n.tLogoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              context.l10n.commonCancel,
              style: TextStyle(color: dialogContext.dr.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              context.l10n.settingsLogout,
              style: TextStyle(color: DrColors.red),
            ),
          ),
        ],
      ),
    );

    // AuthGate swaps in the login screen off the resulting state change.
    if (confirmed ?? false) bloc.add(const AuthLogoutRequested());
  }
}
