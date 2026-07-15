import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/domain/entities/auth_user.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
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
                  const Text('PIN kodu dəyiş',
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
                  label: 'Yeni PIN',
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
            child: const Text('Çıxış',
                style: TextStyle(color: DrColors.accentGreen)),
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

    // "Class Group 7 • ID: 94" — either half is dropped when the login
    // response left it out (an account with no student session).
    final subtitle = [
      if (user?.className != null) user!.className!,
      if (user?.classId != null) 'ID: ${user!.classId}',
    ].join(' • ');

    return DrScaffold(
      child: ListView(
        children: [
          const DrBackHeader(title: 'Buraxılış', showBack: false),
          const SizedBox(height: 8),
          Center(
            child: Column(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DrColors.accentGreen.withValues(alpha: 0.15),
                    border: Border.all(color: context.dr.bgSurface, width: 4),
                  ),
                  child: Center(
                    child: Text(AuthUser.initialsOf(name),
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: DrColors.accentGreen)),
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
          const SizedBox(height: 24),
          DrSectionHeader(title: 'Tənzimləmələr'),
          DrListCard(
            children: [
              DrSettingItem(
                icon: Icons.lock_outline,
                iconColor: DrColors.accentGreen,
                title: 'Şifrəni dəyiş',
                subtitle: 'Turniket və yeməkxana üçün',
                onTap: _changePin,
                trailing: Icon(Icons.chevron_right,
                    color: context.dr.textMuted, size: 18),
              ),
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
