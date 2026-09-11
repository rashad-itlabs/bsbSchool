import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/l10n/l10n.dart';
import '../../features/auth/presentation/cubit/otp_cubit.dart';
import '../theme/dr_colors.dart';
import '../widgets/dr_widgets.dart';

/// The step between signing up and signing in: the parent types the 6-digit
/// code `/register` mailed them.
///
/// Pops `true` once the code is accepted — only then does the register screen
/// hand the credentials to login. Leaving any other way pops nothing, because
/// the account exists but cannot be signed into yet.
///
/// Expects an [OtpCubit] above it; the register screen provides one when it
/// pushes this route.
class OtpScreen extends StatefulWidget {
  final String email;

  const OtpScreen({super.key, required this.email});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _codeController = TextEditingController();
  final _codeFocus = FocusNode();

  /// Keeps a second dialog from stacking when the back control is hit twice.
  bool _confirmingLeave = false;

  /// Set once this route has been asked to close. States keep arriving during
  /// the exit transition — the cooldown tick, a resend landing after the code
  /// was accepted — and a second pop would take the register screen with it.
  bool _leaving = false;

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  void _onCodeChanged(String value) {
    // The boxes paint straight from the controller, so they need the frame.
    setState(() {});
    context.read<OtpCubit>().codeChanged();
    // Six digits is the whole input; asking for a button press after that is
    // one tap too many.
    if (value.length == OtpCubit.codeLength) _submit();
  }

  void _submit() {
    _codeFocus.unfocus();
    context.read<OtpCubit>().submit(_codeController.text);
  }

  void _resend() {
    context.read<OtpCubit>().resendCode();
  }

  /// Registration already created the account, so backing out here strands an
  /// unverified one — worth one question first.
  ///
  /// This also covers [DrBackHeader]'s own button: it offers no tap hook, but
  /// it leaves through `maybePop`, which the enclosing [PopScope] intercepts.
  Future<void> _confirmLeave() async {
    if (_confirmingLeave) return;
    _confirmingLeave = true;

    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.dr.bgSurface,
        title: Text(context.l10n.otpLeaveTitle),
        content: Text(context.l10n.otpLeaveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              context.l10n.otpLeaveStay,
              style: TextStyle(color: dialogContext.dr.accent),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              context.l10n.otpLeaveExit,
              style: const TextStyle(color: DrColors.redStrong),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;
    _confirmingLeave = false;
    if (leave == true) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OtpCubit, OtpState>(
      // `resendSeconds` ticks once a second; without this the confirmation
      // would be re-shown on every tick.
      listenWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.message != curr.message ||
          prev.isResending != curr.isResending,
      listener: (context, state) {
        // Nothing more to say once this route is on its way out.
        if (_leaving) return;

        if (state.status == OtpStatus.success) {
          // Register takes it from here: login shows the confirmation and
          // signs this account in.
          _leaving = true;
          // The leave confirmation can still be on top when the code is
          // accepted — the parent tapped back while the request was in
          // flight. Popping past it would hand `true` to the dialog, which
          // reads it as "exit" and then closes this screen with no result,
          // stranding a verified parent on the login screen.
          if (_confirmingLeave && ModalRoute.of(context)?.isCurrent == false) {
            Navigator.of(context).pop(false);
          }
          Navigator.of(context).pop(true);
          return;
        }
        // A rejected code is shown inline under the boxes; the resend
        // confirmation belongs nowhere on the page, so it passes through.
        if (state.status != OtpStatus.error &&
            !state.isResending &&
            state.message != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message!)));
        }
      },
      builder: (context, state) {
        final complete =
            _codeController.text.length == OtpCubit.codeLength;

        return PopScope(
          // The account is already created, so leaving is a decision rather
          // than a stray swipe — [_confirmLeave] does the popping instead.
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _confirmLeave();
          },
          child: Scaffold(
            backgroundColor: context.dr.bgDark,
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: DrBackHeader(title: context.l10n.otpTitle),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // The same glowing circle register opened with, so
                          // this reads as the next step of one flow.
                          Center(
                            child: Container(
                              width: 88,
                              height: 88,
                              margin: const EdgeInsets.only(bottom: 18),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    context.dr.accent.withValues(alpha: 0.08),
                                boxShadow: [
                                  BoxShadow(
                                    color: context.dr.accent
                                        .withValues(alpha: 0.2),
                                    blurRadius: 30,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.mark_email_read_rounded,
                                  size: 38,
                                  color: context.dr.accent,
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: Text(
                              context.l10n.otpSubtitle(widget.email),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: context.dr.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          DrGlowCard(
                            // Tighter than the default 24 so the six boxes
                            // keep their width on a narrow phone.
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 24,
                            ),
                            child: _CodeInput(
                              controller: _codeController,
                              focusNode: _codeFocus,
                              onChanged: _onCodeChanged,
                            ),
                          ),
                          // Whatever the backend rejects the code for lands
                          // here, right under the digits it refers to.
                          if (state.status == OtpStatus.error &&
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
                            label: context.l10n.otpVerify,
                            trailingIcon: Icons.check_rounded,
                            loading: state.isLoading,
                            onTap: complete ? _submit : null,
                          ),
                          const SizedBox(height: 8),
                          Center(child: _buildResend(context, state)),
                          const SizedBox(height: 4),
                          Center(
                            child: Text(
                              context.l10n.otpSpamHint,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.dr.textMuted,
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
      },
    );
  }

  /// The cooldown reads as plain text; only once it runs out does the resend
  /// become something to press.
  Widget _buildResend(BuildContext context, OtpState state) {
    if (state.resendSeconds > 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(
          context.l10n.otpResendIn(state.resendSeconds),
          style: TextStyle(fontSize: 13, color: context.dr.textMuted),
        ),
      );
    }

    return TextButton(
      onPressed: state.canResend ? _resend : null,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 48),
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
                color: state.canResend
                    ? context.dr.accent
                    : context.dr.textMuted,
              ),
            ),
    );
  }
}

/// Six boxes painted from one invisible [TextField] laid over them.
///
/// One field rather than six keeps the OS keyboard, paste and the e-mail
/// code's autofill working, and leaves no focus to hand between inputs when a
/// digit is typed or deleted.
class _CodeInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _CodeInput({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => focusNode.requestFocus(),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          IgnorePointer(child: _buildBoxes(context)),
          Positioned.fill(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              autofocus: true,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(OtpCubit.codeLength),
              ],
              decoration: const InputDecoration.collapsed(hintText: ''),
              // The boxes are the visible input; this field only collects.
              showCursor: false,
              enableInteractiveSelection: false,
              cursorColor: Colors.transparent,
              style: const TextStyle(color: Colors.transparent),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoxes(BuildContext context) {
    final code = controller.text;
    // The caret sits on the first empty box, or on the last one once all six
    // digits are in.
    final cursor = code.length.clamp(0, OtpCubit.codeLength - 1);

    return Row(
      children: [
        for (var i = 0; i < OtpCubit.codeLength; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          // Expanded instead of a plain 48 so six boxes still fit a narrow
          // phone; the inner width stops them stretching on a wide one.
          Expanded(
            child: Center(
              child: Container(
                width: 48,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.dr.bgDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: i == cursor ? context.dr.accent : context.dr.border,
                    width: i == cursor ? 1.5 : 1,
                  ),
                  boxShadow: i == cursor
                      ? [
                          BoxShadow(
                            color:
                                context.dr.accent.withValues(alpha: 0.25),
                            blurRadius: 16,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  i < code.length ? code[i] : '',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: context.dr.textMain,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
