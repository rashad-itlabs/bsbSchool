import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../theme/dr_colors.dart';
import '../widgets/dr_widgets.dart';

/// Shown instead of the dashboard when a parent logs in successfully but the
/// response carries `user_id: null` — the school hasn't linked a student to the
/// account yet, so there is no student whose data the app could show.
///
/// The parent enters their child's admission number to link one. Parent-only:
/// [AuthUser.needsChild] gates this, and a teacher has no student to link.
///
/// UI only for now — [_submit] is a stub. See the TODO there for what wiring it
/// up requires.
class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _admissionController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _admissionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final admissionNo = _admissionController.text.trim();
    if (admissionNo.isEmpty) {
      setState(() => _error = 'Qəbul nömrəsini daxil edin');
      return;
    }

    setState(() {
      _error = null;
      _submitting = true;
    });

    // TODO: POST the admission number to the link-student endpoint. On success
    // the session must be refreshed so `user_id` is no longer null — otherwise
    // AuthGate keeps `needsChild` true and re-mounts this screen. On failure,
    // assign the server's message to `_error`.
    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Şagird hesabınıza əlavə edildi')),
      );
  }

  /// Without this the parent is stuck: they can't reach the app, and signing in
  /// again is their only way to try a different account.
  Future<void> _logout() async {
    final authBloc = context.read<AuthBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.dr.bgSurface,
        title: const Text('Çıxış'),
        content: const Text('Hesabdan çıxmaq istədiyinizə əminsiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child:
                Text('Ləğv et', style: TextStyle(color: context.dr.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Çıxış',
                style: TextStyle(color: DrColors.accentGreen)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    // Clears the token; AuthGate reacts to `unauthenticated` and shows login.
    authBloc.add(const AuthLogoutRequested());
  }

  @override
  Widget build(BuildContext context) {
    final parentName = context.select<AuthBloc, String>(
      (bloc) => bloc.state.user?.name ?? '',
    );

    return Scaffold(
      backgroundColor: context.dr.bgDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(30, 40, 30, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Same glowing circle as the login logo, so this reads as the
                // last step of signing in rather than a different app.
                Center(
                  child: Container(
                    width: 110,
                    height: 110,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: DrColors.accentGreen.withValues(alpha: 0.08),
                      boxShadow: [
                        BoxShadow(
                          color: DrColors.accentGreen.withValues(alpha: 0.2),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 44,
                        color: DrColors.accentGreen,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    'Şagirdinizi əlavə edin',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: context.dr.textMain,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    parentName.isEmpty
                        ? 'Hesabınıza hələ şagird bağlanmayıb. Davam etmək '
                            'üçün övladınızın qəbul nömrəsini daxil edin.'
                        : '$parentName, hesabınıza hələ şagird bağlanmayıb. '
                            'Davam etmək üçün övladınızın qəbul nömrəsini '
                            'daxil edin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: context.dr.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                DrGlowCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DrTextField(
                        label: 'Qəbul nömrəsi',
                        hint: 'Övladınızın qəbul nömrəsi',
                        icon: Icons.badge_outlined,
                        controller: _admissionController,
                        enabled: !_submitting,
                        autofocus: true,
                        textInputAction: TextInputAction.done,
                        // Codes are alphanumeric: keep iOS from capitalising
                        // the first character on the parent's behalf.
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
                            const Icon(Icons.error_outline,
                                size: 16, color: DrColors.redStrong),
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
                      const SizedBox(height: 20),
                      DrPrimaryButton(
                        label: 'Əlavə et',
                        trailingIcon: Icons.arrow_forward_rounded,
                        loading: _submitting,
                        onTap: _submit,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const _WhereToFindCard(),
                const SizedBox(height: 24),
                // Full-height tap target, unlike a bare text link.
                Center(
                  child: TextButton(
                    onPressed: _submitting ? null : _logout,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      foregroundColor: context.dr.textMuted,
                    ),
                    child: const Text(
                      'Başqa hesabla daxil ol',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tells the parent where the number lives, so an unknown code is a lookup
/// rather than a call to the school.
class _WhereToFindCard extends StatelessWidget {
  const _WhereToFindCard();

  @override
  Widget build(BuildContext context) {
    return DrCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline_rounded,
                  size: 18, color: DrColors.accentGreen),
              const SizedBox(width: 8),
              Text(
                'Qəbul nömrəsi haradadır?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.dr.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final line in const [
            'Şagird vəsiqəsinin üzərində',
            'Məktəbin verdiyi qəbul sənədində',
            'Məktəbin katibliyindən soruşa bilərsiniz',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: DrColors.accentGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      line,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
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
