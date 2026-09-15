import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/support_contact.dart';
import '../../core/di/injection_container.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/cubit/forgot_password_cubit.dart';
import '../../features/auth/presentation/bloc/register_bloc.dart';
import 'register_screen.dart';
import '../theme/dr_colors.dart';
import '../widgets/dr_widgets.dart';
import '../../core/l10n/l10n.dart';

/// Port of `login.html`, wired to [AuthBloc].
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _lang = 'AZ';

  /// A second tap must not stack a second sign-up route on the first.
  bool _registerOpen = false;
  bool _showPassword = true;
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
      _showSnack(context.l10n.loginEnterCredentials);
      return;
    }
    context.read<AuthBloc>().add(
      AuthLoginRequested(email: email, password: password),
    );
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
    _showSnack(context.l10n.loginPasswordUpdated);
  }

  Future<void> _openRegister() async {
    // Two taps inside the push transition would stack two sign-up routes, and
    // the one left underneath outlives the sign-in that follows it.
    if (_registerOpen) return;
    _registerOpen = true;

    FocusScope.of(context).unfocus();
    // Returns the credentials just registered, or null if the parent backed
    // out of the form.
    final registered = await Navigator.of(context)
        .push<({String email, String password})>(
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (_) => sl<RegisterBloc>(),
              child: const RegisterScreen(),
            ),
          ),
        );

    _registerOpen = false;
    if (!mounted || registered == null) return;

    // `/registerParent` mints no token, so the session starts here. The fields
    // keep the values either way — if the sign-in is rejected the parent only
    // has to tap "Daxil ol" again.
    _emailController.text = registered.email;
    _passwordController.text = registered.password;
    _showSnack(context.l10n.registerDone);
    context.read<AuthBloc>().add(
      AuthLoginRequested(
        email: registered.email,
        password: registered.password,
      ),
    );
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
      // Binding the push subscription used to live here, in an `else` this
      // predicate can never reach. It belongs to [AuthBloc] anyway: a restored
      // session never opens this screen, and it would have been skipped.
      listenWhen: (prev, curr) =>
          curr.errorMessage != null && curr.errorMessage != prev.errorMessage,
      listener: (context, state) => _showSnack(state.errorMessage!),
      child: Scaffold(
        backgroundColor: context.dr.bgDark,
        body: SafeArea(
          child: Stack(
            children: [
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
                                color: context.dr.accent.withValues(alpha: 0.2),
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
                          context.l10n.loginWelcome,
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
                          context.l10n.loginSubtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: context.dr.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      DrTextField(
                        label: context.l10n.loginEmail,
                        hint: 'example@bsb.edu.az',
                        icon: Icons.person_outline,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 20),
                      DrTextField(
                        label: context.l10n.loginPassword,
                        hint: '••••••••',
                        icon: Icons.lock_outline,
                        obscure: _showPassword,
                        controller: _passwordController,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _login(),
                        trailing: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: context.dr.textMuted,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: _showForgotSheet,
                          child: Text(
                            context.l10n.loginForgotPassword,
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
                          label: context.l10n.loginSubmit,
                          loading: state.isLoading,
                          onTap: _login,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: GestureDetector(
                          onTap: _openRegister,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Text.rich(
                              TextSpan(
                                text: '${context.l10n.loginNoAccount} ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: context.dr.textMuted,
                                ),
                                children: [
                                  TextSpan(
                                    text: context.l10n.loginRegister,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: context.dr.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: GestureDetector(
                          onTap: _showSupportSheet,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            // Keeps the tap target comfortable without pushing
                            // the copyright line further down.
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.headset_mic_outlined,
                                  size: 16,
                                  color: context.dr.textMuted,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  context.l10n.loginSupport,
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
        ..showSnackBar(SnackBar(content: Text(context.l10n.loginCannotOpen)));
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
                Text(
                  context.l10n.loginSupport,
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
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: context.dr.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.loginSupportText,
              style: TextStyle(fontSize: 14, color: context.dr.textMuted),
            ),
            const SizedBox(height: 20),
            _SupportOption(
              icon: Icons.call_outlined,
              title: context.l10n.loginCall,
              subtitle: SupportContact.phone,
              onTap: () => _open(context, SupportContact.phoneUri),
            ),
            _SupportOption(
              icon: Icons.mail_outline,
              title: context.l10n.loginSendEmail,
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

/// The password reset, in three steps: the address, the 6-digit code mailed
/// to it, then the new password.
///
/// Pops the address once the password is replaced, so the login screen can
/// prefill it; dismissing it any other way pops nothing.
class _ForgotPasswordSheet extends StatefulWidget {
  /// Whatever was already typed on the login screen, so it isn't retyped.
  final String initialEmail;

  const _ForgotPasswordSheet({this.initialEmail = ''});

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  late final TextEditingController _emailController = TextEditingController(
    text: widget.initialEmail,
  );
  final _codeController = TextEditingController();
  final _codeFocus = FocusNode();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _codeFocus.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _requestCode() {
    FocusScope.of(context).unfocus();
    context.read<ForgotPasswordCubit>().requestCode(_emailController.text);
  }

  void _onCodeChanged(String value) {
    // The boxes paint straight from the controller, so they need the frame.
    setState(() {});
    context.read<ForgotPasswordCubit>().inputChanged();
    // Six digits is the whole input; asking for a button press after that is
    // one tap too many.
    if (value.length == ForgotPasswordCubit.codeLength) _continueWithCode();
  }

  void _continueWithCode() {
    _codeFocus.unfocus();
    context.read<ForgotPasswordCubit>().continueWithCode(_codeController.text);
  }

  void _backToEmail() {
    _codeFocus.unfocus();
    _codeController.clear();
    context.read<ForgotPasswordCubit>().backToEmail();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<ForgotPasswordCubit>().submit(
      password: _passwordController.text,
      passwordConfirmation: _confirmController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
      // `resendSeconds` ticks once a second; only the step and the outcome
      // are worth reacting to.
      listenWhen: (prev, curr) =>
          prev.status != curr.status || prev.step != curr.step,
      listener: (context, state) {
        if (state.status == ForgotPasswordStatus.success) {
          // The login screen shows the confirmation and prefills the e-mail.
          Navigator.of(context).pop(state.email);
        }
      },
      builder: (context, state) {
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
                      Text(
                        context.l10n.forgotTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
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
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: context.dr.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ...switch (state.step) {
                    ForgotPasswordStep.email => _emailStep(context, state),
                    ForgotPasswordStep.code => _codeStep(context, state),
                    ForgotPasswordStep.password =>
                      _passwordStep(context, state),
                  },
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Step 1 — the address the code goes to.
  List<Widget> _emailStep(BuildContext context, ForgotPasswordState state) {
    return [
      Text(
        context.l10n.forgotText,
        style: TextStyle(fontSize: 14, color: context.dr.textMuted),
      ),
      const SizedBox(height: 20),
      DrTextField(
        label: context.l10n.forgotEmailField,
        hint: 'example@bsb.edu.az',
        icon: Icons.mail_outline,
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _requestCode(),
      ),
      ..._message(context, state),
      const SizedBox(height: 20),
      DrPrimaryButton(
        label: context.l10n.forgotSendCode,
        trailingIcon: Icons.send_rounded,
        loading: state.isLoading,
        onTap: _requestCode,
      ),
    ];
  }

  /// Step 2 — the code that was mailed, before any password is asked for.
  List<Widget> _codeStep(BuildContext context, ForgotPasswordState state) {
    final complete =
        _codeController.text.length == ForgotPasswordCubit.codeLength;

    return [
      Text(
        context.l10n.otpSubtitle(state.email),
        style: TextStyle(fontSize: 14, height: 1.5, color: context.dr.textMuted),
      ),
      const SizedBox(height: 20),
      DrCodeInput(
        controller: _codeController,
        focusNode: _codeFocus,
        onChanged: _onCodeChanged,
        length: ForgotPasswordCubit.codeLength,
      ),
      ..._message(context, state),
      const SizedBox(height: 20),
      DrPrimaryButton(
        label: context.l10n.commonContinue,
        trailingIcon: Icons.arrow_forward_rounded,
        onTap: complete ? _continueWithCode : null,
      ),
      const SizedBox(height: 4),
      Center(child: _buildResend(context, state)),
      Center(
        child: Text(
          context.l10n.otpSpamHint,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: context.dr.textMuted),
        ),
      ),
      const SizedBox(height: 4),
      Center(
        child: TextButton(
          onPressed: state.isLoading ? null : _backToEmail,
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 44),
            foregroundColor: context.dr.textMuted,
          ),
          child: Text(
            context.l10n.forgotChangeEmail,
            style: TextStyle(fontSize: 13, color: context.dr.textMuted),
          ),
        ),
      ),
    ];
  }

  /// Step 3 — the new password, only reachable once the code was accepted.
  List<Widget> _passwordStep(BuildContext context, ForgotPasswordState state) {
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.mark_email_read_rounded,
            size: 16,
            color: context.dr.accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.forgotSetPasswordText,
              style: TextStyle(fontSize: 14, color: context.dr.textMuted),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      DrTextField(
        label: context.l10n.forgotNewPassword,
        hint: '••••••••',
        icon: Icons.lock_outline,
        obscure: true,
        controller: _passwordController,
        textInputAction: TextInputAction.next,
        autofocus: true,
      ),
      const SizedBox(height: 16),
      DrTextField(
        label: context.l10n.forgotRepeatPassword,
        hint: '••••••••',
        icon: Icons.lock_reset_outlined,
        obscure: true,
        controller: _confirmController,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
      ),
      const SizedBox(height: 8),
      Text(
        context.l10n.forgotMinLength(ForgotPasswordCubit.minPasswordLength),
        style: TextStyle(fontSize: 12, color: context.dr.textMuted),
      ),
      ..._message(context, state),
      const SizedBox(height: 20),
      DrPrimaryButton(
        label: context.l10n.forgotSubmit,
        loading: state.isLoading,
        onTap: _submit,
      ),
      Center(
        child: TextButton(
          onPressed: state.isLoading
              ? null
              : () => context.read<ForgotPasswordCubit>().backToCode(),
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 44),
            foregroundColor: context.dr.textMuted,
          ),
          child: Text(
            context.l10n.forgotBackToCode,
            style: TextStyle(fontSize: 13, color: context.dr.textMuted),
          ),
        ),
      ),
    ];
  }

  /// Whatever the cubit has to say about the step, right under its input: a
  /// rejection in red, a fresh code's confirmation in the muted tone. A
  /// snackbar would land behind the sheet and the keyboard.
  List<Widget> _message(BuildContext context, ForgotPasswordState state) {
    final message = state.message;
    if (message == null) return const [];

    final isError = state.status == ForgotPasswordStatus.error;
    return [
      const SizedBox(height: 12),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.info_outline,
            size: 16,
            color: isError ? Colors.redAccent : context.dr.accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: isError ? Colors.redAccent : context.dr.textMuted,
              ),
            ),
          ),
        ],
      ),
    ];
  }

  /// The cooldown reads as plain text; only once it runs out does the resend
  /// become something to press.
  Widget _buildResend(BuildContext context, ForgotPasswordState state) {
    if (state.resendSeconds > 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          context.l10n.otpResendIn(state.resendSeconds),
          style: TextStyle(fontSize: 13, color: context.dr.textMuted),
        ),
      );
    }

    return TextButton(
      onPressed: state.canResend
          ? () => context.read<ForgotPasswordCubit>().resendCode()
          : null,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        foregroundColor: context.dr.accent,
      ),
      child: state.isResending
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.dr.accent,
              ),
            )
          : Text(
              context.l10n.otpResend,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    state.canResend ? context.dr.accent : context.dr.textMuted,
              ),
            ),
    );
  }
}
