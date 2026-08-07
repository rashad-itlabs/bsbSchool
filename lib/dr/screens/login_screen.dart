import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/support_contact.dart';
import '../../core/di/injection_container.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/cubit/forgot_password_cubit.dart';
import '../theme/dr_colors.dart';
import '../widgets/dr_widgets.dart';

/// Port of `login.html`, wired to [AuthBloc].
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _lang = 'AZ';
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showSnack('E-mail və şifrəni daxil edin');
      return;
    }
    context
        .read<AuthBloc>()
        .add(AuthLoginRequested(email: email, password: password));
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showForgotSheet() async {
    FocusScope.of(context).unfocus();
    // Returns the e-mail whose password was just reset, or null if dismissed.
    final resetEmail = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider(
        create: (_) => sl<ForgotPasswordCubit>(),
        child: _ForgotPasswordSheet(initialEmail: _emailController.text.trim()),
      ),
    );

    if (!mounted || resetEmail == null) return;
    // Carry the address over so only the new password has to be typed.
    _emailController.text = resetEmail;
    _passwordController.clear();
    _showSnack('Şifrəniz yeniləndi. Yeni şifrə ilə daxil olun.');
  }

  void _showSupportSheet() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SupportSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) =>
          curr.errorMessage != null && curr.errorMessage != prev.errorMessage,
      listener: (context, state) => _showSnack(state.errorMessage!),
      child: Scaffold(
      backgroundColor: context.dr.bgDark,
      body: SafeArea(
        child: Stack(
          children: [
            // Language switcher (top-right)
            Positioned(
              top: 14,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: context.dr.bgSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.dr.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _lang,
                    isDense: true,
                    dropdownColor: context.dr.bgSurface,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.dr.textMain,
                    ),
                    items: const ['AZ', 'EN', 'RU']
                        .map((e) =>
                            DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _lang = v ?? 'AZ'),
                  ),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(30, 40, 30, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    Center(
                      child: Container(
                        width: 140,
                        height: 140,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.dr.accent.withValues(alpha: 0.08),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  context.dr.accent.withValues(alpha: 0.2),
                              blurRadius: 30,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'BSB',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: context.dr.accent,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        'Xoş gəlmisiniz',
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
                        'Davam etmək üçün daxil olun',
                        style:
                            TextStyle(fontSize: 14, color: context.dr.textMuted),
                      ),
                    ),
                    const SizedBox(height: 40),
                    DrTextField(
                      label: 'E-mail',
                      hint: 'example@bsb.edu.az',
                      icon: Icons.person_outline,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 20),
                    DrTextField(
                      label: 'Şifrə',
                      hint: '••••••••',
                      icon: Icons.lock_outline,
                      obscure: true,
                      controller: _passwordController,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _showForgotSheet,
                        child: Text(
                          'Şifrəni unutmusunuz?',
                          style: TextStyle(
                            color: context.dr.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    BlocBuilder<AuthBloc, AuthState>(
                      buildWhen: (p, c) => p.isLoading != c.isLoading,
                      builder: (context, state) => DrPrimaryButton(
                        label: 'Daxil ol',
                        loading: state.isLoading,
                        onTap: _login,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: GestureDetector(
                        onTap: _showSupportSheet,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          // Keeps the tap target comfortable without pushing
                          // the copyright line further down.
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.headset_mic_outlined,
                                  size: 16, color: context.dr.textMuted),
                              const SizedBox(width: 8),
                              Text(
                                'Dəstək ilə əlaqə',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: context.dr.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        '© Copyright by AVANTGARDE Solutions',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.dr.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// The three ways to reach support. Values live in [SupportContact].
class _SupportSheet extends StatelessWidget {
  const _SupportSheet();

  /// Hands the URI to the system (dialer / mail app / WhatsApp). Closes the
  /// sheet once something took it, so returning to the app lands on a clean
  /// login screen.
  Future<void> _open(BuildContext context, Uri uri) async {
    bool launched;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // No handler installed (no dialer on a tablet, no mail account, ...).
      launched = false;
    }
    if (!context.mounted) return;

    if (launched) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Bu əməliyyat cihazda açıla bilmədi')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      decoration: BoxDecoration(
        color: context.dr.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dəstək ilə əlaqə',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close,
                        size: 18, color: context.dr.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Daxil ola bilmirsinizsə və ya sualınız varsa, bizimlə '
              'əlaqə saxlayın.',
              style: TextStyle(fontSize: 14, color: context.dr.textMuted),
            ),
            const SizedBox(height: 20),
            _SupportOption(
              icon: Icons.call_outlined,
              title: 'Zəng et',
              subtitle: SupportContact.phone,
              onTap: () => _open(context, SupportContact.phoneUri),
            ),
            _SupportOption(
              icon: Icons.mail_outline,
              title: 'E-mail göndər',
              subtitle: SupportContact.email,
              onTap: () => _open(context, SupportContact.emailUri),
            ),
            _SupportOption(
              icon: Icons.chat_bubble_outline,
              title: 'WhatsApp',
              subtitle: SupportContact.whatsapp,
              onTap: () => _open(context, SupportContact.whatsappUri),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SupportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SupportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.dr.bgDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.dr.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.dr.accentSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: context.dr.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.dr.textMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: context.dr.textMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: context.dr.textMuted),
          ],
        ),
      ),
    );
  }
}

class _ForgotPasswordSheet extends StatefulWidget {
  /// Whatever was already typed on the login screen, so it isn't retyped.
  final String initialEmail;

  const _ForgotPasswordSheet({this.initialEmail = ''});

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  late final TextEditingController _emailController =
      TextEditingController(text: widget.initialEmail);
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<ForgotPasswordCubit>().submit(
          email: _emailController.text,
          password: _passwordController.text,
          passwordConfirmation: _confirmController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == ForgotPasswordStatus.success) {
          // The login screen shows the confirmation and prefills the e-mail.
          Navigator.of(context).pop(_emailController.text.trim());
        }
      },
      builder: (context, state) {
        final error = state.status == ForgotPasswordStatus.error
            ? state.message
            : null;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.dr.bgSurface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Şifrənin bərpası',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close,
                              size: 18, color: context.dr.textMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Qeydiyyatdan keçdiyiniz e-mail ünvanını və yeni şifrənizi '
                    'daxil edin. E-mail doğrudursa, şifrə dərhal yenilənəcək.',
                    style: TextStyle(fontSize: 14, color: context.dr.textMuted),
                  ),
                  const SizedBox(height: 20),
                  DrTextField(
                    label: 'E-mail ünvanı',
                    hint: 'example@bsb.edu.az',
                    icon: Icons.mail_outline,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  DrTextField(
                    label: 'Yeni şifrə',
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                    obscure: true,
                    controller: _passwordController,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  DrTextField(
                    label: 'Yeni şifrə (təkrar)',
                    hint: '••••••••',
                    icon: Icons.lock_reset_outlined,
                    obscure: true,
                    controller: _confirmController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Şifrə ən azı ${ForgotPasswordCubit.minPasswordLength} '
                    'simvol olmalıdır.',
                    style: TextStyle(fontSize: 12, color: context.dr.textMuted),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 16, color: Colors.redAccent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            error,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  DrPrimaryButton(
                    label: 'Şifrəni yenilə',
                    loading: state.isLoading,
                    onTap: _submit,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
