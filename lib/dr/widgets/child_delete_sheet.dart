import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/l10n/l10n.dart';
import '../../features/auth/domain/entities/child_account.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../theme/dr_colors.dart';
import 'add_child_sheet.dart';
import 'dr_widgets.dart';

/// The trash icon on a student's card in the profile: removes that student
/// from the parent's account.
///
/// In order:
/// 1. the account password — checked by the backend in the same request that
///    removes the student, so a wrong one is retyped in place;
/// 2. the removal, through [AuthBloc], since it changes the session;
/// 3. [AddChildSheet], locked, until another student is linked.
///
/// With no student left the account is `needsChild` and AuthGate already
/// shows `AddChildScreen` — the same form, just as impossible to leave
/// without linking one — so the sheet is not stacked on top of it.
class ChildDeleteSheet extends StatelessWidget {
  final ChildAccount child;

  const ChildDeleteSheet({super.key, required this.child});

  Future<void> _delete(BuildContext context) async {
    // Read up front: the removal takes this card — and with the last student
    // the whole profile — off the tree. The navigator outlives both, so the
    // next sheet is opened from it.
    final navigator = Navigator.of(context);
    final authBloc = context.read<AuthBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final deletedMessage = context.l10n.childDeleted;

    final deleted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      // A drag closes the sheet past its PopScope, even mid-request — the
      // removal would then land with nobody left to open step 3.
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChildDeletePasswordSheet(child: child),
    );
    if (deleted != true || !navigator.mounted) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(deletedMessage)));

    if (authBloc.state.user?.needsChild ?? false) return;
    await showAddChildSheet(navigator.context, locked: true);
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.select<AuthBloc, bool>(
      (bloc) => bloc.state.isRemovingChild,
    );

    return IconButton(
      onPressed: busy ? null : () => _delete(context),
      visualDensity: VisualDensity.compact,
      tooltip: context.l10n.childDeleteTitle,
      icon: const Icon(Icons.delete_outline, color: DrColors.redStrong),
    );
  }
}

/// Asks for the account password and removes [child] with it. Stays open,
/// busy, while the request runs; a wrong password is shown under the field.
/// Pops `true` once the student is gone.
class _ChildDeletePasswordSheet extends StatefulWidget {
  final ChildAccount child;

  const _ChildDeletePasswordSheet({required this.child});

  @override
  State<_ChildDeletePasswordSheet> createState() =>
      _ChildDeletePasswordSheetState();
}

class _ChildDeletePasswordSheetState extends State<_ChildDeletePasswordSheet> {
  final _password = TextEditingController();
  bool _obscured = true;

  /// The empty-field check, or the message `/detachChild` came back with.
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (_password.text.isEmpty) {
      setState(() => _error = context.l10n.profileCurrentPasswordRequired);
      return;
    }

    setState(() => _error = null);
    context.read<AuthBloc>().add(AuthChildRemoved(
          childId: widget.child.childId!,
          password: _password.text,
        ));
  }

  void _onSettled(BuildContext context, AuthState state) {
    final failure = state.removeChildError;
    if (failure != null) {
      setState(() => _error = failure);
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.select<AuthBloc, bool>(
      (bloc) => bloc.state.isRemovingChild,
    );
    final name = widget.child.fullName;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.isRemovingChild && !current.isRemovingChild,
      listener: _onSettled,
      child: PopScope(
        // Closing mid-flight would leave the request running with nowhere to
        // report back to.
        canPop: !busy,
        child: Padding(
          // Keeps the field above the keyboard the autofocus just raised.
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: context.dr.bgSurface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // No grab handle: the sheet can't be dragged away.
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: DrColors.redStrong.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: DrColors.redStrong,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            context.l10n.childDeleteTitle,
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
                    const SizedBox(height: 14),
                    Text(
                      context.l10n.childDeleteText(name),
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: context.dr.textMuted,
                      ),
                    ),
                    const SizedBox(height: 18),
                    DrTextField(
                      label: context.l10n.loginPassword,
                      hint: '••••••••',
                      icon: Icons.lock_outline,
                      obscure: _obscured,
                      controller: _password,
                      enabled: !busy,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                      onSubmitted: (_) => _submit(),
                      trailing: GestureDetector(
                        onTap: () => setState(() => _obscured = !_obscured),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 13,
                          ),
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
                      ),
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
                    const SizedBox(height: 20),
                    _deleteButton(busy),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// [DrPrimaryButton]'s shape in red, like the account deletion's button.
  Widget _deleteButton(bool busy) {
    return Semantics(
      button: true,
      enabled: !busy,
      child: GestureDetector(
        onTap: busy ? null : _submit,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: DrColors.redStrong,
            borderRadius: BorderRadius.circular(16),
          ),
          child: busy
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  context.l10n.commonDelete,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
