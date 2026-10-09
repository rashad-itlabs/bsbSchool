import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/l10n/l10n.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../theme/dr_colors.dart';
import 'dr_widgets.dart';

/// Opens [AddChildSheet].
///
/// [locked] keeps it open until a student is linked: no close button, and
/// neither a tap outside, a drag nor the back button takes it down. Used right
/// after a student was removed, when the parent is expected to link another.
Future<void> showAddChildSheet(BuildContext context, {bool locked = false}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: !locked,
    enableDrag: !locked,
    backgroundColor: Colors.transparent,
    builder: (_) => AddChildSheet(locked: locked),
  );
}

/// Links one more student to the signed-in parent account, by admission
/// number — the same code registration asks for, since it is the only thing a
/// parent holds that names a student without exposing the school's ids.
///
/// A sheet rather than a route: the parent came here to look at their
/// students, and lands back on that list with the new one in it.
///
/// The request runs on [AuthBloc], not here, because its result changes the
/// signed-in session — the sheet only reads `isAddingChild` / `addChildError`
/// back out.
class AddChildSheet extends StatefulWidget {
  /// See [showAddChildSheet].
  final bool locked;

  const AddChildSheet({super.key, this.locked = false});

  @override
  State<AddChildSheet> createState() => _AddChildSheetState();
}

class _AddChildSheetState extends State<AddChildSheet> {
  final _admissionController = TextEditingController();

  /// What the field is currently being told off for: the empty-input check
  /// below, or the message `/attachChild` came back with.
  String? _error;

  @override
  void dispose() {
    _admissionController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final admissionNo = _admissionController.text.trim();
    if (admissionNo.isEmpty) {
      setState(() => _error = context.l10n.addChildEnterNumber);
      return;
    }

    setState(() => _error = null);
    context.read<AuthBloc>().add(AuthChildAdded(admissionNo));
  }

  /// Fires once the request settles. A rejected code keeps the sheet open with
  /// the server's wording under the field — the parent's next move is to
  /// correct the number, and closing would make them start over.
  void _onSettled(BuildContext context, AuthState state) {
    final failure = state.addChildError;
    if (failure != null) {
      setState(() => _error = failure);
      return;
    }

    // Both are read before the pop, which deactivates this context.
    final messenger = ScaffoldMessenger.of(context);
    final addedMessage = context.l10n.addChildAdded;

    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(addedMessage)));
  }

  /// The locked sheet's only other way out, as on `AddChildScreen`: without
  /// it a parent with no admission number at hand is stuck.
  Future<void> _logout() async {
    final authBloc = context.read<AuthBloc>();
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.dr.bgSurface,
        title: Text(context.l10n.settingsLogout),
        content: Text(context.l10n.settingsLogoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              context.l10n.commonCancel,
              style: TextStyle(color: context.dr.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              context.l10n.settingsLogout,
              style: TextStyle(color: dialogContext.dr.accent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    // The sheet sits on the navigator, above AuthGate: left open it would
    // cover the login screen. [PopScope] does not stop a direct pop.
    navigator.pop();
    authBloc.add(const AuthLogoutRequested());
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.locked,
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            previous.isAddingChild && !current.isAddingChild,
        listener: _onSettled,
        child: _body(context),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final submitting = context.select<AuthBloc, bool>(
      (bloc) => bloc.state.isAddingChild,
    );

    return Padding(
      // Keeps the field above the keyboard the autofocus just raised.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.dr.bgSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The handle promises a drag the locked sheet doesn't allow.
                if (!widget.locked)
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: context.dr.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.dr.accentSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 20,
                        color: context.dr.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.l10n.addChildTitle,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    // Closing mid-flight would leave the request running with
                    // nowhere to report back to.
                    if (!widget.locked)
                      GestureDetector(
                        onTap: submitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Icon(Icons.close, color: context.dr.textMuted),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  widget.locked
                      ? context.l10n.addChildRequiredText
                      : context.l10n.addChildAnotherText,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: context.dr.textMuted,
                  ),
                ),
                const SizedBox(height: 20),
                DrTextField(
                  label: context.l10n.addChildField,
                  hint: context.l10n.addChildHint,
                  icon: Icons.badge_outlined,
                  controller: _admissionController,
                  enabled: !submitting,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  // Codes are alphanumeric: keep iOS from capitalising the
                  // first character on the parent's behalf.
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
                const SizedBox(height: 16),
                const _WhereToFindHint(),
                const SizedBox(height: 20),
                DrPrimaryButton(
                  label: context.l10n.addChildSubmit,
                  trailingIcon: Icons.arrow_forward_rounded,
                  loading: submitting,
                  onTap: _submit,
                ),
                if (widget.locked) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: submitting ? null : _logout,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        foregroundColor: context.dr.textMuted,
                      ),
                      child: Text(
                        context.l10n.addChildOtherAccount,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Where the admission number lives, so an unknown code is a lookup rather
/// than a call to the school. Compact twin of `AddChildScreen`'s card — the
/// sheet has a keyboard to share the screen with.
class _WhereToFindHint extends StatelessWidget {
  const _WhereToFindHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.dr.bgSurfaceLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline_rounded,
                size: 16,
                color: context.dr.accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.addChildWhereTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final line in [
            context.l10n.addChildWhere1,
            context.l10n.addChildWhere2,
            context.l10n.addChildWhere3,
          ])
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.dr.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      line,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
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
