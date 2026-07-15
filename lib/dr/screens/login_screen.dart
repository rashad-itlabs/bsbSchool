import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
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

  void _showForgotSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ForgotPasswordSheet(),
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
                          color: DrColors.accentGreen.withValues(alpha: 0.08),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  DrColors.accentGreen.withValues(alpha: 0.2),
                              blurRadius: 30,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'BSB',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: DrColors.accentGreen,
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
                        child: const Text(
                          'Şifrəni unutmusunuz?',
                          style: TextStyle(
                            color: DrColors.accentGreen,
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
                    const SizedBox(height: 30),
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

class _ForgotPasswordSheet extends StatelessWidget {
  const _ForgotPasswordSheet();

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Şifrənin bərpası',
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
                    child: Icon(Icons.close, size: 18, color: context.dr.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Şifrəni sıfırlamaq üçün qeydiyyatdan keçdiyiniz e-mail '
              'ünvanını daxil edin.',
              style: TextStyle(fontSize: 14, color: context.dr.textMuted),
            ),
            const SizedBox(height: 20),
            const DrTextField(
              label: 'E-mail ünvanı',
              hint: 'example@bsb.edu.az',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            DrPrimaryButton(
              label: 'Göndər',
              onTap: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
