import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/injection_container.dart';
import '../../core/l10n/l10n.dart';
import '../../features/auth/presentation/bloc/register_bloc.dart';
import '../../features/auth/presentation/cubit/otp_cubit.dart';
import 'otp_screen.dart';
import '../theme/dr_colors.dart';
import '../widgets/dr_widgets.dart';

/// Parent sign-up, reached from the login screen's "Hesabınız yoxdur?" link.
///
/// Sign-up mails a 6-digit code, so success opens the OTP screen and the
/// credentials only travel back to login once that code is confirmed — login
/// stays the one place a token is minted.
///
/// Expects a [RegisterBloc] above it; the login screen provides one when it
/// pushes this route.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _admissionController = TextEditingController();

  bool _acceptedTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  /// A rebuild must not push the confirmation route a second time.
  bool _otpOpen = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _admissionController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<RegisterBloc>().add(RegisterSubmitted(
          name: _nameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          password: _passwordController.text,
          passwordConfirmation: _confirmController.text,
          admissionNo: _admissionController.text,
          acceptedTerms: _acceptedTerms,
        ));
  }

  /// Sends the parent to the confirmation screen and, if the code is
  /// accepted, hands the credentials to login.
  Future<void> _openOtp() async {
    if (_otpOpen) return;
    _otpOpen = true;

    // Read before the push: the field can be gone by the time it returns.
    final email = _emailController.text.trim();
    final verified = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => sl<OtpCubit>(param1: email),
          child: OtpScreen(email: email),
        ),
      ),
    );

    if (!mounted) return;

    // Leaving unverified pops null rather than the filled-in form: the account
    // already exists, so submitting it again would only earn a duplicate
    // e-mail error, and login reads null as nothing having happened.
    Navigator.of(context).pop(
      verified == true
          ? (email: email, password: _passwordController.text)
          : null,
    );
  }

  void _toggleTerms() {
    setState(() => _acceptedTerms = !_acceptedTerms);
    context.read<RegisterBloc>().add(
          const RegisterFieldEdited(RegisterField.terms),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RegisterBloc, RegisterState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == RegisterStatus.success) {
          // The account exists but is unconfirmed; the code decides whether
          // login ever sees these credentials.
          _openOtp();
        }
      },
      builder: (context, state) {
        final bloc = context.read<RegisterBloc>();
        final enabled = !state.isLoading;

        return Scaffold(
          backgroundColor: context.dr.bgDark,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: DrBackHeader(title: context.l10n.registerTitle),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // The same glowing circle login and "add a student"
                        // open with, so this reads as one flow.
                        Center(
                          child: Container(
                            width: 88,
                            height: 88,
                            margin: const EdgeInsets.only(bottom: 18),
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
                              child: Icon(
                                Icons.how_to_reg_rounded,
                                size: 38,
                                color: context.dr.accent,
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            context.l10n.registerSubtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: context.dr.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        DrSectionHeader(
                          title: context.l10n.registerSectionAccount,
                          fontSize: 15,
                          padding: const EdgeInsets.only(bottom: 12),
                        ),
                        DrGlowCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _FormRow(
                                label: context.l10n.registerName,
                                hint: context.l10n.registerNameHint,
                                icon: Icons.person_outline,
                                controller: _nameController,
                                error: state.errorFor(RegisterField.name),
                                onEdited: () =>
                                    bloc.add(const RegisterFieldEdited(RegisterField.name)),
                                enabled: enabled,
                                keyboardType: TextInputType.name,
                                textCapitalization: TextCapitalization.words,
                              ),
                              const SizedBox(height: 16),
                              _FormRow(
                                label: context.l10n.loginEmail,
                                hint: 'example@bsb.edu.az',
                                icon: Icons.mail_outline,
                                controller: _emailController,
                                error: state.errorFor(RegisterField.email),
                                onEdited: () =>
                                    bloc.add(const RegisterFieldEdited(RegisterField.email)),
                                enabled: enabled,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 16),
                              _FormRow(
                                label: context.l10n.registerPhone,
                                hint: context.l10n.registerPhoneHint,
                                icon: Icons.phone_outlined,
                                controller: _phoneController,
                                error: state.errorFor(RegisterField.phone),
                                onEdited: () =>
                                    bloc.add(const RegisterFieldEdited(RegisterField.phone)),
                                enabled: enabled,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 16),
                              _FormRow(
                                label: context.l10n.loginPassword,
                                hint: '••••••••',
                                icon: Icons.lock_outline,
                                controller: _passwordController,
                                error: state.errorFor(RegisterField.password),
                                onEdited: () =>
                                    bloc.add(const RegisterFieldEdited(RegisterField.password)),
                                enabled: enabled,
                                obscure: _obscurePassword,
                                trailing: _RevealButton(
                                  obscured: _obscurePassword,
                                  onTap: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _FormRow(
                                label: context.l10n.registerPasswordRepeat,
                                hint: '••••••••',
                                icon: Icons.lock_reset_outlined,
                                controller: _confirmController,
                                error: state.errorFor(
                                    RegisterField.passwordConfirmation),
                                onEdited: () => bloc.add(const RegisterFieldEdited(
                                    RegisterField.passwordConfirmation)),
                                enabled: enabled,
                                obscure: _obscureConfirm,
                                trailing: _RevealButton(
                                  obscured: _obscureConfirm,
                                  onTap: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                context.l10n.forgotMinLength(
                                  RegisterBloc.minPasswordLength,
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.dr.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        DrSectionHeader(
                          title: context.l10n.registerSectionChild,
                          fontSize: 15,
                          padding: const EdgeInsets.only(bottom: 12),
                        ),
                        DrCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _FormRow(
                                label: context.l10n.addChildField,
                                hint: context.l10n.addChildHint,
                                icon: Icons.badge_outlined,
                                controller: _admissionController,
                                error:
                                    state.errorFor(RegisterField.admissionNo),
                                onEdited: () =>
                                    bloc.add(const RegisterFieldEdited(RegisterField.admissionNo)),
                                enabled: enabled,
                                // Codes are alphanumeric; iOS would otherwise
                                // lower-case whatever the parent copies in.
                                textCapitalization:
                                    TextCapitalization.characters,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _submit(),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.help_outline_rounded,
                                      size: 16, color: context.dr.accent),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      context.l10n.registerAdmissionNote,
                                      style: TextStyle(
                                        fontSize: 12,
                                        height: 1.4,
                                        color: context.dr.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _TermsRow(
                          accepted: _acceptedTerms,
                          error: state.errorFor(RegisterField.terms),
                          onTap: enabled ? _toggleTerms : null,
                        ),
                        // Anything the backend rejects that belongs to no
                        // single field lands here.
                        if (state.status == RegisterStatus.error &&
                            state.message != null) ...[
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 16, color: DrColors.redStrong),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  state.message!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: DrColors.redStrong,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 24),
                        DrPrimaryButton(
                          label: context.l10n.registerSubmit,
                          trailingIcon: Icons.arrow_forward_rounded,
                          loading: state.isLoading,
                          onTap: _submit,
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: enabled
                                ? () => Navigator.of(context).maybePop()
                                : null,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              foregroundColor: context.dr.textMuted,
                            ),
                            child: Text.rich(
                              TextSpan(
                                text: '${context.l10n.registerHaveAccount} ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: context.dr.textMuted,
                                ),
                                children: [
                                  TextSpan(
                                    text: context.l10n.loginSubmit,
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A [DrTextField] plus the validation line underneath it. Written once so the
/// six inputs on this form stay a list of arguments instead of six copies of
/// the same column.
class _FormRow extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;

  /// Message from [RegisterState.errors]; null hides the line entirely.
  final String? error;

  /// Called on the first keystroke after a failed submit, to clear [error].
  final VoidCallback onEdited;

  final bool enabled;
  final bool obscure;
  final Widget? trailing;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onSubmitted;

  const _FormRow({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    required this.error,
    required this.onEdited,
    this.enabled = true,
    this.obscure = false,
    this.trailing,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.none,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DrTextField(
          label: label,
          hint: hint,
          icon: icon,
          controller: controller,
          enabled: enabled,
          obscure: obscure,
          trailing: trailing,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          onChanged: (_) {
            if (error != null) onEdited();
          },
          onSubmitted: onSubmitted,
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(
            error!,
            style: const TextStyle(fontSize: 12, color: DrColors.redStrong),
          ),
        ],
      ],
    );
  }
}

/// Eye toggle inside a password field.
class _RevealButton extends StatelessWidget {
  final bool obscured;
  final VoidCallback onTap;

  const _RevealButton({required this.obscured, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        // Widens the tap target to the field's full height without moving the
        // icon off the right edge.
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 13),
        child: Semantics(
          button: true,
          label: obscured
              ? context.l10n.registerPasswordShow
              : context.l10n.registerPasswordHide,
          child: Icon(
            obscured
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 20,
            color: context.dr.textMuted,
          ),
        ),
      ),
    );
  }
}

/// "İstifadə şərtləri ilə razıyam" — the whole row is the tap target, so the
/// 22px box is never the only thing to hit.
class _TermsRow extends StatelessWidget {
  final bool accepted;
  final String? error;
  final VoidCallback? onTap;

  const _TermsRow({required this.accepted, required this.error, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: accepted
                        ? DrColors.accentGreen
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: accepted
                          ? DrColors.accentGreen
                          : (error != null
                              ? DrColors.redStrong
                              : context.dr.border),
                      width: 1.5,
                    ),
                  ),
                  child: accepted
                      ? const Icon(Icons.check_rounded,
                          size: 16, color: Colors.black)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.l10n.registerTerms,
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
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 34),
            child: Text(
              error!,
              style: const TextStyle(fontSize: 12, color: DrColors.redStrong),
            ),
          ),
        ],
      ],
    );
  }
}
