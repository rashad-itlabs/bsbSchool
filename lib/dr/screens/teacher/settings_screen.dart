import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/auth/domain/entities/auth_user.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../theme/dr_colors.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/dr_widgets.dart';
import '../../widgets/teacher_widgets.dart';

/// Port of `teacher_theme/settings.html` — profile, account and preferences.
class TeacherSettingsScreen extends StatefulWidget {
  const TeacherSettingsScreen({super.key});

  @override
  State<TeacherSettingsScreen> createState() => _TeacherSettingsScreenState();
}

class _TeacherSettingsScreenState extends State<TeacherSettingsScreen> {
  bool _notifications = true;
  String _language = 'English';

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
            title: 'Settings',
            initials: AuthUser.initialsOf(name),
            showBack: false,
          ),
          _profile(context, name, user),
          const SizedBox(height: 25),
          _groupTitle('Account Settings'),
          DrListCard(
            children: [
              DrSettingItem(
                icon: Icons.lock_outline_rounded,
                iconColor: DrColors.accentGreen,
                title: 'Change PIN Code',
                subtitle: 'Turnstile and gate access security PIN',
                trailing: _chevron(context),
                onTap: () =>
                    showTeacherToast(context, 'PIN change screen loading...'),
              ),
              DrSettingItem(
                icon: Icons.notifications_none_rounded,
                iconColor: DrColors.orange,
                title: 'Push Notifications',
                subtitle: 'Grade alerts, schedule updates',
                divider: false,
                trailing: DrSwitch(
                  value: _notifications,
                  onChanged: (v) {
                    setState(() => _notifications = v);
                    showTeacherToast(context, 'Notification settings updated');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          _groupTitle('Preferences'),
          DrListCard(
            children: [
              DrSettingItem(
                icon: Icons.light_mode_outlined,
                iconColor: DrColors.orange,
                title: 'Light Theme',
                subtitle: 'Açıq rəngli interfeys',
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
                title: 'Language Selection',
                subtitle: 'App interface language option',
                trailing: _languagePicker(context),
              ),
              DrSettingItem(
                icon: Icons.logout_rounded,
                iconColor: DrColors.red,
                title: 'Logout',
                titleColor: DrColors.red,
                subtitle: 'Exit the session securely',
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
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: DrColors.accentGreen,
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
          value: _language,
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
          items: const ['English', 'Azerbaijan', 'Russian']
              .map((l) => DropdownMenuItem(value: l, child: Text(l)))
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() => _language = v);
            showTeacherToast(context, 'Language updated');
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
        title: const Text('Logout'),
        content: const Text('Exit the session securely?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: dialogContext.dr.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Logout',
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
